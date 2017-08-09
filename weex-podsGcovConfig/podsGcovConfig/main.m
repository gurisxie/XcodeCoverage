//
//  main.m
//  podsGcovConfig
//
//  Created by 鲁强 on 16/5/16.
//  Copyright © 2016年 鲁强. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>

void generagePods(NSString *projectDir);
void generateEnv(NSString *projectDir);
void generateXcodeIgnore(NSString *projectDir);
NSString *projectDir();

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSString *projectPath = projectDir();
        generagePods(projectPath);
        generateEnv(projectPath);
        generateXcodeIgnore(projectPath);
        NSLog(@"pods gcov config finished");
    }
    return 0;
}

void generagePods(NSString *projectDir){
    // get plist path
    NSString *path = [NSString stringWithFormat:@"%@/Pods/Pods.xcodeproj/project.pbxproj", projectDir];
    NSLog(@"target file path:%@", path);
    
    // get root object id
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    NSString *rootObject = plist[@"rootObject"];
    NSMutableDictionary *objects = plist[@"objects"];
    NSDictionary *projectObject = objects[rootObject];
    
    // get targets
    NSArray *targets = projectObject[@"targets"];
    for (NSString *targetID in targets) {
        NSDictionary *target = objects[targetID];
        if ([target[@"name"] isEqualToString:@"WeexSDK"]) {
            NSString *buildConfigurationListID = target[@"buildConfigurationList"];
            NSDictionary *buildConfigurationList = objects[buildConfigurationListID];
            NSArray *buildConfigurationIDs = buildConfigurationList[@"buildConfigurations"];
            
            for (NSDictionary *buildConfigurationID in buildConfigurationIDs) {
                NSDictionary *buildConfiguration = objects[buildConfigurationID];
                NSMutableDictionary *buildSettings = buildConfiguration[@"buildSettings"];
                buildSettings[@"GCC_INSTRUMENT_PROGRAM_FLOW_ARCS"] = @"YES";
                buildSettings[@"GCC_GENERATE_TEST_COVERAGE_FILES"] = @"YES";
            }
            
        }
    }
    
    // write to file
    [plist writeToFile:path atomically:YES];

}

NSString *projectDir(){
    
    char folderPath[512];
    unsigned size = 512;
    _NSGetExecutablePath(folderPath, &size);
    for (int i = size-1; i>0; i--) {
        if (folderPath[i] == '/') {
            folderPath[i] = '\0';
            size = i;
            break;
        }
    }
    if (folderPath[size - 1] == '.' && folderPath[size - 2] == '/') {
        folderPath[size-2] = '/';
        size -= 2;
    }
    for (int i = size-1; i>0; i--) {
        if (folderPath[i] == '/') {
            folderPath[i] = '\0';
            size = i;
            break;
        }
    }
    if (folderPath[size - 1] == '.' && folderPath[size - 2] == '/') {
        folderPath[size-2] = '/';
        size -= 2;
    }
    NSString *projectDir = [NSString stringWithFormat:@"%s", folderPath];
    if([[projectDir lastPathComponent] isEqualToString:@"."]){
        projectDir = [projectDir stringByDeletingLastPathComponent];
    }
    return projectDir;
}

void generateEnv(NSString *projectDir){
    NSString* envFile = [NSString stringWithFormat:@"%@/XcodeCoverage/env.sh", projectDir];
    NSMutableString *content = [NSMutableString string];
    NSLog(@"generateEnv rootPath:%@", projectDir);
    [content appendFormat:@"export SRCROOT=\"%@\"\n",projectDir];
    [content appendString:@"export BUILT_PRODUCTS_DIR=\"${SRCROOT}/DerivedData/WeexDemo/Build/Products/Debug-iphonesimulator\"\n"];
    [content appendString:@"export CURRENT_ARCH=\"x86_64\"\n"];
    [content appendString:@"export OBJECT_FILE_DIR_normal=\"${SRCROOT}/DerivedData/WeexDemo/Build/Intermediates/Pods.build/Debug-iphonesimulator/WeexSDK.build/Objects-normal\"\n"];
    [content appendString:@"export OBJROOT=\"${SRCROOT}/DerivedData/WeexDemo/Build/Intermediates\""];
    [content writeToFile:envFile atomically:YES];
    
}

void generateXcodeIgnore(NSString *projectDir){
    NSLog(@"generateXcodeIgnore rootPath:%@", projectDir);
    NSString* xcodeIgnoreFile = [NSString stringWithFormat:@"%@/.xcodecoverageignore", projectDir];
    NSMutableString *content = [NSMutableString string];
    [content appendFormat:@"%@/WeexDemo/*\n",projectDir];
    [content appendString:@"/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/*\n"];
    [content appendString:@"/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/*\n"];
    NSString* parentDir = [projectDir stringByDeletingLastPathComponent];
    [content appendFormat:@"%@/sdk/WeexSDK/Sources/WebSocket/*\n",parentDir];
    [content appendFormat:@"%@/sdk/WeexSDK/Sources/Debug/*\n",parentDir];
    
    [content writeToFile:xcodeIgnoreFile atomically:YES];

}

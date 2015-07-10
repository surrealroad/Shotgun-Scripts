//
//  PythonHandler.h
//  Shotgun Scripts
//
//  Created by Jack James on 10/07/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Logger.h"

@interface PythonHandler : NSObject {
    
}

+ (PythonHandler*) sharedManager;

- (BOOL)setupPythonEnvironment;

- (BOOL)loadScriptAtPath:(NSString*)scriptPath runFunction:(NSString*)functionName usingLogger:(Logger*)logger withArguments:(NSMutableArray*)arguments;

- (void)logPythonError:(Logger*)logger;

@end
//
//  AppDelegate.h
//  SGAPI Test
//
//  Created by Jack James on 07/07/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSPipe *pipe, *errorPipe;
    NSFileHandle *pipeReadHandle, *errorPipeReadHandle;
    NSMutableArray *scripts;
}

- (void)handleNotification:(NSNotification*) notification;
- (void)handleErrorNotification:(NSNotification*) notification;
- (NSDictionary *)getConfigurationForScriptExecution:(NSDictionary*) script;
- (void)execPythonScript:(NSDictionary*) script;
- (BOOL)runPythonScript:(NSString*)scriptPath runFunction:(NSString*)functionName withArguments:(NSArray*)arguments;
- (void)restoreInterface;
- (void)resetScriptMenu;
-(NSString *)getKeychainPasswordForURL:(NSURL *)url username:(NSString *)username;
- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent;
- (NSUInteger) indexOfScriptWithFilename: (NSString*) filename;
- (NSString *)getDataFromSourceString:(NSString *)data afterString:(NSString *)leftData;
@end

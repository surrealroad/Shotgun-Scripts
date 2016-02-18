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
    NSArray *scripts;
}

- (void)handleNotification:(NSNotification*) notification;
- (void)handleErrorNotification:(NSNotification*) notification;
- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent;
- (BOOL)runPythonScript:(NSString*)scriptPath runFunction:(NSString*)functionName withArguments:(NSMutableArray*)arguments;
- (NSUInteger) indexOfScriptWithFilename: (NSString*) filename;

@end

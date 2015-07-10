//
//  AppDelegate.h
//  SGAPI Test
//
//  Created by Jack James on 07/07/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Python/Python.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSPipe *pipe;
    NSFileHandle *pipeReadHandle;
}

- (void)handleNotification:(NSNotification*) notification;

@end
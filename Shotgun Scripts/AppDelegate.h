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

@end

//
//  AppDelegate.m
//  SGAPI Test
//
//  Created by Jack James on 07/07/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

#import "AppDelegate.h"
#import "PythonHandler.h"
#import "Logger.h"

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
// http://stackoverflow.com/a/8958316/262455
@property (weak) IBOutlet Logger *logger;
// http://stackoverflow.com/a/14936588/262455
@property (weak) IBOutlet NSArrayController *controller;
@property (weak) IBOutlet NSProgressIndicator *circularProgress;
@property (weak) IBOutlet NSButton *runButton;
@property (weak) IBOutlet NSPopUpButton *popupButton;
@property (unsafe_unretained) IBOutlet NSTextView *textView;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    if (![[PythonHandler sharedManager] setupPythonEnvironment])
        [self.logger appendErrorMessage:@"Error: python environment could not be set up."];
    
    // http://stackoverflow.com/a/2590723/262455
    pipe = [NSPipe pipe] ;
    pipeReadHandle = [pipe fileHandleForReading] ;
    dup2([[pipe fileHandleForWriting] fileDescriptor], fileno(stdout)) ;
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleNotification:) name: NSFileHandleReadCompletionNotification object: pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify] ;

}

// http://stackoverflow.com/a/1991162/262455
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    [[NSAppleEventManager sharedAppleEventManager]
     setEventHandler:self
     andSelector:@selector(handleURLEvent:withReplyEvent:)
     forEventClass:kInternetEventClass
     andEventID:kAEGetURL]; // http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/ScriptableCocoaApplications/SApps_handle_AEs/SAppsHandleAEs.html#//apple_ref/doc/uid/20001239-BBCIDFHG
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
    Py_Finalize();
}

- (void) awakeFromNib {
    // set up progress
    [self.circularProgress startAnimation:nil];
    [self.circularProgress setHidden:YES];
    [self.circularProgress setIndeterminate:YES];
    [self.circularProgress setUsesThreadedAnimation:YES];
    
    
    // load from plist
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"scripts" ofType:@"plist"]];
    //NSLog(@"dictionary = %@", dictionary);
    NSArray *scripts = [dictionary objectForKey:@"scripts"];
    
    // populate controller array with items
    for (id script in scripts) {
        // add full path to script dict
        NSString *path = [[NSBundle mainBundle] pathForResource:[script valueForKey:@"filename"] ofType:@"py"];
        if(path) {
            [script setObject:path forKey:@"filepath"];
            [self.controller addObject:@{
                                         @"name" :[script valueForKey:@"name"],
                                         @"description":[script valueForKey:@"description"],
                                         @"script":script,
                                         }];
        }
    }
    
    // reset options to first in list
    [self.controller setSelectionIndex:0];
}

// intercepts stdout
- (void)handleNotification:(NSNotification*) notification {
    [pipeReadHandle readInBackgroundAndNotify] ;
    NSString *str = [[NSString alloc] initWithData: [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem] encoding: NSASCIIStringEncoding] ;
    // Do whatever you want with str
    [self.logger appendLogMessage:str];
}

- (void)execPythonScript:(NSDictionary*) script {
    // runs the script's process_action()
    [self.logger appendLogMessage:[NSString stringWithFormat:@"Running %@\n",[script valueForKey:@"name"]]];
    // start progress indicator
    [self.circularProgress setHidden:NO];
    
    // disable buttons/fields
    [self.runButton setEnabled:NO];
    [self.popupButton setEnabled:NO];
    [self.textView setEditable:NO];
    
    PythonHandler *pythonHandler = [PythonHandler sharedManager];
    // set arguments
    NSMutableArray *args = [[NSMutableArray alloc] init];
    
    if ([script valueForKey:@"chooseFolder"]) {
        // http://stackoverflow.com/a/10922591/262455
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setAllowsMultipleSelection:NO];
        [panel setCanChooseDirectories:YES];
        [panel setCanChooseFiles:NO];
        if ([panel runModal] != NSFileHandlingPanelOKButton) return;
        NSURL *folder = [[panel URLs] lastObject];
        [args addObject:[folder path]];
    }
    
    if ([script valueForKey:@"arguments"]) {
        [args addObjectsFromArray:[script valueForKey:@"arguments"]];
    }
    
    BOOL success = [pythonHandler loadScriptAtPath:[script valueForKey:@"filepath"]
                                       runFunction:@"process_action"
                                       usingLogger:[self logger]
                                     withArguments:args];
    
    if (!success) {
        [pythonHandler logPythonError:self.logger];
        NSRunAlertPanel(@"Script Failed", @"The script could not be completed.", nil, nil, nil);
    }
    
    // stop progress indicator
    [self.circularProgress setHidden:YES];
    // enable buttons/fields
    [self.runButton setEnabled:YES];
    [self.popupButton setEnabled:YES];
    [self.textView setEditable:YES];
}

- (IBAction)runScript:(id)sender {
    NSDictionary *script = [[self.controller.selectedObjects objectAtIndex:0] objectForKey:@"script"];
    [self execPythonScript:script];
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event
        withReplyEvent:(NSAppleEventDescriptor*)replyEvent {
    NSString* url = [[event paramDescriptorForKeyword:keyDirectObject]
                     stringValue];
    NSLog(@"%@", url);
}

@end
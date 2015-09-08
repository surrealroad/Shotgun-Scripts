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
#import "NSURL+ParseCategory.h"

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
    
    // http://stackoverflow.com/a/2590723/262455
    pipe = [NSPipe pipe] ;
    pipeReadHandle = [pipe fileHandleForReading] ;
    dup2([[pipe fileHandleForWriting] fileDescriptor], fileno(stdout)) ;
    
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleNotification:) name: NSFileHandleReadCompletionNotification object: pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify] ;

}

// http://stackoverflow.com/a/1991162/262455
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    if (![[PythonHandler sharedManager] setupPythonEnvironment])
        [self.logger appendErrorMessage:@"Error: python environment could not be set up."];
    
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
    
    if(scripts == nil) {
        // load from plist
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"scripts" ofType:@"plist"]];
        //NSLog(@"plist = %@", plist);
        scripts = [plist objectForKey:@"scripts"];
        //NSLog(@"%lu", (unsigned long)[scripts count]);
    }
        
    // populate controller array with items
    for (id script in scripts) {
        // add full path to script dict
        NSString *path = [[NSBundle mainBundle] pathForResource:[script valueForKey:@"filename"] ofType:@"py"];
        BOOL shouldDisplay = YES;
        if([script valueForKey:@"visible"]) {
            shouldDisplay = [[script valueForKey:@"visible"] boolValue];
            if(!shouldDisplay) NSLog(@"Skipping hidden script %@", [script valueForKey:@"name"]);
        }
        if(path && shouldDisplay) {
            NSLog(@"Adding script %@", [script valueForKey:@"name"]);
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
        if ([panel runModal] != NSFileHandlingPanelOKButton) {
            [self.logger appendLogMessage:[NSString stringWithFormat:@"Script cancelled.\n"]];
            [self restoreInterface];
            return;
        }
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
        [pythonHandler logPythonError:self.logger]; // doesn't appear to work
        NSRunAlertPanel(@"Script Failed", @"The script could not be completed.", nil, nil, nil);
    }
    
    [self restoreInterface];
    
    // terminate on completion if needed
    BOOL shouldTerminate = NO;
    if ([script valueForKey:@"quitAfter"]) {
        shouldTerminate = [[script valueForKey:@"quitAfter"] boolValue];
    }
    
    if(shouldTerminate) [[NSApplication sharedApplication] terminate:nil];
    //exit(0);
}

- (void)restoreInterface {
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
    
/*    expected URL in the form
        sgscripts://sg_gantt?user_id=42&user_login=jack.james&title=&entity_type=Task&server_hostname=nightingale.shotgunstudio.com&referrer_path=%2Fdetail%2FHumanUser%2F42&page_id=1861&session_uuid=dd8841a0-41cb-11e5-9b33-0242ac110002&project_name=Nightingale%20VFX&project_id=67&ids=2076%2C2077%2C2078%2C2132%2C2133%2C2134%2C2135%2C2136%2C2137%2C2138&selected_ids=2076%2C2078%2C2132%2C2133%2C2136&cols=content&cols=step&cols=sg_status_list&cols=task_assignees&cols=start_date&cols=due_date&cols=duration&cols=entity&column_display_names=Task%20Name&column_display_names=Pipeline%20Step&column_display_names=Status&column_display_names=Assigned%20To&column_display_names=Start%20Date&column_display_names=Due%20Date&column_display_names=Duration&column_display_names=Link&grouping_column=entity&grouping_method=exact&grouping_direction=asc
*/
    
    NSString* urlString = [[event paramDescriptorForKeyword:keyDirectObject]
                     stringValue];
    NSLog(@"%@", urlString);
    
    // convert to NSURL
    NSURL *url = [NSURL URLWithString:urlString];
    
    // filename will be the path
    // http://stackoverflow.com/a/1967451/262455
    NSString *scriptFilename = [url host];
    NSDictionary *params = [url queryDictionary];

    NSUInteger scriptIndex = [self indexOfScriptWithFilename:scriptFilename];
    NSLog(@"Params: %@",params);
    if(scriptIndex != NSNotFound) {
        NSLog(@"Executing %@", scriptFilename);
        NSMutableDictionary *script = scripts[scriptIndex];
        
        // add full path to script dict
        NSString *path = [[NSBundle mainBundle] pathForResource:[script valueForKey:@"filename"] ofType:@"py"];
        [script setObject:path forKey:@"filepath"];
        
        // set arguments (there's probably a cleaner way to do this)
        NSMutableArray *args = [[NSMutableArray alloc] initWithObjects:params, nil];
        if([script valueForKey:@"arguments"]) [args addObjectsFromArray:[script valueForKey:@"arguments"]];
        [script setObject:args forKey:@"arguments"];
        
        // make the controller display the correct info
        // remove all other options
        [self.controller setContent:@{
                                     @"name" :[script valueForKey:@"name"],
                                     @"description":[script valueForKey:@"description"],
                                     @"script":script,
                                     }];
        // reset options to first in list
        [self.controller setSelectionIndex:0];

        [self execPythonScript:script];
    }
}

// http://stackoverflow.com/a/5135053/262455
- (NSUInteger) indexOfScriptWithFilename: (NSString*) filename {
    return [scripts indexOfObjectPassingTest:
            ^BOOL(id dictionary, NSUInteger idx, BOOL *stop) {
                return [[dictionary objectForKey: @"filename"] isEqualToString: filename];
            }];
}

// terminate on last window closed
- (BOOL) applicationShouldTerminateAfterLastWindowClosed {
    return YES;
}

@end
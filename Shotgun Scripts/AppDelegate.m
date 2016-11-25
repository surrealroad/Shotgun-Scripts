 //
//  AppDelegate.m
//  SGAPI Test
//
//  Created by Jack James on 07/07/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

#import "AppDelegate.h"
#import "Logger.h"
#import "NSURL+ParseCategory.h"

@interface AppDelegate () <NSUserNotificationCenterDelegate>
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
    [[NSUserNotificationCenter defaultUserNotificationCenter] setDelegate:self];

}

// http://stackoverflow.com/a/1991162/262455
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    
    // Set up URL handling
    [[NSAppleEventManager sharedAppleEventManager]
     setEventHandler:self
     andSelector:@selector(handleURLEvent:withReplyEvent:)
     forEventClass:kInternetEventClass
     andEventID:kAEGetURL]; // http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/ScriptableCocoaApplications/SApps_handle_AEs/SAppsHandleAEs.html#//apple_ref/doc/uid/20001239-BBCIDFHG
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void) awakeFromNib {
    dispatch_async(dispatch_get_main_queue(), ^{
        // set up progress
        [self.circularProgress startAnimation:nil];
        [self.circularProgress setHidden:YES];
        [self.circularProgress setIndeterminate:YES];
        [self.circularProgress setUsesThreadedAnimation:YES];
        
        // disable buttons/fields
        [self.runButton setEnabled:NO];
        [self.popupButton setEnabled:NO];
        [self.textView setEditable:NO];
    });
    
    if(scripts == nil) {
        // load from plist
        NSDictionary *plist = nil; //[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"scripts" ofType:@"plist"]];
        if(plist){
            //NSLog(@"plist = %@", plist);
            scripts = [plist objectForKey:@"scripts"];
        } else {
            scripts = [[NSMutableArray alloc] init];
            // read info from files
            NSError *error = nil;
            NSString *scriptsPath = [[NSBundle mainBundle] pathForResource:@"Scripts" ofType:nil];
            NSArray *scriptfiles =  [[NSFileManager defaultManager] contentsOfDirectoryAtPath:scriptsPath error: &error];
            
            // get files from scripts subfolder
            for (id scriptfile in scriptfiles) {
                if([[scriptfile pathExtension]  isEqual: @"py"]) {
                    NSString *scriptPath = [scriptsPath stringByAppendingPathComponent:scriptfile];
                    //NSLog(@"%@", scriptPath);
                    // parse the file for settings
                    NSString *scriptContents = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:nil];
                    if (scriptContents) {
                        //NSLog(@"%@", scriptContents);
                        NSString *scriptName = [self getDataFromSourceString:scriptContents afterString:@"@SGS_NAME:"];
                        if (scriptName) {
                            // Appears to be valid, get all other options and add to array
                            NSMutableDictionary *parsedScript = [[NSMutableDictionary alloc]
                                    initWithObjectsAndKeys:
                                       scriptPath, @"filepath",
                                       [[scriptPath lastPathComponent] stringByDeletingPathExtension], @"filename",
                                       scriptName, @"name",
                                       [self getDataFromSourceString:scriptContents afterString:@"@SGS_DESCRIPTION:"], @"description",
                                    nil
                            ];
                            NSString *chooseFolderString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_CHOOSEFOLDER:"];
                            if (chooseFolderString) {
                                [parsedScript setObject:chooseFolderString forKey:@"chooseFolder"];
                            }
                            NSString *chooseFileString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_CHOOSEFILE:"];
                            if (chooseFileString) {
                                [parsedScript setObject:chooseFileString forKey:@"chooseFile"];
                            }
                            NSString *saveFileString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_SAVEFILE:"];
                            if (saveFileString) {
                                [parsedScript setObject:saveFileString forKey:@"saveFile"];
                            }
                            NSString *quitAfterString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_QUITAFTER:"];
                            if (quitAfterString) {
                                [parsedScript setObject:quitAfterString forKey:@"quitAfter"];
                            }
                            NSString *notifyAfterString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_NOTIFYAFTER:"];
                            if (notifyAfterString) {
                                [parsedScript setObject:notifyAfterString forKey:@"notifyAfter"];
                            }
                            NSString *visibleString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_VISIBLE:"];
                            if (visibleString) {
                                [parsedScript setObject:visibleString forKey:@"visible"];
                            }
                            
                            [scripts addObject: parsedScript];
                            //NSLog(@"%@", parsedScript);
                            
                        } else {
                            NSLog(@"Skipping invalid or incorrectly formatted script %@", scriptName);
                        }
                    }
                } else {
                    NSLog(@"Skipping %@", scriptfile);
                }
            }
            
        }
    }
    
    NSLog(@"%lu", (unsigned long)[scripts count]);
    
    [self resetScriptMenu];
    }

// reset script selector
- (void)resetScriptMenu {
    // remove any existing items
    [self.controller setContent:nil];
    // populate controller array with items
    for (id script in scripts) {
        NSLog(@"%@", script);
        // add full path to script dict if it is missing
        NSString *path;
        if([script valueForKey:@"filepath"]) {
            path = [script valueForKey:@"filepath"];
        } else {
            path = [[NSBundle mainBundle] pathForResource:[script valueForKey:@"filename"] ofType:@"py"];
        }
        // default function name
        if(![script valueForKey:@"function"]) [script setValue:@"process_action" forKey:@"function"];
        BOOL shouldDisplay = YES;
        if([script valueForKey:@"visible"]) {
            shouldDisplay = [[script valueForKey:@"visible"] boolValue];
            if(!shouldDisplay) NSLog(@"Skipping hidden script %@", [script valueForKey:@"name"]);
        }
        if(path && shouldDisplay) {
            NSLog(@"Adding script %@", [script valueForKey:@"name"]);
            [script setObject:path forKey:@"filepath"];
            NSString *description = [script valueForKey:@"description"];
            if (!description) description = @"";
            
            [self.controller addObject:@{
                                         @"name" :[script valueForKey:@"name"],
                                         @"description":description,
                                         @"script":script,
                                         }];
        }
    }
    // reset options to first in list
    [self.controller setSelectionIndex:0];
    [self restoreInterface];
}

// intercepts stdout
- (void)handleNotification:(NSNotification*) notification {
    [pipeReadHandle readInBackgroundAndNotify] ;
    NSString *str = [[NSString alloc] initWithData: [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem] encoding: NSUTF8StringEncoding] ;
    // Do whatever you want with str
    [self.logger appendLogMessage:str];
}

// intercepts stderr
- (void)handleErrorNotification:(NSNotification*) notification {
    [errorPipeReadHandle readInBackgroundAndNotify] ;
    NSString *str = [[NSString alloc] initWithData: [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem] encoding: NSUTF8StringEncoding] ;
    // Do whatever you want with str
    [self.logger appendErrorMessage:str];
}

- (void)execPythonScript:(NSDictionary*) script {
    // runs the script's process_action()
    [self.logger appendLogMessage:[NSString stringWithFormat:@"Running %@\n",[script valueForKey:@"name"]]];
    
    // set arguments
    NSMutableArray *args = [[NSMutableArray alloc] init];
    
    BOOL chooseFolder = NO;
    if ([script valueForKey:@"chooseFolder"]) {
        chooseFolder = [[script valueForKey:@"chooseFolder"] boolValue];
    }
    BOOL chooseFile = NO;
    if ([script valueForKey:@"chooseFile"]) {
        chooseFile = [[script valueForKey:@"chooseFile"] boolValue];
    }
    BOOL saveFile = NO;
    if ([script valueForKey:@"saveFile"]) {
        saveFile = [[script valueForKey:@"saveFile"] boolValue];
    }
    BOOL shouldTerminate = NO;
    if ([script valueForKey:@"quitAfter"]) {
        shouldTerminate = [[script valueForKey:@"quitAfter"] boolValue];
    }
    BOOL notifyAfter = NO;
    if ([script valueForKey:@"notifyAfter"]) {
        notifyAfter = [[script valueForKey:@"notifyAfter"] boolValue];
    }
    
    NSString *resultPath = @"";
    NSURL *resultURL = nil;
    
    if (chooseFolder) {
        // http://stackoverflow.com/a/10922591/262455
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setAllowsMultipleSelection:NO];
        [panel setCanChooseDirectories:YES];
        [panel setCanCreateDirectories:YES];
        [panel setCanChooseFiles:NO];
        if ([panel runModal] != NSFileHandlingPanelOKButton) {
            [self.logger appendLogMessage:[NSString stringWithFormat:@"Script cancelled.\n"]];
            [self restoreInterface];
            return;
        }
        NSURL *resultURL = [[panel URLs] lastObject];
        resultPath = [resultURL path];
        [args addObject:resultPath];
    } else if (chooseFile) {
        NSOpenPanel *panel = [NSOpenPanel openPanel];
        [panel setAllowsMultipleSelection:NO];
        [panel setCanChooseDirectories:NO];
        [panel setCanChooseDirectories:YES];
        [panel setCanChooseFiles:YES];
        if ([panel runModal] != NSFileHandlingPanelOKButton) {
            [self.logger appendLogMessage:[NSString stringWithFormat:@"Script cancelled.\n"]];
            [self restoreInterface];
            return;
        }
        NSURL *resultURL = [[panel URLs] lastObject];
        resultPath = [resultURL path];
        [args addObject:resultPath];
    }
    
    if (saveFile) {
        NSDictionary *saveOptions = [script valueForKey:@"saveFile"];
        NSSavePanel *panel = [NSSavePanel savePanel];
        [panel setMessage:@"Choose where to save the file"]; // Message inside modal window
        [panel setAllowsOtherFileTypes:YES];
        [panel setExtensionHidden:YES];
        [panel setCanCreateDirectories:YES];
        if ([saveOptions valueForKey:@"default"]) {
            [panel setNameFieldStringValue:[saveOptions valueForKey:@"default"]];
        }
        
        [panel setTitle:@"Save file as"]; // Window title
        
        if ([panel runModal] != NSFileHandlingPanelOKButton) {
            [self.logger appendLogMessage:[NSString stringWithFormat:@"Script cancelled.\n"]];
            [self restoreInterface];
            return;
        }
        NSURL *resultURL = [panel URL];
        resultPath = [resultURL path];
        [args addObject:resultPath];
    }
    
    if ([script valueForKey:@"arguments"]) {
        [args addObjectsFromArray:[script valueForKey:@"arguments"]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // start progress indicator
        [self.circularProgress setHidden:NO];
        
        // disable buttons/fields
        [self.runButton setEnabled:NO];
        [self.popupButton setEnabled:NO];
        [self.textView setEditable:NO];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        BOOL success = [self runPythonScript:[script valueForKey:@"filepath"]
                                 runFunction:[script valueForKey:@"function"]
                               withArguments:args];
        
        if (!success) {
            //[pythonHandler logPythonError:self.logger]; // doesn't appear to work
            dispatch_async(dispatch_get_main_queue(), ^{
                NSRunAlertPanel(@"Script Failed", @"The script could not be completed.", nil, nil, nil);
            });
        } else if(notifyAfter) {
            NSAlert *alert = [NSAlert new];
            alert.messageText = @"Complete";
            alert.informativeText = @"Process is complete";
            [alert addButtonWithTitle:@"Ok"];
            if(chooseFolder) {
                [alert addButtonWithTitle:@"Open Folder"];
            } else if (chooseFile || saveFile) {
                [alert addButtonWithTitle:@"Open Location"];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
                    if(result == NSAlertSecondButtonReturn) {
                        if(chooseFolder) [[NSWorkspace sharedWorkspace]openFile:resultPath withApplication:@"Finder"];
                        else [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ resultURL ]];
                    }
                    NSLog(@"Success");
                }];
            });
            
            // send notification center notification
            NSUserNotification *notification = [[NSUserNotification alloc] init];
            notification.title = @"Process complete";
            notification.informativeText = [NSString stringWithFormat:@"%@ has completed",[script valueForKey:@"name"]];
            notification.soundName = NSUserNotificationDefaultSoundName;
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            
        }
        
        [self restoreInterface];
        
        // terminate on completion if needed
        if(shouldTerminate) [[NSApplication sharedApplication] terminate:nil];
        
    });
}

// http://stackoverflow.com/a/8874124/262455
// returns YES on success
/*  Script is called in the following manner:
    /usr/bin/python ¬
    /path/to/script ¬
    function ¬
    additional arguments
 */
- (BOOL)runPythonScript:(NSString*)scriptPath runFunction:(NSString*)functionName withArguments:(NSMutableArray*)arguments {
    // Set up piping for stdout
    // http://stackoverflow.com/a/2590723/262455
    pipe = [NSPipe pipe] ;
    pipeReadHandle = [pipe fileHandleForReading] ;
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleNotification:) name: NSFileHandleReadCompletionNotification object: pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify] ;
    
    // Set up piping for stderr
    errorPipe = [NSPipe pipe] ;
    errorPipeReadHandle = [errorPipe fileHandleForReading] ;
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleErrorNotification:) name: NSFileHandleReadCompletionNotification object: errorPipeReadHandle] ;
    [errorPipeReadHandle readInBackgroundAndNotify] ;
    
    NSTask* task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/python";
    NSLog(@"Running %@:%@ with arguments: %@", scriptPath, functionName, arguments);
    NSString *wrapperPath = [[NSBundle mainBundle] pathForResource:@"wrapper" ofType:@"py"];
    // note that the -u option must be specified to prevent python's built-in buffering
    NSMutableArray* args = [NSMutableArray arrayWithObjects: @"-u", wrapperPath, scriptPath, functionName, nil];
    [args addObjectsFromArray: arguments];
    task.arguments = args;
    
    // NSLog breaks if we don't do this...
    [task setStandardInput: [NSPipe pipe]];
    
    [task setStandardOutput:pipe];
    [task setStandardError: errorPipe];
    
    // disable internal buffering
    // http://stackoverflow.com/a/8269886/262455
    NSDictionary *defaultEnvironment = [[NSProcessInfo processInfo] environment];
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    [environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
    [task setEnvironment:environment];
    
    [task launch];
    
    [task waitUntilExit];
    
    NSInteger exitCode = task.terminationStatus;
    
    if (exitCode != 0)
    {
        NSLog(@"Error!");
        return NO;
    }
    
    return YES;
}

- (void)restoreInterface {
    dispatch_async(dispatch_get_main_queue(), ^{
        // stop progress indicator
        [self.circularProgress setHidden:YES];
        // enable buttons/fields
        if (self.controller.selectedObjects && self.controller.selectedObjects.count) {
            NSDictionary *script = [[self.controller.selectedObjects objectAtIndex:0] objectForKey:@"script"];
            if (script) {
                [self.runButton setEnabled:[[script valueForKey:@"visible"] boolValue]];
                [self.popupButton setEnabled:YES];
                [self.textView setEditable:YES];
            }
        }
    });
}

- (IBAction)runScript:(id)sender {
    if (self.controller.selectedObjects && self.controller.selectedObjects.count) {
        NSDictionary *script = [[self.controller.selectedObjects objectAtIndex:0] objectForKey:@"script"];
        
        // don't allow running of hidden scripts via button
        BOOL shouldRun = YES;
        if (!script) {
            shouldRun = NO;
        } else if ([script valueForKey:@"visible"]) {
            shouldRun = [[script valueForKey:@"visible"] boolValue];
        }
        if(shouldRun)[self execPythonScript:script];
    }
}

- (IBAction)copyToClipboard:(id)sender {
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] setString:self.textView.textStorage.string  forType:NSStringPboardType];
}

- (IBAction)changePopupButton:(id)sender {
    [self restoreInterface];
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
    
    // encode as json string
    // http://stackoverflow.com/a/9020923/262455
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                       options:0 // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    

    NSUInteger scriptIndex = [self indexOfScriptWithFilename:scriptFilename];
    NSLog(@"Params: %@",params);
    if(scriptIndex != NSNotFound) {
        NSLog(@"Executing %@", scriptFilename);
        NSMutableDictionary *script = scripts[scriptIndex];
        
        // add full path to script dict
        NSString *path = @"";
        if([script valueForKey:@"filepath"]) {
            path = [script valueForKey:@"filepath"];
        } else {
            path = [[NSBundle mainBundle] pathForResource:[script valueForKey:@"filename"] ofType:@"py"];
            [script setObject:path forKey:@"filepath"];
        }
        
        // set arguments (there's probably a cleaner way to do this)
        NSMutableArray *oldargs = [script valueForKey:@"arguments"];
        NSMutableArray *args = [[NSMutableArray alloc] init];
        if(oldargs) [args addObjectsFromArray:oldargs];
        if (! jsonData) {
            NSLog(@"Got an error: %@", error);
        } else {
            NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [args addObject:jsonString];
        }
        [script setObject:args forKey:@"arguments"];
        
        // make the controller display the correct info
        [self resetScriptMenu];
        // append current script
        [self.controller addObject:@{
                                     @"name" :[script valueForKey:@"name"],
                                     @"description":[script valueForKey:@"description"],
                                     @"script":script,
                                     }];
        // this script should be selected automatically
        [self execPythonScript:script];
        // reset arguments
        if(oldargs) [script setObject:oldargs forKey:@"arguments"];
        else [script removeObjectForKey:@"arguments"];
    }
}

// http://stackoverflow.com/a/5135053/262455
- (NSUInteger) indexOfScriptWithFilename: (NSString*) filename {
    return [scripts indexOfObjectPassingTest:
            ^BOOL(id dictionary, NSUInteger idx, BOOL *stop) {
                return [[dictionary objectForKey: @"filename"] isEqualToString: filename];
            }];
}


// http://stackoverflow.com/a/594867/262455
- (NSString *)getDataFromSourceString:(NSString *)data afterString:(NSString *)leftData;
{
    NSInteger left, right;
    NSString *foundData;
    if ([data rangeOfString:leftData].location != NSNotFound) {
        NSScanner *scanner=[NSScanner scannerWithString:data];
        while ([scanner isAtEnd] == NO) {
            [scanner scanUpToString:leftData intoString: nil];
            left = [scanner scanLocation];
            [scanner setScanLocation:left + [leftData length]];
            [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil];
            right = [scanner scanLocation] + 1;
            left += [leftData length];
            foundData = [data substringWithRange: NSMakeRange(left, (right - left) - 1)];
            return [foundData stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        }
    }
    return nil;
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center
     shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}


// terminate on last window closed
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}

@end

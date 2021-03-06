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
#import <Security/Security.h>
#import <Python/Python.h>

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
@property (weak) IBOutlet NSTextField *shotgunURLField;
@property (weak) IBOutlet NSTextField *shotgunUsernameField;
@property (weak) IBOutlet NSPanel *preferencesPanel;
@property (weak) IBOutlet NSButton *preferencesCancelButton;
@property (weak) IBOutlet NSPanel *passwordPanel;
@property (weak) IBOutlet NSSecureTextField *shotgunPasswordField;
@property (weak) IBOutlet NSTextField *passwordError;
@property char *passwordData;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    [NSUserNotificationCenter defaultUserNotificationCenter].delegate = self;
}

// http://stackoverflow.com/a/1991162/262455
- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    // set defaults prior to being called by URL event
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
                                                              @"shotgunURL":@"",
                                                              @"shotgunUsername":@"",
                                                              @"savePassword":@YES}];
    
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
        NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"scripts" ofType:@"plist"]];
        if(plist){
            //NSLog(@"plist = %@", plist);
            scripts = plist[@"scripts"];
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
                                       scriptPath.lastPathComponent.stringByDeletingPathExtension, @"filename",
                                       scriptName, @"name",
                                       [self getDataFromSourceString:scriptContents afterString:@"@SGS_DESCRIPTION:"], @"description",
                                    nil
                            ];
                            NSString *chooseFolderString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_CHOOSEFOLDER:"];
                            if (chooseFolderString) {
                                parsedScript[@"chooseFolder"] = chooseFolderString;
                            }
                            NSString *chooseFileString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_CHOOSEFILE:"];
                            if (chooseFileString) {
                                parsedScript[@"chooseFile"] = chooseFileString;
                            }
                            NSString *saveFileString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_SAVEFILE:"];
                            if (saveFileString) {
                                parsedScript[@"saveFile"] = saveFileString;
                            }
                            NSString *quitAfterString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_QUITAFTER:"];
                            if (quitAfterString) {
                                parsedScript[@"quitAfter"] = quitAfterString;
                            }
                            NSString *notifyAfterString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_NOTIFYAFTER:"];
                            if (notifyAfterString) {
                                parsedScript[@"notifyAfter"] = notifyAfterString;
                            }
                            NSString *visibleString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_VISIBLE:"];
                            if (visibleString) {
                                parsedScript[@"visible"] = visibleString;
                            }
                            NSString *userauthString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_USERAUTHENTICATION:"];
                            if (userauthString) {
                                parsedScript[@"userAuthentication"] = userauthString;
                            }
                            NSString *siteurlString = [self getDataFromSourceString:scriptContents afterString:@"@SGS_SITEURL:"];
                            if (siteurlString) {
                                parsedScript[@"siteURL"] = siteurlString;
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
    
    NSLog(@"%lu", (unsigned long)scripts.count);
    
    [self resetScriptMenu];
    }


#pragma mark - Message piping

// intercepts stdout
- (void)handleNotification:(NSNotification*) notification {
    [pipeReadHandle readInBackgroundAndNotify] ;
    NSString *str = [[NSString alloc] initWithData: notification.userInfo[NSFileHandleNotificationDataItem] encoding: NSUTF8StringEncoding] ;
    // Do whatever you want with str
    [self.logger appendLogMessage:str];
}

// intercepts stderr
- (void)handleErrorNotification:(NSNotification*) notification {
    [errorPipeReadHandle readInBackgroundAndNotify] ;
    NSString *str = [[NSString alloc] initWithData: notification.userInfo[NSFileHandleNotificationDataItem] encoding: NSUTF8StringEncoding] ;
    // Do whatever you want with str
    [self.logger appendErrorMessage:str];
}

#pragma mark - Script execution

- (NSDictionary *)getConfigurationForScriptExecution:(NSDictionary*) script {
    // return a dictionary containing arguments and other session-specific data
    NSLog(@"Getting configuration for script");

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
    BOOL userAuthentication = NO;
    if ([script valueForKey:@"userAuthentication"]) {
        userAuthentication = [[script valueForKey:@"userAuthentication"] boolValue];
    }
    if(userAuthentication) {
        NSUserDefaultsController *controller = [NSUserDefaultsController sharedUserDefaultsController];
        // get a username and password, if required
        NSURL *sgURL;
        if([script valueForKey:@"siteURL"]) {
            // site provided by script
            sgURL = [NSURL URLWithString:[script valueForKey:@"siteURL"]];
        } else if ([[controller.values valueForKey:@"shotgunURL"] length]) {
            // get from preferences
            sgURL = [NSURL URLWithString:[controller.values valueForKey:@"shotgunURL"]];
        }
        NSString *sgUsername;
        if([script valueForKey:@"username"]) {
            // username provided by script
            sgUsername = [script valueForKey:@"username"];
        } else if ([[controller.values valueForKey:@"shotgunUsername"] length]) {
            // get from preferences
            sgUsername = [controller.values valueForKey:@"shotgunUsername"];
        }
        
        NSString *token = [self authenticateUser:sgUsername AtURL:sgURL WithMessage:Nil];
        if(!token)
            return Nil;
        
        [self.logger appendLogMessage:[NSString stringWithFormat:@"Authenticating with site %@\n",  sgURL.host]];
        [args addObject:[NSString stringWithFormat:@"%@://%@", sgURL.scheme, sgURL.host]];
        [args addObject:token];
    }
    
    NSString *resultPath = @"";
    NSURL *resultURL = [[NSURL alloc] init];
    
    if (chooseFolder) {
        // http://stackoverflow.com/a/10922591/262455
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setCanCreateDirectories:YES];
        [openPanel setCanChooseFiles:NO];
        openPanel.title = @"Choose Folder";
        openPanel.prompt = @"Choose";
        if ([openPanel runModal] != NSFileHandlingPanelOKButton) {
            [self.logger appendErrorMessage:[NSString stringWithFormat:@"Script cancelled.\n"]];
            return Nil;
        }
        resultURL = openPanel.URLs.lastObject;
        resultPath = resultURL.path;
        [args addObject:resultPath];
        
    } else if (chooseFile) {
        NSOpenPanel *openPanel = [NSOpenPanel openPanel];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setCanChooseDirectories:YES];
        [openPanel setCanChooseFiles:YES];
        openPanel.title = @"Choose File";
        openPanel.prompt = @"Choose";
        if ([openPanel runModal] != NSFileHandlingPanelOKButton) {
            [self.logger appendErrorMessage:[NSString stringWithFormat:@"Script cancelled.\n"]];
            return Nil;
        }
        resultURL = openPanel.URLs.lastObject;
        resultPath = resultURL.path;
        [args addObject:resultPath];
    }
    
    if (saveFile) {
        NSDictionary *saveOptions = [script valueForKey:@"saveFile"];
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        savePanel.message = @"Choose where to save the file"; // Message inside modal window
        [savePanel setAllowsOtherFileTypes:YES];
        [savePanel setExtensionHidden:YES];
        [savePanel setCanCreateDirectories:YES];
        if ([saveOptions valueForKey:@"default"]) {
            savePanel.nameFieldStringValue = [saveOptions valueForKey:@"default"];
        }
        
        savePanel.title = @"Save file as"; // Window title
        
        if ([savePanel runModal] != NSFileHandlingPanelOKButton) {
            [self.logger appendErrorMessage:[NSString stringWithFormat:@"Script cancelled.\n"]];
            return Nil;
        }
        NSURL *resultURL = savePanel.URL;
        resultPath = resultURL.path;
        [args addObject:resultPath];
    }
    
    if ([script valueForKey:@"arguments"]) {
        [args addObjectsFromArray:[script valueForKey:@"arguments"]];
    }
    
    NSDictionary *config = [NSMutableDictionary dictionaryWithObjectsAndKeys:
         args,@"arguments",
         resultURL,@"resultURL",
         @(chooseFolder),@"chooseFolder",
         @(chooseFile),@"chooseFile",
         @(saveFile),@"saveFile",
         @(shouldTerminate),@"shouldTerminate",
         @(notifyAfter),@"notifyAfter",
        nil];
    
    return config;
}

- (void)execPythonScript:(NSDictionary*) script {
    // runs the script's process_action()
    [self.logger appendLogMessage:[NSString stringWithFormat:@"Running %@\n",[script valueForKey:@"name"]]];
    
    // get arguments
    NSDictionary *config = [self getConfigurationForScriptExecution:script];
    if(!config) {
        [self restoreInterface];
        return;
    }
    NSArray *args = [config valueForKey:@"arguments"];
    
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
        } else if([[config valueForKey:@"notifyAfter"] boolValue]) {
            NSAlert *alert = [NSAlert new];
            alert.messageText = @"Complete";
            alert.informativeText = @"Process is complete";
            [alert addButtonWithTitle:@"Ok"];
            if([[config valueForKey:@"chooseFolder"] boolValue]) {
                [alert addButtonWithTitle:@"Open Folder"];
            } else if ([[config valueForKey:@"chooseFile"] boolValue] || [[config valueForKey:@"saveFile"] boolValue]) {
                [alert addButtonWithTitle:@"Open Location"];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
                    if(result == NSAlertSecondButtonReturn) {
                        if([[config valueForKey:@"chooseFolder"] boolValue]) [[NSWorkspace sharedWorkspace]openFile:[[config valueForKey:@"resultURL"] path] withApplication:@"Finder"];
                        else [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:@[ [config valueForKey:@"resultURL"] ]];
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
        if([[config valueForKey:@"shouldTerminate"] boolValue]) [[NSApplication sharedApplication] terminate:nil];
        
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
- (BOOL)runPythonScript:(NSString*)scriptPath runFunction:(NSString*)functionName withArguments:(NSArray*)arguments {
    // Set up piping for stdout
    // http://stackoverflow.com/a/2590723/262455
    pipe = [NSPipe pipe] ;
    pipeReadHandle = pipe.fileHandleForReading ;
    [[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleNotification:) name: NSFileHandleReadCompletionNotification object: pipeReadHandle] ;
    [pipeReadHandle readInBackgroundAndNotify] ;
    
    // Set up piping for stderr
    errorPipe = [NSPipe pipe] ;
    errorPipeReadHandle = errorPipe.fileHandleForReading ;
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
    task.standardInput = [NSPipe pipe];
    
    task.standardOutput = pipe;
    task.standardError = errorPipe;
    
    // disable internal buffering
    // http://stackoverflow.com/a/8269886/262455
    NSDictionary *defaultEnvironment = [NSProcessInfo processInfo].environment;
    NSMutableDictionary *environment = [[NSMutableDictionary alloc] initWithDictionary:defaultEnvironment];
    environment[@"NSUnbufferedIO"] = @"YES";
    task.environment = environment;
    
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

#pragma mark - Interface methods

- (void)restoreInterface {
    dispatch_async(dispatch_get_main_queue(), ^{
        // stop progress indicator
        [self.circularProgress setHidden:YES];
        // enable buttons/fields
        if (self.controller.selectedObjects && self.controller.selectedObjects.count) {
            NSDictionary *script = (self.controller.selectedObjects)[0][@"script"];
            if (script) {
                (self.runButton).enabled = [[script valueForKey:@"visible"] boolValue];
                [self.popupButton setEnabled:YES];
                [self.textView setEditable:YES];
            }
        }
    });
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
            script[@"filepath"] = path;
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

- (IBAction)runScript:(id)sender {
    if (self.controller.selectedObjects && self.controller.selectedObjects.count) {
        NSDictionary *script = (self.controller.selectedObjects)[0][@"script"];
        
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

// http://stackoverflow.com/questions/8058653/displaying-a-cocoa-window-as-a-sheet-in-xcode-4-osx-10-7-2-with-arc
- (IBAction)showPreferences:(id)sender {
    [self showPreferencesPanel];
}

- (void)showPreferencesPanel {
    [NSUserDefaultsController.sharedUserDefaultsController setAppliesImmediately:NO];
    [self.window beginSheet: self.preferencesPanel
          completionHandler:^(NSModalResponse returnCode) {
              [NSApp stopModalWithCode: returnCode];
          }];
    
    [NSApp runModalForWindow: self.preferencesPanel];
}

- (void)showPasswordPanel {
    [self.window beginSheet: self.passwordPanel
          completionHandler:^(NSModalResponse returnCode) {
              [NSApp stopModalWithCode: returnCode];
          }];
    
    [NSApp runModalForWindow: self.passwordPanel];
}

-(IBAction)closePreferences:(id)sender {
    [self.preferencesPanel makeFirstResponder:nil]; // required so all changes are committed
    NSUserDefaultsController *controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSInteger code = 0;
    switch ([sender tag]) {
        case 0:
            // ok
            [controller save:self];
            code = NSOKButton;
            break;
        case 1:
            [controller revert:self];
            code = NSCancelButton;
            break;
            
        default:
            break;
    }
    // this is for when called from preferences menu
    [self.window endSheet: self.preferencesPanel];
    // this is for when called as a modal
    [NSApp stopModalWithCode:code];
}

- (IBAction)closePassword:(id)sender {
    NSUserDefaultsController *controller = [NSUserDefaultsController sharedUserDefaultsController];
    NSInteger code = 0;
    switch ([sender tag]) {
        case 0:
            // ok
            [controller save:self];
            code = NSOKButton;
            break;
        case 1:
            [controller revert:self];
            code = NSCancelButton;
            break;
            
        default:
            break;
    }
    [NSApp stopModalWithCode:code];
}

#pragma mark - Shotgun Authentication

- (void)setupPythonEnvironment {
    if (Py_IsInitialized())
        return;
    
    // just in case /usr/bin/ is not in the user's path, although it should be
    Py_SetProgramName("/usr/bin/python");
    
    // https://gist.github.com/andyvanee/3754412
    // Setup python environment
    
    Py_Initialize();
    //[self.logger setLogMessage:@"PyInit\n"];
    const char *pypath = [NSBundle mainBundle].resourcePath.UTF8String;
    // import sys
    PyObject *sys = PyImport_Import(PyString_FromString("sys"));
    
    // sys.path.append(resourcePath)
    PyObject *sys_path_append = PyObject_GetAttrString(PyObject_GetAttrString(sys, "path"), "append");
    PyObject *resourcePath = PyTuple_New(1);
    PyTuple_SetItem(resourcePath, 0, PyString_FromString(pypath));
    PyObject_CallObject(sys_path_append, resourcePath);
    
}

- (NSString *)getShotgunSessionTokenForSite:(NSString*)site WithUsername:(NSString*)username Password:(NSString*)password {
    if(!site.length || !username.length || !password.length)
        return Nil;
    [self setupPythonEnvironment];
    // import shotgun_api3
    PyObject *shotgun_api = PyImport_Import(PyString_FromString("shotgun_api3"));
    
    // shotgun_api3.Shotgun()
    PyObject *shotgun = PyObject_GetAttrString(shotgun_api, "Shotgun");
    if (shotgun && PyCallable_Check(shotgun)){
        PyObject *args = PyTuple_New(1);
        PyTuple_SetItem(args, 0, PyString_FromString(site.UTF8String));
        PyObject *keywords = PyDict_New();
        PyDict_SetItemString(keywords, "login", PyString_FromString(username.UTF8String));
        PyDict_SetItemString(keywords, "password", PyString_FromString(password.UTF8String));
        PyObject *sg = PyObject_Call(shotgun, args, keywords);
        if(sg == NULL){
            PyObject *ptype, *pvalue, *ptraceback;
            PyErr_Fetch(&ptype, &pvalue, &ptraceback);
            NSLog(@"Error connecting to Shotgun: %s", PyString_AsString(pvalue)); // TODO figure out why error doesn't show
            return Nil;
        }
        PyObject *result = PyObject_CallMethod(sg, "get_session_token", NULL);
        if(result) {
            //NSLog(@"Session token: %s", PyString_AsString(result));
            NSString *token = @(PyString_AsString(result));
            return token;
        }
    }
    return Nil;
}

#pragma mark - Keychain handling

-(NSString *)promptForPasswordForUser:(NSString *)username AtURL:(NSURL *)url WithMessage:(NSString*)message {
    NSUserDefaultsController *controller = [NSUserDefaultsController sharedUserDefaultsController];
    if(username)
        [controller.values setValue:username forKey:@"shotgunUsername"];
    if(url)
        [controller.values setValue:[NSString stringWithFormat:@"%@://%@", url.scheme, url.host] forKey:@"shotgunURL"];
    
    [NSApp beginSheet: self.passwordPanel
       modalForWindow: self.window
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    
    if(message) {
        (self.passwordError).stringValue = message;
        [self.passwordError setHidden:NO];
    }
    
    NSInteger code = [NSApp runModalForWindow: self.passwordPanel];
    NSString* password = (self.shotgunPasswordField).stringValue;
    [NSApp endSheet: self.passwordPanel];
    [self.passwordPanel orderOut: self];
    [self.passwordError setHidden:YES];
    
    if(code != NSOKButton) {
        [self.logger appendErrorMessage:@"Script cancelled\n"];
        return Nil;
    }
    return password;
}

-(NSString *)authenticateUser:(NSString *)username AtURL:(NSURL *)url WithMessage:(NSString *)message {
    // https://developer.apple.com/library/content/documentation/Security/Conceptual/keychainServConcepts/03tasks/tasks.html#//apple_ref/doc/uid/TP30000897-CH205-BCIHAAGG
    
    NSString *password = Nil;
    BOOL shouldSavePassword = NO;
    BOOL shouldClearPassword = NO;
    OSStatus status;
    NSUserDefaultsController *controller = [NSUserDefaultsController sharedUserDefaultsController];

    if(username && url) {
        // I have tried and tried to make this work with iCloud but it is not worth the hassle
        NSLog(@"Looking for %@ @ %@", username, url.host);
        // http://stackoverflow.com/a/13532428/262455
        
        UInt32 returnpasswordLength = 0;
        
        status = SecKeychainFindInternetPassword(
                                                 NULL,
                                                 (int)url.host.length,
                                                 (char *)url.host.UTF8String,
                                                 0,
                                                 NULL,
                                                 (int)username.length,
                                                 (char *)username.UTF8String,
                                                 0,
                                                 nil,
                                                 0,
                                                 kSecProtocolTypeHTTPS, // TODO
                                                 kSecAuthenticationTypeDefault,
                                                 &returnpasswordLength,
                                                 (void *)&_passwordData,
                                                 NULL
                                                 );
        
        NSLog(@"Password retrieval status:%@", SecCopyErrorMessageString(status, NULL));
        if(status == errSecItemNotFound) {
            // password is not on keychain
            
        } else if(status == noErr) {
            // password is on keychain
            shouldClearPassword = YES;
            password = [[NSString alloc] initWithBytes:self.passwordData
                                                length:returnpasswordLength
                                              encoding:NSUTF8StringEncoding];
        }
    }
    if(!password) {
        // prompt user for credentials
        password = [self promptForPasswordForUser:username AtURL:url WithMessage:message];
        if(!password) return Nil; // user cancelled
        
        // update values in case user changed them
        url = [NSURL URLWithString:[controller.values valueForKey:@"shotgunURL"]];
        username = [controller.values valueForKey:@"shotgunUsername"];
        
        if([[controller.values valueForKey:@"savePassword"] boolValue]) {
            shouldSavePassword = YES;
        }
    }
    
    // make sure everything is valid
    if(!url || !username.length || !password.length) {
        return [self authenticateUser:username AtURL:url WithMessage:@"Fields cannot be empty"]; // try again until user cancels
    }
    
    // authenticate user
    // start progress indicator
    [self.circularProgress setHidden:NO];
    
    // disable buttons/fields
    [self.runButton setEnabled:NO];
    [self.popupButton setEnabled:NO];
    [self.textView setEditable:NO];
    NSString *token = [self getShotgunSessionTokenForSite:[NSString stringWithFormat:@"%@://%@", url.scheme, url.host]
                                             WithUsername:username Password:password];
    
    // clear password if required
    if(shouldClearPassword)
        NSLog(@"Clearing password data: %@", SecCopyErrorMessageString(SecKeychainItemFreeContent(NULL, _passwordData), NULL));
    
    [self restoreInterface];
    
    if(!token) {
        NSString *message = @"Authentication failed";
        [self.logger appendErrorMessage:message];
        return [self authenticateUser:username AtURL:url WithMessage:message]; // try again until user cancels
    }
    
    if (shouldSavePassword) {
        status = SecKeychainAddInternetPassword(
                                                NULL,
                                                (int)url.host.length,
                                                (char *)url.host.UTF8String,
                                                0,
                                                NULL,
                                                (int)username.length,
                                                (char *)username.UTF8String,
                                                0,
                                                nil,
                                                0,
                                                kSecProtocolTypeHTTPS,
                                                kSecAuthenticationTypeDefault,
                                                (int)password.length,
                                                (char *)password.UTF8String,
                                                NULL
                                                );
        NSLog(@"Password store status:%@", SecCopyErrorMessageString(status, NULL));
    }
    
    return token;
}

#pragma mark - Action Menu Item handling

- (void)handleURLEvent:(NSAppleEventDescriptor*)event
        withReplyEvent:(NSAppleEventDescriptor*)replyEvent {
    
/*    expected URL in the form
        sgscripts://sg_gantt?user_id=42&user_login=jack.james&title=&entity_type=Task&server_hostname=nightingale.shotgunstudio.com&referrer_path=%2Fdetail%2FHumanUser%2F42&page_id=1861&session_uuid=dd8841a0-41cb-11e5-9b33-0242ac110002&project_name=Nightingale%20VFX&project_id=67&ids=2076%2C2077%2C2078%2C2132%2C2133%2C2134%2C2135%2C2136%2C2137%2C2138&selected_ids=2076%2C2078%2C2132%2C2133%2C2136&cols=content&cols=step&cols=sg_status_list&cols=task_assignees&cols=start_date&cols=due_date&cols=duration&cols=entity&column_display_names=Task%20Name&column_display_names=Pipeline%20Step&column_display_names=Status&column_display_names=Assigned%20To&column_display_names=Start%20Date&column_display_names=Due%20Date&column_display_names=Duration&column_display_names=Link&grouping_column=entity&grouping_method=exact&grouping_direction=asc
*/
    NSString* urlString = [event paramDescriptorForKeyword:keyDirectObject].stringValue;
    NSLog(@"%@", urlString);
    
    // convert to NSURL
    NSURL *url = [NSURL URLWithString:urlString];
    
    // filename will be the path
    // http://stackoverflow.com/a/1967451/262455
    NSString *scriptFilename = url.host;
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
            script[@"filepath"] = path;
        }
        
        // Set URL and username
        NSURL *siteURL = [[NSURL alloc] initWithScheme:@"https" host:params[@"server_hostname"] path:@"/"];
        [script setValue:siteURL.absoluteString forKey:@"siteURL"];
        [script setValue:params[@"user_login"] forKey:@"username"];
        // Save URL and username to defaults as needed
        NSUserDefaultsController *controller = [NSUserDefaultsController sharedUserDefaultsController];
        if(![controller.values valueForKey:@"shotgunURL"] || ![[controller.values valueForKey:@"shotgunURL"] length])
            [controller.values setValue:[NSString stringWithFormat:@"%@://%@", siteURL.scheme, siteURL.host] forKey:@"shotgunURL"];
        if(![controller.values valueForKey:@"shotgunUsername"] || ![[controller.values valueForKey:@"shotgunUsername"] length])
            [controller.values setValue:params[@"user_login"] forKey:@"shotgunUsername"];

        
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
        script[@"arguments"] = args;
        
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
        if(oldargs) script[@"arguments"] = oldargs;
        else [script removeObjectForKey:@"arguments"];
    }
}

// http://stackoverflow.com/a/5135053/262455
- (NSUInteger) indexOfScriptWithFilename: (NSString*) filename {
    return [scripts indexOfObjectPassingTest:
            ^BOOL(id dictionary, NSUInteger idx, BOOL *stop) {
                return [dictionary[@"filename"] isEqualToString: filename];
            }];
}


// http://stackoverflow.com/a/594867/262455
- (NSString *)getDataFromSourceString:(NSString *)data afterString:(NSString *)leftData
{
    NSInteger left, right;
    NSString *foundData;
    if ([data rangeOfString:leftData].location != NSNotFound) {
        NSScanner *scanner=[NSScanner scannerWithString:data];
        while (scanner.atEnd == NO) {
            [scanner scanUpToString:leftData intoString: nil];
            left = scanner.scanLocation;
            scanner.scanLocation = left + leftData.length;
            [scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil];
            right = scanner.scanLocation + 1;
            left += leftData.length;
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

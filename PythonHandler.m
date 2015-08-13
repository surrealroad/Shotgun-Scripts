//
//  PythonHandler.m
//  Shotgun Scripts
//
//  Created by Jack James on 10/07/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

#import "PythonHandler.h"
#import <Python/Python.h>

// https://github.com/bignerdranch/ScriptableTextEditor

@interface NSObject (PythonPluginInterface)

- (BOOL) loadModuleAtPath:(NSString*)path
             functionName:(NSString*)funcName
                   logger:(Logger*)logger
                arguments:(NSMutableArray*)args;

@end



@implementation PythonHandler

+ (PythonHandler*) sharedManager {
    static dispatch_once_t pred;
    static PythonHandler *sharedManager;
    dispatch_once(&pred, ^{
        sharedManager = [[PythonHandler alloc] init];
    });
    return sharedManager;
}

- (BOOL) setupPythonEnvironment {
    // if deja-vu'ing, skip the rest
    if (Py_IsInitialized())
    return YES;
    
    // just in case /usr/bin/ is not in the user's path, although it should be
    Py_SetProgramName("/usr/bin/python");
    
    // https://gist.github.com/andyvanee/3754412
    // Setup python environment
    
    Py_Initialize();
    //[self.logger setLogMessage:@"PyInit\n"];
    const char *pypath = [[[NSBundle mainBundle] resourcePath] UTF8String];
    // import sys
    PyObject *sys = PyImport_Import(PyString_FromString("sys"));
    
    // sys.path.append(resourcePath)
    PyObject *sys_path_append = PyObject_GetAttrString(PyObject_GetAttrString(sys, "path"), "append");
    PyObject *resourcePath = PyTuple_New(1);
    PyTuple_SetItem(resourcePath, 0, PyString_FromString(pypath));
    PyObject_CallObject(sys_path_append, resourcePath);
    
    // get path to our python entrypoint
    NSString *wrapperPath = [[NSBundle mainBundle] pathForResource:@"wrapper" ofType:@"py"];
    
    // load the wrapper script into the python runtime
    FILE *wrapper = fopen([wrapperPath UTF8String], "r");
    return (PyRun_SimpleFile(wrapper, (char *)[[wrapperPath lastPathComponent] UTF8String]) == 0);
}

// returns YES on success
- (BOOL) loadScriptAtPath:(NSString*)scriptPath runFunction:(NSString*)functionName usingLogger:(Logger*)logger withArguments:(NSMutableArray*)arguments {
    NSLog(@"Executing %@ from %@ with arguments: %@", functionName, scriptPath, arguments);
    Class executor = NSClassFromString(@"PyExecutor");
    return [executor loadModuleAtPath:scriptPath
                         functionName:functionName
                               logger:logger
                            arguments:arguments];
}

- (void)logPythonError:(Logger*)logger {
    // Error handling
    PyObject *ptype, *pvalue, *ptraceback;
    PyErr_Fetch(&ptype, &pvalue, &ptraceback);
    //pvalue contains error message
    //ptraceback contains stack snapshot and many other information
    //(see python traceback structure)
    NSString *err;
    if (pvalue) {
        err = [NSString stringWithFormat:@"Error: %s\n", PyString_AsString(pvalue)];
    } else {
        err = @"Unspecified error\n";
    }
    
    [logger appendErrorMessage:err];
//    PyErr_Print();
}

@end
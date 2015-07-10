#!/usr/bin/env python
# encoding: utf-8
"""
wrapper.py

Wrapper script to integrate and launch scripts into Cocoa launcher

Tasks:
• Redirect stdout to textview

Created by Jack James on 2015-07-10.

"""

import sys, imp
from Foundation import *
from AppKit import *

# http://stackoverflow.com/a/14986754/262455
class CustomPrint(object):
    logger = None
    def __init__(self,logger):
        self.logger = logger
    def write(self, text):
        text = text.rstrip()
        if len(text) == 0: return
        self.logger.appendToTextView_(text + "\n")

class PyExecutor(NSObject):
    @classmethod
    def loadModuleAtPath_functionName_logger_arguments_(self, path, function_name, logger, args):
        
        newPrint = CustomPrint(logger)
        sys.stdout = newPrint
        sys.stderr = newPrint
        
        f = open(path)
        try:
            module = imp.load_module('script', f, path, (".py", "r", imp.PY_SOURCE))
            executor = getattr(module, function_name, None)
            if executor is not None:
                executor(*tuple(args))
        except Exception as e:
            NSRunAlertPanel('Script Error', '%s' % e, None, None, None)
            return NO
        finally:
            f.close()
        
        return YES


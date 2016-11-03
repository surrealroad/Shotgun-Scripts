#!/usr/bin/env python
# encoding: utf-8
"""
wrapper.py

Wrapper script to integrate and launch scripts into Cocoa launcher

Tasks:
• Pass parameters to function

Created by Jack James on 2015-07-10.

"""

import sys, imp, os

if __name__ == '__main__':
    args = ()
    if(len(sys.argv)>3):
        args = tuple(sys.argv[3:])
    path = sys.argv[1]
    sys.path.append(os.path.dirname(path))
    module = imp.load_source('script', path)
    func = getattr(module, sys.argv[2], None)
    if func is not None:
        func(*args)
    else:
        raise ImportError("Module or function missing")


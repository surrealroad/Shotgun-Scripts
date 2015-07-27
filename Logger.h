//
//  Logger.h
//  SGAPI Test
//
//  Created by Jack James on 08/07/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface Logger : NSObject {
    
    // http://stackoverflow.com/a/31302273/262455
}

- (void)setLogMessage:(NSString*) message;
- (void)appendToTextView:(NSString*)text;
- (void)appendAttributedToTextView:(NSAttributedString*) attr;
- (void)appendLogMessage:(NSString*) message;
- (void)appendErrorMessage:(NSString*) message;
- (void)appendAttributedLogMessage:(NSAttributedString*) message;

@end

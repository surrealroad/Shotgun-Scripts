//
//  Logger.m
//  SGAPI Test
//
//  Created by Jack James on 08/07/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

#import "Logger.h"

@interface Logger ()
@property (unsafe_unretained) IBOutlet NSTextView *textView;

@end

@implementation Logger

- (id)init {
    NSLog(@"Starting up");
    return [super init];
}

- (void)setLogMessage:(NSString*) message {
    NSLog(@"%@", message);
    [self.textView setString:message];
}

// http://stackoverflow.com/a/15173067/262455
- (void)appendToTextView:(NSString*)text {
    NSAttributedString* attr = [[NSAttributedString alloc] initWithString:text];
    [self appendAttributedToTextView:attr];
}

- (void)appendAttributedToTextView:(NSAttributedString*)attr {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.textView textStorage] appendAttributedString:attr];
        [self.textView scrollRangeToVisible:NSMakeRange([[self.textView string] length], 0)];
    });
}

- (void)appendLogMessage:(NSString*) message {
    NSLog(@"%@", message);
    [self appendToTextView:message];
}

- (void)appendErrorMessage:(NSString*) message {
    NSAttributedString* attrStr = [[NSAttributedString alloc]
       initWithString:message
       attributes: @{
                     NSForegroundColorAttributeName:[NSColor redColor],
                     
    }];
    [self appendAttributedLogMessage:attrStr];
    
}

- (void)appendAttributedLogMessage:(NSAttributedString*) message {
    NSLog(@"%@", [message string]);
    [self appendAttributedToTextView:message];
}

@end

//
//  NSURL+ParseCategory.m
//  Shotgun Scripts
//
//  Created by Jack James on 13/08/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

// http://stackoverflow.com/a/1967451/262455

#import "NSURL+ParseCategory.h"
#import "NSString+ParseCategory.h"

@implementation NSURL (ParseCategory)

- (NSArray *)pathArray {
    // Create a character set for the slash character
    NSRange slashRange;
    slashRange.location = (unsigned int)'/';
    slashRange.length = 1;
    NSCharacterSet *slashSet = [NSCharacterSet characterSetWithRange:slashRange];
    
    // Get path with leading (and trailing) slashes removed
    NSString *path = [self.path stringByTrimmingCharactersInSet:slashSet];
    
    return [path componentsSeparatedByCharactersInSet:slashSet];
}

- (NSDictionary *)queryDictionary {
    NSDictionary *returnDictionary = [[self.query explodeToDictionaryInnerGlue:@"=" outterGlue:@"&"] copy];
    return returnDictionary;
}

@end

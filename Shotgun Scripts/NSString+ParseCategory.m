//
//  NSString+ParseCategory.m
//  Shotgun Scripts
//
//  Created by Jack James on 13/08/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

// http://stackoverflow.com/a/1967451/262455

#import "NSString+ParseCategory.h"

@implementation NSString (ParseCategory)

- (NSMutableDictionary *)explodeToDictionaryInnerGlue:(NSString *)innerGlue outterGlue:(NSString *)outterGlue {
    // Explode based on outter glue
    NSArray *firstExplode = [self componentsSeparatedByString:outterGlue];
    NSArray *secondExplode;
    
    // Explode based on inner glue
    NSInteger count = firstExplode.count;
    NSMutableDictionary *returnDictionary = [NSMutableDictionary dictionaryWithCapacity:count];
    for (NSInteger i = 0; i < count; i++) {
        secondExplode = [(NSString *)firstExplode[i] componentsSeparatedByString:innerGlue];
        if (secondExplode.count == 2) {
            NSString *value = [[secondExplode[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"+" withString:@" "];
            returnDictionary[secondExplode[0]] = value;
        }
    }
    
    return returnDictionary;
}

@end

//
//  NSString+ParseCategory.h
//  Shotgun Scripts
//
//  Created by Jack James on 13/08/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

// http://stackoverflow.com/a/1967451/262455

#import <Foundation/Foundation.h>

@interface NSString (ParseCategory)
- (NSMutableDictionary *)explodeToDictionaryInnerGlue:(NSString *)innerGlue outterGlue:(NSString *)outterGlue;
@end

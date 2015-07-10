//
//  SGAPIScript.h
//  SGAPI Test
//
//  Created by Jack James on 08/07/2015.
//  Copyright (c) 2015 Jack James. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SGAPIScript : NSObject {
    NSURL *path;
    NSString *title;
    NSString *description;
}

@property NSURL *path;
@property NSString *title;
@property NSString *details;

@end

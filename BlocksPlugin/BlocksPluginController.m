//
//  BlocksPluginController.m
//  BlocksPlugin
//
//  Created by __UserName__ on 1/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BlocksPluginController.h"


@implementation BlocksPluginController

#pragma mark Class Methods

+ (id)sharedInstance {
    static id sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

#pragma mark Actions

- (IBAction)blocksPluginMenuItemAction:(id)sender {
	NSBeep();
}

@end

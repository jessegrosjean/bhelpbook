//
//  BlocksPluginController.h
//  BlocksPlugin
//
//  Created by __UserName__ on 1/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface BlocksPluginController : NSObject {

}

#pragma mark Class Methods

+ (id)sharedInstance;

#pragma mark Actions

- (IBAction)blocksPluginMenuItemAction:(id)sender;

@end

//
//  BPluginDevelopmentController.h
//  BPluginDevelopment
//
//  Created by Jesse Grosjean on 1/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Blocks/Blocks.h>


@interface BPluginDevelopmentController : NSObject {
}

#pragma mark Class Methods

+ (id)sharedInstance;

#pragma mark Actions

- (IBAction)generateXcodePluginProject:(id)sender;

@end

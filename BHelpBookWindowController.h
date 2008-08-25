//
//  BHelpBookWindowController.h
//  BHelpBook
//
//  Created by Jesse Grosjean on 1/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Blocks/Blocks.h>
#import <WebKit/WebKit.h>


@interface BHelpBookWindowController : NSWindowController {
	IBOutlet WebView *webView;
	IBOutlet NSSegmentedControl *navigation;
}

#pragma mark Class Methods

+ (id)sharedInstance;

#pragma mark Actions

- (IBAction)navigationAction:(id)sender;
- (IBAction)goHome:(id)sender;

@end

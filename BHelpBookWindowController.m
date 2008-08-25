//
//  BHelpBookWindowController.m
//  BHelpBook
//
//  Created by Jesse Grosjean on 1/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BHelpBookWindowController.h"
#import "BHelpBook.h"
#import "BHelpBookPage.h"


@implementation BHelpBookWindowController

#pragma mark Class Methods

+ (id)sharedInstance {
    static id sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

- (id)init {
	if (self = [super initWithWindowNibName:@"BHelpBookWindow"]) {
	}
	return self;
}

#pragma mark awake from nib like methods

- (void)windowDidLoad {
	[[self window] setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
	[[self window] setContentBorderThickness:36 forEdge:NSMaxYEdge];	
	[[self window] setTitle:[NSString stringWithFormat:@"%@ Help", [[NSProcessInfo processInfo] processName]]];
	[[self window] center];
	[webView setMaintainsBackForwardList:YES];
	[self goHome:nil];
}

#pragma mark Actions

- (IBAction)showWindow:(id)sender {
    NSError *error = nil;
    if (![[BHelpBook sharedInstance] startHelpBookServer:&error]) {
        NSLog(@"Error starting server: %@", error);
    } else {
        NSLog(@"Starting HelpBook on port %d", [[BHelpBook sharedInstance] helpBookServerPort]);
    }	
	[super showWindow:sender];
}

- (void)windowWillClose:(NSNotification *)notification {
	[[BHelpBook sharedInstance] stopHelpBookServer];
}

- (IBAction)navigationAction:(id)sender {
	NSInteger clickedTag = [[navigation cell] tagForSegment:[navigation selectedSegment]]; 
	if (clickedTag == 1) {
		[webView goBack:sender];
	} else if (clickedTag == 2) {
		[webView goForward:sender];
	}
}

- (IBAction)goHome:(id)sender {	
	[[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[[[BHelpBook sharedInstance] homePage] absoluteURL]]];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if (frame == [sender mainFrame]){
		[navigation setEnabled:[sender canGoBack] forSegment:0];
		[navigation setEnabled:[sender canGoForward] forSegment:1];
    }
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener {
    NSString *host = [[request URL] host];
    if ([host isEqualToString:@"localhost"]) {
        [listener use];
	} else {
        [listener ignore];
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
	}
}

@end
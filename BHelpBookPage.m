//
//  BHelpBookPage.m
//  BHelpBook
//
//  Created by Jesse Grosjean on 2/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BHelpBookPage.h"
#import "BHelpBook.h"
#import "NSTask+runScriptNamed.h"


@implementation BHelpBookPage

+ (NSString *)pageTemplate {
	static NSString *pageTemplate = nil;
	if (!pageTemplate) pageTemplate = [NSString stringWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"page_template" ofType:@"html"]];
	return pageTemplate;
}

@synthesize helpBook;
@synthesize name;
@synthesize label;
@synthesize tags;

- (NSString *)path {
	return [NSString stringWithFormat:@"/%@/%@", [configurationElement.plugin identifier], name];
}

- (void)writeAllPagesContent:(NSMutableString *)resourceContent {
	[resourceContent appendFormat:@"<ul>"];
	for (BHelpBookPage *each in [[[BHelpBook sharedInstance] pages] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"label" ascending:YES]]]) {
		[resourceContent appendFormat:@"<li><a href=\"%@\">%@</a></li>", each.absoluteURL, each.label];
	}
	[resourceContent appendFormat:@"</ul>"];	
}


- (void)writeKeyboardShortcutsForMenu:(NSMenu *)menu inContent:(NSMutableString *)resourceContent {
	for (NSMenuItem *each in [menu itemArray]) {
		if ([[each keyEquivalent] length] > 0) {
			[resourceContent appendFormat:@"<li>%@ %@</li>", [each title], [each keyEquivalent]];
		}
		
		if ([each submenu] != nil) {
			[resourceContent appendString:@"<ul>"];
			[self writeKeyboardShortcutsForMenu:[each submenu] inContent:resourceContent];
			[resourceContent appendString:@"</ul>"];
		}
	}
}

- (void)writePlugins:(NSMutableString *)resourceContent {
	[resourceContent appendString:@"<ul>"];
	for (BPlugin *each in [[BExtensionRegistry sharedInstance] plugins]) {
		[resourceContent appendFormat:@"<li><code><a href=\"/%@/%@\">%@</a></code></li>", each.identifier, each.identifier, each.identifier];
	}
	[resourceContent appendString:@"</ul>"];	
}

- (void)writeExtensionPoints:(NSMutableString *)resourceContent {
	[resourceContent appendString:@"<ul>"];
	for (BExtensionPoint *each in [[BExtensionRegistry sharedInstance] extensionPoints]) {
		[resourceContent appendFormat:@"<li><code><a href=\"/%@/%@\">%@</a></code></li>", each.identifier, each.identifier, each.identifier];
//		[resourceContent appendFormat:@"<li><input name=\"%@\" type=\"checkbox\" /><a href=\"extensionPoint://%@\"><code>%@</code></a></li>", each.identifier, each.identifier, each.identifier];
	}
	[resourceContent appendString:@"</ul>"];	
}

- (NSString *)content {
	NSString *resource = [name stringByDeletingPathExtension];
	NSString *extension = [name pathExtension];
	NSMutableString *resourceContent = [NSMutableString string];
	NSString *result = nil;
	
	if ([resource isEqualToString:@"all_topics"]) {	
		[self writeAllPagesContent:resourceContent];
	} else if ([resource isEqualToString:@"keyboard_shortcuts"]) {
		[self writeKeyboardShortcutsForMenu:[[NSApplication sharedApplication] mainMenu] inContent:resourceContent];
	} else if ([resource isEqualToString:@"plugin_list"]) {
		[self writePlugins:resourceContent];
	} else if ([resource isEqualToString:@"extension_point_list"]) {
		[self writeExtensionPoints:resourceContent];
	} else if ([resource isEqualToString:@"generate_plugin_xcode_project"]) {
		NSBeep();
	} else {
		resourceContent = [NSMutableString stringWithContentsOfFile:[configurationElement.plugin.bundle pathForResource:resource ofType:extension] encoding:NSUTF8StringEncoding error:nil];
		
		if ([extension isEqualToString:@"markdown"]) {
			resourceContent = [[NSTask markdown2html:resourceContent] mutableCopy];
		}
				
	}
	
	[resourceContent replaceOccurrencesOfString:@"$PROCESS_NAME$" withString:[[NSProcessInfo processInfo] processName] options:0 range:NSMakeRange(0, [resourceContent length])];

	NSMutableString *mutablePageTemplate = [[BHelpBookPage pageTemplate] mutableCopy];	
	[mutablePageTemplate replaceOccurrencesOfString:@"$PAGE_TITLE$" withString:label options:0 range:NSMakeRange(0, [mutablePageTemplate length])];
	[mutablePageTemplate replaceOccurrencesOfString:@"$PAGE_BODY$" withString:resourceContent options:0 range:NSMakeRange(0, [mutablePageTemplate length])];
	result = mutablePageTemplate;

	return result;
}

- (NSURL *)absoluteURL {
	return [helpBook absoluteURLForPage:self];
}

@end

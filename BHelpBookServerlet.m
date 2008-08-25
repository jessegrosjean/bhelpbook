//
//  BHelpBookServerlet.m
//  BHelpBook
//
//  Created by Jesse Grosjean on 2/3/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BHelpBookServerlet.h"
#import "BHTTPServerRequest.h"
#import "BHTTPConnection.h"
#import "BHTTPServer.h"
#import "BHelpBook.h"
#import "BHelpBookPage.h"
#import "BPluginDevelopmentController.h"


@interface BPlugin (BHelpBookServerlet)
- (NSString *)HB_htmlDocumentation;
@end

@interface BExtensionPoint (BHelpBookServerlet)
- (NSString *)HB_htmlDocumentation;
@end

@implementation BHelpBookServerlet

- (BOOL)doGET:(BHTTPServerRequest *)request {
	NSURL *requestURL = request.requestURL;
	NSString *path = [requestURL path];
	BHelpBookPage *page = [[BHelpBook sharedInstance] pageForPath:path];
	NSString *pageContent = page.content;
	NSString *contentType = nil;
	NSData *data = nil;

	if (pageContent) {
		data = [pageContent dataUsingEncoding:NSUTF8StringEncoding];
		contentType = @"text/html";
	} else {
		if ([path rangeOfString:@"APPLICATION_ICON"].location != NSNotFound) {
			data = [[[NSApplication sharedApplication] applicationIconImage] TIFFRepresentation];
			contentType = @"image/tiff";
		} else {
			NSArray *pathComponents = [path pathComponents];
			NSString *bundleID = [pathComponents count] > 1 ? [pathComponents objectAtIndex:1] : nil;
			NSBundle *bundle = [NSBundle bundleWithIdentifier:bundleID];
			NSString *resource = [[path lastPathComponent] stringByDeletingPathExtension];
			NSString *extension = [path pathExtension];
			NSString *resourcePath = [bundle pathForResource:resource ofType:extension];
			
			if (resourcePath) {
				data = resourcePath == nil ? nil : [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:resourcePath]];
				contentType = [BHTTPServer mimeTypeForExtension:extension];
			} else {
				BPlugin *plugin = [[BExtensionRegistry sharedInstance] pluginFor:[path lastPathComponent]];
				BExtensionPoint *extensionPonit = [[BExtensionRegistry sharedInstance] extensionPointFor:[path lastPathComponent]];
				NSString *pageTitle = nil;
				NSString *pageContent = nil;
				
				if (plugin) {
					pageTitle = [NSString stringWithFormat:@"%@ plugin", plugin.label];
					pageContent = [plugin HB_htmlDocumentation];
				} else if (extensionPonit) {
					pageTitle = [NSString stringWithFormat:@"%@ extension point", [path lastPathComponent]];
					pageContent = [extensionPonit HB_htmlDocumentation];
				}
				
				if (pageContent) {
					NSMutableString *mutablePageTemplate = [[BHelpBookPage pageTemplate] mutableCopy];
					[mutablePageTemplate replaceOccurrencesOfString:@"$PAGE_TITLE$" withString:pageTitle options:0 range:NSMakeRange(0, [mutablePageTemplate length])];
					[mutablePageTemplate replaceOccurrencesOfString:@"$PAGE_BODY$" withString:pageContent options:0 range:NSMakeRange(0, [mutablePageTemplate length])];
					data = [mutablePageTemplate dataUsingEncoding:NSUTF8StringEncoding];
				}
			}
		}
	}
	
	if (contentType == nil) {
		contentType = @"text/html";
	}
	
	if (data) {
		CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, NULL, kCFHTTPVersion1_1); // OK
		CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Length", (CFStringRef)[NSString stringWithFormat:@"%d", [data length]]);
		CFHTTPMessageSetHeaderFieldValue(response, (CFStringRef)@"Content-Type", (CFStringRef)contentType);
		//if ([method isEqual:@"GET"]) {
			CFHTTPMessageSetBody(response, (CFDataRef)data);
		//}
		[request setResponse:response];
		CFRelease(response);
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)doHEAD:(BHTTPServerRequest *)request {
	return NO;	
}

- (BOOL)doPOST:(BHTTPServerRequest *)request {	
	if ([[request.requestURL path] rangeOfString:@"generate_plugin_xcode_project"].location != NSNotFound) {
		[[BPluginDevelopmentController sharedInstance] generateXcodePluginProject:nil];
		return YES;
	}
	
	return NO;	
}

@end

@implementation BPlugin (BHelpBookServerlet)

- (NSString *)HB_htmlDocumentation {
	NSMutableString *html = [NSMutableString string];

	[html appendString:documentation];
	
	if ([self.headerFilePaths count] > 0) {
		[html appendString:@"<h3>Headers</h3>"];
		[html appendString:@"<ul>"];
		for (NSString *each in self.headerFilePaths) {
			[html appendFormat:@"<li><a href=\"file://%@\">%@</a></li>", each, [each lastPathComponent]];
		}
		[html appendString:@"</ul>"];
	}
	
	if ([extensionPoints count] > 0) {
		[html appendString:@"<h3>Extension Points</h3>"];
		[html appendString:@"<ul>"];
		for (BExtensionPoint *each in extensionPoints) {
			[html appendFormat:@"<li><code><a href=\"/%@/%@\">%@</a></code></li>", each.identifier, each.identifier, each.identifier];
		}
		[html appendString:@"</ul>"];
	}
	
	if ([requirements count] > 0) {
		[html appendString:@"<h3>Requirments</h3>"];
		[html appendString:@"<ul>"];
		for (BRequirement *each in requirements) {
			[html appendFormat:@"<li><code><a href=\"/%@/%@\">%@</a></code></li>", each.requiredBundleIdentifier, each.requiredBundleIdentifier, each.requiredBundleIdentifier];
		}
		[html appendString:@"</ul>"];
	}
	
	/*
	 [html appendString:@"<h2>Plugin.xml</h2>"];
	 [html appendFormat:@"<pre>%@</pre>", (NSString *) CFXMLCreateStringByEscapingEntities(NULL, (CFStringRef)[NSString stringWithContentsOfFile:[[self bundle] pathForResource:@"Plugin" ofType:@"xml"]], NULL)];
	 */
	/*	if ([requirements count] > 0) {
	 [html appendString:@"<h2>Requirements</h2>"];
	 [html appendString:@"<ul>"];
	 for (BRequirement *each in requirements) {
	 NSString *optional = each.optional ? @"yes" : @"no";
	 [html appendFormat:@"<li><code>%@</code>, version=<code>%@</code>, optional=<code>%@</code></li>", each.requiredBundleIdentifier, each.version, optional];
	 }
	 [html appendString:@"</ul>"];
	 }
	 
	 if ([extensionPoints count] > 0) {
	 [html appendString:@"<h2>Extension Points</h2>"];
	 [html appendString:@"<ul>"];
	 for (BExtensionPoint *each in extensionPoints) {
	 [html appendFormat:@"<li>Extension Point Identifier: <code>%@</code></li>", each.identifier];
	 }
	 [html appendString:@"</ul>"];
	 }
	 */
	return html;
}

@end

@implementation BExtensionPoint (BHelpBookServerlet)

- (NSString *)HB_htmlDocumentation {
	NSMutableString *html = [NSMutableString string];
	[html appendFormat:@"<p><strong>Contributing Plugin:</strong> <code><a href=\"/%@/%@\">%@</a></code></p>", plugin.identifier, plugin.identifier, plugin.identifier];
	[html appendString:documentation];
	/*
	 if ([self.extensions count] > 0) {
	 [html appendString:@"<h2>Current Extensions</h2>"];
	 
	 [html appendString:@"<ul>"];
	 for (BExtension *each in self.extensions) {
	 [html appendFormat:@"<code><a href=\"plugin://%@\">%@</a></code></p>", each.plugin.identifier, each.plugin.identifier];
	 }
	 [html appendString:@"</ul>"];
	 }*/
	
	return html;
}

@end

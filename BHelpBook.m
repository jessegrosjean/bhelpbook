//
//  BHelpBook.m
//  BHelpBook
//
//  Created by Jesse Grosjean on 2/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BHelpBook.h"
#import "BHelpBookPage.h"
#import "BHelpBookServerlet.h"


@interface BHelpBookPage (BHelpBookPrivate)
- (id)initWithHelpBook:(BHelpBook *)aHelpBook configurationElement:(BConfigurationElement *)configurationElement;
@end

@implementation BHelpBook

#pragma mark Class Methods

+ (id)sharedInstance {
    static id sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

#pragma mark Init

- (id)init {
	if (self = [super init]) {
		server = [[BHTTPServer alloc] init];
		[server mount:[[BHelpBookServerlet alloc] init] path:@"/"];
	}
	return self;
}

#pragma mark Help Book Server

- (BOOL)startHelpBookServer:(NSError **)error {
	[server stop];
    [server setName:@"HelpBook HTTP Server"];
    return [server start:error];
}

- (BOOL)stopHelpBookServer {
	return [server stop];
}

- (uint16_t)helpBookServerPort {
	return server.port;
}

#pragma mark Pages

- (NSArray *)pages {
	if (!pages) {
		pages = [[NSMutableArray alloc] init];
		
		for (BConfigurationElement *each in [[BExtensionRegistry sharedInstance] configurationElementsFor:@"com.blocks.BHelpBook.pages"]) {
			if ([each assertKeysPresent:[NSArray arrayWithObjects:@"name", @"label", nil]]) {
				[pages addObject:[[BHelpBookPage alloc] initWithHelpBook:self configurationElement:each]];
			}
		}
	}
	return pages;
}

- (BHelpBookPage *)homePage {
	return [[self pagesMatchingTag:@"home"] lastObject];
}

- (BHelpBookPage *)pageForPath:(NSString *)path {
	return [[self pagesMatchingPredicate:[NSPredicate predicateWithFormat:@"path = %@", path]] lastObject];
}

- (NSArray *)pagesMatchingTag:(NSString *)tag {
	return [self pagesMatchingPredicate:[NSPredicate predicateWithFormat:@"ANY tags = %@", tag]];
}

- (NSArray *)pagesMatchingPredicate:(NSPredicate *)predicate {
	return [self.pages filteredArrayUsingPredicate:predicate];
}

- (NSURL *)absoluteURLForPage:(BHelpBookPage *)page {
	return [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%d%@", server.port, page.path]];
}

@end

@implementation BHelpBookPage (BHelpBookPrivate)

- (id)initWithHelpBook:(BHelpBook *)aHelpBook configurationElement:(BConfigurationElement *)aConfigurationElement {
	if (self = [super init]) {
		helpBook = aHelpBook;
		configurationElement = aConfigurationElement;
		name = [configurationElement attributeForKey:@"name"];
		label = [[configurationElement localizedAttributeForKey:@"label"] stringByReplacingOccurrencesOfString:@"PROCESS_NAME" withString:[[NSProcessInfo processInfo] processName]];
		tags = [[configurationElement attributeForKey:@"tags"] componentsSeparatedByString:@","];
	}
	return self;
}

@end

//
//  BHelpBook.h
//  BHelpBook
//
//  Created by Jesse Grosjean on 2/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Blocks/Blocks.h>
#import "BHTTPServer.h"


@class BHelpBookPage;

@interface BHelpBook : NSObject {
	BHTTPServer *server;
	NSMutableArray *pages;
}

#pragma mark Class Methods

+ (id)sharedInstance;

#pragma mark Help Book Server

- (BOOL)startHelpBookServer:(NSError **)error;
- (BOOL)stopHelpBookServer;
@property(readonly) uint16_t helpBookServerPort;

#pragma mark Pages

@property(readonly) NSArray *pages;
- (BHelpBookPage *)homePage;
- (BHelpBookPage *)pageForPath:(NSString *)path;
- (NSArray *)pagesMatchingTag:(NSString *)tag;
- (NSArray *)pagesMatchingPredicate:(NSPredicate *)predicate;
- (NSURL *)absoluteURLForPage:(BHelpBookPage *)page;

@end

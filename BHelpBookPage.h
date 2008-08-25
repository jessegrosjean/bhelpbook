//
//  BHelpBookPage.h
//  BHelpBook
//
//  Created by Jesse Grosjean on 2/5/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Blocks/Blocks.h>


@class BHelpBook;

@interface BHelpBookPage : NSObject {
	BHelpBook *helpBook;
	BConfigurationElement *configurationElement;
	NSString *name;
	NSString *label;
	NSArray *tags;
}

+ (NSString *)pageTemplate;

@property(readonly) BHelpBook *helpBook;
@property(readonly) NSString *name;
@property(readonly) NSString *label;
@property(readonly) NSArray *tags;
@property(readonly) NSString *path;
@property(readonly) NSString *content;
@property(readonly) NSURL *absoluteURL;

@end

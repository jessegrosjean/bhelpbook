//
//  BHTTPServerResource.h
//  BHelpBook
//
//  Created by Jesse Grosjean on 2/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Blocks/Blocks.h>


@class BHTTPServerRequest;

@interface BHTTPServerlet : NSObject {
}

- (BOOL)processRequest:(BHTTPServerRequest *)request;
- (BOOL)doGET:(BHTTPServerRequest *)request;
- (BOOL)doHEAD:(BHTTPServerRequest *)request;
- (BOOL)doPOST:(BHTTPServerRequest *)request;

@end

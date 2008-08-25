//
//  BHTTPServerResource.m
//  BHelpBook
//
//  Created by Jesse Grosjean on 2/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BHTTPServerlet.h"
#import "BHTTPServer.h"
#import "BHTTPConnection.h"
#import "BHTTPServerRequest.h"


@implementation BHTTPServerlet

- (BOOL)processRequest:(BHTTPServerRequest *)request {
	NSString *requestMethod = [request requestMethod];
	BOOL result = NO;
	
	if ([requestMethod isEqualToString:@"HEAD"]) {
		result = [self doHEAD:request];
	} else if ([requestMethod isEqualToString:@"GET"]) {
		result = [self doGET:request];
	} else if ([requestMethod isEqualToString:@"POST"]) {
		result = [self doPOST:request];
	}
		
	return result;
}

- (BOOL)doGET:(BHTTPServerRequest *)request {
	return NO;	
}

- (BOOL)doHEAD:(BHTTPServerRequest *)request {
	return NO;	
}

- (BOOL)doPOST:(BHTTPServerRequest *)request {
	return NO;	
}

@end

//
//  BHTTPServerRequest.m
//  CocoaBHTTPServer
//
//  Created by Jesse Grosjean on 2/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BHTTPServerRequest.h"
#import "BHTTPConnection.h"


@implementation BHTTPServerRequest

- (id)init {
    [self dealloc];
    return nil;
}

- (id)initWithRequest:(CFHTTPMessageRef)req connection:(BHTTPConnection *)conn {
    connection = conn;
    request = (CFHTTPMessageRef)CFRetain(req);
    return self;
}

- (void)finalize {
    if (request) CFRelease(request);
    if (response) CFRelease(response);
	[super finalize];
}

- (NSString *)requestMethod {
	if (!requestMethod) {
		requestMethod = (id) CFHTTPMessageCopyRequestMethod(request);
	}
	return requestMethod;
}

- (NSURL *)requestURL {
	if (!requestURL) {
		requestURL = (NSURL *) CFHTTPMessageCopyRequestURL(request);
	}
	return requestURL;
}

@synthesize connection;
@synthesize request;
@synthesize response;

- (void)setResponse:(CFHTTPMessageRef)value {
    if (value != response) {
        if (response) CFRelease(response);
        response = (CFHTTPMessageRef)CFRetain(value);
        if (response) {
            // check to see if the response can now be sent out
            [connection processOutgoingBytes];
        }
    }
}

@synthesize responseBodyStream;

@end

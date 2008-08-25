//
//  BHTTPServerRequest.h
//  CocoaBHTTPServer
//
//  Created by Jesse Grosjean on 2/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BHTTPConnection;
@class BHTTPServerlet;

// As NSURLRequest and NSURLResponse are not entirely suitable for use from 
// the point of view of an HTTP server, we use CFHTTPMessageRef to encapsulate
// requests and responses.  This class packages the (future) response with a
// request and other info for convenience.
@interface BHTTPServerRequest : NSObject {
    BHTTPConnection *connection;
	NSURL *requestURL;
	NSString *requestMethod;
    CFHTTPMessageRef request;
    CFHTTPMessageRef response;
    NSInputStream *responseBodyStream;
}

- (id)initWithRequest:(CFHTTPMessageRef)req connection:(BHTTPConnection *)conn;

@property(readonly) BHTTPConnection *connection;
@property(readonly) NSURL *requestURL;
@property(readonly) NSString *requestMethod;
@property(readonly) CFHTTPMessageRef request;
@property(assign) CFHTTPMessageRef response;

// The response may include a body.  As soon as the response is set, 
// the response may be written out to the network.

@property(retain) NSInputStream *responseBodyStream;
// If there is to be a response body stream (when, say, a big
// file is to be returned, rather than reading the whole thing
// into memory), then it must be set on the request BEFORE the
// response [headers] itself.

@end

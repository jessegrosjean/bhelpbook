//
//  HTTPConnection.h
//  CocoaBHTTPServer
//
//  Created by Jesse Grosjean on 2/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BHTTPServer;
@class BHTTPServerRequest;

@interface BHTTPConnection : NSObject {
    BHTTPServer *server;
    NSData *peerAddress;
    NSMutableArray *requests;
    NSInputStream *istream;
    NSOutputStream *ostream;
    NSMutableData *ibuffer;
    NSMutableData *obuffer;
    BOOL isValid;
    BOOL firstResponseDone;
}

- (id)initWithPeerAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr forServer:(BHTTPServer *)serv;

@property(readonly) BOOL isValid;
@property(readonly) NSData *peerAddress;
@property(readonly) BHTTPServer *server;
@property(readonly) BHTTPServerRequest *nextRequest;

- (void)invalidate;
- (void)processOutgoingBytes;

@end
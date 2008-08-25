//
//  HTTPConnection.m
//  CocoaBHTTPServer
//
//  Created by Jesse Grosjean on 2/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BHTTPConnection.h"
#import "BHTTPServer.h"
#import "BHTTPServerRequest.h"
#import "BHTTPServerlet.h"

@interface BHTTPServer (BHTTPConnectionPrivate)
- (void)removeConnection:(BHTTPConnection *)connection;
@end

@implementation BHTTPConnection

- (id)init {
    [self dealloc];
    return nil;
}

- (id)initWithPeerAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr forServer:(BHTTPServer *)serv {
    peerAddress = [addr copy];
    server = serv;
    istream = istr;
    ostream = ostr;
    [istream setDelegate:self];
    [ostream setDelegate:self];
    [istream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
    [ostream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:(id)kCFRunLoopCommonModes];
    [istream open];
    [ostream open];
    isValid = YES;
    return self;
}

- (void)finalize {
	[self invalidate];
	[super finalize];
}

@synthesize isValid;
@synthesize peerAddress;
@synthesize server;

- (BHTTPServerRequest *)nextRequest {
    unsigned idx, cnt = requests ? [requests count] : 0;
    for (idx = 0; idx < cnt; idx++) {
        id obj = [requests objectAtIndex:idx];
        if ([obj response] == nil) {
            return obj;
        }
    }
    return nil;
}

- (void)invalidate {
    if (isValid) {
        isValid = NO;
        [istream close];
		[istream setDelegate:nil];
        [ostream close];
		[ostream setDelegate:nil];
        istream = nil;
        ostream = nil;
        ibuffer = nil;
        obuffer = nil;
        requests = nil;
		[server removeConnection:self];
		server = nil;
    }
}

- (void)processRequestWithServerlet:(BHTTPServerRequest *)mess {
    CFHTTPMessageRef request = [mess request];
	
    NSString *vers = [(id)CFHTTPMessageCopyVersion(request) autorelease];
    if (!vers || ![vers isEqual:(id)kCFHTTPVersion1_1]) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 505, NULL, (CFStringRef)vers); // Version Not Supported
        [mess setResponse:response];
        CFRelease(response);
        return;
    }
	
    NSString *requestMethod = [mess requestMethod];
    if (!requestMethod) {
        CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 400, NULL, kCFHTTPVersion1_1); // Bad Request
        [mess setResponse:response];
        CFRelease(response);
        return;
    }
	
	for (BHTTPServerlet *each in [server serverletsForURL:[mess requestURL]]) {
		if ([each processRequest:mess]) {
			return;
		}
	}
	
	CFHTTPMessageRef response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 404, NULL, kCFHTTPVersion1_1); // Not Found
	[mess setResponse:response];
	CFRelease(response);
	
	return;
}

// YES return means that a complete request was parsed, and the caller
// should call again as the buffered bytes may have another complete
// request available.
- (BOOL)processIncomingBytes {
    CFHTTPMessageRef working = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
    CFHTTPMessageAppendBytes(working, [ibuffer bytes], [ibuffer length]);
    
    // This "try and possibly succeed" approach is potentially expensive
    // (lots of bytes being copied around), but the only API available for
    // the server to use, short of doing the parsing itself.
    
    // HTTPConnection does not handle the chunked transfer encoding
    // described in the HTTP spec.  And if there is no Content-Length
    // header, then the request is the remainder of the stream bytes.
    
    if (CFHTTPMessageIsHeaderComplete(working)) {
        NSString *contentLengthValue = [(NSString *)CFHTTPMessageCopyHeaderFieldValue(working, (CFStringRef)@"Content-Length") autorelease];
        unsigned contentLength = contentLengthValue ? [contentLengthValue intValue] : 0;
        NSData *body = [(NSData *)CFHTTPMessageCopyBody(working) autorelease];
        unsigned bodyLength = [body length];
		
        if (contentLength <= bodyLength) {
            NSData *newBody = [NSData dataWithBytes:[body bytes] length:contentLength];
            [ibuffer setLength:0];
            [ibuffer appendBytes:([body bytes] + contentLength) length:(bodyLength - contentLength)];
            CFHTTPMessageSetBody(working, (CFDataRef)newBody);
        } else {
            CFRelease(working);
            return NO;
        }
    } else {
        return NO;
    }
    
    BHTTPServerRequest *request = [[BHTTPServerRequest alloc] initWithRequest:working connection:self];
    if (!requests) {
        requests = [[NSMutableArray alloc] init];
    }
	
    [requests addObject:request];
	
	[self processRequestWithServerlet:request];
    CFRelease(working);
    return YES;
}

- (void)processOutgoingBytes {
    // The HTTP headers, then the body if any, then the response stream get
    // written out, in that order.  The Content-Length: header is assumed to 
    // be properly set in the response.  Outgoing responses are processed in 
    // the order the requests were received (required by HTTP).
    
    // Write as many bytes as possible, from buffered bytes, response
    // headers and body, and response stream.
	
    if (![ostream hasSpaceAvailable]) {
        return;
    }
	
    unsigned olen = [obuffer length];
    if (0 < olen) {
        int writ = [ostream write:[obuffer bytes] maxLength:olen];
        // buffer any unwritten bytes for later writing
        if (writ < olen) {
            memmove([obuffer mutableBytes], [obuffer mutableBytes] + writ, olen - writ);
            [obuffer setLength:olen - writ];
            return;
        }
        [obuffer setLength:0];
    }
	
    unsigned cnt = requests ? [requests count] : 0;
    BHTTPServerRequest *req = (0 < cnt) ? [requests objectAtIndex:0] : nil;
	
    CFHTTPMessageRef cfresp = req ? [req response] : NULL;
    if (!cfresp) return;
    
    if (!obuffer) {
        obuffer = [[NSMutableData alloc] init];
    }
	
    if (!firstResponseDone) {
        firstResponseDone = YES;
        NSData *serialized = [(NSData *)CFHTTPMessageCopySerializedMessage(cfresp) autorelease];
        unsigned olen = [serialized length];
        if (0 < olen) {
            int writ = [ostream write:[serialized bytes] maxLength:olen];
            if (writ < olen) {
                // buffer any unwritten bytes for later writing
                [obuffer setLength:(olen - writ)];
                memmove([obuffer mutableBytes], [serialized bytes] + writ, olen - writ);
                return;
            }
        }
    }
	
    NSInputStream *respStream = [req responseBodyStream];
    if (respStream) {
        if ([respStream streamStatus] == NSStreamStatusNotOpen) {
            [respStream open];
        }
        // read some bytes from the stream into our local buffer
        [obuffer setLength:16 * 1024];
        int read = [respStream read:[obuffer mutableBytes] maxLength:[obuffer length]];
        [obuffer setLength:read];
    }
	
    if (0 == [obuffer length]) {
		// XXX tell anyone who cares that response completed here.
        [requests removeObjectAtIndex:0];
        firstResponseDone = NO;
        if ([istream streamStatus] == NSStreamStatusAtEnd && [requests count] == 0) {
            [self invalidate];
        }
        return;
    }
    
    olen = [obuffer length];
    if (0 < olen) {
        int writ = [ostream write:[obuffer bytes] maxLength:olen];
        // buffer any unwritten bytes for later writing
        if (writ < olen) {
            memmove([obuffer mutableBytes], [obuffer mutableBytes] + writ, olen - writ);
        }
        [obuffer setLength:olen - writ];
    }
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)streamEvent {
    switch(streamEvent) {
		case NSStreamEventHasBytesAvailable: {
			uint8_t buf[16 * 1024];
			uint8_t *buffer = NULL;
			unsigned int len = 0;
			if (![istream getBuffer:&buffer length:&len]) {
				int amount = [istream read:buf maxLength:sizeof(buf)];
				buffer = buf;
				len = amount;
			}
			if (0 < len) {
				if (!ibuffer) {
					ibuffer = [[NSMutableData alloc] init];
				}
				[ibuffer appendBytes:buffer length:len];
			}
			do {} while ([self processIncomingBytes]);
			break;
		}
		
		case NSStreamEventHasSpaceAvailable: {
			[self processOutgoingBytes];
			break;
		}
		
		case NSStreamEventEndEncountered: {
			[self processIncomingBytes];
			if (stream == ostream) {
				// When the output stream is closed, no more writing will succeed and
				// will abandon the processing of any pending requests and further
				// incoming bytes.
				[self invalidate];
			}
			break;
		}
		
		case NSStreamEventErrorOccurred: {
			NSLog(@"BHTTPServer stream error: %@", [stream streamError]);
			break;
		}
		
		default: {
			break;
		}
    }
}

@end

@implementation BHTTPServer (BHTTPConnectionPrivate)

- (void)removeConnection:(BHTTPConnection *)connection {
	[connections removeObject:connection];
}

@end




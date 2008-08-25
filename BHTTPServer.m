#import "BHTTPServer.h"
#import "BHTTPConnection.h"
#import "BHTTPServerRequest.h"
#import "BHTTPServerlet.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

@interface BHTTPServer (BPrivate)
- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr;
@end

@implementation BHTTPServer

+ (NSString *)mimeTypeForUTI:(NSString *)uti {
    return (id) UTTypeCopyPreferredTagWithClass((CFStringRef)uti, kUTTagClassMIMEType);
}

+ (NSString *)mimeTypeForExtension:(NSString *)extension {
	return (id) UTTypeCopyPreferredTagWithClass((CFStringRef)extension, kUTTagClassMIMEType);
}

- (id)init {
	if (self = [super init]) {
		connections = [NSMutableArray array];
		mountedServerlets = [NSMutableDictionary dictionary];
		sortedServerletPaths = [NSMutableArray array];
	}
    return self;
}

- (void)finalize {
    [self stop];
	[super finalize];
}

@synthesize domain;
@synthesize name;
@synthesize port;

// This function is called by CFSocket when a new connection comes in.
// We gather some data here, and convert the function call to a method
// invocation on BHTTPServer.
static void BHTTPServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    BHTTPServer *server = (BHTTPServer *)info;
    if (kCFSocketAcceptCallBack == type) { 
        // for an AcceptCallBack, the data parameter is a pointer to a CFSocketNativeHandle
        CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
        uint8_t name[SOCK_MAXADDRLEN];
        socklen_t namelen = sizeof(name);
        NSData *peer = nil;
        if (0 == getpeername(nativeSocketHandle, (struct sockaddr *)name, &namelen)) {
            peer = [NSData dataWithBytes:name length:namelen];
        }
        CFReadStreamRef readStream = NULL;
		CFWriteStreamRef writeStream = NULL;
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &readStream, &writeStream);
        if (readStream && writeStream) {
            CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            CFWriteStreamSetProperty(writeStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
            [server handleNewConnectionFromAddress:peer inputStream:(NSInputStream *)readStream outputStream:(NSOutputStream *)writeStream];
        } else {
            // on any failure, need to destroy the CFSocketNativeHandle 
            // since we are not going to use it any more
            close(nativeSocketHandle);
        }
        if (readStream) CFRelease(readStream);
        if (writeStream) CFRelease(writeStream);
    }
}

- (BOOL)start:(NSError **)error {
    CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
    ipv4socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&BHTTPServerAcceptCallBack, &socketCtxt);
    ipv6socket = CFSocketCreate(kCFAllocatorDefault, PF_INET6, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, (CFSocketCallBack)&BHTTPServerAcceptCallBack, &socketCtxt);
	
    if (NULL == ipv4socket || NULL == ipv6socket) {
        if (error) *error = [[NSError alloc] initWithDomain:BHTTPServerErrorDomain code:kBHTTPServerNoSocketsAvailable userInfo:nil];
        if (ipv4socket) CFRelease(ipv4socket);
        if (ipv6socket) CFRelease(ipv6socket);
        ipv4socket = NULL;
        ipv6socket = NULL;
        return NO;
    }
	
    int yes = 1;
    setsockopt(CFSocketGetNative(ipv4socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
    setsockopt(CFSocketGetNative(ipv6socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
	
    // set up the IPv4 endpoint; if port is 0, this will cause the kernel to choose a port for us
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(port);
    addr4.sin_addr.s_addr = htonl(INADDR_ANY);
    NSData *address4 = [NSData dataWithBytes:&addr4 length:sizeof(addr4)];
	
    if (kCFSocketSuccess != CFSocketSetAddress(ipv4socket, (CFDataRef)address4)) {
        if (error) *error = [[NSError alloc] initWithDomain:BHTTPServerErrorDomain code:kBHTTPServerCouldNotBindToIPv4Address userInfo:nil];
        if (ipv4socket) CFRelease(ipv4socket);
        if (ipv6socket) CFRelease(ipv6socket);
        ipv4socket = NULL;
        ipv6socket = NULL;
        return NO;
    }
    
    if (0 == port) {
        // now that the binding was successful, we get the port number 
        // -- we will need it for the v6 endpoint and for the NSNetService
        NSData *addr = [(NSData *)CFSocketCopyAddress(ipv4socket) autorelease];
        memcpy(&addr4, [addr bytes], [addr length]);
        port = ntohs(addr4.sin_port);
    }
	
    // set up the IPv6 endpoint
    struct sockaddr_in6 addr6;
    memset(&addr6, 0, sizeof(addr6));
    addr6.sin6_len = sizeof(addr6);
    addr6.sin6_family = AF_INET6;
    addr6.sin6_port = htons(port);
    memcpy(&(addr6.sin6_addr), &in6addr_any, sizeof(addr6.sin6_addr));
    NSData *address6 = [NSData dataWithBytes:&addr6 length:sizeof(addr6)];
	
    if (kCFSocketSuccess != CFSocketSetAddress(ipv6socket, (CFDataRef)address6)) {
        if (error) *error = [[NSError alloc] initWithDomain:BHTTPServerErrorDomain code:kBHTTPServerCouldNotBindToIPv6Address userInfo:nil];
        if (ipv4socket) CFRelease(ipv4socket);
        if (ipv6socket) CFRelease(ipv6socket);
        ipv4socket = NULL;
        ipv6socket = NULL;
        return NO;
    }
	
    // set up the run loop sources for the sockets
    CFRunLoopRef cfrl = CFRunLoopGetCurrent();
    CFRunLoopSourceRef source4 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv4socket, 0);
    CFRunLoopAddSource(cfrl, source4, kCFRunLoopCommonModes);
    CFRelease(source4);
	
    CFRunLoopSourceRef source6 = CFSocketCreateRunLoopSource(kCFAllocatorDefault, ipv6socket, 0);
    CFRunLoopAddSource(cfrl, source6, kCFRunLoopCommonModes);
    CFRelease(source6);
	
	NSString *publishingDomain = domain ? domain : @"";
	NSString *publishingName = nil;
	if (nil != name) {
		publishingName = name;
	} else {
		NSString * thisHostName = [[NSProcessInfo processInfo] hostName];
		if ([thisHostName hasSuffix:@".local"]) {
			publishingName = [thisHostName substringToIndex:([thisHostName length] - 6)];
		}
	}
	netService = [[NSNetService alloc] initWithDomain:publishingDomain type:@"_http._tcp." name:publishingName port:port];
	[netService publish];
	
    return YES;
}

- (BOOL)stop {
    [netService stop];
    [netService release];
    netService = nil;
    if (ipv4socket) CFSocketInvalidate(ipv4socket);
    if (ipv6socket) CFSocketInvalidate(ipv6socket);
    if (ipv4socket) CFRelease(ipv4socket);
    if (ipv6socket) CFRelease(ipv6socket);
    ipv4socket = NULL;
    ipv6socket = NULL;
	[connections makeObjectsPerformSelector:@selector(invalidate)];
	[connections removeAllObjects];
    return YES;
}

- (void)mount:(BHTTPServerlet *)serverlet path:(NSString *)path {
	[mountedServerlets setObject:serverlet forKey:path];
	[sortedServerletPaths addObject:path];
	[sortedServerletPaths sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"length" ascending:YES]]];
}

- (void)unmount:(NSString *)path {
	[mountedServerlets removeObjectForKey:path];
	[sortedServerletPaths removeObject:path];
}

- (NSArray *)serverletsForURL:(NSURL *)url {
	NSMutableArray *matches = [NSMutableArray array];
	NSString *path = [url path];
	
	for (NSString *each in sortedServerletPaths) {
		if ([path rangeOfString:each].location == 0) {
			[matches addObject:[mountedServerlets objectForKey:each]];
		}
	}
	
	return matches;
}

- (void)handleNewConnectionFromAddress:(NSData *)addr inputStream:(NSInputStream *)istr outputStream:(NSOutputStream *)ostr {
	[connections addObject:[[BHTTPConnection alloc] initWithPeerAddress:addr inputStream:istr outputStream:ostr forServer:self]];
}

@end

NSString * const BHTTPServerErrorDomain = @"BHTTPServerErrorDomain";

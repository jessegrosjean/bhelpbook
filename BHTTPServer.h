/*
 File: BHTTPServer.h
 
 Abstract: Interface description for a basic HTTP server Foundation class
 */ 

#import <Foundation/Foundation.h>
#import <CoreServices/CoreServices.h>


typedef enum {
    kBHTTPServerCouldNotBindToIPv4Address = 1,
    kBHTTPServerCouldNotBindToIPv6Address = 2,
    kBHTTPServerNoSocketsAvailable = 3,
} BHTTPServerErrorCode;

@class BHTTPConnection;
@class BHTTPServerRequest;
@class BHTTPServerlet;

@interface BHTTPServer : NSObject {
    NSString *domain;
    NSString *name;
    uint16_t port;
    CFSocketRef ipv4socket;
    CFSocketRef ipv6socket;
    NSNetService *netService;
	NSMutableArray *connections;
	NSMutableDictionary *mountedServerlets;
	NSMutableArray *sortedServerletPaths;
}

+ (NSString *)mimeTypeForUTI:(NSString *)uti;
+ (NSString *)mimeTypeForExtension:(NSString *)extension;

@property(retain) NSString *domain;
@property(retain) NSString *name;
@property(assign) uint16_t port;

- (BOOL)start:(NSError **)error;
- (BOOL)stop;

- (void)mount:(BHTTPServerlet *)serverlet path:(NSString *)path;
- (void)unmount:(NSString *)path;
- (NSArray *)serverletsForURL:(NSURL *)url;

@end

NSString * const BHTTPServerErrorDomain;

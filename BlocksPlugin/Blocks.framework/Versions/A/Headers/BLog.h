//
//  BLog.h
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define LOCATION_PARAMETERS lineNumber:__LINE__ fileName:(char *)__FILE__ function:(char *)__PRETTY_FUNCTION__

#define BLog(...) [BLog logWithLevel:BLoggingInfo LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogDebug(...) [BLog logWithLevel:BLoggingDebug LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogInfo(...) [BLog logWithLevel:BLoggingInfo LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogWarn(...) [BLog logWithLevel:BLoggingWarn LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogError(...) [BLog logWithLevel:BLoggingError LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogFatal(...) [BLog logWithLevel:BLoggingFatal LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogErrorWithException(e, ...) [BLog logErrorWithException:e LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogAssert(assertion, ...) [BLog assert:assertion LOCATION_PARAMETERS message:__VA_ARGS__]

typedef enum _BLoggingLevel {
    BLoggingDebug = 0,
    BLoggingInfo = 10,
    BLoggingWarn = 20,
    BLoggingError = 30,
    BLoggingFatal = 40
} BLoggingLevel;

@interface BLog : NSObject {

}

+ (BLoggingLevel)loggingLevel;
+ (void)setLoggingLevel:(BLoggingLevel)level;
+ (void)logWithLevel:(BLoggingLevel)level lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)functionName format:(NSString *)format arguments:(va_list)args;
+ (void)logWithLevel:(BLoggingLevel)level lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ...;
+ (void)logErrorWithException:(NSException *)exception lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ...;
+ (void)assert:(BOOL)assertion lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)methodName message:(NSString *)formatStr, ... ;

@end


#import <Cocoa/Cocoa.h>

@interface NSTask (runScriptNamed)

+ (NSString*)markdown2html:(NSString*)markdown;
+ (NSString*)runScriptNamed:(NSString*)scriptName_ extension:(NSString*)scriptExtension_ fromBundle:(NSBundle *)bundle input:(NSString*)input_ error:(NSError**)error_;

@end

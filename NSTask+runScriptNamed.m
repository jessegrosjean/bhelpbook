#import "NSTask+runScriptNamed.h"

@implementation NSTask (runScriptNamed)

+ (NSString*)markdown2html:(NSString*)markdown_ {
	if (!markdown_)
		return @"";
	
	NSString *dumbQuoteHTML = [NSTask runScriptNamed:@"Markdown" extension:@"pl" fromBundle:[NSBundle bundleWithIdentifier:@"com.blocks.BHelpBook"] input:markdown_ error:nil];
	NSString *smartQuoteHTML = nil;
	if (dumbQuoteHTML)
		smartQuoteHTML = [NSTask runScriptNamed:@"SmartyPants" extension:@"pl" fromBundle:[NSBundle bundleWithIdentifier:@"com.blocks.BHelpBook"] input:dumbQuoteHTML error:nil];
	
	return smartQuoteHTML;
}

+ (NSString*)runScriptNamed:(NSString*)scriptName_ extension:(NSString*)scriptExtension_ fromBundle:(NSBundle *)bundle input:(NSString*)input_ error:(NSError**)error_ {
	NSParameterAssert(scriptName_ && [scriptName_ length]);
	NSParameterAssert(scriptExtension_ && [scriptExtension_ length]);
	NSParameterAssert(input_); // It's OK if the data is zero-length, I think.
	
	NSString *result = nil;
	
	NSString *scriptPath = [bundle pathForResource:scriptName_ ofType:scriptExtension_];
	
	if (scriptPath) {
		NSPipe *inputPipe = [NSPipe pipe];
		NSPipe *outputPipe = [NSPipe pipe];
		
		NSTask *scriptTask = [[[NSTask alloc] init] autorelease];
		NSAssert([scriptExtension_ isEqualToString:@"pl"], nil); // We only know how to handle perl scripts right now. Extend on-demand.
		[scriptTask setLaunchPath:@"/usr/bin/perl"];
		[scriptTask setArguments:[NSArray arrayWithObject:scriptPath]];
		[scriptTask setStandardInput:inputPipe];
		[scriptTask setStandardOutput:outputPipe];
		[scriptTask launch];
		
		NS_DURING
			[[inputPipe fileHandleForWriting] writeData:[input_ dataUsingEncoding:NSUTF8StringEncoding]];
		NS_HANDLER
			//	Catch Broken pipe exceptions in case the script for some reason doesn't read its STDIN.
		NS_ENDHANDLER
		[[inputPipe fileHandleForWriting] closeFile];
		result = [[[NSString alloc] initWithData:[[outputPipe fileHandleForReading] readDataToEndOfFile]
										encoding:NSUTF8StringEncoding] autorelease];
	} else {
		if (error_)
			*error_ = [NSError errorWithDomain:NSCocoaErrorDomain
										  code:NSFileNoSuchFileError
									  userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@/%@.%@",
																					  [[NSBundle mainBundle] bundlePath],
																					  scriptName_,
																					  scriptExtension_]
																		   forKey:NSFilePathErrorKey]];
	}
	return result;
}

@end

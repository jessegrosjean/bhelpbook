//
//  BPluginDevelopmentController.m
//  BPluginDevelopment
//
//  Created by Jesse Grosjean on 1/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BPluginDevelopmentController.h"
#import "NSTask+runScriptNamed.h"

@implementation BPluginDevelopmentController

#pragma mark Class Methods

+ (id)sharedInstance {
    static id sharedInstance = nil;
    if (sharedInstance == nil) {
        sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

#pragma mark Init

- (id)init {
	if (self = [super init]) {
	}
	return self;
}

- (BOOL)generateXcodePluginProjectAtPath:(NSString *)newProjectPath {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if ([fileManager fileExistsAtPath:newProjectPath]) {
		if (![fileManager removeFileAtPath:newProjectPath handler:nil]) {
			BLogError([NSString stringWithFormat:@"failed removeFileAtPath:%@", newProjectPath]);
			return NO;
		}
	}
	
	if (![fileManager createDirectoryAtPath:newProjectPath attributes:nil]) {
		BLogError([NSString stringWithFormat:@"failed createDirectoryAtPath:%@", newProjectPath]);
		return NO;
	}
	
	NSString *newProjectName = [newProjectPath lastPathComponent];
	NSString *templateProjectFolder = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:@"BlocksPlugin"];
	
	for (NSString *eachPath in [fileManager subpathsAtPath:templateProjectFolder]) {
		NSString *source = [templateProjectFolder stringByAppendingPathComponent:eachPath];
		NSString *destination = [newProjectPath stringByAppendingPathComponent:eachPath];
		BOOL isDirectory;

		if ([destination rangeOfString:@"BlocksPlugin"].location != NSNotFound) {
			destination = [destination stringByReplacingOccurrencesOfString:@"BlocksPlugin" withString:newProjectName];
		}
		
		if ([fileManager fileExistsAtPath:source isDirectory:&isDirectory]) {
			if (isDirectory) {
				if (![fileManager createDirectoryAtPath:destination attributes:nil]) {
					BLogError([NSString stringWithFormat:@"failed createDirectoryAtPath:%@", destination]);
					return NO;
				}
			} else {
				NSMutableString *stringContent = nil;
				NSStringEncoding encoding = NSUTF8StringEncoding;
				NSString *extension = [eachPath pathExtension];
				BOOL needsCopy = YES;
				
				// Trial and error, strings files seem to always be in NSUTF16StringEncoding
				if ([extension isEqualToString:@"strings"]) {
					stringContent = [NSMutableString stringWithContentsOfFile:source encoding:NSUTF16StringEncoding error:nil];
				} else {
					stringContent = [NSMutableString stringWithContentsOfFile:source];
				}
				
				if (stringContent) {
					if (0 != [stringContent replaceOccurrencesOfString:@"BlocksPlugin" withString:newProjectName options:0 range:NSMakeRange(0, [stringContent length])]) {
						// These encoding settings are done by trial and error, if someone knows a better way let me know.
						if ([extension isEqualToString:@"h"] || [extension isEqualToString:@"m"]) {
							encoding = NSMacOSRomanStringEncoding;
						} else if ([extension isEqualToString:@"strings"]) {
							encoding = NSUTF16StringEncoding;
						}
						
						if ([stringContent writeToURL:[NSURL fileURLWithPath:destination] atomically:YES encoding:encoding error:nil]) {
							needsCopy = NO;
						}
					}					
				}
				
				if (needsCopy) {
					if (![fileManager copyPath:source toPath:destination handler:nil]) {
						BLogError([NSString stringWithFormat:@"failed copyPath:%@ toPath:%@", source, destination]);
						NSBeep();
						return NO;
					}
				}
			}
		}
	}
	
	return YES;
}

- (BOOL)transformToHTML:(NSString *)markdownText andSaveAtPath:(NSString *)destinationPath {
	destinationPath = [destinationPath stringByAppendingPathExtension:@"html"];
	NSString *htmlText = [NSTask markdown2html:markdownText];
	return [[htmlText dataUsingEncoding:NSUTF8StringEncoding] writeToFile:destinationPath atomically:YES];
}

- (BOOL)generatePluginDocumentationAtPath:(NSString *)path {
	NSMutableString *markdown = [NSMutableString string];
	
	[markdown appendString:@"# Index:\n\n"];
	
	[markdown appendString:@"**Plugins:**\n\n"];
	
	for (BPlugin *eachPlugin in [[BExtensionRegistry sharedInstance] plugins]) {
		[markdown appendFormat:@" * <a href=\"#%@\">%@</a>\n", eachPlugin.identifier, eachPlugin.label];
	}

	[markdown appendString:@"\n**Extension Points:**\n\n"];
	
	for (BExtensionPoint *eachExtensionPoint in [[BExtensionRegistry sharedInstance] extensionPoints]) {
		[markdown appendFormat:@" * <a href=\"#%@\">%@</a>\n", eachExtensionPoint.identifier, eachExtensionPoint.identifier];
	}	

	[markdown appendString:@"\n"];

	for (BPlugin *eachPlugin in [[BExtensionRegistry sharedInstance] plugins]) {
		[markdown appendString:@"---\n\n"];
		[markdown appendFormat:@"# <a name=\"%@\">%@ Plugin</a>\n\n", eachPlugin.identifier, eachPlugin.label];
		[markdown appendString:eachPlugin.documentation];
		[markdown appendString:@"\n\n"];
		[markdown appendFormat:@"**Identifier:** `%@`\n\n", eachPlugin.identifier];
		
		if ([eachPlugin.headerFilePaths count] > 0) {
			[markdown appendString:@"**Headers:**\n\n"];
			for (NSString *each in eachPlugin.headerFilePaths) {
				[markdown appendFormat:@" * <a href=\"./AssembledHeaders/%@/%@\">`%@`</a>\n", eachPlugin.identifier, [each lastPathComponent], [each lastPathComponent]];
			}
			[markdown appendString:@"\n"];
		}
		
		if ([eachPlugin.requirements count] > 0) {
			[markdown appendString:@"**Requirments:**\n\n"];
			for (BRequirement *each in eachPlugin.requirements) {
				[markdown appendFormat:@" * <a href=\"#%@\">%@</a>\n", each.requiredBundleIdentifier, each.requiredBundleIdentifier];
			}
			[markdown appendString:@"\n"];
		}
		
		if ([eachPlugin.extensionPoints count] > 0) {
			[markdown appendString:@"**Extension Points:**\n\n"];
			for (BExtensionPoint *each in eachPlugin.extensionPoints) {
				[markdown appendFormat:@" * <a href=\"#%@\">%@</a>\n", each.identifier, each.identifier];
			}
			[markdown appendString:@"\n"];
		}
	}

	[markdown appendString:@"\n\n---\n\n---\n\n"];
	
	for (BExtensionPoint *eachExtensionPoint in [[BExtensionRegistry sharedInstance] extensionPoints]) {
		[markdown appendString:@"---\n\n"];
		[markdown appendFormat:@"# <a name=\"%@\">%@</a>\n\n", eachExtensionPoint.identifier, eachExtensionPoint.identifier];
		[markdown appendString:eachExtensionPoint.documentation];
		[markdown appendString:@"\n\n"];
	}	
			
	return [[[NSTask markdown2html:markdown] dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
}

#pragma mark Actions

- (IBAction)generateXcodePluginProject:(id)sender {
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	
	if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *newProjectPath = [savePanel filename];
		NSString *newProjectName = [newProjectPath lastPathComponent];
		
		// 1. Create project from template
		if (![self generateXcodePluginProjectAtPath:newProjectPath]) {
			NSBeep();
			return;
		}
		
		// 2. Replace Blocks Framework.
		NSString *currentBlocksPath = [[NSBundle bundleWithIdentifier:@"com.blocks.Blocks"] bundlePath];
		NSString *projectsBlocksPath = [NSString stringWithFormat:@"%@/Blocks.framework", newProjectPath, newProjectName];

		if (![fileManager removeFileAtPath:projectsBlocksPath handler:nil]) {
			BLogError([NSString stringWithFormat:@"failed removeFileAtPath:%@", projectsBlocksPath]);
			NSBeep();
			return;
		}

		if (![fileManager copyPath:currentBlocksPath toPath:projectsBlocksPath handler:nil]) {
			BLogError([NSString stringWithFormat:@"failed copyPath:%@ toPath:%@", currentBlocksPath, projectsBlocksPath]);
			NSBeep();
			return;
		}

		// 3. Generated Plugin Headers.
		for (BPlugin *eachPlugin in [[BExtensionRegistry sharedInstance] plugins]) {

			if ([eachPlugin.headerFilePaths count] > 0) {
				NSString *pluginHeadersFolder = [newProjectPath stringByAppendingPathComponent:[NSString stringWithFormat:@"AssembledHeaders/%@", eachPlugin.identifier]];
				if (![fileManager createDirectoryAtPath:pluginHeadersFolder attributes:nil]) {
					BLogError([NSString stringWithFormat:@"failed createDirectoryAtPath:%@", pluginHeadersFolder]);
					NSBeep();
					return;
				}	
				for (NSString *eachPluginHeaderPath in eachPlugin.headerFilePaths) {
					NSString *eachPluginHeaderDestination = [pluginHeadersFolder stringByAppendingPathComponent:[eachPluginHeaderPath lastPathComponent]];
					if (![fileManager copyPath:eachPluginHeaderPath toPath:eachPluginHeaderDestination handler:nil]) {
						BLogError([NSString stringWithFormat:@"failed copyPath:%@ toPath:%@", eachPluginHeaderPath, eachPluginHeaderDestination]);
						NSBeep();
						return;
					}
				}
			}
		}
		
		NSString *welcomeFile = [newProjectPath stringByAppendingPathComponent:@"Welcome.html"];
		[[[NSTask markdown2html:[NSString stringWithContentsOfFile:welcomeFile]] dataUsingEncoding:NSUTF8StringEncoding] writeToFile:welcomeFile atomically:YES];

		[self generatePluginDocumentationAtPath:[newProjectPath stringByAppendingPathComponent:@"AssembledDocumentation.html"]];
		
		// 5. Open Xcode Project.
		[[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/%@.xcodeproj", newProjectPath, newProjectName]];
	}
}

@end
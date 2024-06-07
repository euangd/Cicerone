//
//	BrewInterface.m
//	Cicerone – The Homebrew GUI App for OS X
//
//	Created by Vincent Saluzzo on 06/12/11.
//	Copyright (c) 2014 Bruno Philipe. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "COHomebrewInterface.h"
#import "COTask.h"

static NSString * const shellHeaderEndMarker = @"+++++ Cicerone +++++";

@interface COHomebrewInterfaceListCall : NSObject

@property (strong, readonly) NSArray *arguments;
@property (readonly) BOOL casks;

- (instancetype)initWithArguments:(NSArray *)arguments casks:(BOOL)casks;
- (NSArray *)parseData:(NSString *)data;
- (COFormula *)parseFormulaItem:(NSString *)item;

@end

@interface COHomebrewInterfaceListCallInstalledFormulae : COHomebrewInterfaceListCall
@end

@interface COHomebrewInterfaceListCallInstalledCasks : COHomebrewInterfaceListCallInstalledFormulae
@end

@interface COHomebrewInterfaceListCallAllFormulae : COHomebrewInterfaceListCall
@end

@interface COHomebrewInterfaceListCallAllCasks : COHomebrewInterfaceListCall
@end

@interface COHomebrewInterfaceListCallUpgradeableFormulae : COHomebrewInterfaceListCall
@end

@interface COHomebrewInterfaceListCallUpgradeableCasks : COHomebrewInterfaceListCallUpgradeableFormulae
@end

@interface COHomebrewInterfaceListCallLeaves : COHomebrewInterfaceListCall
@end

@interface COHomebrewInterfaceListCallRepositories : COHomebrewInterfaceListCall
@end

@interface COHomebrewInterface ()

@end

/* this class used to use
dispatch_queue_create("oaVa-o.Cicerone.COHomebrewInterface.Tasks", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,
                                                                                                           QOS_CLASS_USER_INITIATED,
                                                                                                           -5));
to pass to async tasks, even though this never happened, to run the update blocks on, the output of which were only ever used in the case of list commands
 */

@implementation COHomebrewInterface

+ (instancetype)sharedInterface
{
	@synchronized(self)
	{
		static dispatch_once_t once;
		static COHomebrewInterface *instance;
		dispatch_once(&once, ^{ instance = [[COHomebrewInterface alloc] init]; });
		return instance;
	}
}

- (NSString *)checkForBrew
{
    if (!self.shellPath) return nil;
    
    static NSString *brewPath;
    
    if (!brewPath) {
        brewPath = [self removeNewLineFromString:[self shellCommandStandardOutputWithArguments:@[@"-l", @"-c", @"which brew"] addingMarkerShellCommand:NO]];
        
#ifdef DEBUG
        NSLog(@"brew: %@", brewPath);
#endif
    }
    
    return brewPath;
}

- (void)setDelegate:(id<COHomebrewInterfaceDelegate>)delegate
{
	if (_delegate != delegate) {
		_delegate = delegate;
		
        [self getValidUserShellPath];
		
        NSString *brewPath = [self checkForBrew];
        if (!brewPath || brewPath.length == 0) {
            [self showBrewNotInstalledMessage];
        }
		else
		{
            [self getHomebrewPrefixPath];
		}
	}
}

#pragma mark - Private Methods

- (NSString *)getValidUserShellPath
{
    static NSString *userShell = nil;
    
    if (!userShell) {
        userShell = [[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"];
        
        // avoid executing stuff like /sbin/nologin as a shell
        BOOL isValidShell = NO;
        
        for (NSString *validShell in [[NSString stringWithContentsOfFile:@"/etc/shells" encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]])
        {
            if ([[validShell stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:userShell])
            {
                isValidShell = YES;
                break;
            }
        }
        
        if (!isValidShell)
        {
            static NSAlert *alert = nil;
            
            dispatch_group_t waitForFinish = dispatch_group_create();
            dispatch_group_enter(waitForFinish);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!alert) {
                    alert = [[NSAlert alloc] init];
                    alert.messageText = NSLocalizedString(@"Message_Shell_Invalid_Title", nil);
                    [alert addButtonWithTitle:NSLocalizedString(@"Generic_OK", nil)];
                    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Message_Shell_Invalid_Body", nil), userShell];
                }
                
                [alert runModal];
                
                dispatch_group_leave(waitForFinish);
            });
            
            dispatch_group_wait(waitForFinish, DISPATCH_TIME_FOREVER);
            
            NSLog(@"No valid shell found...");
            return nil;
        }
        
#ifdef DEBUG
        NSLog(@"shell: %@", userShell);
#endif
        
    }

    return userShell;
}

- (NSString *)getHomebrewPrefixPath
{
    static NSString *path = nil;
    
    if (!path) {
        path = [[NSUserDefaults standardUserDefaults] objectForKey:@"COBrewPrefixPath"];
        
        if (!path) {
            NSString *brew_config = [self brewToolStandardOutputWithArguments:@[@"config"]];
            
            [brew_config enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                if ([line hasPrefix:@"HOMEBREW_PREFIX"]) {
                    path = [line substringFromIndex:17];
                }
            }];
            
            [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"COBrewPrefixPath"];
        }

#ifdef DEBUG
        NSLog(@"cellar: %@", self.homebrewPrefixPath);
#endif
    }
	
	return path;
}

- (NSArray *)makeShellArgumentsFromBrewToolArguments:(NSArray *)extraArguments addingMarkerShellCommand:(BOOL)sendOutputID
{
	NSString *command = nil;
	
    if (sendOutputID) {
		command = [NSString stringWithFormat:@"echo \"%@\";%@ %@", shellHeaderEndMarker, self.brewPath, [extraArguments componentsJoinedByString:@" "]];
	} else {
		command = [NSString stringWithFormat:@"%@ %@", self.brewPath, [extraArguments componentsJoinedByString:@" "]];
	}
    
	return @[@"-l", @"-c", command];
}

- (void)showBrewNotInstalledMessage
{
	static BOOL isShowing = NO;
    
	if (!isShowing) {
		isShowing = YES;
        
		if (self.delegate) {
			id delegate = self.delegate;
			dispatch_async(dispatch_get_main_queue(), ^{
				[delegate homebrewInterfaceDidNotFindBrew:YES];
			});
		}
	}
}

- (NSString *)shellCommandStandardOutputWithArguments:(NSArray *)arguments addingMarkerShellCommand:(BOOL)useMarker
{
    assert(self.shellPath);
    assert(arguments);
    
    NSString *standardOutput;
    [[[COTask alloc] initWithPath:self.shellPath withArguments:arguments] runToExitReturningStandardOutput:&standardOutput returningStandardError:nil];
    return useMarker ? [self substringAfterMarker:standardOutput] : standardOutput;
}

- (NSString *)brewToolStandardOutputWithArguments:(NSArray *)arguments addingMarkerShellCommand:(BOOL)useMarker
{
    assert(arguments);
    
    arguments = [self makeShellArgumentsFromBrewToolArguments:arguments addingMarkerShellCommand:useMarker];
    
    return [self shellCommandStandardOutputWithArguments:arguments addingMarkerShellCommand:useMarker];
}

- (NSString *)brewToolStandardOutputWithArguments:(NSArray *)arguments
{
    return [self brewToolStandardOutputWithArguments:arguments addingMarkerShellCommand:NO];
}

#pragma mark - Operations that return on finish

- (NSArray<COFormula *> *)packagesWithMode:(COListMode)mode
{
	COHomebrewInterfaceListCall *listCall = nil;

	switch (mode) {
		case kCOListModeInstalledFormulae:
			listCall = [[COHomebrewInterfaceListCallInstalledFormulae alloc] init];
			break;
			
		case kCOListModeInstalledCasks:
			listCall = [[COHomebrewInterfaceListCallInstalledCasks alloc] init];
			break;
			
		case kCOListModeAllFormulae:
			listCall = [[COHomebrewInterfaceListCallAllFormulae alloc] init];
			break;
			
		case kCOListModeAllCasks:
			listCall = [[COHomebrewInterfaceListCallAllCasks alloc] init];
			break;

		case kCOListModeOutdatedFormulae:
			listCall = [[COHomebrewInterfaceListCallUpgradeableFormulae alloc] init];
			break;
			
		case kCOListModeOutdatedCasks:
			listCall = [[COHomebrewInterfaceListCallUpgradeableCasks alloc] init];
			break;
			
		case kCOListModeLeaves:
			listCall = [[COHomebrewInterfaceListCallLeaves alloc] init];
			break;

		case kCOListModeRepositories:
			listCall = [[COHomebrewInterfaceListCallRepositories alloc] init];
			break;

		default:
			return nil;
	}

	NSString *string = [self brewToolStandardOutputWithArguments:listCall.arguments];

	if (string)
	{
		return [listCall parseData:string];
	}
	else
	{
		return nil;
	}
}

- (NSString *)informationWithFormulaName:(NSString *)name cask:(BOOL)isCask;
{
    return [self brewToolStandardOutputWithArguments:@[@"info", name, isCask ? @"--cask" : @"--formula"]];
}

- (NSString *)dependentsWithFormulaName:(NSString *)name installed:(BOOL)installedOnly
{
	return [self brewToolStandardOutputWithArguments:@[@"uses", name, installedOnly ? @"--installed" : @"--eval-all"]];
}

- (NSString *)substringAfterMarker:(NSString *)string {
	if (string) {
		NSRange range = [string rangeOfString:shellHeaderEndMarker];
        
		if (range.location != NSNotFound) {
			return [string substringFromIndex:range.location + range.length + 1];
		} else {
			return string;
		}
	}
    
	return nil;
}

- (NSString *)removeNewLineFromString:(NSString*)string {
	if (string) {
		return [string stringByReplacingOccurrencesOfString:@"\n" withString:@""];
	}
    
	return nil;
}

- (NSString *)update
{
    @try {
        return [self brewToolStandardOutputWithArguments:@[@"update"]];
    } @finally {
        [self sendDependedHomebrewPrefixStateChangedDelegateCall];
    }
}

- (NSString *)upgradeWithFormulaeNames:(NSArray *)formulae
{
    @try {
        return [self brewToolStandardOutputWithArguments:[@[@"upgrade"] arrayByAddingObjectsFromArray:formulae]];
    } @finally {
        [self sendDependedHomebrewPrefixStateChangedDelegateCall];
    }
}

- (NSString *)installWithFormulaName:(NSString *)formula withOptions:(NSArray *)options
{
    NSArray *arguments = @[@"install", formula];
    
	if (options) {
		arguments = [arguments arrayByAddingObjectsFromArray:options];
	}
    
    @try {
        return [self brewToolStandardOutputWithArguments:arguments];
    } @finally {
        [self sendDependedHomebrewPrefixStateChangedDelegateCall];
    }
}

- (NSString *)uninstallWithFormulaName:(NSString*)formula
{
    @try {
        return [self brewToolStandardOutputWithArguments:@[@"uninstall", formula]];
    } @finally {
        [self sendDependedHomebrewPrefixStateChangedDelegateCall];
    }
}

- (NSString *)tapWithRepositoryName:(NSString *)repository
{
    @try {
        return [self brewToolStandardOutputWithArguments:@[@"tap", repository]];
    } @finally {
        [self sendDependedHomebrewPrefixStateChangedDelegateCall];
    }
}

- (NSString *)untapWithRepositoryName:(NSString *)repository
{
    @try {
        return [self brewToolStandardOutputWithArguments:@[@"untap", repository]];
    } @finally {
        [self sendDependedHomebrewPrefixStateChangedDelegateCall];
    }
}

// todo: stream output for realtime output tasks like cleanup doctor import and export

- (NSString *)cleanup
{
    return [self brewToolStandardOutputWithArguments:@[@"cleanup"]];
}

- (NSString *)doctor
{
    @try {
        return [self brewToolStandardOutputWithArguments:@[@"doctor"]];
    } @finally {
        [self sendDependedHomebrewPrefixStateChangedDelegateCall];
    }
}

// supposedly this command sends errors over standard output and no output on success? highly dubious.
// this method used to return an error on output with fatal: or Error:
// [NSError errorWithDomain:@"Cicerone"
//                     code:2701
//                 userInfo:@{NSLocalizedDescriptionKey: errorLine}];

- (NSString *)exportWithPath:(NSString *)path
{
	NSString *output = [self brewToolStandardOutputWithArguments:@[@"bundle",
																   @"dump",
																   @"--force",
																   [NSString stringWithFormat:@"--file=%@", path]]];
	
	[self sendDependedHomebrewPrefixStateChangedDelegateCall];
	
	if ([output length] == 0)
	{
		return output;
	}
	else
	{
		__block NSString *errorLine = nil;
		
		[output enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
			if ([line hasPrefix:@"Error:"] || [line hasPrefix:@"fatal:"])
			{
                errorLine = line;
				*stop = YES;
			}
		}];
		
		return errorLine;
	}
}

- (NSString *)importWithPath:(NSString *)path
{
    @try {
        return [self brewToolStandardOutputWithArguments:@[@"bundle", [NSString stringWithFormat:@"--file=%@", path]]];
    } @finally {
        [self sendDependedHomebrewPrefixStateChangedDelegateCall];
    }
}

- (void)sendDependedHomebrewPrefixStateChangedDelegateCall
{
	if (self.delegate) {
		id delegate = self.delegate;
		dispatch_async(dispatch_get_main_queue(), ^{
			[delegate homebrewInterfaceChangedDependedHomebrewPrefixState];
		});
	}
}

@end

#pragma mark - Homebrew Interface List Calls

@implementation COHomebrewInterfaceListCall

- (instancetype)initWithArguments:(NSArray *)arguments casks:(BOOL)casks
{
	self = [super init];
	if (self) {
		_arguments = arguments;
        _casks = casks;
	}
	return self;
}

- (NSArray<COFormula *> *)parseData:(NSString *)data
{
	NSMutableArray<NSString *> *dataLines = [[data componentsSeparatedByString:@"\n"] mutableCopy];
	[dataLines removeLastObject];
	
	NSMutableArray<COFormula *> *formulae = [NSMutableArray arrayWithCapacity:dataLines.count];
	
	for (NSString *item in dataLines) {
		COFormula *formula = [self parseFormulaItem:item];
		if (formula) {
			[formulae addObject:formula];
		}
	}
	return formulae;
}

- (COFormula *)parseFormulaItem:(NSString *)item
{
	return [COFormula formulaWithName:item cask:self.casks];
}

@end

@implementation COHomebrewInterfaceListCallInstalledFormulae

- (instancetype)init
{
	return (COHomebrewInterfaceListCallInstalledFormulae *)[super initWithArguments:@[@"list", @"--versions", @"--formulae"] casks:NO];
}

- (COFormula *)parseFormulaItem:(NSString *)item
{
	NSArray *aux = [item componentsSeparatedByString:@" "];
	return [COFormula formulaWithName:[aux firstObject] withVersion:[aux lastObject] cask:self.casks];
}

@end

@implementation COHomebrewInterfaceListCallInstalledCasks

- (instancetype)init
{
	return (COHomebrewInterfaceListCallInstalledCasks *)[super initWithArguments:@[@"list", @"--versions", @"--casks"] casks:YES];
}

@end

@implementation COHomebrewInterfaceListCallAllFormulae

- (instancetype)init
{
	return (COHomebrewInterfaceListCallAllFormulae *)[super initWithArguments:@[@"formulae"] casks:NO];
}

@end

@implementation COHomebrewInterfaceListCallAllCasks

- (instancetype)init
{
	return (COHomebrewInterfaceListCallAllCasks *)[super initWithArguments:@[@"casks"] casks:YES];
}

@end

@implementation COHomebrewInterfaceListCallUpgradeableFormulae

- (instancetype)init
{
	return (COHomebrewInterfaceListCallUpgradeableFormulae *)[super initWithArguments:@[@"outdated", @"--verbose", @"--formulae"] casks:NO];
}

- (COFormula *)parseFormulaItem:(NSString *)item
{
	static NSString *regexString = @"(\\S+)\\s\\(((.*, )*(.*))\\) (<|!=) (\\S+)";
	
	COFormula __block *formula = nil;
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
	
	[regex enumerateMatchesInString:item options:0 range:NSMakeRange(0, [item length]) usingBlock:
	 ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
	 {
		if (result.resultType == NSTextCheckingTypeRegularExpression && [result numberOfRanges] >= 4)
		{
			NSString *formulaName = [item substringWithRange:[result rangeAtIndex:1]];
			NSString *installedVersion = [item substringWithRange:[result rangeAtIndex:[result numberOfRanges] - 3]];
			NSString *latestVersion = [item substringWithRange:[result rangeAtIndex:[result numberOfRanges] - 1]];

			formula = [COFormula formulaWithName:formulaName
                                     withVersion:installedVersion
                               withLatestVersion:latestVersion
                                            cask:self.casks];
		}
	}];
	
	if (!formula) {
		formula = [COFormula formulaWithName:item cask:self.casks];
	}
	
	return formula;
}

@end


@implementation COHomebrewInterfaceListCallUpgradeableCasks

- (instancetype)init
{
	return (COHomebrewInterfaceListCallUpgradeableCasks *)[super initWithArguments:@[@"outdated", @"--verbose", @"--casks"] casks:YES];
}

@end


@implementation COHomebrewInterfaceListCallLeaves

- (instancetype)init
{
	return (COHomebrewInterfaceListCallLeaves *)[super initWithArguments:@[@"leaves"] casks:NO];
}

@end


@implementation COHomebrewInterfaceListCallRepositories

- (instancetype)init
{
	return (COHomebrewInterfaceListCallRepositories *)[super initWithArguments:@[@"tap"] casks:NO];
}

@end

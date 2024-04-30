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

#import "CiHomebrewInterface.h"
#import "CiTask.h"

static NSString * const shellHeaderEndMarker = @"+++++ Cicerone +++++";

@interface CiHomebrewInterfaceListCall : NSObject

@property (strong, readonly) NSArray *arguments;

- (instancetype)initWithArguments:(NSArray *)arguments;
- (NSArray *)parseData:(NSString *)data;
- (CiFormula *)parseFormulaItem:(NSString *)item;

@end

@interface CiHomebrewInterfaceListCallInstalledFormulae : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallInstalledCasks : CiHomebrewInterfaceListCallInstalledFormulae
@end

@interface CiHomebrewInterfaceListCallAllFormulae : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallAllCasks : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallUpgradeableFormulae : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallUpgradeableCasks : CiHomebrewInterfaceListCallUpgradeableFormulae
@end

@interface CiHomebrewInterfaceListCallLeaves : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallRepositories : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterface ()
{
    NSString *brewPath;
}

@property (strong) NSString *homebrewCellarPath;
@property (strong) NSString *shellPath;

@end

/* this class used to use
dispatch_queue_create("oaVa-o.Cicerone.CiHomebrewInterface.Tasks", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,
                                                                                                           QOS_CLASS_USER_INITIATED,
                                                                                                           -5));
to pass to async tasks, even though this never happened, to run the update blocks on, the output of which were only ever used in the case of list commands
 */

@implementation CiHomebrewInterface

+ (instancetype)sharedInterface
{
	@synchronized(self)
	{
		static dispatch_once_t once;
		static CiHomebrewInterface *instance;
		dispatch_once(&once, ^{ instance = [[CiHomebrewInterface alloc] init]; });
		return instance;
	}
}

- (BOOL)checkForBrew
{
	if (!self.shellPath) return NO;
	
    brewPath = [self removeNewLineFromString:[self shellCommandStandardOutputWithArguments:@[@"-l", @"-c", @"which brew"] addingMarkerShellCommand:NO]];
    
#ifdef DEBUG
    NSLog(@"brew: %@", brewPath);
#endif
    
	return brewPath.length != 0;
}

- (void)setDelegate:(id<CiHomebrewInterfaceDelegate>)delegate
{
	if (_delegate != delegate) {
		_delegate = delegate;
		
        self.shellPath = [self getValidUserShellPath];
		
		if (![self checkForBrew])
			[self showBrewNotInstalledMessage];
		else
		{
            self.homebrewCellarPath = [self getUserCellarPath];
#ifdef DEBUG
			NSLog(@"cellar: %@", self.homebrewCellarPath);
#endif
		}
	}
}

#pragma mark - Private Methods

- (NSString *)getValidUserShellPath
{
	NSString *userShell = [[[NSProcessInfo processInfo] environment] objectForKey:@"SHELL"];
	
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
			  [alert setMessageText:NSLocalizedString(@"Message_Shell_Invalid_Title", nil)];
			  [alert addButtonWithTitle:NSLocalizedString(@"Generic_OK", nil)];
			  [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Message_Shell_Invalid_Body", nil), userShell]];
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

    return userShell;
}

- (NSString *)getUserCellarPath
{
	NSString __block *path = [[NSUserDefaults standardUserDefaults] objectForKey:@"CiBrewCellarPath"];
	
	if (!path) {
		NSString *brew_config = [self brewToolStandardOutputWithArguments:@[@"config"]];
		
		[brew_config enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
			if ([line hasPrefix:@"HOMEBREW_CELLAR"]) {
				path = [line substringFromIndex:17];
			}
		}];
		
		[[NSUserDefaults standardUserDefaults] setObject:path forKey:@"CiBrewCellarPath"];
	}
	
	return path;
}

- (NSArray *)makeShellArgumentsFromBrewToolArguments:(NSArray *)extraArguments addingMarkerShellCommand:(BOOL)sendOutputID
{
	NSString *command = nil;
	if (sendOutputID) {
		command = [NSString stringWithFormat:@"echo \"%@\";%@ %@", shellHeaderEndMarker, brewPath, [extraArguments componentsJoinedByString:@" "]];
	} else {
		command = [NSString stringWithFormat:@"%@ %@", brewPath, [extraArguments componentsJoinedByString:@" "]];
	}
	NSArray *arguments = @[@"-l", @"-c", command];
	return arguments;
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
    [[[CiTask alloc] initWithPath:self.shellPath withArguments:arguments] runToExitReturningStandardOutput:&standardOutput returningStandardError:nil];
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

- (NSArray<CiFormula *> *)packagesWithMode:(CiListMode)mode
{
	CiHomebrewInterfaceListCall *listCall = nil;

	switch (mode) {
		case kCiListModeInstalledFormulae:
			listCall = [[CiHomebrewInterfaceListCallInstalledFormulae alloc] init];
			break;
			
		case kCiListModeInstalledCasks:
			listCall = [[CiHomebrewInterfaceListCallInstalledCasks alloc] init];
			break;
			
		case kCiListModeAllFormulae:
			listCall = [[CiHomebrewInterfaceListCallAllFormulae alloc] init];
			break;
			
		case kCiListModeAllCasks:
			listCall = [[CiHomebrewInterfaceListCallAllCasks alloc] init];
			break;

		case kCiListModeOutdatedFormulae:
			listCall = [[CiHomebrewInterfaceListCallUpgradeableFormulae alloc] init];
			break;
			
		case kCiListModeOutdatedCasks:
			listCall = [[CiHomebrewInterfaceListCallUpgradeableCasks alloc] init];
			break;
			
		case kCiListModeLeaves:
			listCall = [[CiHomebrewInterfaceListCallLeaves alloc] init];
			break;

		case kCiListModeRepositories:
			listCall = [[CiHomebrewInterfaceListCallRepositories alloc] init];
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

- (NSString *)informationWithFormulaName:(NSString *)name;
{
	return [self brewToolStandardOutputWithArguments:@[@"info", name]];
}

- (NSString *)dependentsWithFormulaName:(NSString *)name installed:(BOOL)onlyInstalled
{
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"uses"];

	if (onlyInstalled)
	{
		[arguments addObject:@"--installed"];
	}

	[arguments addObject:name];

	return [self brewToolStandardOutputWithArguments:arguments];
}

- (NSString*)substringAfterMarker:(NSString*)string {
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

- (NSString*)removeNewLineFromString:(NSString*)string {
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
        [self sendDelegateFormulaeUpdatedCall];
    }
}

- (NSString *)upgradeWithFormulaeNamed:(NSArray*)formulae withReturnBlock:(void (^)(NSString*output))block
{
    @try {
        return [self brewToolStandardOutputWithArguments:[@[@"upgrade"] arrayByAddingObjectsFromArray:formulae]];
    } @finally {
        [self sendDelegateFormulaeUpdatedCall];
    }
}

- (NSString *)installWithFormulaNamed:(NSString*)formula withOptions:(NSArray*)options andReturnBlock:(void (^)(NSString*output))block
{
    NSArray *arguments = @[@"install", formula];
    
	if (options) {
		arguments = [arguments arrayByAddingObjectsFromArray:options];
	}
    
    @try {
        return [self brewToolStandardOutputWithArguments:arguments];
    } @finally {
        [self sendDelegateFormulaeUpdatedCall];
    }
}

- (NSString *)uninstallWithFormulaNamed:(NSString*)formula withReturnBlock:(void (^)(NSString*output))block
{
    @try {
        return [self brewToolStandardOutputWithArguments:@[@"uninstall", formula]];
    } @finally {
        [self sendDelegateFormulaeUpdatedCall];
    }
}

- (NSString *)tapWithRepositoryNamed:(NSString *)repository withReturnsBlock:(void (^)(NSString *))block
{
    @try {
        return [self brewToolStandardOutputWithArguments:@[@"tap", repository]];
    } @finally {
        [self sendDelegateFormulaeUpdatedCall];
    }
}

- (NSString *)untapWithRepositoryNamed:(NSString *)repository withReturnsBlock:(void (^)(NSString *))block
{
    @try {
        return [self brewToolStandardOutputWithArguments:@[@"untap", repository]];
    } @finally {
        [self sendDelegateFormulaeUpdatedCall];
    }
}

- (NSString *)cleanup:(void (^)(NSString*output))block
{
	return [self brewToolStandardOutputWithArguments:@[@"cleanup"]];
}

- (NSString *)doctor:(void (^)(NSString*output))block
{
    @try {
        return [self brewToolStandardOutputWithArguments:@[@"doctor"]];
    } @finally {
        [self sendDelegateFormulaeUpdatedCall];
    }
}

// supposedly this command sends errors over standard output and no output on success? highly dubious.
// this method used to return an error on output with fatal: or Error:
// [NSError errorWithDomain:@"Cicerone"
//                     code:2701
//                 userInfo:@{NSLocalizedDescriptionKey: errorLine}];

- (NSString *)exportWithPath:(NSString*)path
{
	NSString *output = [self brewToolStandardOutputWithArguments:@[@"bundle",
																   @"dump",
																   @"--force",
																   [NSString stringWithFormat:@"--file=%@", path]]];
	
	[self sendDelegateFormulaeUpdatedCall];
	
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
        [self sendDelegateFormulaeUpdatedCall];
    }
}

- (void)sendDelegateFormulaeUpdatedCall
{
	if (self.delegate) {
		id delegate = self.delegate;
		dispatch_async(dispatch_get_main_queue(), ^{
			[delegate homebrewInterfaceDidUpdateFormulae];
		});
	}
}

@end

#pragma mark - Homebrew Interface List Calls

@implementation CiHomebrewInterfaceListCall

- (instancetype)initWithArguments:(NSArray *)arguments
{
	self = [super init];
	if (self) {
		_arguments = arguments;
	}
	return self;
}

- (NSArray<CiFormula *> *)parseData:(NSString *)data
{
	NSMutableArray<NSString *> *dataLines = [[data componentsSeparatedByString:@"\n"] mutableCopy];
	[dataLines removeLastObject];
	
	NSMutableArray<CiFormula *> *formulae = [NSMutableArray arrayWithCapacity:dataLines.count];
	
	for (NSString *item in dataLines) {
		CiFormula *formula = [self parseFormulaItem:item];
		if (formula) {
			[formulae addObject:formula];
		}
	}
	return formulae;
}

- (CiFormula *)parseFormulaItem:(NSString *)item
{
	return [CiFormula formulaWithName:item];
}

@end

@implementation CiHomebrewInterfaceListCallInstalledFormulae

- (instancetype)init
{
	return (CiHomebrewInterfaceListCallInstalledFormulae *)[super initWithArguments:@[@"list", @"--versions", @"--formulae"]];
}

- (CiFormula *)parseFormulaItem:(NSString *)item
{
	NSArray *aux = [item componentsSeparatedByString:@" "];
	return [CiFormula formulaWithName:[aux firstObject] withVersion:[aux lastObject]];
}

@end

@implementation CiHomebrewInterfaceListCallInstalledCasks

- (instancetype)init
{
	return (CiHomebrewInterfaceListCallInstalledCasks *)[super initWithArguments:@[@"list", @"--versions", @"--casks"]];
}

@end

@implementation CiHomebrewInterfaceListCallAllFormulae

- (instancetype)init
{
	return (CiHomebrewInterfaceListCallAllFormulae *)[super initWithArguments:@[@"formulae"]];
}

@end

@implementation CiHomebrewInterfaceListCallAllCasks

- (instancetype)init
{
	return (CiHomebrewInterfaceListCallAllCasks *)[super initWithArguments:@[@"casks"]];
}

@end

@implementation CiHomebrewInterfaceListCallUpgradeableFormulae

- (instancetype)init
{
	return (CiHomebrewInterfaceListCallUpgradeableFormulae *)[super initWithArguments:@[@"outdated", @"--verbose", @"--formulae"]];
}

- (CiFormula *)parseFormulaItem:(NSString *)item
{
	static NSString *regexString = @"(\\S+)\\s\\(((.*, )*(.*))\\) < (\\S+)";
	
	CiFormula __block *formula = nil;
	NSError *error = nil;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
	
	[regex enumerateMatchesInString:item options:0 range:NSMakeRange(0, [item length]) usingBlock:
	 ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
	 {
		if (result.resultType == NSTextCheckingTypeRegularExpression && [result numberOfRanges] >= 4)
		{
			NSString *formulaName = [item substringWithRange:[result rangeAtIndex:1]];
			NSString *installedVersion = [item substringWithRange:[result rangeAtIndex:[result numberOfRanges] - 2]];
			NSString *latestVersion = [item substringWithRange:[result rangeAtIndex:[result numberOfRanges] - 1]];

			formula = [CiFormula formulaWithName:formulaName
										 withVersion:installedVersion
								withLatestVersion:latestVersion];
		}
	}];
	
	if (!formula) {
		formula = [CiFormula formulaWithName:item];
	}
	
	return formula;
}

@end


@implementation CiHomebrewInterfaceListCallUpgradeableCasks

- (instancetype)init
{
	return (CiHomebrewInterfaceListCallUpgradeableCasks *)[super initWithArguments:@[@"outdated", @"--verbose", @"--casks"]];
}

@end


@implementation CiHomebrewInterfaceListCallLeaves

- (instancetype)init
{
	return (CiHomebrewInterfaceListCallLeaves *)[super initWithArguments:@[@"leaves"]];
}

@end


@implementation CiHomebrewInterfaceListCallRepositories

- (instancetype)init
{
	return (CiHomebrewInterfaceListCallRepositories *)[super initWithArguments:@[@"tap"]];
}

@end

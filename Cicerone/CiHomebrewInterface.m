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

NSString *brewPath = @"";

#define kDEBUG_WARNING @"\
User Shell: %@\n\
Command: %@\n\
macOS Version: %@\n\n\
The outputs are going to be different if run from Xcode!!\n\
Installing and upgrading formulas is not advised in DEBUG mode!\n\n"

static NSString *CiceroneOutputIdentifier = @"+++++Cicerone+++++";

@interface CiHomebrewInterfaceListCall : NSObject

@property (strong, readonly) NSArray *arguments;

- (instancetype)initWithArguments:(NSArray *)arguments;
- (NSArray *)parseData:(NSString *)data;
- (CiFormula *)parseFormulaItem:(NSString *)item;

@end

@interface CiHomebrewInterfaceListCallInstalledFormulae : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallInstalledCasks : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallAllFormulae : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallAllCasks : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallUpgradeableFormulae : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallUpgradeableCasks : CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterfaceListCallLeaves : CiHomebrewInterfaceListCall
@end


@interface CiHomebrewInterfaceListCallRepositories: CiHomebrewInterfaceListCall
@end

@interface CiHomebrewInterface () <CiTaskCompleted>

@property (strong) NSString *path_cellar;
@property (strong) NSString *path_shell;
@property (strong) NSMutableDictionary *tasks;
@property (strong) dispatch_queue_t taskOperationsQueue;

@end

@implementation CiHomebrewInterface

+ (instancetype)sharedInterface
{
	@synchronized(self)
	{
		static dispatch_once_t once;
		static CiHomebrewInterface *instance;
		dispatch_once(&once, ^ { instance = [[CiHomebrewInterface alloc] initUniqueInstance]; });
		return instance;
	}
}

- (instancetype)initUniqueInstance
{
	self = [super init];
	if (self) {
		_tasks = [[NSMutableDictionary alloc] init];

		dispatch_queue_attr_t attributes;

		if (@available(macOS 10.10, *)) {
			attributes = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT,
																 QOS_CLASS_USER_INITIATED,
																 -5);
		} else {
			attributes = DISPATCH_QUEUE_CONCURRENT;
		}

		_taskOperationsQueue = dispatch_queue_create("com.brunophilipe.Cicerone.CiHomebrewInterface.Tasks", attributes);
	}
	return self;
}

- (void)cleanup
{
	[self.tasks enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(NSString *key, CiTask *task, BOOL *stop){
		[task cleanup];
	}];
}

- (BOOL)checkForHomebrew
{
	if (!self.path_shell) return NO;
	
	CiTask *task = [[CiTask alloc] initWithPath:self.path_shell arguments:@[@"-l", @"-c", @"which brew"]];
	task.delegate = self;
	[task execute];
	
	NSString *output = [task output];
	output = [self removeLoginShellOutputFromString:output];
	output = [self removeNewLineFromString:output];
	brewPath = output;
//	#ifdef DEBUG
//		NSLog(@"brew: %@", output);
//	#endif
	return output.length != 0;
}

- (void)setDelegate:(id<CiHomebrewInterfaceDelegate>)delegate
{
	if (_delegate != delegate) {
		_delegate = delegate;
		
		[self setPath_shell:[self getValidUserShellPath]];
		
		if (![self checkForHomebrew])
			[self showHomebrewNotInstalledMessage];
		else
		{
			[self setPath_cellar:[self getUserCellarPath]];
//			NSLog(@"cellar: %@", self.path_cellar);
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
//	#ifdef DEBUG
//		NSLog(@"shell: %@", userShell);
//	#endif
	return userShell;
}

- (NSString *)getUserCellarPath
{
	NSString __block *path = [[NSUserDefaults standardUserDefaults] objectForKey:@"CiBrewCellarPath"];
	
	if (!path) {
		NSString *brew_config = [self performSyncBrewCommandWithArguments:@[@"config"]];
		
		[brew_config enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
			if ([line hasPrefix:@"HOMEBREW_CELLAR"]) {
				path = [line substringFromIndex:17];
			}
		}];
		
		[[NSUserDefaults standardUserDefaults] setObject:path forKey:@"CiBrewCellarPath"];
	}
	
	return path;
}

- (NSArray *)formatArguments:(NSArray *)extraArguments sendOutputId:(BOOL)sendOutputID
{
	NSString *command = nil;
	if (sendOutputID) {
		command = [NSString stringWithFormat:@"echo \"%@\";%@ %@", CiceroneOutputIdentifier, brewPath, [extraArguments componentsJoinedByString:@" "]];
	} else {
		command = [NSString stringWithFormat:@"%@ %@", brewPath, [extraArguments componentsJoinedByString:@" "]];
	}
	NSArray *arguments = @[@"-l", @"-c", command];
	return arguments;
}

- (void)showHomebrewNotInstalledMessage
{
	static BOOL isShowing = NO;
	if (!isShowing) {
		isShowing = YES;
		if (self.delegate) {
			id delegate = self.delegate;
			dispatch_async(dispatch_get_main_queue(), ^{
				[delegate homebrewInterfaceShouldDisplayNoBrewMessage:YES];
			});
		}
	}
}

- (void)task:(CiTask *)task didFinishWithOutput:(NSString *)output error:(NSString *)error
{
	[self.tasks removeObjectForKey:[NSString stringWithFormat:@"%p",task]];
}

- (BOOL)performBrewCommandWithArguments:(NSArray*)arguments dataReturnBlock:(void (^)(NSString*))block
{
	return [self performSyncBrewCommandWithArguments:arguments dataReturnBlock:block wrapRequest:false];
	//return [self performAsyncBrewCommandWithArguments:arguments wrapsSynchronousRequest:NO queue:nil dataReturnBlock:block];
}

- (BOOL)performAsyncBrewCommandWithArguments:(NSArray*)arguments
					 wrapsSynchronousRequest:(BOOL)isSynchronous
									   queue:(dispatch_queue_t)queue
							 dataReturnBlock:(void (^)(NSString*))block
{
	arguments = [self formatArguments:arguments sendOutputId:isSynchronous];
	
	if (!self.path_shell || !arguments)
	{
		return NO;
	}
	
	CiTask *task = [[CiTask alloc] initWithPath:self.path_shell arguments:arguments];
	task.delegate = self;
	task.updateBlock = block;
	task.updateBlockQueue = queue;

	[self.tasks setObject:task forKey:[NSString stringWithFormat:@"%p", task]];


#ifdef DEBUG
	if (!isSynchronous)
	{
		block([NSString stringWithFormat:kDEBUG_WARNING,
			   self.path_shell,
			   [arguments componentsJoinedByString:@" "],
			   [[NSProcessInfo processInfo] operatingSystemVersionString]]);
	}
#endif
	
	int status = [task execute];
	
	NSString *taskDoneString = [NSString stringWithFormat:@"%@: (%d) %@ %@!",
								NSLocalizedString(@"Homebrew_Task_Finished", nil),
								status,
								NSLocalizedString(@"Homebrew_Task_Finished_At", nil),
								[NSDateFormatter localizedStringFromDate:[NSDate date]
															   dateStyle:NSDateFormatterShortStyle
															   timeStyle:NSDateFormatterShortStyle]];
	
	block(taskDoneString);
	
	return status == 0;
}

- (BOOL)performSyncBrewCommandWithArguments:(NSArray*)arguments
							 dataReturnBlock:(void (^)(NSString*))block
								wrapRequest:(BOOL)wrap
{
	arguments = [self formatArguments:arguments sendOutputId:wrap];
	CiTask *task = [[CiTask alloc] initWithPath:self.path_shell arguments:arguments];
	int status =  [task execute];
	NSString *output = [task output];
	if (wrap) {
		output = [self removeLoginShellOutputFromString:output];
	}
	block(output);
	return status == 0;
}

- (BOOL)isRunningBackgroundTask
{
	return [[self.tasks allKeys] count] > 0;
}


- (NSString*)performSyncBrewCommandWithArguments:(NSArray*)arguments
{
	NSString __block *outputValue;
	void (^displayTerminalOutput)(NSString *outputValue) = ^(NSString *output) {
		if (outputValue) {
			outputValue = [outputValue stringByAppendingString:output];
		} else {
			outputValue = output;
		}
	};
	[self performBrewCommandWithArguments:arguments dataReturnBlock:displayTerminalOutput];
	return [self removeLoginShellOutputFromString:outputValue];
}

#pragma mark - Operations that return on finish

- (NSArray<CiFormula *> *)listMode:(CiListMode)mode
{
	CiHomebrewInterfaceListCall *listCall = nil;

	switch (mode) {
		case kCiListInstalledFormulae:
			listCall = [[CiHomebrewInterfaceListCallInstalledFormulae alloc] init];
			break;
			
		case kCiListInstalledCasks:
			listCall = [[CiHomebrewInterfaceListCallInstalledCasks alloc] init];
			break;
			
		case kCiListAllFormulae:
			listCall = [[CiHomebrewInterfaceListCallAllFormulae alloc] init];
			break;
			
		case kCiListAllCasks:
			listCall = [[CiHomebrewInterfaceListCallAllCasks alloc] init];
			break;

		case kCiListOutdatedFormulae:
			listCall = [[CiHomebrewInterfaceListCallUpgradeableFormulae alloc] init];
			break;
			
		case kCiListOutdatedCasks:
			listCall = [[CiHomebrewInterfaceListCallUpgradeableCasks alloc] init];
			break;
			
		case kCiListLeaves:
			listCall = [[CiHomebrewInterfaceListCallLeaves alloc] init];
			break;

		case kCiListRepositories:
			listCall = [[CiHomebrewInterfaceListCallRepositories alloc] init];
			break;

		default:
			return nil;
	}

	NSString *string = [self performSyncBrewCommandWithArguments:listCall.arguments];

	if (string)
	{
		return [listCall parseData:string];
	}
	else
	{
		return nil;
	}
}

- (NSString *)informationForFormulaName:(NSString *)name;
{
	return [self performSyncBrewCommandWithArguments:@[@"info", name]];
}

- (NSString *)dependantsForFormulaName:(NSString *)name onlyInstalled:(BOOL)onlyInstalled
{
	NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"uses"];

	if (onlyInstalled)
	{
		[arguments addObject:@"--installed"];
	}

	[arguments addObject:name];

	return [self performSyncBrewCommandWithArguments:arguments];
}

- (NSString*)removeLoginShellOutputFromString:(NSString*)string {
	if (string) {
		NSRange range = [string rangeOfString:CiceroneOutputIdentifier];
		if (range.location != NSNotFound) {
			return [string substringFromIndex:range.location + range.length+1];
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

#pragma mark - Operations with live data callback block

- (BOOL)updateWithReturnBlock:(void (^)(NSString*output))block
{
	BOOL val = [self performBrewCommandWithArguments:@[@"update"] dataReturnBlock:block];
	[self sendDelegateFormulaeUpdatedCall];
	return val;
}

- (BOOL)upgradeFormulae:(NSArray*)formulae withReturnBlock:(void (^)(NSString*output))block
{
	BOOL val = [self performBrewCommandWithArguments:[@[@"upgrade"] arrayByAddingObjectsFromArray:formulae] dataReturnBlock:block];
	[self sendDelegateFormulaeUpdatedCall];
	return val;
}

- (BOOL)installFormula:(NSString*)formula withOptions:(NSArray*)options andReturnBlock:(void (^)(NSString*output))block
{
	NSArray *params = @[@"install", formula];
	if (options) {
		params = [params arrayByAddingObjectsFromArray:options];
	}
	BOOL val = [self performBrewCommandWithArguments:params dataReturnBlock:block];
	[self sendDelegateFormulaeUpdatedCall];
	return val;
}

- (BOOL)uninstallFormula:(NSString*)formula withReturnBlock:(void (^)(NSString*output))block
{
	BOOL val = [self performBrewCommandWithArguments:@[@"uninstall", formula] dataReturnBlock:block];
	[self sendDelegateFormulaeUpdatedCall];
	return val;
}

- (BOOL)tapRepository:(NSString *)repository withReturnsBlock:(void (^)(NSString *))block
{
	BOOL val = [self performBrewCommandWithArguments:@[@"tap", repository] dataReturnBlock:block];
	[self sendDelegateFormulaeUpdatedCall];
	return val;
}

- (BOOL)untapRepository:(NSString *)repository withReturnsBlock:(void (^)(NSString *))block
{
	BOOL val = [self performBrewCommandWithArguments:@[@"untap", repository] dataReturnBlock:block];
	[self sendDelegateFormulaeUpdatedCall];
	return val;
}

- (BOOL)runCleanupWithReturnBlock:(void (^)(NSString*output))block
{
	return [self performBrewCommandWithArguments:@[@"cleanup"] dataReturnBlock:block];;
}

- (BOOL)runDoctorWithReturnBlock:(void (^)(NSString*output))block
{
	BOOL val = [self performBrewCommandWithArguments:@[@"doctor"] dataReturnBlock:block];
	[self sendDelegateFormulaeUpdatedCall];
	return val;
}

- (NSError*)runBrewExportToolWithPath:(NSString*)path
{
	NSString *output = [self performSyncBrewCommandWithArguments:@[@"bundle",
																   @"dump",
																   @"--force",
																   [NSString stringWithFormat:@"--file=%@", path]]];
	
	[self sendDelegateFormulaeUpdatedCall];
	
	if ([output length] == 0)
	{
		return nil;
	}
	else
	{
		__block NSError *error = nil;
		
		[output enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
			if ([line hasPrefix:@"Error:"] || [line hasPrefix:@"fatal:"])
			{
				error = [NSError errorWithDomain:@"Cicerone"
											code:2701
										userInfo:@{NSLocalizedDescriptionKey: line}];
				
				*stop = YES;
			}
		}];
		
		return error;
	}
}

- (BOOL)runBrewImportToolWithPath:(NSString*)path withReturnsBlock:(void (^)(NSString *))block
{
	NSArray *arguments = @[@"bundle", [NSString stringWithFormat:@"--file=%@", path]];
	[self sendDelegateFormulaeUpdatedCall];
	return [self performBrewCommandWithArguments:arguments
								 dataReturnBlock:block];
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
	return [CiFormula formulaWithName:[aux firstObject] andVersion:[aux lastObject]];
}

@end

@implementation CiHomebrewInterfaceListCallInstalledCasks

- (instancetype)init
{
	return (CiHomebrewInterfaceListCallInstalledCasks *)[super initWithArguments:@[@"list", @"--versions", @"--casks"]];
}

- (CiFormula *)parseFormulaItem:(NSString *)item
{
	NSArray *aux = [item componentsSeparatedByString:@" "];
	return [CiFormula formulaWithName:[aux firstObject] andVersion:[aux lastObject]];
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
										 version:installedVersion
								andLatestVersion:latestVersion];
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
										 version:installedVersion
								andLatestVersion:latestVersion];
		}
	}];
	
	if (!formula) {
		formula = [CiFormula formulaWithName:item];
	}
	
	return formula;
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

//
//	CiHomebrewManager.m
//	Cicerone – The Homebrew GUI App for OS X
//
//	Created by Bruno Philipe on 4/3/14.
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

#import "CiHomebrewManager.h"
#import "CiHomebrewInterface.h"
#import "CiAppDelegate.h"

NSString *const kCiCacheLastUpdateKey = @"CiCacheLastUpdateKey";
NSString *const kCiCacheDataKey	= @"CiCacheDataKey";

#define kCi_SECONDS_IN_A_DAY 86400

@interface CiHomebrewManager () <CiHomebrewInterfaceDelegate>

@end

@implementation CiHomebrewManager

+ (CiHomebrewManager *)sharedManager
{
	@synchronized(self)
	{
        static dispatch_once_t once;
        static CiHomebrewManager *instance;
        dispatch_once(&once, ^ { instance = [[super allocWithZone:NULL] initUniqueInstance]; });
        return instance;
	}
}

- (instancetype)initUniqueInstance
{
	self = [super init];
	if (self) {
		
	}
	return self;
}

+ (instancetype)allocWithZone:(NSZone *)zone
{
	return [self sharedManager];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadFromInterfaceRebuildingCache:(BOOL)shouldRebuildCache;
{
	NSUInteger previousCountOfAllFormulae = [self allFormulae].count;
	NSUInteger previousCountOfAllCasks = [self allCasks].count;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		[[CiHomebrewInterface sharedInterface] setDelegate:self];
		
		NSArray *installedFormulae = [[CiHomebrewInterface sharedInterface] listMode:kCiListInstalledFormulae];
		NSArray *leavesFormulae = [[CiHomebrewInterface sharedInterface] listMode:kCiListLeaves];
		NSArray *outdatedFormulae = [[CiHomebrewInterface sharedInterface] listMode:kCiListOutdatedFormulae];
		NSArray *repositoriesFormulae = [[CiHomebrewInterface sharedInterface] listMode:kCiListRepositories];

		NSArray *installedCasks = [[CiHomebrewInterface sharedInterface] listMode:kCiListInstalledCasks];
		NSArray *outdatedCasks = [[CiHomebrewInterface sharedInterface] listMode:kCiListOutdatedCasks];
		
		NSArray *allFormulae = nil;
		NSArray *allCasks = nil;

		if (![self loadAllFormulaeCaches] || previousCountOfAllFormulae <= 100 || shouldRebuildCache) {
			allFormulae = [[CiHomebrewInterface sharedInterface] listMode:kCiListAllFormulae];
		}
		
		if (![self loadAllCasksCaches] || previousCountOfAllCasks <= 10 || shouldRebuildCache) {
			allCasks = [[CiHomebrewInterface sharedInterface] listMode:kCiListAllCasks];
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			if (allFormulae != nil) {
				[self setAllFormulae:allFormulae];
				[self storeAllFormulaeCaches];
			}
			if (allCasks != nil) {
				[self setAllCasks:allCasks];
				[self storeAllCasksCaches];
			}
			[self setInstalledFormulae:installedFormulae];
			[self setLeavesFormulae:leavesFormulae];
			[self setOutdatedFormulae:outdatedFormulae];
			[self setRepositoriesFormulae:repositoriesFormulae];
			[self setInstalledCasks:installedCasks];
			[self setOutdatedCasks:outdatedCasks];
			[self.delegate homebrewManagerFinishedUpdating:self];
		});
	});
}

- (void)updateSearchWithName:(NSString *)name
{
	NSMutableArray *matches = [NSMutableArray array];
	NSRange range;
	
	for (CiFormula *formula in _allFormulae) {
		range = [[formula name] rangeOfString:name options:NSCaseInsensitiveSearch];
		if (range.location != NSNotFound) {
			[matches addObject:formula];
		}
	}
	
	_searchFormulae = matches;

	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate homebrewManager:self didUpdateSearchResults:matches];
	});
}

- (BOOL)loadAllFormulaeCaches
{
	return [self loadCache:@"allFormulae.cache.bin" array:self.allFormulae];
}

- (BOOL)loadAllCasksCaches
{
	return [self loadCache:@"allCasks.cache.bin" array:self.allCasks];
}

/**
 Returns `YES` if cache exists, was created less than 24 hours ago and was loaded successfully. Otherwise returns `NO`.
 */
- (BOOL)loadCache:(NSString*)fileName array:(NSArray<CiFormula*>*)cache
{
   NSURL *cachesFolder = [CiAppDelegate urlForApplicationCachesFolder];
   NSURL *allFile = [cachesFolder URLByAppendingPathComponent:fileName];
   BOOL shouldLoadCache = NO;
   
   if ([[NSUserDefaults standardUserDefaults] objectForKey:kCiCacheLastUpdateKey])
   {
	   NSDate *storageDate = [NSDate dateWithTimeIntervalSince1970:[[NSUserDefaults standardUserDefaults]
																	integerForKey:kCiCacheLastUpdateKey]];
	   
	   if ([[NSDate date] timeIntervalSinceDate:storageDate] <= 3600*24)
	   {
		   shouldLoadCache = YES;
	   }
   }
   
   if (shouldLoadCache && allFile)
   {
	   NSDictionary *cacheDict = nil;
	   
	   if ([[NSFileManager defaultManager] fileExistsAtPath:allFile.relativePath])
	   {
		   NSData *data = [NSData dataWithContentsOfFile:allFile.relativePath];
		   NSError *error = nil;

		   if (@available(macOS 10.13, *)) {
			   NSSet *classes = [NSSet setWithArray:@[[NSString class], [NSDictionary class], [NSMutableArray class], [CiFormula class]]];
			   cacheDict = [NSKeyedUnarchiver unarchivedObjectOfClasses:classes fromData:data error:&error];
			   if (error) {
				   NSLog(@"Failed decoding data: %@", [error localizedDescription]);
			   }
		   } else {
			   cacheDict = [NSKeyedUnarchiver unarchiveObjectWithFile:allFile.relativePath];
		   }
		   cache = [cacheDict objectForKey:kCiCacheDataKey];
	   }
   } else {
	   // Delete all cache data
	   [[NSFileManager defaultManager] removeItemAtURL:allFile error:nil];
	   [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCiCacheLastUpdateKey];
   }
   return cache != nil;
}

- (void)storeAllFormulaeCaches
{
	[self storeCache:@"allFormulae.cache.bin" array:self.allFormulae];
}

- (void)storeAllCasksCaches
{
	[self storeCache:@"allCasks.cache.bin" array:self.allCasks];
}

- (void)storeCache:(NSString*)fileName array:(NSArray<CiFormula*>*)cache
{
	if (self.allCasks)
	{
		NSURL *cachesFolder = [CiAppDelegate urlForApplicationCachesFolder];
		if (cachesFolder)
		{
			NSURL *allFile = [cachesFolder URLByAppendingPathComponent:fileName];
			NSDate *storageDate = [NSDate date];
			
			if ([[NSUserDefaults standardUserDefaults] objectForKey:kCiCacheLastUpdateKey])
			{
				storageDate = [NSDate dateWithTimeIntervalSince1970:[[NSUserDefaults standardUserDefaults]
																	 integerForKey:kCiCacheLastUpdateKey]];
			}
			
			NSDictionary *cacheDict = @{kCiCacheDataKey: cache};
			NSData *cacheData;

			if (@available(macOS 10.13, *)) {
				NSError *error = nil;
				cacheData = [NSKeyedArchiver archivedDataWithRootObject:cacheDict
												  requiringSecureCoding:YES
																  error:&error];

				if (error) {
					NSLog(@"Failed encoding data: %@", [error localizedDescription]);
				}
			} else {
				cacheData = [NSKeyedArchiver archivedDataWithRootObject:cacheDict];
			}
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:allFile.relativePath])
			{
				[cacheData writeToURL:allFile atomically:YES];
			}
			else
			{
				[[NSFileManager defaultManager] createFileAtPath:allFile.relativePath
														contents:cacheData attributes:nil];
			}
			
			[[NSUserDefaults standardUserDefaults] setInteger:[storageDate timeIntervalSince1970]
													   forKey:kCiCacheLastUpdateKey];
		} else {
			NSLog(@"Could not store cache file. CiAppDelegate function returned nil!");
		}
	}
}

- (NSInteger)searchForFormula:(CiFormula*)formula inArray:(NSArray*)array
{
	NSUInteger index = 0;
	
	for (CiFormula* item in array)
	{
		if ([[item installedName] isEqualToString:[formula installedName]])
		{
			return index;
		}
		
		index++;
	}
	
	return -1;
}

- (CiFormulaStatus)statusForFormula:(CiFormula*)formula {
	if ([self searchForFormula:formula inArray:self.installedFormulae] >= 0) {
		if ([self searchForFormula:formula inArray:self.outdatedFormulae] >= 0)
		{
			return kCiFormulaOutdated;
		} else {
			return kCiFormulaInstalled;
		}
	} else {
		return kCiFormulaNotInstalled;
	}
}

- (CiFormulaStatus)statusForCask:(CiFormula*)formula {
	if ([self searchForFormula:formula inArray:self.installedCasks] >= 0) {
		if ([self searchForFormula:formula inArray:self.outdatedCasks] >= 0) {
			return kCiFormulaOutdated;
		} else {
			return kCiFormulaInstalled;
		}
	} else {
		return kCiFormulaNotInstalled;
	}
}

- (void)cleanUp
{
	[[CiHomebrewInterface sharedInterface] cleanup];
}

#pragma - Homebrew Interface Delegate

- (void)homebrewInterfaceDidUpdateFormulae
{
	[self reloadFromInterfaceRebuildingCache:YES];
}

- (void)homebrewInterfaceShouldDisplayNoBrewMessage:(BOOL)yesOrNo
{
	if (self.delegate) {
		[self.delegate homebrewManager:self shouldDisplayNoBrewMessage:yesOrNo];
	}
}

@end

//
//	COHomebrewManager.m
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

#import "COHomebrewManager.h"
#import "COHomebrewInterface.h"
#import "COAppDelegate.h"
#import "COFormulaeDataSource.h"

NSString *const kCOCacheLastUpdateKey = @"COCacheLastUpdateKey";
NSString *const kCOCacheDataKey	= @"COCacheDataKey";

#define kCO_SECONDS_IN_A_DAY 86400

@interface COHomebrewManager () <COHomebrewInterfaceDelegate>

@end

@implementation COHomebrewManager

+ (COHomebrewManager *)sharedManager
{
	@synchronized(self)
	{
        static dispatch_once_t once;
        static COHomebrewManager *instance;
        
        dispatch_once(&once, ^{ instance = [[super allocWithZone:NULL] initUniqueInstance]; });
        
        return instance;
	}
}

- (instancetype)initUniqueInstance
{
	self = [super init];
	if (self) {
        [COHomebrewInterface sharedInterface].delegate = self;
        _formulaeDataSource = [[COFormulaeDataSource alloc] initWithMode:kCOListModeAllFormulae];
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

- (void)loadHomebrewPrefixState;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate homebrewManagerWillLoadHomebrewPrefixState:self];
    });
    
	NSUInteger previousCountOfAllFormulae = [self allFormulae].count;
	NSUInteger previousCountOfAllCasks = [self allCasks].count;

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSArray *installedFormulae = [[COHomebrewInterface sharedInterface] packagesWithMode:kCOListModeInstalledFormulae];
		NSArray *leavesFormulae = [[COHomebrewInterface sharedInterface] packagesWithMode:kCOListModeLeaves];
		NSArray *outdatedFormulae = [[COHomebrewInterface sharedInterface] packagesWithMode:kCOListModeOutdatedFormulae];
		NSArray *repositoriesFormulae = [[COHomebrewInterface sharedInterface] packagesWithMode:kCOListModeRepositories];

		NSArray *installedCasks = [[COHomebrewInterface sharedInterface] packagesWithMode:kCOListModeInstalledCasks];
		NSArray *outdatedCasks = [[COHomebrewInterface sharedInterface] packagesWithMode:kCOListModeOutdatedCasks];
		
		NSArray *allFormulae = nil;
		NSArray *allCasks = nil;

		if (![self loadAllFormulaeCaches] || previousCountOfAllFormulae <= 100) {
			allFormulae = [[COHomebrewInterface sharedInterface] packagesWithMode:kCOListModeAllFormulae];
		}
		
		if (![self loadAllCasksCaches] || previousCountOfAllCasks <= 10) {
			allCasks = [[COHomebrewInterface sharedInterface] packagesWithMode:kCOListModeAllCasks];
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			if (allFormulae != nil) {
                self.allFormulae = allFormulae;
				[self storeAllFormulaeCaches];
			}
			
            if (allCasks != nil) {
				self.allCasks = allCasks;
				[self storeAllCasksCaches];
			}
            
            self.installedFormulae = installedFormulae;
            self.leavesFormulae = leavesFormulae;
            self.outdatedFormulae = outdatedFormulae;
            self.repositoriesFormulae = repositoriesFormulae;
            self.installedCasks = installedCasks;
            self.outdatedCasks = outdatedCasks;
			
            [self.delegate homebrewManagerDidLoadHomebrewPrefixState:self];
		});
	});
}

- (void)updateSearchWithName:(NSString *)name
{
    _searchFormulae = [[_allFormulae arrayByAddingObjectsFromArray:_allCasks] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        if ([[evaluatedObject name] rangeOfString:name options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return true;
        }
        
        return false;
    }]];

	dispatch_async(dispatch_get_main_queue(), ^{
		[self.delegate homebrewManager:self didFinishSearchReturningSearchResults:self.searchFormulae];
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
- (BOOL)loadCache:(NSString*)fileName array:(NSArray<COFormula *> *)cache
{
   NSURL *filePath = [[COAppDelegate urlForApplicationCachesFolder] URLByAppendingPathComponent:fileName];
   BOOL shouldLoadCache = NO;
   
   if ([[NSUserDefaults standardUserDefaults] objectForKey:kCOCacheLastUpdateKey])
   {
	   NSDate *storageDate = [NSDate dateWithTimeIntervalSince1970:[[NSUserDefaults standardUserDefaults] integerForKey:kCOCacheLastUpdateKey]];
	   
	   if ([[NSDate date] timeIntervalSinceDate:storageDate] <= 3600 * 24)
	   {
		   shouldLoadCache = YES;
	   }
   }
   
   if (shouldLoadCache && filePath)
   {
       if ([[NSFileManager defaultManager] fileExistsAtPath:filePath.relativePath])
       {
           NSLog(@"Loading cache at: %@", [filePath debugDescription]);
           
		   NSError *error = nil;
           NSDictionary *cacheDict = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[[NSNumber class],
                                                                                                        [NSString class],
                                                                                                        [NSDictionary class],
                                                                                                        [NSMutableArray class],
                                                                                                        [COFormula class]]]
                                                                         fromData:[NSData dataWithContentsOfFile:filePath.relativePath]
                                                                            error:&error];
           if (error) {
               NSLog(@"Failed decoding cache data: %@", [error localizedDescription]);
           }
           
		   cache = [cacheDict objectForKey:kCOCacheDataKey];
	   }
   } else {
       NSLog(@"Deleting cache supposedly at: %@", [filePath debugDescription]);
       
	   // Delete all cache data
	   [[NSFileManager defaultManager] removeItemAtURL:filePath error:nil];
	   [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCOCacheLastUpdateKey];
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

- (void)storeCache:(NSString*)fileName array:(NSArray<COFormula*>*)cache
{
	if (self.allCasks)
	{
		NSURL *cachesFolder = [COAppDelegate urlForApplicationCachesFolder];
		if (cachesFolder)
		{
			NSURL *filePath = [cachesFolder URLByAppendingPathComponent:fileName];
			NSDate *storageDate = [NSDate date];
			
			if ([[NSUserDefaults standardUserDefaults] objectForKey:kCOCacheLastUpdateKey])
			{
				storageDate = [NSDate dateWithTimeIntervalSince1970:[[NSUserDefaults standardUserDefaults] integerForKey:kCOCacheLastUpdateKey]];
			}
			
			NSDictionary *cacheDict = @{kCOCacheDataKey: cache};
            NSError *error = nil;
            NSData *cacheData = [NSKeyedArchiver archivedDataWithRootObject:cacheDict
                                                      requiringSecureCoding:YES
                                                                      error:&error];
            
            if (error) {
                NSLog(@"Failed encoding data: %@", [error localizedDescription]);
            }
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:filePath.relativePath])
			{
				[cacheData writeToURL:filePath atomically:YES];
			}
			else
			{
				[[NSFileManager defaultManager] createFileAtPath:filePath.relativePath
														contents:cacheData attributes:nil];
			}
			
			[[NSUserDefaults standardUserDefaults] setInteger:[storageDate timeIntervalSince1970]
													   forKey:kCOCacheLastUpdateKey];
		} else {
			NSLog(@"Could not store cache file. COAppDelegate function returned nil!");
		}
	}
}

- (COFormulaStatus)statusForListedPackage:(COFormula *)package
{
    return [self.formulaeDataSource statusForFormula:package];
}

- (void)cleanUp
{
	[[COHomebrewInterface sharedInterface] cleanup];
}

#pragma mark - Calls to Homebrew Interface Delegate

- (void)homebrewInterfaceChangedDependedHomebrewPrefixState
{
	[self loadHomebrewPrefixState];
}

- (void)homebrewInterfaceDidNotFindBrew:(BOOL)yesOrNo
{
	if (self.delegate) {
		[self.delegate homebrewManager:self didNotFindBrew:yesOrNo];
	}
}

@end

//
//	CiFormula.m
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

#import "CiFormula.h"
#import "CiFormulaOption.h"
#import "CiHomebrewManager.h"
#import "CiHomebrewInterface.h"
#import "NSURL+URLValidation.h"

static void *kCiFormulaContext = &kCiFormulaContext;

NSString *const kCi_ENCODE_FORMULA_NAME = @"Ci_ENCODE_FORMULA_NAME";
NSString *const kCi_ENCODE_FORMULA_IVER = @"Ci_ENCODE_FORMULA_IVER";
NSString *const kCi_ENCODE_FORMULA_LVER = @"Ci_ENCODE_FORMULA_LVER";
NSString *const kCi_ENCODE_FORMULA_PATH = @"Ci_ENCODE_FORMULA_PATH";
NSString *const kCi_ENCODE_FORMULA_WURL = @"Ci_ENCODE_FORMULA_WURL";
NSString *const kCi_ENCODE_FORMULA_DEPS = @"Ci_ENCODE_FORMULA_DEPS";
NSString *const kCi_ENCODE_FORMULA_INST = @"Ci_ENCODE_FORMULA_INST"; // load not implemented
NSString *const kCi_ENCODE_FORMULA_CNFL = @"Ci_ENCODE_FORMULA_CNFL";
NSString *const kCi_ENCODE_FORMULA_SDSC = @"Ci_ENCODE_FORMULA_SDSC";
NSString *const kCi_ENCODE_FORMULA_INFO = @"Ci_ENCODE_FORMULA_INFO";
NSString *const kCi_ENCODE_FORMULA_OPTN = @"Ci_ENCODE_FORMULA_OPTN";
NSString *const kCi_ENCODE_FORMULA_REQS = @"Ci_ENCODE_FORMULA_REQS"; // not implemented
NSString *const kCi_ENCODE_FORMULA_CASK = @"Ci_ENCODE_FORMULA_CASK";

NSString *const kCiBrewInfoSectionHeaderIndicator = @"==>";

NSString *const kCiFormulaInfoSectionHeaderDependencies = @"==> Dependencies"; // never in cask
NSString *const kCiFormulaInfoSectionHeaderRequirements = @"==> Requirements"; // never in cask
NSString *const kCiFormulaInfoSectionHeaderOptions = @"==> Options"; // never in cask

// casks only
NSString *const kCiCaskInfoSectionHeaderName = @"==> Name";
NSString *const kCiCaskInfoSectionHeaderDescription = @"==> Description";
NSString *const kCiCaskInfoSectionHeaderLanguages = @"==> Languages";
NSString *const kCiCaskInfoSectionHeaderArtifacts = @"==> Artifacts";

NSString *const kCiFormulaInfoSectionHeaderCaveats = @"==> Caveats";
NSString *const kCiFormulaInfoSectionHeaderAnalytics = @"==> Analytics";


NSString *const kCiFormulaDidUpdateNotification = @"CiFormulaDidUpdateNotification";

@interface CiFormula ()

@property (getter=isInstalled, readonly) BOOL installed;
@property (getter=isOutdated, readonly) BOOL outdated;

@property (copy, readwrite) NSString *name;
@property (copy, readwrite) NSString *version;
@property (copy, readwrite) NSString *latestVersion;
@property (copy, readwrite) NSString *installPath;
@property (copy, readwrite) NSString *dependencies;
@property (copy, readwrite) NSString *conflicts;
@property (copy, readwrite) NSString *analytics;
@property (copy, readwrite) NSString *shortDescription;
@property (copy, readwrite) NSString *information;
@property (readwrite) NSURL *website;
@property (readwrite) NSArray *options;
//@property (copy, readwrite) NSString *requirements;
@property (getter=isCask, readwrite) BOOL cask;

@end

@implementation CiFormula

+ (BOOL)supportsSecureCoding
{
	return YES;
}

+ (instancetype)formulaWithName:(NSString*)name withVersion:(NSString*)version withLatestVersion:(NSString*)latestVersion cask:(BOOL)isCask
{
	CiFormula *formula = [[self alloc] init];
	
	if (formula)
	{
		formula.name = name;
		formula.version = version;
		formula.latestVersion = latestVersion;
        formula.cask = isCask;
        
		[formula commonInit];
	}
	
	return formula;
}

+ (instancetype)formulaWithName:(NSString*)name withVersion:(NSString*)version cask:(BOOL)isCask
{
	return [self formulaWithName:name withVersion:version withLatestVersion:nil cask:isCask];
}

+ (instancetype)formulaWithName:(NSString*)name cask:(BOOL)isCask
{
    return [self formulaWithName:name withVersion:nil cask:isCask];
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	if (self.name)				[aCoder encodeObject:self.name				forKey:kCi_ENCODE_FORMULA_NAME];
	if (self.version)			[aCoder encodeObject:self.version			forKey:kCi_ENCODE_FORMULA_IVER];
	if (self.latestVersion)		[aCoder encodeObject:self.latestVersion		forKey:kCi_ENCODE_FORMULA_LVER];
	if (self.installPath)		[aCoder encodeObject:self.installPath		forKey:kCi_ENCODE_FORMULA_PATH];
	if (self.website)			[aCoder encodeObject:self.website			forKey:kCi_ENCODE_FORMULA_WURL];
	if (self.dependencies)		[aCoder encodeObject:self.dependencies		forKey:kCi_ENCODE_FORMULA_DEPS];
	if (self.conflicts)			[aCoder encodeObject:self.conflicts			forKey:kCi_ENCODE_FORMULA_CNFL];
	if (self.shortDescription)	[aCoder encodeObject:self.shortDescription	forKey:kCi_ENCODE_FORMULA_SDSC];
	if (self.information)		[aCoder encodeObject:self.information		forKey:kCi_ENCODE_FORMULA_INFO];
	if (self.options)			[aCoder encodeObject:self.options			forKey:kCi_ENCODE_FORMULA_OPTN];
    [aCoder encodeObject:@(self.isInstalled) forKey:kCi_ENCODE_FORMULA_INST];
    [aCoder encodeObject:@(self.isCask)      forKey:kCi_ENCODE_FORMULA_CASK];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self)
	{
		self.name				= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCi_ENCODE_FORMULA_NAME];
		self.version			= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCi_ENCODE_FORMULA_IVER];
		self.latestVersion		= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCi_ENCODE_FORMULA_LVER];
		self.installPath		= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCi_ENCODE_FORMULA_PATH];
		self.website			= [aDecoder decodeObjectOfClass:[NSURL class] forKey:kCi_ENCODE_FORMULA_WURL];
		self.dependencies		= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCi_ENCODE_FORMULA_DEPS];
		self.conflicts			= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCi_ENCODE_FORMULA_CNFL];
		self.shortDescription	= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCi_ENCODE_FORMULA_CNFL];
		self.information		= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCi_ENCODE_FORMULA_INFO];
		self.options			= [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSArray class], [CiFormulaOption class]]] forKey:kCi_ENCODE_FORMULA_OPTN];
        self.cask               = [aDecoder decodeObjectForKey:kCi_ENCODE_FORMULA_CASK];
        
		[self commonInit];
	}
	return self;
}

- (void)commonInit
{
	[self addObserver:self
		   forKeyPath:NSStringFromSelector(@selector(needsInformation))
			  options:NSKeyValueObservingOptionNew
			  context:kCiFormulaContext];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	/*
	 * Following best practices as suggested by:
	 * http://stackoverflow.com/questions/9907154/best-practice-when-implementing-copywithzone
	 */
	CiFormula *formula = [[[self class] allocWithZone:zone] init];
	if (formula)
	{
		formula->_name				= [self->_name				copy];
		formula->_version			= [self->_version			copy];
		formula->_latestVersion 	= [self->_latestVersion 	copy];
		formula->_installPath		= [self->_installPath		copy];
		formula->_website			= [self->_website			copy];
		formula->_dependencies		= [self->_dependencies		copy];
		formula->_conflicts			= [self->_conflicts			copy];
		formula->_shortDescription	= [self->_shortDescription	copy];
		formula->_information		= [self->_information		copy];
		formula->_options			= [self->_options			copy];
		
		[formula addObserver:formula forKeyPath:NSStringFromSelector(@selector(needsInformation))
					 options:NSKeyValueObservingOptionNew
					 context:kCiFormulaContext];
	}
	return formula;
}

- (NSString*)installedName
{
	NSRange locationOfLastSlash = [self.name rangeOfString:@"/" options:NSBackwardsSearch];
	
	if (locationOfLastSlash.location != NSNotFound)
	{
		return [self.name substringFromIndex:locationOfLastSlash.location + 1];
	}
	else
	{
		return [self name];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == kCiFormulaContext)
	{
		if ([object isEqualTo:self])
		{
			if ([keyPath isEqualToString:NSStringFromSelector(@selector(needsInformation))])
			{
				if (self.needsInformation)
				{
					[self getInformation];
				}
			}
		}
	}
	else
	{
		@try
		{
			[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		}
		@catch (NSException *exception) {}
	}
}

- (BOOL)getInformation
{
	NSString *line         = nil;
	NSString *output       = nil;
	NSArray *lines         = nil;
	NSUInteger lineIndex   = 0;
	
	if (!self.information)
	{
		id<CiFormulaDataProvider> dataProvider = [self dataProvider];
		
        if (![dataProvider respondsToSelector:@selector(informationWithFormulaName:cask:)])
		{
			_needsInformation = NO;
			return NO;
		}

        NSString *information = [[self dataProvider] informationWithFormulaName:self.name cask:self.isCask];

		if ([information rangeOfString:@"\n"].location == NSNotFound)
		{
			return NO;
		}
		else
		{
			[self setInformation:information];
		}
	}
	
	output = self.information;
	
	if ([output isEqualToString:@""])
	{
		_needsInformation = NO;
		return YES;
	}

	if ([output hasPrefix:@"Error"])
	{
		NSLog(@"Error parsing formula with name: %@", [self name]);

		_needsInformation = NO;
		[self setInformation:nil];
		[self setLatestVersion:nil];
		[self setVersion:nil];
		[self setShortDescription:nil];
		return YES;
	}
	
	lines = [output componentsSeparatedByString:@"\n"];
	
	lineIndex = 0;
	line = [lines objectAtIndex:lineIndex];
	[self setLatestVersion:[line substringFromIndex:[line rangeOfString:@":"].location+2]];
	
	lineIndex = 1;
	line = [lines objectAtIndex:lineIndex];
	id url = [NSURL validatedURLWithString:line];
	
	if (url == nil)
	{
		[self setShortDescription:line];
		
		lineIndex = 2;
		line = [lines objectAtIndex:lineIndex];
		[self setWebsite:[NSURL URLWithString:line]];
	}
	else
	{
		[self setWebsite:url];
	}
	
	lineIndex++;
	line = [lines objectAtIndex:lineIndex];
	if ([line rangeOfString:@"Conflicts with:"].location != NSNotFound)
	{
		if ([line isEqualToString:@"Conflicts with:"])
		{
			// One conflict per line
			NSMutableArray<NSString *> *conflicts = [NSMutableArray new];

			do
			{
				lineIndex++;
				line = [lines objectAtIndex:lineIndex];

				if ([line hasPrefix:@"  "])
				{
					[conflicts addObject:[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
				}
			}
			while ([line hasPrefix:@"  "]);

			[self setConflicts:[conflicts componentsJoinedByString:@", "]];
		}
		else
		{
			[self setConflicts:[line substringFromIndex:16]];
			lineIndex++;
			line = [lines objectAtIndex:lineIndex];
		}
	}
	
	if (![line isEqualToString:@"Not installed"])
	{
        lineIndex++;
        [self setInstallPath:[lines objectAtIndex:lineIndex]];
	}
    
    // end first header
    
    // casks only
    NSRange nameRange = [output rangeOfString:kCiCaskInfoSectionHeaderName];
    if (nameRange.location != NSNotFound) {
        NSString *tail = [output substringFromIndex:nameRange.location + nameRange.length];
        
        NSRange nextHeaderIndicatorRange = [tail rangeOfString:kCiBrewInfoSectionHeaderIndicator];
        if (nextHeaderIndicatorRange.location != NSNotFound) {
            NSString *name = [[tail substringToIndex:nextHeaderIndicatorRange.location] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            tail = [tail substringFromIndex:nextHeaderIndicatorRange.location];
            
            NSRange descriptionRange = [tail rangeOfString:kCiCaskInfoSectionHeaderDescription];
            if (descriptionRange.location != NSNotFound) {
                tail = [tail substringFromIndex:descriptionRange.location + descriptionRange.length];
                nextHeaderIndicatorRange = [tail rangeOfString:kCiBrewInfoSectionHeaderIndicator];
                tail = [(nextHeaderIndicatorRange.location != NSNotFound ? [tail substringToIndex:nextHeaderIndicatorRange.location] : tail) stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                self.shortDescription = [name isEqualToString:self.name] ? tail : [NSString stringWithFormat:@"%@;\n%@", name, tail];
            }
        } else {
            self.shortDescription = [tail stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        }
    }
	
	NSRange dependenciesRange = [output rangeOfString:kCiFormulaInfoSectionHeaderDependencies];
	NSRange optionsRange = [output rangeOfString:kCiFormulaInfoSectionHeaderOptions];
	NSRange caveatsRange = [output rangeOfString:kCiFormulaInfoSectionHeaderCaveats];
    NSRange analyticsRange = [output rangeOfString:kCiFormulaInfoSectionHeaderAnalytics];
	
	// Find dependencies
	if (dependenciesRange.location != NSNotFound)
	{
		dependenciesRange.location = dependenciesRange.location + dependenciesRange.length + 1;

		if (optionsRange.location != NSNotFound)
		{
			dependenciesRange.length = optionsRange.location - dependenciesRange.location;
		}
		else if (caveatsRange.location != NSNotFound)
		{
			dependenciesRange.length = caveatsRange.location - dependenciesRange.location;
		}
        else if (analyticsRange.location != NSNotFound)
        {
            dependenciesRange.length = analyticsRange.location - dependenciesRange.location;
        }
		else
		{
			dependenciesRange.length = [output length] - dependenciesRange.location;
		}
		
		NSMutableArray<NSString *> __block *dependencies = [NSMutableArray new];
		
		[output enumerateSubstringsInRange:dependenciesRange
								   options:NSStringEnumerationByLines usingBlock:^(NSString *substring,
																				   NSRange substringRange,
																				   NSRange enclosingRange,
																				   BOOL *stop)
		 {
			 if ([substring rangeOfString:NSLocalizedString(@"Homebrew_Task_Finished", nil)].location == NSNotFound)
			 {
				 [dependencies addObject:substring];
			 }
		 }];
		
		[self setDependencies:[dependencies componentsJoinedByString:@"; "]];
	} else {
		[self setDependencies:nil];
	}
	
	// Find options
	if (optionsRange.location != NSNotFound)
	{
		NSString *optionsString = [output substringFromIndex:optionsRange.length + optionsRange.location + 1];
		NSMutableArray *options = [NSMutableArray arrayWithCapacity:10];
		
		caveatsRange = [optionsString rangeOfString:kCiFormulaInfoSectionHeaderCaveats];
        analyticsRange = [optionsString rangeOfString:kCiFormulaInfoSectionHeaderAnalytics];
		
		if (caveatsRange.location != NSNotFound) {
			optionsString = [optionsString substringToIndex:caveatsRange.location];
		}
        else if (analyticsRange.location != NSNotFound) {
            optionsString = [optionsString substringToIndex:analyticsRange.location];
        }
		
		CiFormulaOption __block *formulaOption = nil;
		[optionsString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
			if ([line hasPrefix:@"--"]) { // This is an option command
				formulaOption = [[CiFormulaOption alloc] init];
				formulaOption.name = line;
			} else if (formulaOption) { // This is the option description
				formulaOption.explanation = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
				[options addObject:formulaOption];
				formulaOption = nil;
			} else {
				*stop = YES;
			}
		}];
		
		[self setOptions:[options copy]];
	} else {
		[self setOptions:nil];
	}
	
	_needsInformation = NO;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kCiFormulaDidUpdateNotification object:self];
	return YES;
}

- (BOOL)isInstalled
{
	return [[[CiHomebrewManager sharedManager] formulaeDataSource] statusForFormula:self] != kCiFormulaStatusNotInstalled;
}

- (BOOL)isOutdated
{
	return [[[CiHomebrewManager sharedManager] formulaeDataSource] statusForFormula:self] == kCiFormulaStatusOutdated;
}

- (NSString*)description
{
	return [NSString stringWithFormat:@"%@ <%p> name:%@ version:%@ latestVerson:%@", NSStringFromClass([self class]), self, self.name, self.version, self.latestVersion];
}

- (NSString*)shortLatestVersion
{
	NSArray *components = [[self latestVersion] componentsSeparatedByString:@" "];
	NSUInteger count = [components count];
	
	if (3 == count || 4 == count)
	{
		// New Version, like: stable 1.6.23 (bottled), HEAD
		// We take only the second component, like: 1.6.23
		
		return [components objectAtIndex:1];
	}
	else
	{
		return [self latestVersion];
	}
}

- (id<CiFormulaDataProvider>)dataProvider
{
	return [CiHomebrewInterface sharedInterface];
}

- (void)dealloc
{
	[self removeObserver:self
			  forKeyPath:NSStringFromSelector(@selector(needsInformation))
				 context:kCiFormulaContext];
}

@end

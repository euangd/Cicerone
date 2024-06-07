//
//	COFormula.m
//	Bruh – The Homebrew GUI App for OS X
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

#import "COFormula.h"
#import "COFormulaOption.h"
#import "COHomebrewManager.h"
#import "COHomebrewInterface.h"
#import "NSURL+URLValidation.h"

static void *kCOFormulaContext = &kCOFormulaContext;

NSString *const kCO_ENCODE_FORMULA_NAME = @"CO_ENCODE_FORMULA_NAME";
NSString *const kCO_ENCODE_FORMULA_IVER = @"CO_ENCODE_FORMULA_IVER";
NSString *const kCO_ENCODE_FORMULA_LVER = @"CO_ENCODE_FORMULA_LVER";
NSString *const kCO_ENCODE_FORMULA_PATH = @"CO_ENCODE_FORMULA_PATH";
NSString *const kCO_ENCODE_FORMULA_WURL = @"CO_ENCODE_FORMULA_WURL";
NSString *const kCO_ENCODE_FORMULA_DEPS = @"CO_ENCODE_FORMULA_DEPS";
NSString *const kCO_ENCODE_FORMULA_INST = @"CO_ENCODE_FORMULA_INST"; // load not implemented
NSString *const kCO_ENCODE_FORMULA_CNFL = @"CO_ENCODE_FORMULA_CNFL";
NSString *const kCO_ENCODE_FORMULA_SDSC = @"CO_ENCODE_FORMULA_SDSC";
NSString *const kCO_ENCODE_FORMULA_INFO = @"CO_ENCODE_FORMULA_INFO";
NSString *const kCO_ENCODE_FORMULA_OPTN = @"CO_ENCODE_FORMULA_OPTN";
NSString *const kCO_ENCODE_FORMULA_REQS = @"CO_ENCODE_FORMULA_REQS"; // not implemented
NSString *const kCO_ENCODE_FORMULA_CASK = @"CO_ENCODE_FORMULA_CASK";

NSString *const kCOBrewInfoSectionHeaderIndicator = @"==>";

NSString *const kCOFormulaInfoSectionHeaderDependencies = @"==> Dependencies"; // never in cask
NSString *const kCOFormulaInfoSectionHeaderRequirements = @"==> Requirements"; // never in cask
NSString *const kCOFormulaInfoSectionHeaderOptions = @"==> Options"; // never in cask

// casks only
NSString *const kCOCaskInfoSectionHeaderName = @"==> Name";
NSString *const kCOCaskInfoSectionHeaderDescription = @"==> Description";
NSString *const kCOCaskInfoSectionHeaderLanguages = @"==> Languages";
NSString *const kCOCaskInfoSectionHeaderArtifacts = @"==> Artifacts";

NSString *const kCOFormulaInfoSectionHeaderCaveats = @"==> Caveats";
NSString *const kCOFormulaInfoSectionHeaderAnalytics = @"==> Analytics";


NSString *const kCOFormulaDidUpdateNotification = @"COFormulaDidUpdateNotification";

@interface COFormula ()

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
@property (readwrite) BOOL cask;

@end

@implementation COFormula

+ (BOOL)supportsSecureCoding
{
	return YES;
}

+ (instancetype)formulaWithName:(NSString*)name withVersion:(NSString*)version withLatestVersion:(NSString*)latestVersion cask:(BOOL)isCask
{
	COFormula *formula = [[self alloc] init];
	
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
	if (self.name)				[aCoder encodeObject:self.name				forKey:kCO_ENCODE_FORMULA_NAME];
	if (self.version)			[aCoder encodeObject:self.version			forKey:kCO_ENCODE_FORMULA_IVER];
	if (self.latestVersion)		[aCoder encodeObject:self.latestVersion		forKey:kCO_ENCODE_FORMULA_LVER];
	if (self.installPath)		[aCoder encodeObject:self.installPath		forKey:kCO_ENCODE_FORMULA_PATH];
	if (self.website)			[aCoder encodeObject:self.website			forKey:kCO_ENCODE_FORMULA_WURL];
	if (self.dependencies)		[aCoder encodeObject:self.dependencies		forKey:kCO_ENCODE_FORMULA_DEPS];
	if (self.conflicts)			[aCoder encodeObject:self.conflicts			forKey:kCO_ENCODE_FORMULA_CNFL];
	if (self.shortDescription)	[aCoder encodeObject:self.shortDescription	forKey:kCO_ENCODE_FORMULA_SDSC];
	if (self.information)		[aCoder encodeObject:self.information		forKey:kCO_ENCODE_FORMULA_INFO];
	if (self.options)			[aCoder encodeObject:self.options			forKey:kCO_ENCODE_FORMULA_OPTN];
    [aCoder encodeObject:@(self.isInstalled) forKey:kCO_ENCODE_FORMULA_INST];
    [aCoder encodeObject:@(self.isCask)      forKey:kCO_ENCODE_FORMULA_CASK];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self)
	{
		self.name				= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCO_ENCODE_FORMULA_NAME];
		self.version			= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCO_ENCODE_FORMULA_IVER];
		self.latestVersion		= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCO_ENCODE_FORMULA_LVER];
		self.installPath		= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCO_ENCODE_FORMULA_PATH];
		self.website			= [aDecoder decodeObjectOfClass:[NSURL class] forKey:kCO_ENCODE_FORMULA_WURL];
		self.dependencies		= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCO_ENCODE_FORMULA_DEPS];
		self.conflicts			= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCO_ENCODE_FORMULA_CNFL];
		self.shortDescription	= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCO_ENCODE_FORMULA_CNFL];
		self.information		= [aDecoder decodeObjectOfClass:[NSString class] forKey:kCO_ENCODE_FORMULA_INFO];
		self.options			= [aDecoder decodeObjectOfClasses:[NSSet setWithArray:@[[NSArray class], [COFormulaOption class]]] forKey:kCO_ENCODE_FORMULA_OPTN];
        self.cask               = [aDecoder decodeObjectForKey:kCO_ENCODE_FORMULA_CASK];
        
		[self commonInit];
	}
	return self;
}

- (void)commonInit
{
	[self addObserver:self
		   forKeyPath:NSStringFromSelector(@selector(needsInformation))
			  options:NSKeyValueObservingOptionNew
			  context:kCOFormulaContext];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	/*
	 * Following best practices as suggested by:
	 * http://stackoverflow.com/questions/9907154/best-practice-when-implementing-copywithzone
	 */
	COFormula *formula = [[[self class] allocWithZone:zone] init];
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
					 context:kCOFormulaContext];
	}
	return formula;
}

- (NSString *)installedName
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
	if (context == kCOFormulaContext)
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
		id<COFormulaDataProvider> dataProvider = [self dataProvider];
		
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
        self.information = nil;
        self.latestVersion = nil;
        self.version = nil;
        self.shortDescription = nil;
        
		return YES;
	}
	
	lines = [output componentsSeparatedByString:@"\n"];
	
	lineIndex = 0;
	line = [lines objectAtIndex:lineIndex];
    self.latestVersion = [line substringFromIndex:[line rangeOfString:@":"].location+2];
	
	lineIndex = 1;
	line = [lines objectAtIndex:lineIndex];
	id url = [NSURL validatedURLWithString:line];
	
	if (url == nil)
	{
        self.shortDescription = line;
		
		lineIndex = 2;
		line = [lines objectAtIndex:lineIndex];
        self.website = [NSURL URLWithString:line];
	}
	else
	{
        self.website = url;
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

            self.conflicts = [conflicts componentsJoinedByString:@", "];
		}
		else
		{
            self.conflicts = [line substringFromIndex:16];
			lineIndex++;
			line = [lines objectAtIndex:lineIndex];
		}
	}
	
	if (![line isEqualToString:@"Not installed"])
	{
        lineIndex++;
        self.installPath = [lines objectAtIndex:lineIndex];
	}
    
    // end first header
    
    // casks only
    NSRange nameRange = [output rangeOfString:kCOCaskInfoSectionHeaderName];
    if (nameRange.location != NSNotFound) {
        NSString *tail = [output substringFromIndex:nameRange.location + nameRange.length];
        
        NSRange nextHeaderIndicatorRange = [tail rangeOfString:kCOBrewInfoSectionHeaderIndicator];
        if (nextHeaderIndicatorRange.location != NSNotFound) {
            NSString *name = [[tail substringToIndex:nextHeaderIndicatorRange.location] stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            tail = [tail substringFromIndex:nextHeaderIndicatorRange.location];
            
            NSRange descriptionRange = [tail rangeOfString:kCOCaskInfoSectionHeaderDescription];
            if (descriptionRange.location != NSNotFound) {
                tail = [tail substringFromIndex:descriptionRange.location + descriptionRange.length];
                nextHeaderIndicatorRange = [tail rangeOfString:kCOBrewInfoSectionHeaderIndicator];
                tail = [(nextHeaderIndicatorRange.location != NSNotFound ? [tail substringToIndex:nextHeaderIndicatorRange.location] : tail) stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
                self.shortDescription = [name isEqualToString:self.name] ? tail : [NSString stringWithFormat:@"%@;\n%@", name, tail];
            }
        } else {
            self.shortDescription = [tail stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        }
    }
	
	NSRange dependenciesRange = [output rangeOfString:kCOFormulaInfoSectionHeaderDependencies];
	NSRange optionsRange = [output rangeOfString:kCOFormulaInfoSectionHeaderOptions];
	NSRange caveatsRange = [output rangeOfString:kCOFormulaInfoSectionHeaderCaveats];
    NSRange analyticsRange = [output rangeOfString:kCOFormulaInfoSectionHeaderAnalytics];
	
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
		
        self.dependencies = [dependencies componentsJoinedByString:@"; "];
	} else {
        self.dependencies = nil;
	}
	
	// Find options
	if (optionsRange.location != NSNotFound)
	{
		NSString *optionsString = [output substringFromIndex:optionsRange.length + optionsRange.location + 1];
		NSMutableArray *options = [NSMutableArray arrayWithCapacity:10];
		
		caveatsRange = [optionsString rangeOfString:kCOFormulaInfoSectionHeaderCaveats];
        analyticsRange = [optionsString rangeOfString:kCOFormulaInfoSectionHeaderAnalytics];
		
		if (caveatsRange.location != NSNotFound) {
			optionsString = [optionsString substringToIndex:caveatsRange.location];
		}
        else if (analyticsRange.location != NSNotFound) {
            optionsString = [optionsString substringToIndex:analyticsRange.location];
        }
		
		COFormulaOption __block *formulaOption = nil;
		[optionsString enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
			if ([line hasPrefix:@"--"]) { // This is an option command
				formulaOption = [[COFormulaOption alloc] init];
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
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kCOFormulaDidUpdateNotification object:self];
	return YES;
}

- (BOOL)isInstalled
{
	return [[[COHomebrewManager sharedManager] formulaeDataSource] statusForFormula:self] != kCOFormulaStatusNotInstalled;
}

- (BOOL)isOutdated
{
	return [[[COHomebrewManager sharedManager] formulaeDataSource] statusForFormula:self] == kCOFormulaStatusOutdated;
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

- (id<COFormulaDataProvider>)dataProvider
{
	return [COHomebrewInterface sharedInterface];
}

- (void)dealloc
{
	[self removeObserver:self
			  forKeyPath:NSStringFromSelector(@selector(needsInformation))
				 context:kCOFormulaContext];
}

@end

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

static void *kCiFormulaContext = &kCiFormulaContext;

NSString *const kCi_ENCODE_FORMULA_NAME = @"Ci_ENCODE_FORMULA_NAME";
NSString *const kCi_ENCODE_FORMULA_IVER = @"Ci_ENCODE_FORMULA_IVER";
NSString *const kCi_ENCODE_FORMULA_LVER = @"Ci_ENCODE_FORMULA_LVER";
NSString *const kCi_ENCODE_FORMULA_PATH = @"Ci_ENCODE_FORMULA_PATH";
NSString *const kCi_ENCODE_FORMULA_WURL = @"Ci_ENCODE_FORMULA_WURL";
NSString *const kCi_ENCODE_FORMULA_DEPS = @"Ci_ENCODE_FORMULA_DEPS";
NSString *const kCi_ENCODE_FORMULA_INST = @"Ci_ENCODE_FORMULA_INST";
NSString *const kCi_ENCODE_FORMULA_CNFL = @"Ci_ENCODE_FORMULA_CNFL";
NSString *const kCi_ENCODE_FORMULA_SDSC = @"Ci_ENCODE_FORMULA_SDSC";
NSString *const kCi_ENCODE_FORMULA_INFO = @"Ci_ENCODE_FORMULA_INFO";
NSString *const kCi_ENCODE_FORMULA_OPTN = @"Ci_ENCODE_FORMULA_OPTN";

NSString *const kCiIdentifierDependencies = @"==> Dependencies";
NSString *const kCiIdentifierOptions = @"==> Options";
NSString *const kCiIdentifierCaveats = @"==> Caveats";

NSString *const kCiFormulaDidUpdateNotification = @"CiFormulaDidUpdateNotification";

@interface CiFormula ()

@property (getter=isInstalled) BOOL installed;
@property (getter=isOutdated) BOOL outdated;

@property (copy, readwrite) NSString *name;
@property (copy, readwrite) NSString *version;
@property (copy, readwrite) NSString *latestVersion;
@property (copy, readwrite) NSString *installPath;
@property (copy, readwrite) NSString *dependencies;
@property (copy, readwrite) NSString *conflicts;
@property (copy, readwrite) NSString *shortDescription;
@property (copy, readwrite) NSString *information;
@property (strong, readwrite) NSURL *website;
@property (strong, readwrite) NSArray *options;

@end

@implementation CiFormula

+ (BOOL)supportsSecureCoding
{
	return YES;
}

+ (instancetype)formulaWithName:(NSString*)name withVersion:(NSString*)version withLatestVersion:(NSString*)latestVersion
{
	CiFormula *formula = [[self alloc] init];
	
	if (formula)
	{
		formula.name = name;
		formula.version = version;
		formula.latestVersion = latestVersion;
        
		[formula commonInit];
	}
	
	return formula;
}

+ (instancetype)formulaWithName:(NSString*)name withVersion:(NSString*)version
{
	return [self formulaWithName:name withVersion:version withLatestVersion:nil];
}

+ (instancetype)formulaWithName:(NSString*)name
{
	return [self formulaWithName:name withVersion:nil];
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
	[aCoder encodeObject:@([self isInstalled]) forKey:kCi_ENCODE_FORMULA_INST];
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

		NSSet *optionsClasses = [NSSet setWithArray:@[[NSArray class], [CiFormulaOption class]]];
		self.options			= [aDecoder decodeObjectOfClasses:optionsClasses forKey:kCi_ENCODE_FORMULA_OPTN];
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
		return [self.name substringFromIndex:locationOfLastSlash.location+1];
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
		
		if (![dataProvider respondsToSelector:@selector(informationWithFormulaName:)])
		{
			_needsInformation = NO;
			return NO;
		}

		NSString *information = [[self dataProvider] informationWithFormulaName:self.name];

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
	id url = [NSURL URLWithString:line];
	
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
		if ([line isEqualToString:@""]) { //keg-only formual has no path
			lineIndex += 1;
			[self setInstallPath:[lines objectAtIndex:lineIndex]];
		} else {
			[self setInstallPath:line];
		}
	}
	
	NSRange range_deps = [output rangeOfString:kCiIdentifierDependencies];
	NSRange range_opts = [output rangeOfString:kCiIdentifierOptions];
	NSRange range_cvts = [output rangeOfString:kCiIdentifierCaveats];
	
	// Find dependencies
	if (range_deps.location != NSNotFound)
	{
		range_deps.location = range_deps.length+range_deps.location+1;

		if (range_opts.location != NSNotFound)
		{
			range_deps.length = range_opts.location-range_deps.location;
		}
		else if (range_cvts.location != NSNotFound)
		{
			range_deps.length = range_cvts.location-range_deps.location;
		}
		else
		{
			range_deps.length = [output length] - range_deps.location;
		}
		
		NSMutableArray<NSString *> __block *dependencies = [NSMutableArray new];
		
		[output enumerateSubstringsInRange:range_deps
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
	if (range_opts.location != NSNotFound)
	{
		NSString *optionsString = [output substringFromIndex:range_opts.length+range_opts.location+1];
		NSMutableArray *options = [NSMutableArray arrayWithCapacity:10];
		
		range_cvts = [optionsString rangeOfString:kCiIdentifierCaveats];
		
		if (range_cvts.location != NSNotFound) {
			optionsString = [optionsString substringToIndex:range_cvts.location];
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

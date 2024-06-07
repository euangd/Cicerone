//
//  COFormulaOption.m
//  Cicerone
//
//  Created by Marek Hrusovsky on 09/10/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import "COFormulaOption.h"

static NSString *const kCOFormulaOptionNameKey = @"formulaOptionName";
static NSString *const kCOFormulaOptionExplanationKey = @"formulaOptionExplanation";

@implementation COFormulaOption

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self) {
		_name = [aDecoder decodeObjectOfClass:[NSString class] forKey:kCOFormulaOptionNameKey];
		_explanation = [aDecoder decodeObjectOfClass:[NSString class] forKey:kCOFormulaOptionExplanationKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.name forKey:kCOFormulaOptionNameKey];
	[aCoder encodeObject:self.explanation forKey:kCOFormulaOptionExplanationKey];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	COFormulaOption *option = [[[self class] allocWithZone:zone] init];
	if (option)
	{
		option->_name = [self->_name  copy];
		option->_explanation = [self->_explanation copy];
	}
	return option;
}

@end

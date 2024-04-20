//
//  CiFormulaOption.m
//  Cicerone
//
//  Created by Marek Hrusovsky on 09/10/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import "CiFormulaOption.h"

static NSString *const kCiFormulaOptionNameKey = @"formulaOptionName";
static NSString *const kCiFormulaOptionExplanationKey = @"formulaOptionExplanation";

@implementation CiFormulaOption

+ (BOOL)supportsSecureCoding
{
	return YES;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	self = [super init];
	if (self) {
		_name = [aDecoder decodeObjectOfClass:[NSString class] forKey:kCiFormulaOptionNameKey];
		_explanation = [aDecoder decodeObjectOfClass:[NSString class] forKey:kCiFormulaOptionExplanationKey];
	}
	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.name forKey:kCiFormulaOptionNameKey];
	[aCoder encodeObject:self.explanation forKey:kCiFormulaOptionExplanationKey];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
	CiFormulaOption *option = [[[self class] allocWithZone:zone] init];
	if (option)
	{
		option->_name = [self->_name  copy];
		option->_explanation = [self->_explanation copy];
	}
	return option;
}

@end

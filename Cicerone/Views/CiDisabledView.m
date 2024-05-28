//
//  CiDisabledView.m
//
//
//  Created by Marek Hrusovsky on 26/08/15.
//
//

#import "CiDisabledView.h"

@interface CiDisabledView()

@property (strong) IBOutlet NSView *view;

@end


@implementation CiDisabledView

- (instancetype)initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	if (self) {
		[self commonInit];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self commonInit];
	}
	return self;
}

- (void)commonInit
{
	NSNib *nib = [[NSNib alloc] initWithNibNamed:@"CiDisabledView" bundle:nil];
	[nib instantiateWithOwner:self topLevelObjects:NULL];
	[self addSubview:self.view];
	
	self.view.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self addConstraint:[self pin:self.view attribute:NSLayoutAttributeTop]];
	[self addConstraint:[self pin:self.view attribute:NSLayoutAttributeLeft]];
	[self addConstraint:[self pin:self.view attribute:NSLayoutAttributeBottom]];
	[self addConstraint:[self pin:self.view attribute:NSLayoutAttributeRight]];
}

- (NSLayoutConstraint *)pin:(id)item attribute:(NSLayoutAttribute)attribute
{
	return [NSLayoutConstraint constraintWithItem:self
										attribute:attribute
										relatedBy:NSLayoutRelationEqual
										   toItem:item
										attribute:attribute
									   multiplier:1.0
										 constant:0.0];
}


@end

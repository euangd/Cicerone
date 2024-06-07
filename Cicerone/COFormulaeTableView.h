//
//  COFormulaeTableView.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 04/09/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import "COHomebrewInterface.h"
#import <Cocoa/Cocoa.h>

extern NSString * const kColumnIdentifierVersion;
extern NSString * const kColumnIdentifierLatestVersion;
extern NSString * const kColumnIdentifierStatus;
extern NSString * const kColumnIdentifierName;

@interface COFormulaeTableView : NSTableView

@property (nonatomic, assign) COListMode mode;

@end

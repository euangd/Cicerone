//
//  CiUpdateViewController.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 24/08/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CiHomebrewViewController.h"

@interface CiUpdateViewController : NSViewController

@property (weak) CiHomebrewViewController *homebrewViewController;

- (IBAction)runStopUpdate:(id)sender;

@end

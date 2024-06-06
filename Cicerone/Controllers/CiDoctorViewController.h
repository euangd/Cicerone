//
//  CiDoctorViewController.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 24/08/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CiHomebrewViewController.h"

@interface CiDoctorViewController : NSViewController

@property (weak) CiHomebrewViewController *homebrewViewController;

- (IBAction)runStopDoctor:(id)sender;

@end

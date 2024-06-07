//
//  CODoctorViewController.h
//  Cicerone
//
//  Created by Marek Hrusovsky on 24/08/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "COHomebrewViewController.h"

@interface CODoctorViewController : NSViewController

@property (weak) COHomebrewViewController *homebrewViewController;

- (IBAction)runStopDoctor:(id)sender;

@end

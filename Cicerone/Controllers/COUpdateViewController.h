//
//  COUpdateViewController.h
//  Bruh
//
//  Created by Marek Hrusovsky on 24/08/14.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "COHomebrewViewController.h"

@interface COUpdateViewController : NSViewController

@property (weak) COHomebrewViewController *homebrewViewController;

- (IBAction)runStopUpdate:(id)sender;

@end

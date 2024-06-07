//
//  COBundleWindowController.h
//  Bruh
//
//  Created by Bruno Philipe on 20/02/16.
//  Copyright © 2016 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface COBundleWindowController : NSWindowController

+ (COBundleWindowController*)runImportOperationWithFile:(NSURL*)fileURL;
+ (COBundleWindowController*)runExportOperationWithFile:(NSURL*)fileURL;

@end

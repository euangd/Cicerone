//
//  CiBundleWindowController.h
//  Cicerone
//
//  Created by Bruno Philipe on 20/02/16.
//  Copyright © 2016 Bruno Philipe. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CiBundleWindowController : NSWindowController

+ (CiBundleWindowController*)runImportOperationWithFile:(NSURL*)fileURL;
+ (CiBundleWindowController*)runExportOperationWithFile:(NSURL*)fileURL;

@end

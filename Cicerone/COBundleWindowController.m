//
//  COBundleWindowController.m
//  Cicerone
//
//  Created by Bruno Philipe on 20/02/16.
//  Copyright © 2016 Bruno Philipe. All rights reserved.
//

#import "COBundleWindowController.h"
#import "COAppDelegate.h"
#import "COHomebrewInterface.h"

@interface COBundleWindowController ()

@property (strong) IBOutlet NSView *viewOperationContainer;

@property (strong) IBOutlet NSView *viewExportProgress;
@property (strong) IBOutlet NSView *viewImportProgress;

@property (strong) IBOutlet NSTextView *textViewImport;
@property (strong) IBOutlet NSTextField *progressLabelImport;
@property (strong) IBOutlet NSImageView *statusViewExport;
@property (strong) IBOutlet NSTextField *statusLabelExport;
@property (strong) IBOutlet NSTextField *progressLabelExport;

@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSButton *buttonClose;

@property (nonatomic, copy) void (^windowLoadedBlock)(void);
@property (nonatomic, copy) void (^operationBlock)(void);

@property (strong) NSMutableString *importOutputString;

@end

@implementation COBundleWindowController

+ (COBundleWindowController*)runImportOperationWithFile:(NSURL*)fileURL
{
	COBundleWindowController *controller = [self createWindow];
	__weak COBundleWindowController *weakController = controller;
	
	[controller setWindowLoadedBlock:^{
		[weakController embedView:[weakController viewImportProgress]];
	}];
	
	[COAppDelegateRef setRunningBackgroundTask:YES];
	
	[controller startSheetOnMainWindow];
	[controller runImportOperationWithFile:fileURL];
	
	return controller;
}

+ (COBundleWindowController*)runExportOperationWithFile:(NSURL*)fileURL
{
	COBundleWindowController *controller = [self createWindow];
	__weak COBundleWindowController *weakController = controller;
	
	[controller setWindowLoadedBlock:^{
		[weakController embedView:[weakController viewExportProgress]];
	}];
	
	[COAppDelegateRef setRunningBackgroundTask:YES];
	
	[controller startSheetOnMainWindow];
	[controller runExportOperationWithFile:fileURL];
	
	return controller;
}

+ (COBundleWindowController*)createWindow
{
	return [[COBundleWindowController alloc] initWithWindowNibName:@"COBundleWindow"];
}

- (void)windowDidLoad
{
	if (self.windowLoadedBlock)
	{
		self.windowLoadedBlock();
		[self setWindowLoadedBlock:nil];
	}
	
	[self.progressIndicator startAnimation:nil];
}

- (void)startSheetOnMainWindow
{
	[[NSApp mainWindow] beginSheet:self.window completionHandler:^(NSModalResponse returnCode) {
		[COAppDelegateRef setRunningBackgroundTask:NO];
	}];
}

- (void)runImportOperationWithFile:(NSURL*)fileURL
{
	self.importOutputString = [NSMutableString new];
	__weak COBundleWindowController *weakSelf = self;
	
	[self.importOutputString appendString:[[COHomebrewInterface sharedInterface] importWithPath:[fileURL path]]];
    [weakSelf.textViewImport performSelectorOnMainThread:@selector(setString:)
                                              withObject:self.importOutputString
                                           waitUntilDone:YES];
	
	[self.progressLabelImport setHidden:YES];
	[self.buttonClose setEnabled:YES];
	[self.progressIndicator stopAnimation:nil];
}

- (void)runExportOperationWithFile:(NSURL*)fileURL
{
	NSError *error = [[COHomebrewInterface sharedInterface] exportWithPath:[fileURL path]];
	
	if (error)
	{
		[self.statusLabelExport setStringValue:@"Export Failed"];
		[self.statusViewExport setImage:[NSImage imageNamed:@"status_Error"]];
		[self.progressLabelExport setStringValue:[error localizedDescription]];
		[self.progressLabelExport setHidden:NO];
		
		NSLog(@"%@", error.localizedDescription);
	}
	else
	{
		[self.progressLabelExport setHidden:YES];
	}
	
	[self.statusLabelExport setHidden:NO];
	[self.statusViewExport setHidden:NO];
	[self.buttonClose setEnabled:YES];
	[self.progressIndicator stopAnimation:nil];
}

- (void)windowOperationSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
	[sheet orderOut:self];
	[COAppDelegateRef setRunningBackgroundTask:NO];
}

- (void)embedView:(NSView*)view
{
	[view setTranslatesAutoresizingMaskIntoConstraints:NO];
	
	[self.viewOperationContainer addSubview:view];
	
	[self.viewOperationContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0-|"
																						options:0
																						metrics:nil
																						  views:@{@"view": view}]];
	
	[self.viewOperationContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|"
																						options:0
																						metrics:nil
																						  views:@{@"view": view}]];
	
	[self.viewOperationContainer setNeedsLayout:YES];
}

- (IBAction)didClickClose:(id)sender
{
	NSWindow *mainWindow = [NSApp mainWindow];
	
	if ([mainWindow respondsToSelector:@selector(endSheet:)])
	{
		[mainWindow endSheet:self.window];
	}
	else
	{
		[[NSApplication sharedApplication] endSheet:self.window];
	}
}

@end

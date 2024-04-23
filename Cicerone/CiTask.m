
//	BrewInterface.h
//	Cicerone – The Homebrew GUI App for OS X
//
//  Created by Marek Hrusovsky on 24/08/15.
//	Copyright (c) 2014 Bruno Philipe. All rights reserved.
//
//	This program is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	This program is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "CiTask.h"
#import "Categories/NSString+Summarization.h"

NSString *const kDidBeginBackgroundActivityNotification	= @"DidBeginBackgroundActivityNotification";
NSString *const kDidEndBackgroundActivityNotification	= @"DidEndBackgroundActivityNotification";

@interface CiTask()
{
    BOOL halting;
    id launchLock;
    
	id activity;
	NSFileHandle *standardOutputFileHandle;
	NSFileHandle *standardErrorFileHandle;
	NSMutableData *standardOutputData;
	NSMutableData *standardErrorData;
	int standardOutputDataNextWritePosition;
	int standardErrorDataNextWritePosition;
    dispatch_group_t processingDispatchGroup;
}

@property (nonatomic, strong) NSTask *coreTask;

// todo: standard input

@property (nonatomic, strong) NSPipe *standardOutputPipe, *standardErrorPipe;

// public
@property (readwrite, nonatomic) BOOL ran;

@property (readwrite, nonatomic, strong) NSString *executablePath;
@property (readwrite, nonatomic, strong) NSArray *executableArguments;

@end

@implementation CiTask

- (instancetype)initWithPath:(NSString *)path withArguments:(NSArray *)arguments
{
    assert(path);
    
	self = [super init];
	if (self)
	{
        launchLock = [[NSObject alloc] init];
        
        _executablePath = path;
        _executableArguments = arguments;
        
		#ifdef DEBUG
        NSLog(@"task: %@ %@", path, [arguments componentsJoinedByString:@" "]);
		#endif
	}
	return self;
}

- (void)setCoreTask:(NSTask *)coreTask
{
    _coreTask = coreTask;
    
    [coreTask setLaunchPath:_executablePath];
    [coreTask setArguments:_executableArguments];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskDidTerminate:)
                                                 name:NSTaskDidTerminateNotification object:_coreTask];
}

- (void)setStandardOutputPipe:(NSPipe *)standardOutputPipe
{
    _standardOutputPipe = standardOutputPipe;
    
    standardOutputData = [[NSMutableData alloc] init];
    standardOutputDataNextWritePosition = 0;
    
    [self.coreTask setStandardOutput:standardOutputPipe];
    
    standardOutputFileHandle = [standardOutputPipe fileHandleForReading];
    [standardOutputFileHandle waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveStandardOutputFileHandleDataAvailableNotification:) name:NSFileHandleDataAvailableNotification
                                               object:standardOutputFileHandle];
}

- (void)setStandardErrorPipe:(NSPipe *)standardErrorPipe
{
    _standardErrorPipe = standardErrorPipe;
    
    standardErrorData = [[NSMutableData alloc] init];
    standardErrorDataNextWritePosition = 0;
    
    [self.coreTask setStandardError:standardErrorPipe];
    standardErrorFileHandle = [standardErrorPipe fileHandleForReading];
    
    [standardErrorFileHandle waitForDataInBackgroundAndNotify];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveStandardErrorFileHandleDataAvailableNotification:) name:NSFileHandleDataAvailableNotification
                                               object:standardErrorFileHandle];
}

// waitUntilExit makes sure that we stay in the same run loop (thread); needed for notifications

- (int)runToExitReturningStandardOutput:(out NSString * __autoreleasing *)standardOutput returningStandardError:(out NSString * __autoreleasing *)standardError
{
	@try {
        @synchronized (self) {
            processingDispatchGroup = dispatch_group_create();
            dispatch_group_enter(processingDispatchGroup);
            
            [self beginActivity];
            
            self.coreTask = [[NSTask alloc] init];
            
            self.standardOutputPipe = [NSPipe pipe];
            self.standardErrorPipe = [NSPipe pipe];
            
            @synchronized (launchLock) {
                if (halting) {
                    return -1;
                }
                
                NSError *error = nil;
                
                if (![self.coreTask launchAndReturnError:&error]) {
                    @throw [NSException exceptionWithName:@"MyCustomException"
                                                   reason:@"Something went wrong"
                                                 userInfo:@{ @"error": error }];
                }
                
                self.ran = true;
            }
            
            [self.coreTask waitUntilExit];
            dispatch_group_wait(processingDispatchGroup, DISPATCH_TIME_FOREVER);
            
            if (standardOutput) {
                [self readOutStandardOutputFileHandle:standardOutputFileHandle];
                (*standardOutput) = [[NSString alloc] initWithData:standardOutputData encoding:NSUTF8StringEncoding];
            }
            
            if (standardError) {
                [self readOutStandardErrorFileHandle:standardErrorFileHandle];
                (*standardError) = [[NSString alloc] initWithData:standardErrorData encoding:NSUTF8StringEncoding];
            }
            
            [self endActivity];
            self.ran = false;
            
            return [self.coreTask terminationStatus];
        }
	}
	@catch (NSException *exception) {
		NSLog(@"Exception: %@", exception);
        
        NSDictionary *userInfo = exception.userInfo;
        
        if (userInfo) {
            NSError *error = userInfo[@"error"];
            
            if (error) {
                NSLog(@"Error: %@", error);
            }
        }
        
		return -1;
    } @finally {
        [self halt];
    }
}

// these used to the same method but there was no point because it just compared the received file handle to each receiver handle
// todo consider sanity-checking the respective file handles against what is already stored

- (void)receiveStandardOutputFileHandleDataAvailableNotification:(NSNotification *)notification
{
    [self readOutStandardOutputFileHandle:[notification object]];
}

- (void)readOutStandardOutputFileHandle:(NSFileHandle *)fileHandle
{
    standardOutputDataNextWritePosition += [self readOutFileHandle:fileHandle toAggregateData:standardOutputData];
}

- (void)receiveStandardErrorFileHandleDataAvailableNotification:(NSNotification *)notification
{
    [self readOutStandardErrorFileHandle:[notification object]];
}

- (void)readOutStandardErrorFileHandle:(NSFileHandle *)fileHandle
{
    standardErrorDataNextWritePosition += [self readOutFileHandle:fileHandle toAggregateData:standardErrorData];
}

- (NSUInteger)readOutFileHandle:(NSFileHandle *)fileHandle toAggregateData:(NSMutableData *)aggregateData
{
    @synchronized (aggregateData) {
        dispatch_group_enter(processingDispatchGroup);
        
        @try {
            NSData *data = [fileHandle readDataToEndOfFile];
            [aggregateData appendData:data];
            return data.length + 1;
        } @finally {
            dispatch_group_leave(processingDispatchGroup);
        }
    }
}

// this method used to send a result update via dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{ });

- (void)taskDidTerminate:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"async cmd: %@ %@",  [self.coreTask launchPath], [[self.coreTask arguments] componentsJoinedByString:@" "]);
    NSLog(@"\tcode = %d", [self.coreTask terminationStatus]);
#endif
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self endActivity];
    dispatch_group_leave(processingDispatchGroup);
}

// the system will always have app nap on modern targets. using the terminology app nap because that's what the variable used to be called; supposedly the gated features were introduced with app nap? there used to be a check: [[NSProcessInfo processInfo] respondsToSelector:@selector(beginActivityWithOptions:reason:)]

- (void)beginActivity
{
    
    activity = [[NSProcessInfo processInfo] beginActivityWithOptions:NSActivityUserInitiated | NSActivityLatencyCritical // latency-critical because usually there's a loading indicator and that should go away as quickly as possible
                                                              reason:NSLocalizedString(@"Homebrew_AppNap_Task_Reason", nil)];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidBeginBackgroundActivityNotification object:self];
}

- (void)endActivity
{
    [[NSProcessInfo processInfo] endActivity:activity];
    activity = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidEndBackgroundActivityNotification object:self];
}

- (void)halt
{
    // if the task is running, send sigterm, then wait for task data plumbing to stop... or now just secure the self lock as fast as possible, then wait for sync run to stop, then deinitialize
    // this is done through making sure that if the task is not yet running, it will see the attempt to halt as soon as it tries to start and then exit, or if the task is running it will sigterm
    // halting = true is basically a screwy way to seize the self lock with the launchLock, because if this code does need to wait for the self lock the launch lock will also be hit, where it checks halting and exits.
    
    @synchronized (launchLock) {
        halting = true;
        
        if (self.ran) {
            [self.coreTask terminate];
        }
    }
    
    @synchronized (self) {
        if (activity) {
            [self endActivity];
        }
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        standardOutputData = nil;
        standardErrorData = nil;
        standardOutputFileHandle = nil;
        standardErrorFileHandle = nil;
        _standardOutputPipe = nil;
        _standardErrorPipe = nil;
        
        activity = nil;
        
        halting = false;
    }
}

- (void)dealloc
{
    [self halt];
    
    self.executableArguments = nil;
    self.executablePath = nil;
    
    processingDispatchGroup = nil;
}

@end

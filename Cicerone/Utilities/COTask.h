//
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

#import <Foundation/Foundation.h>

extern NSString * _Nonnull const kDidBeginBackgroundActivityNotification;
extern NSString * _Nonnull const kDidEndBackgroundActivityNotification;

@class COTask;

// this class used to use an output notification protocol, checked with [self.delegate respondsToSelector:@selector(task:didFinishWithOutput:error:)]

@interface COTask : NSObject

- (_Nonnull instancetype)initWithPath:(NSString * _Nonnull)path
                        withArguments:(NSArray * _Nonnull)arguments;
- (int)runToExitReturningStandardOutput:(out NSString * _Nullable * _Nullable)standardOutput returningStandardError:(out NSString * _Nullable * _Nullable)standardError;
- (void)halt;

@property (strong, readonly, nonnull) NSString *executablePath;
@property (strong, readonly, nonnull) NSArray *executableArguments;
@property (readonly) BOOL ran;

@end

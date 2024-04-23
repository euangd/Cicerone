//
//  NSString+Summarization.m
//  Cicerone
//
//  Created by Alexander Yan on 2024-04-21.
//  Copyright © 2024 oaVa-o. All rights reserved.
//

#import "NSString+Summarization.h"

@implementation NSString (Summarization)

// https://sl.bing.net/dqm5JEJs8mi
// https://sl.bing.net/iueWaF92JQi

- (NSString *)summarizedString {
    NSArray *lines = [self componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    if (lines.count > 10) {
        NSArray *firstEightLines = [lines subarrayWithRange:NSMakeRange(0, 8)];
        NSString *lastLine = [lines lastObject];
        NSUInteger omittedLinesCount = lines.count - 9;
        
        NSString *summary = [NSString stringWithFormat:@"%@\n… (%lu more lines) \n%@",
                             [firstEightLines componentsJoinedByString:@"\n"],
                             (unsigned long)omittedLinesCount,
                             lastLine];
        return summary;
    }
    
    return self;
}

@end

//
//  CiSourceListTableCellView.h
//  Cicerone
//
//  Created by Alexander Yan on 2024-05-29.
//  Copyright © 2024 oaVa-o. All rights reserved.
//

#import <PXSourceList/PXSourceList.h>
#import "Cocoa/Cocoa.h"

NS_ASSUME_NONNULL_BEGIN

@interface CiSourceListTableCellView : PXSourceListTableCellView

@property (strong) IBOutlet NSProgressIndicator *loadingIndicator;
@property (getter=isLoading, nonatomic) BOOL loading;

@end

NS_ASSUME_NONNULL_END

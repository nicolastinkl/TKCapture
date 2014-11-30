//
//  TKAssetsViewController.h
//  TKCapture
//
//  Created by tinkl on 30/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "TKProtocol.h"

@interface TKAssetsViewController : UICollectionViewController<TKAssetsProtocol>

@property (nonatomic, strong) ALAssetsGroup *assetsGroup;

@end

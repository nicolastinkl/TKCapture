//
//  TKAssetsSupplementaryView.h
//  TKCapture
//
//  Created by tinkl on 30/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//
#import <UIKit/UIKit.h>

@interface TKAssetsSupplementaryView : UICollectionReusableView

@property (nonatomic, strong) UILabel *sectionLabel;

- (void)setNumberOfPhotos:(NSInteger)numberOfPhotos numberOfVideos:(NSInteger)numberOfVideos;

@end
//
//  TKAssetsSupplementaryView.m
//  TKCapture
//
//  Created by tinkl on 30/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKAssetsSupplementaryView.h"

@interface TKAssetsSupplementaryView ()

@end

#pragma mark - TKAssetsSupplementaryView

@implementation TKAssetsSupplementaryView

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        _sectionLabel               = [[UILabel alloc] initWithFrame:CGRectInset(self.bounds, 8.0, 8.0)];
        _sectionLabel.font          = [UIFont systemFontOfSize:18.0];
        _sectionLabel.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:_sectionLabel];
    }
    
    return self;
}

- (void)setNumberOfPhotos:(NSInteger)numberOfPhotos numberOfVideos:(NSInteger)numberOfVideos
{
    NSString *title;
    
    if (numberOfVideos == 0)
        title = [NSString stringWithFormat:@"%ld 张照片", (long)numberOfPhotos];
    else if (numberOfPhotos == 0)
        title = [NSString stringWithFormat:@"%ld 个视频", (long)numberOfVideos];
    else
        title = [NSString stringWithFormat:@"%ld 张照片, %ld 个视频", (long)numberOfPhotos, (long)numberOfVideos];
    
    self.sectionLabel.text = title;
}

@end
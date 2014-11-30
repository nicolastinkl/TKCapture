//
//  TKProtocol.h
//  TKCapture
//
//  Created by tinkl on 29/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

/*!
 *  @author tinkl, 14-11-29 18:11:49
 *
 *  全局所有objection界面protocol
 *
 *  @since 1.0.1
 */
@protocol TKProtocol <NSObject>

@end

/*!
 *  拍照protocol
 */
@protocol TKCameraProtocol <NSObject>

@end

/*!
 *  相册protocol
 */
@protocol TKAlbumProtocol <NSObject>

@end

/*!
 *  相册组 protocol
 */
@protocol TKAlbumGroupProtocol <NSObject>

@end

/*!
 *  相册view protocol
 */
@protocol TKAssetsProtocol <NSObject>
-(void) fillAssetsGroup:(ALAssetsGroup *)assetsGroup;
@end

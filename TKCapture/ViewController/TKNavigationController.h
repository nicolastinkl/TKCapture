//
//  TKNavigationController.h
//  TKCapture
//
//  Created by tinkl on 29/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import <UIKit/UIKit.h>


/*!
 *  @author tinkl, 14-11-29 18:11:28
 *
 *  重写Navigation控制器，处理状态栏和拍照后跳转逻辑
 *
 *  @since 1.0.1
 */
@interface TKNavigationController : UINavigationController

- (void)showController:(UIViewController*)pController;

@end

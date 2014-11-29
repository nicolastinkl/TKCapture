//
//  TKNavigationController.m
//  TKCapture
//
//  Created by tinkl on 29/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKNavigationController.h"
#import "TKUtilsMacro.h"
#import "TKProtocol.h"
#import <Objection.h>

@interface TKNavigationController ()

@property (nonatomic, assign) BOOL statusBarHidden;

@end

@implementation TKNavigationController
@synthesize statusBarHidden = _statusBarHidden;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationBarHidden = YES;
    self.hidesBottomBarWhenPushed = YES;
    _statusBarHidden = [UIApplication sharedApplication].statusBarHidden;
    
    if ([UIApplication sharedApplication].statusBarHidden == NO) {
        if (IOS7) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }
    }
}

/*!
 *  @author tinkl, 14-11-29 18:11:49
 *
 *  开始拍照主界面
 *
 *  @param pController parent view controller
 *
 *  @since 1.0.1
 */
- (void)showController:(UIViewController*)pController
{
    /*
     * TODO:    Get TKTakePhotoViewController object
     * example : develop by dev1 or dev2...
     */
    UIViewController * viewController = [[JSObjection defaultInjector] getObject:@protocol(TKCameraProtocol)];
    [self setViewControllers:@[viewController]];
    [pController presentViewController:self animated:YES completion:nil];
    
}


- (void)dealloc {
    //status bar
    if ([UIApplication sharedApplication].statusBarHidden != _statusBarHidden) {
        if (IOS7) {
            [[UIApplication sharedApplication] setStatusBarHidden:_statusBarHidden withAnimation:UIStatusBarAnimationSlide];
        }
        
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
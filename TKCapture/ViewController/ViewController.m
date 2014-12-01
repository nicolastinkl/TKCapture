//
//  ViewController.m
//  TKCapture
//
//  Created by tinkl on 28/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import "ViewController.h"
#import "TKProtocol.h"
#import <Objection.h>
@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIButton *TKBtn_Camera;

@property (weak, nonatomic) IBOutlet UIButton *TKBtn_Album;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
}

/*!
 *  @author tinkl, 14-11-29 16:11:32
 *
 *  拍照
 *
 *  @since 1.0.1
 */
-(IBAction)TKTakePhotoAction:(id)sender
{
    
    UIViewController * viewController = [[JSObjection defaultInjector] getObject:@protocol(TKCameraProtocol)];
    UINavigationController* navigation = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentViewController:navigation animated:YES completion:^{
        
    }];
}

/*!
 *  @author tinkl, 14-11-29 16:11:35
 *
 *  查看相册
 *
 *  @since 1.0.1
 */
-(IBAction)TKSeeAlbumAction:(id)sender
{
    
    UINavigationController*  viewController = [[JSObjection defaultInjector] getObject:@protocol(TKAlbumProtocol)];
    [self presentViewController:viewController animated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

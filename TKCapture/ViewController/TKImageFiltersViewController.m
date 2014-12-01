//
//  TKImageFiltersViewController.m
//  TKCapture
//
//  Created by tinkl on 1/12/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKImageFiltersViewController.h"
#import <Objection.h>
#import <TKUtilsMacro.h>


@interface TKImageFiltersViewController ()<UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) UIImageView *imageView;
@property (nonatomic, strong) UIImage *orgImage;
@property (nonatomic, strong) NSArray *items;

@end


@implementation TKImageFiltersViewController

-(instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}


- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    /*!
     *  @author tinkl, 14-12-01 14:12:46
     *
     *  See Apple document : https://developer.apple.com/library/mac/documentation/GraphicsImaging/Reference/CoreImageFilterReference/index.html
     *
     *  @since 1.0.2
     */
    self.items = @[@"原图",
                   @"CIPhotoEffectChrome",
                   @"CIPhotoEffectFade",
                   @"CIPhotoEffectInstant",
                   @"CIPhotoEffectMono",
                   @"CIPhotoEffectNoir",
                   @"CIPhotoEffectProcess",
                   @"CIPhotoEffectTonal",
                   @"CIPhotoEffectTransfer"];
   
    
    //init UI
    UIImageView * mImageView    = [[UIImageView alloc] init];
    mImageView.frame            = self.view.frame;
    self.imageView              = mImageView;
    
    UIPickerView * pickView     = [[UIPickerView alloc] init];
    pickView.delegate           = self;
    pickView.dataSource         = self;
    pickView.center             = self.view.center;

    UIButton * closeButton      = [UIButton buttonWithType:UIButtonTypeCustom];
    [closeButton setBackgroundImage:[UIImage imageNamed:@"close_cha_h"] forState:UIControlStateNormal];
    closeButton.showsTouchWhenHighlighted   = YES;
    [closeButton addTarget:self action:@selector(closeSelfView:) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setFrame:CGRectMake(20, 20, 50, 50)];
    
    [self.view addSubview:mImageView];
    [self.view addSubview:pickView];
    [self.view addSubview:closeButton];
    
    //fill image
    self.imageView.image = self.orgImage;

}

-(IBAction)closeSelfView:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

-(void) fitlersImage:(UIImage *) image
{
    self.orgImage = image;
    self.imageView.image = self.orgImage;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    
    return self.items.count;
}


#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return self.items[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    if (row == 0) {
        
        self.imageView.image = self.orgImage;
        
        return;
    }
    
    [self filterImageWithCGImageIndex:row];
    
}

/*!
 *  @author tinkl, 14-12-01 14:12:23
 *
 *  滤镜处理
 *
 *  @param row 行
 *
 *  @since 1.0.2
 */
-(void) filterImageWithCGImageIndex:(NSInteger) row
{
    
 
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        CIImage *ciImage = [[CIImage alloc] initWithImage:self.orgImage];
        
        CIFilter *filter = [CIFilter filterWithName:self.items[row]
                                      keysAndValues:kCIInputImageKey, ciImage, nil];
        [filter setDefaults];
        
        CIContext *context = [CIContext contextWithOptions:nil];
        CIImage *outputImage = [filter outputImage];
        CGImageRef cgImage = [context createCGImage:outputImage
                                           fromRect:[outputImage extent]];
        
        
        __block UIImageView* imageBlock = self.imageView;
        [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^
        {
            imageBlock.image = [UIImage imageWithCGImage:cgImage];
            self.imageView.alpha = 0.6f;    
        } completion:^(BOOL finished) {
            
            self.imageView.alpha = 1.0f;
            
        }];
        
        CGImageRelease(cgImage);
    });
}

@end
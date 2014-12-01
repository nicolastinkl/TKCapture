//
//  TKCaptureSessionManager.h
//  TKCapture
//
//  Created by tinkl on 29/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#define MAX_PINCH_SCALE_NUM   3.f
#define MIN_PINCH_SCALE_NUM   1.f

@protocol TKCaptureSessionManager;

typedef void(^DidCapturePhotoBlock)(UIImage *stillImage);

@interface TKCaptureSessionManager : NSObject

//property
@property (nonatomic) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureDeviceInput *inputDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, assign) CGFloat preScaleNum;
@property (nonatomic, assign) CGFloat scaleNum;
@property (nonatomic, assign) id <TKCaptureSessionManager> delegate;


//function
- (void)configureWithParentLayer:(UIView*)parent previewRect:(CGRect)preivewRect;
- (void)takePicture:(DidCapturePhotoBlock)block;
- (void)switchCamera:(BOOL)isFrontCamera;
- (void)switchFlashMode:(UIButton*)sender;
- (void)focusInPoint:(CGPoint)devicePoint;
- (void)switchCaptureSession:(int) index;

@end


@protocol TKCaptureSessionManager <NSObject>

@optional
- (void)didCapturePhoto:(UIImage*)stillImage;

@end

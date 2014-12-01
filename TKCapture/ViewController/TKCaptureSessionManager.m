//
//  TKCaptureSessionManager.m
//  TKCapture
//
//  Created by tinkl on 29/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.

#import "TKCaptureSessionManager.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+Resize.h"
#import "TKUtilsMacro.h"

/*!
 *  @author tinkl, 14-11-29 22:11:29
 *
 *  处理系统功能切换逻辑
 *
 *  @since 1.0.1
 */
@interface TKCaptureSessionManager ()

@property (nonatomic, strong) UIView *preview;

@end

@implementation TKCaptureSessionManager


#pragma mark configure
- (id)init {
    self = [super init];
    if (self != nil) {
        _scaleNum = 1.f;
        _preScaleNum = 1.f;
    }
    return self;
}

- (void)dealloc {
    [_session stopRunning];
    self.previewLayer = nil;
    self.session = nil;
    self.stillImageOutput = nil;
}

/*!
 *  @author tinkl, 14-11-29 22:11:55
 *
 *  init function
 *
 *  @param parent      parent view
 *  @param preivewRect rect for subview
 *
 *  @since 1.0.1
 */
- (void)configureWithParentLayer:(UIView*)parent previewRect:(CGRect)preivewRect {
    
    self.preview = parent;
    
    //1、queue
    [self createQueue];
    
    //2、session
    [self addSession];
    
    //3、previewLayer
    [self addVideoPreviewLayerWithRect:preivewRect];
    [parent.layer addSublayer:_previewLayer];
    
    //4、input
    [self addVideoInputFrontCamera:NO];
    
    //5、output
    [self addStillImageOutput];
    
}

/**
 *  @author tinkl, 14-11-29 22:11:23
 *
 *  create queue
 *
 *  @return return value description
 *
 *  @since 1.0.1
 */
- (void)createQueue {
	dispatch_queue_t sessionQueue = dispatch_queue_create("tk_session_queue", DISPATCH_QUEUE_SERIAL);
    self.sessionQueue = sessionQueue;
}


- (void)addSession {
    AVCaptureSession *tmpSession = [[AVCaptureSession alloc] init];
    self.session = tmpSession;
    //设置质量
//    _session.sessionPreset = AVCaptureSessionPresetiFrame960x540;
}

/*!
 *  @author tinkl, 14-11-29 22:11:08
 *
 *  camera preview
 *
 *  @param previewRect 预览页面的frame
 *
 *
 *  @since 1.0.1
 */
- (void)addVideoPreviewLayerWithRect:(CGRect)previewRect {
    
    AVCaptureVideoPreviewLayer *preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = previewRect;
    self.previewLayer = preview;
}

/*!
 *  @author tinkl, 14-11-29 22:11:19
 *
 *   *  add video
 *
 *  @param front 前或后摄像头
 *
 *  @since 1.0.1
 */
- (void)addVideoInputFrontCamera:(BOOL)front {
    
    NSArray *devices = [AVCaptureDevice devices];
    AVCaptureDevice *frontCamera;
    AVCaptureDevice *backCamera;
    
    for (AVCaptureDevice *device in devices) {
        
        SLog(@"Device name: %@", [device localizedName]);
        
        if ([device hasMediaType:AVMediaTypeVideo]) {
            
            if ([device position] == AVCaptureDevicePositionBack) {
                SLog(@"Device position : back");
                backCamera = device;
                
            }  else {
                SLog(@"Device position : front");
                frontCamera = device;
            }
        }
    }
    
    NSError *error = nil;
    
    if (front) {
        AVCaptureDeviceInput *frontFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:frontCamera error:&error];
        if (!error) {
            if ([_session canAddInput:frontFacingCameraDeviceInput]) {
                [_session addInput:frontFacingCameraDeviceInput];
                self.inputDevice = frontFacingCameraDeviceInput;
                
            } else {
                SLog(@"Couldn't add front facing video input");
            }
        }
    } else {
        AVCaptureDeviceInput *backFacingCameraDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:backCamera error:&error];
        if (!error) {
            if ([_session canAddInput:backFacingCameraDeviceInput]) {
                [_session addInput:backFacingCameraDeviceInput];
                self.inputDevice = backFacingCameraDeviceInput;
            } else {
                SLog(@"Couldn't add back facing video input");
            }
        }
    }
}

/*!
 *  @author tinkl, 14-11-29 22:11:31
 *
 *  添加输出
 *
 *  @since 1.0.1
 */
- (void)addStillImageOutput {
    
    AVCaptureStillImageOutput *tmpOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];//output jpeg
    tmpOutput.outputSettings = outputSettings;
    [_session addOutput:tmpOutput];
    self.stillImageOutput = tmpOutput;
}

- (AVCaptureConnection*)findVideoConnection {
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _stillImageOutput.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    return videoConnection;
}

/*!
 *  @author tinkl, 14-11-29 22:11:53
 *
 *  拍照函数
 *
 *  @param block 传入异步队列处理
 *
 *  @since 1.0.1
 */
- (void)takePicture:(DidCapturePhotoBlock)block {
    AVCaptureConnection *videoConnection = [self findVideoConnection];
    
    [videoConnection setVideoScaleAndCropFactor:_scaleNum];
    
	SLog(@"about to request a capture from: %@", _stillImageOutput);
    
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        
        CFDictionaryRef exifAttachments = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
        if (exifAttachments) {
            SLog(@"attachements: %@", exifAttachments);
        } else {
            SLog(@"no attachments");
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        UIImage *image = [[UIImage alloc] initWithData:imageData];
        SLog(@"originImage:%@", [NSValue valueWithCGSize:image.size]);
        
        CGFloat squareLength = SC_APP_SIZE.width;
        CGFloat headHeight = _previewLayer.bounds.size.height - squareLength;
        CGSize size = CGSizeMake(squareLength * 2, squareLength * 2);
        
        UIImage *scaledImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:size interpolationQuality:kCGInterpolationHigh];
        SLog(@"scaledImage:%@", [NSValue valueWithCGSize:scaledImage.size]);
        
        CGRect cropFrame = CGRectMake((scaledImage.size.width - size.width) / 2, (scaledImage.size.height - size.height) / 2 + headHeight, size.width, size.height);
        SLog(@"cropFrame:%@", [NSValue valueWithCGRect:cropFrame]);
        UIImage *croppedImage = [scaledImage croppedImage:cropFrame];
        SLog(@"croppedImage:%@", [NSValue valueWithCGSize:croppedImage.size]);
        
        //调整图片orientation
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation != UIDeviceOrientationPortrait) {
            
            CGFloat degree = 0;
            if (orientation == UIDeviceOrientationPortraitUpsideDown) {
                degree = 180;// M_PI;
            } else if (orientation == UIDeviceOrientationLandscapeLeft) {
                degree = -90;// -M_PI_2;
            } else if (orientation == UIDeviceOrientationLandscapeRight) {
                degree = 90;// M_PI_2;
            }
            croppedImage = [croppedImage rotatedByDegrees:degree];
        }
        
        //block、delegate、notification
        if (block) {
            block(croppedImage);
        } else if ([_delegate respondsToSelector:@selector(didCapturePhoto:)]) {
            [_delegate didCapturePhoto:croppedImage];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kCapturedPhotoSuccessfully object:croppedImage];
        }
    }];
}

- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result = (AVCaptureVideoOrientation)deviceOrientation;
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
		result = AVCaptureVideoOrientationLandscapeRight;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result = AVCaptureVideoOrientationLandscapeLeft;
	return result;
}

/*!
 *  @author tinkl, 14-11-29 22:11:16
 *
 *  切换像素 1:1 16:9  4:3
 *
 *  @param index
 *  @param 先注销
 *  @since 1.0.1
 */
- (void)switchCaptureSession:(int) index {
    /*
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //   异步队列里
        switch (index) {
            case 0:
                _session.sessionPreset = AVCaptureSessionPresetPhoto;
                break;
                
            case 1:
                _session.sessionPreset = AVCaptureSessionPresetiFrame960x540;
                break;
                
            case 2:
                _session.sessionPreset = AVCaptureSessionPresetiFrame1280x720;
                break;
                
            default:
                break;
        }
    });

    */
}

/*!
 *  @author tinkl, 14-11-29 22:11:51
 *
 *  切换前后摄像头
 *
 *  @param isFrontCamera YES:前摄像头  NO:后摄像头
 *
 *  @since 1.0.1
 */
- (void)switchCamera:(BOOL)isFrontCamera {
    if (!_inputDevice) {
        return;
    }
    [_session beginConfiguration];
    
    [_session removeInput:_inputDevice];
    
    [self addVideoInputFrontCamera:isFrontCamera];
    
    [_session commitConfiguration];
}
 

/*!
 *  @author tinkl, 14-11-29 22:11:03
 *
 *  切换闪光灯模式
 *  @param （切换顺序：最开始是auto，然后是off，最后是on，一直循环）
 *  @since 1.0.1
 */
- (void)switchFlashMode:(UIButton*)sender {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (!captureDeviceClass) {
        //no flash mode
        return;
    }
    
    NSString *imgStr = @"";
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    if ([device hasFlash]) {
        if (device.flashMode == AVCaptureFlashModeOff) {
            device.flashMode = AVCaptureFlashModeOn;
            imgStr = @"flashing_on.png";
            
        } else if (device.flashMode == AVCaptureFlashModeOn) {
            device.flashMode = AVCaptureFlashModeAuto;
            imgStr = @"flashing_auto.png";
            
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            device.flashMode = AVCaptureFlashModeOff;
            imgStr = @"flashing_off.png";
            
        }
        
        if (sender) {
            [sender setImage:[UIImage imageNamed:imgStr] forState:UIControlStateNormal];
        }
        
    } else{
        //error ..with no flash mode
    }
    [device unlockForConfiguration];
}

/**
 *  对焦
 *
 *  @param devicePoint 点击的point
 */
- (void)focusInPoint:(CGPoint)devicePoint {
    devicePoint = [self convertToPointOfInterestFromViewCoordinates:devicePoint];
	[self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    
	dispatch_async(_sessionQueue, ^{
		AVCaptureDevice *device = [_inputDevice device];
		NSError *error = nil;
		if ([device lockForConfiguration:&error])
		{
			if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
			{
				[device setFocusMode:focusMode];
				[device setFocusPointOfInterest:point];
			}
			if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
			{
				[device setExposureMode:exposureMode];
				[device setExposurePointOfInterest:point];
			}
			[device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
			[device unlockForConfiguration];
		}
		else
		{
			SLog(@"%@", error);
		}
	});
}

- (void)subjectAreaDidChange:(NSNotification *)notification {
    
	CGPoint devicePoint = CGPointMake(.5, .5);
	[self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

/*!
 *  @author tinkl, 14-11-29 22:11:12
 *
 *  外部的point转换为camera需要的point(外部point/相机页面的frame)
 *
 *  @param viewCoordinates 外部的point
 *
 *  @return 相对位置的point
 *
 *  @since 1.0.1
 */
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = _previewLayer.bounds.size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = self.previewLayer;
    
    if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResize]) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for(AVCaptureInputPort *port in [[self.session.inputs lastObject]ports]) {
            if([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                
                if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspect]) {
                    if(viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
                        if(point.x >= blackBar && point.x <= blackBar + x2) {
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
                        if(point.y >= blackBar && point.y <= blackBar + y2) {
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if([[videoPreviewLayer videoGravity]isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
                    if(viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
                        xc = point.y / frameSize.height;
                    }
                    
                }
                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    
    return pointOfInterest;
}


@end

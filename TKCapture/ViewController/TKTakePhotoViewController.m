//
//  TKTakePhotoViewController.m
//  TKCapture
//
//  Created by tinkl on 29/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SVProgressHUD.h>
#import <TKUtilsMacro.h>
#import <UIView+Additon.h>
#import <objc/runtime.h>
#import <Objection.h>
#import "TKTakePhotoViewController.h"
#import "TKCaptureSessionManager.h"

#pragma mark   ----------------------- start define   -----------------------

#define SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE      0   //对焦框

/* height or width px*/
#define CAMERA_TOPVIEW_HEIGHT                       44
#define CAMERA_MENU_VIEW_HEIGH                      44
#define CAMERA_HEIGHT                               366  //正对ip5

/*color*/
#define bottomContainerView_UP_COLOR     [UIColor colorWithRed:68/255.0f green:68/255.0f blue:68/255.0f alpha:.3f]
#define bottomContainerView_DOWN_COLOR   [UIColor colorWithRed:68/255.0f green:68/255.0f blue:68/255.0f alpha:.3f]
#define DARK_GREEN_COLOR        [UIColor colorWithRed:10/255.0f green:107/255.0f blue:42/255.0f alpha:.3f]
#define LIGHT_GREEN_COLOR       [UIColor colorWithRed:143/255.0f green:191/255.0f blue:62/255.0f alpha:.5f]

//对焦
#define ADJUSTINT_FOCUS @"adjustingFocus"               // key for kvc
#define LOW_ALPHA   0.7f                                // alpha 0.7
#define HIGH_ALPHA  1.0f                                // alpha 1.0


static const void *SwitchSessionNameKey = &SwitchSessionNameKey;

#pragma mark   ----------------------- end define   -----------------------

/*!
 *  @author tinkl, 14-11-29 19:11:00
 *
 *  拍照处理类`
 *
 *  @since 1.0.1
 */
@interface TKTakePhotoViewController ()
{
    int alphaTimes;
    CGPoint currTouchPoint;
}

@property (nonatomic, strong) TKCaptureSessionManager *captureManager;

@property (nonatomic, assign) CGRect previewRect;
@property (nonatomic, assign) BOOL isStatusBarHidden;

@property (nonatomic, strong) UIView *bottomContainerView;  //除了顶部标题、拍照区域剩下的所有区域
@property (nonatomic, strong) UIView *cameraMenuView;       //网格、闪光灯、前后摄像头等按钮
@property (nonatomic, strong) NSMutableSet *cameraBtnSet;

@property (nonatomic, strong) UIView *doneCameraUpView;
@property (nonatomic, strong) UIView *doneCameraDownView;


@property (nonatomic, strong) UIImageView *focusImageView;  //对焦


@end

@implementation TKTakePhotoViewController

//objection_initializer(selectorSymbol, args...)
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        alphaTimes = -1;
        currTouchPoint = CGPointZero;
        _cameraBtnSet = [[NSMutableSet alloc] init];
    }
    return self;
}


#pragma mark        -----------------------   viewDidLoad  -----------------------

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    //init StatusBar NaviBar and body Rect..
    [self initStatusBarNaviBarRect];
    
    //init session manager
    [self initCaptureSessionManager];
    
    /* init custom views*/
    [self initCustomViews];
    
    /*bingo*/
    [_captureManager.session startRunning];
    
}

/*!
 *  @author tinkl, 14-11-29 19:11:24
 *
 *  初始化 状态栏，根据不同尺寸调整自动布局
 *
 *  @since 1.0.1
 */
-(void) initStatusBarNaviBarRect
{
    //navigation bar
    if (self.navigationController && !self.navigationController.navigationBarHidden) {
        self.navigationController.navigationBarHidden = YES;
    }
    
    //status bar
    if (!self.navigationController) {
        _isStatusBarHidden = [UIApplication sharedApplication].statusBarHidden;
        if ([UIApplication sharedApplication].statusBarHidden == NO) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }
    }  
}

/*!
 *  @author tinkl, 14-11-29 19:11:05
 *
 *  初始化系统AVCaptureSession *session;
 *
 *  @since 1.0.1
 */
-(void) initCaptureSessionManager
{
    //AvcaptureManager
    if (CGRectEqualToRect(_previewRect, CGRectZero)) {
        self.previewRect = CGRectMake(0, 0, SC_APP_SIZE.width, SC_APP_SIZE.width + CAMERA_TOPVIEW_HEIGHT);
    }
    
    TKCaptureSessionManager *manager = [[TKCaptureSessionManager alloc] init];
    [manager configureWithParentLayer:self.view previewRect:_previewRect];
    self.captureManager = manager;
}

/*!
 *  @author tinkl, 14-11-29 19:11:49
 *
 *  初始化多有UI相关组件
 *
 *  @since 1.0.1
 */
-(void) initCustomViews
{
    
    self.view.backgroundColor  = bottomContainerView_UP_COLOR;
//==================================================1==================================================
    {
        CGFloat bottomY = _captureManager.previewLayer.frame.origin.y + CAMERA_HEIGHT;
        
        CGRect bottomFrame ;
        if (isHigherThaniPhone4_SC) {
            bottomFrame = CGRectMake(0, bottomY, SC_APP_SIZE.width, SC_APP_SIZE.height - bottomY );
        }else{
            if (IOS7) {
                bottomFrame = CGRectMake(0, bottomY, SC_APP_SIZE.width, SC_APP_SIZE.height - bottomY + 20);
            }else{
                bottomFrame = CGRectMake(0, bottomY, SC_APP_SIZE.width, SC_APP_SIZE.height - bottomY );
            }
        }
        
        UIView *view = [[UIView alloc] initWithFrame:bottomFrame];
        view.backgroundColor = bottomContainerView_UP_COLOR;
        [self.view addSubview:view];
        self.bottomContainerView = view;
    }
    
//==================================================2==================================================
    
    
    {
        CGFloat cameraBtnLength = 90;
        [self buildButton:CGRectMake((SC_APP_SIZE.width - cameraBtnLength) / 2, (_bottomContainerView.frame.size.height - CAMERA_MENU_VIEW_HEIGH - cameraBtnLength) / 2 + CAMERA_MENU_VIEW_HEIGH, cameraBtnLength, cameraBtnLength)
             normalImgStr:@"tk_lanrentuku_0001s_0027_camera.png"
          highlightImgStr:@"tk_lanrentuku_0001s_0027_camera.png"
           selectedImgStr:@""
                   action:@selector(takePictureBtnPressed:)
               parentView:_bottomContainerView];
        
        UIView *menuView = [[UIView alloc] initWithFrame:CGRectMake(0,CAMERA_HEIGHT-CAMERA_MENU_VIEW_HEIGH, self.view.frame.size.width, CAMERA_MENU_VIEW_HEIGH )];
        menuView.backgroundColor = bottomContainerView_DOWN_COLOR;
        [self.view addSubview:menuView];
        self.cameraMenuView = menuView;
        
        [self addMenuViewButtons];
    }
    
//==================================================3==================================================
    //对焦图
    {
        UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"touch_focus_x.png"]];
        imgView.alpha = 0;
        [self.view addSubview:imgView];
        self.focusImageView = imgView;
        
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if (device && [device isFocusPointOfInterestSupported]) {
            [device addObserver:self forKeyPath:ADJUSTINT_FOCUS options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        }
#endif
    }
    
//==================================================4==================================================

    {
        UIView *upView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SC_APP_SIZE.width, 0)];
        upView.backgroundColor = [UIColor blackColor];
        [self.view addSubview:upView];
        self.doneCameraUpView = upView;
        
        UIView *downView = [[UIView alloc] initWithFrame:CGRectMake(0, _bottomContainerView.frame.origin.y, SC_APP_SIZE.width, 0)];
        downView.backgroundColor = [UIColor blackColor];
        [self.view addSubview:downView];
        self.doneCameraDownView = downView;
    }
    
//==================================================5==================================================
   
    {
        
        UIButton *btnClose = [UIButton buttonWithType:UIButtonTypeCustom];
        [btnClose setImage:[UIImage imageNamed:@"close_cha.png"] forState:UIControlStateNormal];
        [btnClose setImage:[UIImage imageNamed:@"close_cha_h.png"] forState:UIControlStateHighlighted];
        [btnClose addTarget:self action:NSSelectorFromString(@"dismissBtnPressed:") forControlEvents:UIControlEventTouchUpInside];
        btnClose.showsTouchWhenHighlighted = YES;
        btnClose.frame = CGRectMake(10, self.view.height-65.0, 65.0, 65.0);
        [self.view addSubview:btnClose];
    }
}

//拍照动画
- (void)showCameraCover:(BOOL)toShow {
    
    [UIView animateWithDuration:0.15f animations:^{
        CGRect upFrame = _doneCameraUpView.frame;
        upFrame.size.height = (toShow ? SC_APP_SIZE.width / 2 + CAMERA_TOPVIEW_HEIGHT : 0);
        _doneCameraUpView.frame = upFrame;
        
        CGRect downFrame = _doneCameraDownView.frame;
        downFrame.origin.y = (toShow ? SC_APP_SIZE.width / 2 + CAMERA_TOPVIEW_HEIGHT : _bottomContainerView.frame.origin.y);
        downFrame.size.height = (toShow ? SC_APP_SIZE.width / 2 : 0);
        _doneCameraDownView.frame = downFrame;
    }];
}

//切换镜头和闪光灯
- (void)addMenuViewButtons {
    NSMutableArray *normalArr = [[NSMutableArray alloc] initWithObjects:@"switch_camera.png", @"switch_camera.png", @"flashing_off.png", nil];
    NSMutableArray *highlightArr = [[NSMutableArray alloc] initWithObjects:@"", @"", @"", nil];
    NSMutableArray *selectedArr = [[NSMutableArray alloc] initWithObjects:@"switch_camera_h.png", @"switch_camera_h.png", @"", nil];
    NSMutableArray *actionArr = [[NSMutableArray alloc] initWithObjects:@"switchCaptureSession:",@"switchCameraBtnPressed:", @"flashBtnPressed:", nil];
    
    CGFloat eachW = SC_APP_SIZE.width / actionArr.count;
    
    for (int i = 0; i < actionArr.count; i++) {
        
        CGFloat theH = (!isHigherThaniPhone4_SC && i == 0 ? _bottomContainerView.frame.size.height : CAMERA_MENU_VIEW_HEIGH);
        
        UIView *parent = (!isHigherThaniPhone4_SC && i == 0 ? _bottomContainerView : _cameraMenuView);
        
        if (!isHigherThaniPhone4_SC) {
            eachW = 65.0f;
        }
        
        UIButton * btn = [self buildButton:CGRectMake(eachW * i, 0, eachW, theH)
                              normalImgStr:[normalArr objectAtIndex:i]
                           highlightImgStr:[highlightArr objectAtIndex:i]
                            selectedImgStr:[selectedArr objectAtIndex:i]
                                    action:NSSelectorFromString([actionArr objectAtIndex:i])
                                parentView:parent];
        
        btn.showsTouchWhenHighlighted = YES;
        
        [_cameraBtnSet addObject:btn];
        
        if (i == 0) {
            //像素按钮 初始化为0
//            objc_setAssociatedObject(btn, SwitchSessionNameKey, @"0", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

- (UIButton*)buildButton:(CGRect)frame
            normalImgStr:(NSString*)normalImgStr
         highlightImgStr:(NSString*)highlightImgStr
          selectedImgStr:(NSString*)selectedImgStr
                  action:(SEL)action
              parentView:(UIView*)parentView {
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = frame;
    if (normalImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:normalImgStr] forState:UIControlStateNormal];
    }
    if (highlightImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:highlightImgStr] forState:UIControlStateHighlighted];
    }
    if (selectedImgStr.length > 0) {
        [btn setImage:[UIImage imageNamed:selectedImgStr] forState:UIControlStateSelected];
    }
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [parentView addSubview:btn];
    
    return btn;
}




#pragma mark        -----------------------   end of init  -----------------------
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
    if (!self.navigationController) {
        if ([UIApplication sharedApplication].statusBarHidden != _isStatusBarHidden) {
            [[UIApplication sharedApplication] setStatusBarHidden:_isStatusBarHidden withAnimation:UIStatusBarAnimationSlide];
        }
    }
    
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device && [device isFocusPointOfInterestSupported]) {
        [device removeObserver:self forKeyPath:ADJUSTINT_FOCUS context:nil];
    }
#endif
    
    self.captureManager = nil;
}

#pragma mark   -----------------------focuview touch to focus   -----------------------
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    //listen focus view is complate...
    if ([keyPath isEqualToString:ADJUSTINT_FOCUS]) {
        BOOL isAdjustingFocus = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1] ];
        if (!isAdjustingFocus) {
            alphaTimes = -1;
        }
    }
}

- (void)showFocusInPoint:(CGPoint)touchPoint {
    
    [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        
        int alphaNum = (alphaTimes % 2 == 0 ? HIGH_ALPHA : LOW_ALPHA);
        self.focusImageView.alpha = alphaNum;
        alphaTimes++;
        
    } completion:^(BOOL finished) {
        
        if (alphaTimes != -1) {
            [self showFocusInPoint:currTouchPoint];
        } else {
            self.focusImageView.alpha = 0.0f;
        }
    }];
}
#endif

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    alphaTimes = -1;
    
    UITouch *touch = [touches anyObject];
    currTouchPoint = [touch locationInView:self.view];
    
    if (!CGRectContainsPoint(_captureManager.previewLayer.bounds, currTouchPoint)) {
        return;
    }

    //对焦框
    [_captureManager focusInPoint:currTouchPoint];
    [_focusImageView setCenter:currTouchPoint];
    _focusImageView.transform = CGAffineTransformMakeScale(2.0, 2.0);
    
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    [UIView animateWithDuration:0.1f animations:^{
        _focusImageView.alpha = HIGH_ALPHA;
        _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [self showFocusInPoint:currTouchPoint];
    }];
#else
    [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
        _focusImageView.alpha = 1.f;
        _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.5f delay:0.5f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            _focusImageView.alpha = 0.f;
        } completion:nil];
    }];
#endif
}

#pragma mark         -----------------------   button actions        -----------------------
//拍照页面，拍照按钮
- (void)takePictureBtnPressed:(UIButton*)sender {
#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [SVProgressHUD showErrorWithStatus:@"设备不支持拍照功能"];
        return;
    }
#endif
    
    sender.userInteractionEnabled = NO;
    [self showCameraCover:YES];
    
    // weak __self 防止内存泄露
    WEAKSELF_SC
    [_captureManager takePicture:^(UIImage *stillImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //   异步队列里
            [self saveImageToPhotoAlbum:stillImage];
        });
        
        double delayInSeconds = .5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            sender.userInteractionEnabled = YES;
            [weakSelf_SC showCameraCover:NO];
        });
    }];
}

-(void)saveImageToPhotoAlbum:(UIImage *) image
{
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error != NULL) {
       [SVProgressHUD showErrorWithStatus:@"照片保存到相册失败"];
    } else {
       [SVProgressHUD showSuccessWithStatus:@"照片保存成功"];
    }
}

- (void)tmpBtnPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark        -----------------------   Action events        -----------------------

//拍照页面，"X"按钮
- (void)dismissBtnPressed:(id)sender {
    if (self.navigationController) {
        if (self.navigationController.viewControllers.count == 1) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

//切换像素比例 1:1  16:9 4:3
-(void)switchCaptureSession:(UIButton*)sender
{

    //AVCaptureSessionPreset640x480  4:3
    
    //AVCaptureSessionPresetiFrame1280x720 16:9
    
    //AVCaptureSessionPresetPhoto  1:1
    
    NSString * sessionIndex = objc_getAssociatedObject(sender, SwitchSessionNameKey);
    if (sessionIndex == NULL ||[sessionIndex isEqualToString:@"0"] ) {
        objc_setAssociatedObject(sender, SwitchSessionNameKey, @"1", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        // 4:3
        [UIView animateWithDuration:0.15f animations:^{
            _captureManager.previewLayer.frame = CGRectMake(0, 0, self.view.width,  self.view.width*4/3);
        }];
        [_captureManager switchCaptureSession:1];
    }else{
        if ([sessionIndex isEqualToString:@"1"]) {
            objc_setAssociatedObject(sender, SwitchSessionNameKey, @"2", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [UIView animateWithDuration:0.15f animations:^{
                _captureManager.previewLayer.frame = CGRectMake(0, 0, self.view.width,  self.view.width*16/9);
            }];
            //16:9
            [_captureManager switchCaptureSession:2];
        }else  if ([sessionIndex isEqualToString:@"2"]) {
            objc_setAssociatedObject(sender, SwitchSessionNameKey, @"0", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [UIView animateWithDuration:0.15f animations:^{
                _captureManager.previewLayer.frame = CGRectMake(0, 0, self.view.width, self.view.height);}];
            //1:1
        [_captureManager switchCaptureSession:0];
        }
    }    
}

//拍照页面，切换前后摄像头按钮按钮
- (void)switchCameraBtnPressed:(UIButton*)sender {
    sender.selected = !sender.selected;
    [_captureManager switchCamera:sender.selected];
}

//拍照页面，闪光灯按钮
- (void)flashBtnPressed:(UIButton*)sender {
    [_captureManager switchFlashMode:sender];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}
@end






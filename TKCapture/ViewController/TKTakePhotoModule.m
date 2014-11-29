//
//  MDRealNameAuthModule.m
//  OwnerApp
//
//  Created by tinkl on 19/5/14.
//  Copyright (c) 2014 ___TINKL___. All rights reserved.
//

#import "TKTakePhotoModule.h"
#import "TKProtocol.h"
#import <Objection.h>
#import "TKTakePhotoViewController.h"

@implementation TKTakePhotoModule

+ (void)load
{
    JSObjectionInjector *injector = [JSObjection defaultInjector];
    injector = injector ? : [JSObjection createInjector];
    injector = [injector withModule:[[self alloc] init]];
    [JSObjection setDefaultInjector:injector];
}

- (void)configure
{
    [self bindClass:[TKTakePhotoViewController class] toProtocol:@protocol(TKCameraProtocol)];
}

@end

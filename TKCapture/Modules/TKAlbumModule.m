//
//  TKAlbumModule.m
//  TKCapture
//
//  Created by tinkl on 30/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKAlbumModule.h"
#import "TKProtocol.h"
#import <Objection.h>
#import "TKTakePhotoViewController.h"
#import "TKAlibumGroupViewController.h"
#import "TKAlbumViewController.h"
#import "TKAssetsViewController.h"

@implementation TKAlbumModule

+ (void)load
{
    JSObjectionInjector *injector = [JSObjection defaultInjector];
    injector = injector ? : [JSObjection createInjector];
    injector = [injector withModule:[[self alloc] init]];
    [JSObjection setDefaultInjector:injector];
}

- (void)configure
{
    [self bindClass:[TKAlbumViewController class] toProtocol:@protocol(TKAlbumProtocol)];
    
}

@end


@implementation TKAlbumGroupModule

- (void)configure
{
    [self bindClass:[TKAlibumGroupViewController class] toProtocol:@protocol(TKAlbumGroupProtocol)];
    
}

@end

@implementation TKAssetsModule

- (void)configure
{
     [self bindClass:[TKAssetsViewController class] toProtocol:@protocol(TKAssetsProtocol)];
}

@end
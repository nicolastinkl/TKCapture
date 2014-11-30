//
//  TKAlbumViewController.m
//  TKCapture
//
//  Created by tinkl on 30/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKAlbumViewController.h"
#import "NSDate+TimeInterval.h"
#import <TKUtilsMacro.h>
#import "TKProtocol.h"
#import <Objection.h>


@implementation TKAlbumViewController 

- (id)init
{
    UIViewController<TKAlbumGroupProtocol> * groupViewController = [[JSObjection defaultInjector] getObject:@protocol(TKAlbumGroupProtocol)];
    
    if (self = [super initWithRootViewController:groupViewController])
    {
        if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
        {
            [self setContentSizeForViewInPopover:kPopoverContentSize];
        }
    }
    // UIViewController.preferredContentSize
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
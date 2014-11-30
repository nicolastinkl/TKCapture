//
//  TKAssetsViewController.m
//  TKCapture
//
//  Created by tinkl on 30/11/14.
//  Copyright (c) 2014年 ___TINKL___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKAssetsViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "NSDate+TimeInterval.h"
#import <TKUtilsMacro.h>
#import "TKAssetsSupplementaryView.h"
#import "TKAlbumViewController.h"
#import "TKAlibumGroupViewController.h"

static CGRect oldframe;

#pragma mark --------------------------------------cell --------------------

@interface TKAssetsViewCell : UICollectionViewCell

- (void)bind:(ALAsset *)asset;

@end

@interface TKAssetsViewCell ()

@property (nonatomic, strong) ALAsset *asset;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *type;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIImage *videoImage;
@property (nonatomic, assign) BOOL disabled;

@end



#pragma mark - TKAssetsViewCell

@implementation TKAssetsViewCell

static UIFont *titleFont = nil;
static CGFloat titleHeight;
static UIColor *titleColor;

+ (void)initialize
{
    titleFont       = [UIFont systemFontOfSize:14];
    titleHeight     = 20.0f;
    titleColor      = [UIColor whiteColor];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        self.opaque                     = YES;
        self.isAccessibilityElement     = YES;
        self.accessibilityTraits        = UIAccessibilityTraitImage;
    }
    
    return self;
}

- (void)bind:(ALAsset *)asset
{
    self.asset  = asset;
    self.image  = [UIImage imageWithCGImage:asset.thumbnail];
    self.type   = [asset valueForProperty:ALAssetPropertyType];
    
    if ([self.type isEqual:ALAssetTypeVideo])
    {
        self.title = [NSDate timeDescriptionOfTimeInterval:[[asset valueForProperty:ALAssetPropertyDuration] doubleValue]];
    }
}

- (void)drawRect:(CGRect)rect
{
    [self.image drawInRect:CGRectMake(0, 0, kThumbnailLength, kThumbnailLength)];
}

@end




#pragma mark -------------------------------------- main view----------------

@interface TKAssetsViewController ()

@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@property (nonatomic, strong) NSMutableArray *assets;
@property (nonatomic, assign) NSInteger numberOfPhotos;
@property (nonatomic, assign) NSInteger numberOfVideos;

@end


#pragma mark - TKAssetsViewController

#define kAssetsViewCellIdentifier           @"AssetsViewCellIdentifier"
#define kAssetsSupplementaryViewIdentifier  @"AssetsSupplementaryViewIdentifier"

@implementation TKAssetsViewController

- (id)init
{
    self.layout                         = [[UICollectionViewFlowLayout alloc] init];
    self.layout.itemSize                = kThumbnailSize;
    self.layout.footerReferenceSize     = CGSizeMake(0, 44.0);
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
    {
        self.layout.sectionInset            = UIEdgeInsetsMake(9.0, 2.0, 0, 2.0);
        self.layout.minimumInteritemSpacing = 3.0;
        self.layout.minimumLineSpacing      = 3.0;
    }
    else
    {
        self.layout.sectionInset            = UIEdgeInsetsMake(9.0, 0, 0, 0);
        self.layout.minimumInteritemSpacing = 2.0;
        self.layout.minimumLineSpacing      = 2.0;
    }
    
    if (self = [super initWithCollectionViewLayout:self.layout])
    {
        self.collectionView.allowsMultipleSelection = YES;
        
        [self.collectionView registerClass:[TKAssetsViewCell class]
                forCellWithReuseIdentifier:kAssetsViewCellIdentifier];
        
        [self.collectionView registerClass:[TKAssetsSupplementaryView class]
                forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                       withReuseIdentifier:kAssetsSupplementaryViewIdentifier];
        
        if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)])
            [self setEdgesForExtendedLayout:UIRectEdgeNone];

        self.preferredContentSize = kPopoverContentSize;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor whiteColor];
}


-(void) fillAssetsGroup:(ALAssetsGroup *)assetsGroup
{
    self.assetsGroup = assetsGroup;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupAssets];
}


#pragma mark - Rotation

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        self.layout.sectionInset            = UIEdgeInsetsMake(9.0, 2.0, 0, 2.0);
        self.layout.minimumInteritemSpacing = 3.0;
        self.layout.minimumLineSpacing      = 3.0;
    }
    else
    {
        self.layout.sectionInset            = UIEdgeInsetsMake(9.0, 0, 0, 0);
        self.layout.minimumInteritemSpacing = 2.0;
        self.layout.minimumLineSpacing      = 2.0;
    }
    
    [self.collectionView setCollectionViewLayout:self.layout animated:YES];
}


- (void)setupAssets
{
    self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
    self.numberOfPhotos = 0;
    self.numberOfVideos = 0;
    
    if (!self.assets)
        self.assets = [[NSMutableArray alloc] init];
    else
        [self.assets removeAllObjects];
    
    ALAssetsGroupEnumerationResultsBlock resultsBlock = ^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        
        if (asset)
        {
            [self.assets addObject:asset];
            
            NSString *type = [asset valueForProperty:ALAssetPropertyType];
            
            if ([type isEqual:ALAssetTypePhoto])
                self.numberOfPhotos ++;
            if ([type isEqual:ALAssetTypeVideo])
                self.numberOfVideos ++;
        }
        
        else if (self.assets.count > 0)
        {
            [self.collectionView reloadData];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.assets.count-1 inSection:0]
                                        atScrollPosition:UICollectionViewScrollPositionTop
                                                animated:YES];
        }
    };
    
    [self.assetsGroup enumerateAssetsUsingBlock:resultsBlock];
}


#pragma mark - Collection View Data Source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = kAssetsViewCellIdentifier;
    
    TKAssetsViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellIdentifier forIndexPath:indexPath];
    ALAsset* asset = [self.assets objectAtIndex:indexPath.row];
    [cell bind:asset];
    [cell setNeedsDisplay];
    return cell;
}

//底部view
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *viewIdentifiert = kAssetsSupplementaryViewIdentifier;
    
    TKAssetsSupplementaryView *view =
    [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:viewIdentifiert forIndexPath:indexPath];
    
    [view setNumberOfPhotos:self.numberOfPhotos numberOfVideos:self.numberOfVideos];
    
    return view;
}

#pragma mark - Collection View Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    TKAssetsViewCell *cell = (TKAssetsViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    ALAsset* asset = [self.assets objectAtIndex:indexPath.row];
    UIImage *image =[UIImage imageWithCGImage:asset.aspectRatioThumbnail];
    [self showImage:cell withImage:image];
    
}

-(void) showImage:(UIView *) viewCell withImage:(UIImage *) image
{
    UIWindow *window=[UIApplication sharedApplication].keyWindow;
    UIView *backgroundView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    oldframe=[viewCell convertRect:viewCell.bounds toView:window];
    backgroundView.backgroundColor=[UIColor blackColor];
    backgroundView.alpha=0;
    UIImageView *imageView=[[UIImageView alloc]initWithFrame:oldframe];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    imageView.tag=1;
    
    imageView.image = image;
    
    [backgroundView addSubview:imageView];
    [window addSubview:backgroundView];
    
    UITapGestureRecognizer *tap=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideImage:)];
    [backgroundView addGestureRecognizer: tap];
    
    [UIView animateWithDuration:0.3 animations:^{
        imageView.frame=CGRectMake(0,([UIScreen mainScreen].bounds.size.height-image.size.height*[UIScreen mainScreen].bounds.size.width/image.size.width)/2, [UIScreen mainScreen].bounds.size.width, image.size.height*[UIScreen mainScreen].bounds.size.width/image.size.width);
        backgroundView.alpha=1;
    } completion:^(BOOL finished) {
        
    }];
}
-(void)hideImage:(UITapGestureRecognizer*)tap{
    UIView *backgroundView=tap.view;
    UIImageView *imageView=(UIImageView*)[tap.view viewWithTag:1];
    [UIView animateWithDuration:0.3 animations:^{
        imageView.frame=oldframe;
        backgroundView.alpha=0;
    } completion:^(BOOL finished) {
        [backgroundView removeFromSuperview];
    }];
}
@end

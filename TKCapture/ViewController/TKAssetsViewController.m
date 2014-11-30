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
static UIImage *videoIcon;
static UIColor *titleColor;
static UIImage *checkedIcon;
static UIColor *selectedColor;
static UIColor *disabledColor;

+ (void)initialize
{
    titleFont       = [UIFont systemFontOfSize:12];
    titleHeight     = 20.0f;
    videoIcon       = [UIImage imageNamed:@"CTAssetsPickerVideo"];
    titleColor      = [UIColor whiteColor];
    checkedIcon     = [UIImage imageNamed:@"CTAssetsPickerChecked"];
    selectedColor   = [UIColor colorWithWhite:1 alpha:0.3];
    disabledColor   = [UIColor colorWithWhite:1 alpha:0.9];
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

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [self setNeedsDisplay];
}

// Draw everything to improve scrolling responsiveness

- (void)drawRect:(CGRect)rect
{
    // Image
    [self.image drawInRect:CGRectMake(0, 0, kThumbnailLength, kThumbnailLength)];
    
    // Video title
    if ([self.type isEqual:ALAssetTypeVideo])
    {
        // Create a gradient from transparent to black
        CGFloat colors [] = {
            0.0, 0.0, 0.0, 0.0,
            0.0, 0.0, 0.0, 0.8,
            0.0, 0.0, 0.0, 1.0
        };
        
        CGFloat locations [] = {0.0, 0.75, 1.0};
        
        CGColorSpaceRef baseSpace   = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient      = CGGradientCreateWithColorComponents(baseSpace, colors, locations, 2);
        
        CGContextRef context    = UIGraphicsGetCurrentContext();
        
        CGFloat height          = rect.size.height;
        CGPoint startPoint      = CGPointMake(CGRectGetMidX(rect), height - titleHeight);
        CGPoint endPoint        = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
        
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, kCGGradientDrawsBeforeStartLocation);
        
        
        CGSize titleSize        = [self.title sizeWithFont:titleFont];
        [titleColor set];
        [self.title drawAtPoint:CGPointMake(rect.size.width - titleSize.width - 2 , startPoint.y + (titleHeight - 12) / 2)
                       forWidth:kThumbnailLength
                       withFont:titleFont
                       fontSize:12
                  lineBreakMode:NSLineBreakByTruncatingTail
             baselineAdjustment:UIBaselineAdjustmentAlignCenters];
        
        [videoIcon drawAtPoint:CGPointMake(2, startPoint.y + (titleHeight - videoIcon.size.height) / 2)];
    }
    
    if (self.disabled)
    {
        CGContextRef context    = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, disabledColor.CGColor);
        CGContextFillRect(context, rect);
    }
    
    else if (self.selected)
    {
        CGContextRef context    = UIGraphicsGetCurrentContext();
        CGContextSetFillColorWithColor(context, selectedColor.CGColor);
        CGContextFillRect(context, rect);
        
        [checkedIcon drawAtPoint:CGPointMake(CGRectGetMaxX(rect) - checkedIcon.size.width, CGRectGetMinY(rect))];
    }
}


- (NSString *)accessibilityLabel
{
    ALAssetRepresentation *representation = self.asset.defaultRepresentation;
    
    NSMutableArray *labels          = [[NSMutableArray alloc] init];
    NSString *type                  = [self.asset valueForProperty:ALAssetPropertyType];
    NSDate *date                    = [self.asset valueForProperty:ALAssetPropertyDate];
    CGSize dimension                = representation.dimensions;
    
    
    // Type
    if ([type isEqual:ALAssetTypeVideo])
        [labels addObject:@"视频"];
    else
        [labels addObject:@"照片"];
    
    // Orientation
    if (dimension.height >= dimension.width)
        [labels addObject:@"竖屏"];
    else
        [labels addObject:@"横屏"];
    
    // Date
    NSDateFormatter *df             = [[NSDateFormatter alloc] init];
    df.locale                       = [NSLocale currentLocale];
    df.dateStyle                    = NSDateFormatterMediumStyle;
    df.timeStyle                    = NSDateFormatterShortStyle;
    df.doesRelativeDateFormatting   = YES;
    
    [labels addObject:[df stringFromDate:date]];
    
    return [labels componentsJoinedByString:@", "];
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
        
        if ([self respondsToSelector:@selector(setContentSizeForViewInPopover:)])
            [self setContentSizeForViewInPopover:kPopoverContentSize];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupViews];
    [self setupButtons];
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


#pragma mark - Setup

- (void)setupViews
{
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

- (void)setupButtons
{
    self.navigationItem.rightBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"完成"
                                     style:UIBarButtonItemStyleDone
                                    target:self
                                    action:@selector(finishPickingAssets:)];
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
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    static NSString *viewIdentifiert = kAssetsSupplementaryViewIdentifier;
    
    TKAssetsSupplementaryView *view =
    [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:viewIdentifiert forIndexPath:indexPath];
    
    [view setNumberOfPhotos:self.numberOfPhotos numberOfVideos:self.numberOfVideos];
    
    return view;
}


#pragma mark - Collection View Delegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return true;
//    TKAlbumViewController *vc = (TKAlbumViewController *)self.navigationController;
//    ALAsset* asset = [self.assets objectAtIndex:indexPath.row];
//    BOOL selectable = [vc.selectionFilter evaluateWithObject:asset];
//    
//    return (selectable && collectionView.indexPathsForSelectedItems.count < vc.maximumNumberOfSelection);
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    TKAlbumViewController *vc = (TKAlbumViewController *)self.navigationController;
//    vc.indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems;
//    
//    if ([vc.delegate respondsToSelector:@selector(assetsPickerController:didSelectItemAtIndexPath:)])
//        [vc.delegate assetsPickerController:vc didSelectItemAtIndexPath:indexPath];
//    
//    [self setTitleWithSelectedIndexPaths:collectionView.indexPathsForSelectedItems];
}

#pragma mark - Title

- (void)setTitleWithSelectedIndexPaths:(NSArray *)indexPaths
{
    // Reset title to group name
    if (indexPaths.count == 0)
    {
        self.title = [self.assetsGroup valueForProperty:ALAssetsGroupPropertyName];
        return;
    }
    
    BOOL photosSelected = NO;
    BOOL videoSelected  = NO;
    
    for (NSIndexPath *indexPath in indexPaths)
    {
        ALAsset *asset = [self.assets objectAtIndex:indexPath.item];
        
        if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypePhoto])
            photosSelected  = YES;
        
        if ([[asset valueForProperty:ALAssetPropertyType] isEqual:ALAssetTypeVideo])
            videoSelected   = YES;
        
        if (photosSelected && videoSelected)
            break;
    }
    
    NSString *format;
    
    if (photosSelected && videoSelected)
        format = @"已选取 %ld 个項目";
    
    else if (photosSelected)
        format = @"已选取 %ld 张照片"; //(indexPaths.count > 1) ? NSLocalizedString(@"%ld Photos Selected", nil) : NSLocalizedString(@"%ld Photo Selected", nil);
    
    else if (videoSelected)
        format =  @"已选取 %ld 部视频";;// (indexPaths.count > 1) ? NSLocalizedString(@"%ld Videos Selected", nil) : NSLocalizedString(@"%ld Video Selected", nil);
    
    self.title = [NSString stringWithFormat:format, (long)indexPaths.count];
}


#pragma mark - Actions

- (void)finishPickingAssets:(id)sender
{
    NSMutableArray *assets = [[NSMutableArray alloc] init];
    
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems)
    {
        [assets addObject:[self.assets objectAtIndex:indexPath.item]];
    }
    
    TKAlbumViewController *picker = (TKAlbumViewController *)self.navigationController;
    [picker.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

@end

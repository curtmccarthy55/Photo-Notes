//
//  CJMPhotoGrabViewController.m
//  Unroll
//
//  Created by Curt on 4/19/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMPhotoGrabViewController.h"
#import "CJMGrabCell.h"
#import "CJMHudView.h"

@import Photos;

@interface CJMPhotoGrabViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) PHFetchResult *fetchResult;
@property (strong) PHCachingImageManager *imageManager;

@end


@implementation CJMPhotoGrabViewController

static NSString * const reuseIdentifier = @"GrabCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (self.singleSelection) {
        self.collectionView.allowsMultipleSelection = NO;
    } else {
        self.collectionView.allowsMultipleSelection = YES;
    }
    //cjm album fetch.  PHAsset fetch call made here.
    self.imageManager = [[PHCachingImageManager alloc] init];
    self.fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    self.navigationItem.title = @"Select Photos";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(donePressed)];
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    if (self.userColorTag.integerValue != 5 && self.userColorTag.integerValue != 7) {
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        [self.navigationController.toolbar setTintColor:[UIColor whiteColor]];
        [self.navigationController.navigationBar setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    } else {
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
        [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
        [self.navigationController.toolbar setTintColor:[UIColor blackColor]];
        [self.navigationController.navigationBar setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor blackColor] }];
    }
    
    [self.navigationController.navigationBar setBarTintColor:self.userColor];
    [self.navigationController.toolbar setBarTintColor:self.userColor];
    
    //scroll to bottom before displaying
    CGSize pageSize = self.view.bounds.size;
    CGPoint contentOffset = CGPointMake(0, pageSize.height * self.fetchResult.count - 1);
    [self.collectionView setContentOffset:contentOffset animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

//Scroll to most recent photos in library (bottom of collectionView)
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = [self.fetchResult count];
    return count;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMGrabCell *cell = (CJMGrabCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    cell.cellSelectCover.hidden = YES;
    
    //check if indexPath has been selected and reveal its cell's selectCover if it has been.
    if ((collectionView.indexPathsForSelectedItems.count > 0) &&
        ([collectionView.indexPathsForSelectedItems containsObject:indexPath])) {
        [collectionView selectItemAtIndexPath:indexPath
                                     animated:NO
                               scrollPosition:UICollectionViewScrollPositionNone];
        cell.cellSelectCover.hidden = NO;
    }
    
    PHAsset *asset = self.fetchResult[indexPath.row];
    cell.asset = asset;
    [self.imageManager requestImageForAsset:asset
                                 targetSize:cell.frame.size
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  cell.cellImage.image = result;
                              }];
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMGrabCell *selectedCell = (CJMGrabCell *)[collectionView cellForItemAtIndexPath:indexPath];
    selectedCell.cellSelectCover.hidden = NO;
    if (!self.navigationItem.rightBarButtonItem.enabled) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMGrabCell *selectedCell = (CJMGrabCell *)[collectionView cellForItemAtIndexPath:indexPath];
    selectedCell.cellSelectCover.hidden = YES;
    if ([self.collectionView indexPathsForSelectedItems].count == 0) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

#pragma mark - Actions

- (void)cancelPressed
{
    [self.delegate photoGrabViewControllerDidCancel:self];
}

- (void)donePressed
{
    CJMHudView *hudView = [CJMHudView hudInView:self.view withType:@"Pending" animated:YES];
    hudView.text = @"Importing";
    
    NSArray *selectedItems = [[NSArray alloc] initWithArray:[self.collectionView indexPathsForSelectedItems]];
    
    NSMutableArray *pickedPhotos = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < selectedItems.count; i++) {
        NSIndexPath *indexPath = [selectedItems objectAtIndex:i];
        PHAsset *asset = self.fetchResult[indexPath.item];
        [pickedPhotos addObject:asset];
    }
    [self.delegate photoGrabViewController:self didFinishSelectingPhotos:[pickedPhotos copy]];
}

#pragma mark UICollectionViewFlowLayoutDelegate

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
        CGFloat viewWidth = lroundf(collectionView.frame.size.width);
        int cellWidth = (viewWidth/5) - 2;
        return CGSizeMake(cellWidth, cellWidth);
    } else {
        CGFloat viewWidth = lroundf(collectionView.frame.size.width);
        int cellWidth = (viewWidth/4) - 2;
        return CGSizeMake(cellWidth, cellWidth);
    }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(1, 1, 1, 1);
}

//resizes collectionView cells per sizeForItemAtIndexPath when user rotates device.
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.collectionView.collectionViewLayout invalidateLayout];
    
}


@end

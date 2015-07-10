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
    
    self.collectionView.allowsMultipleSelection = YES;
    self.imageManager = [[PHCachingImageManager alloc] init];
    self.fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(donePressed)];
}

//Scroll to most recent photos in library (bottom of collectionView)
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSInteger section = [self.collectionView numberOfSections] - 1;
    NSInteger item = [self.collectionView numberOfItemsInSection:section] - 1;
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
    [self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:(UICollectionViewScrollPositionBottom) animated:YES];
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
    
    if (collectionView.indexPathsForSelectedItems.count > 0) {
        if ([collectionView.indexPathsForSelectedItems containsObject:indexPath]) {
            [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            cell.cellSelectCover.hidden = NO;
        }
    }
    
    // Increment the cell's tag
    NSInteger currentTag = cell.tag + 1;
    cell.tag = currentTag;
    
    PHAsset *asset = self.fetchResult[indexPath.row];
    cell.asset = asset;
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:cell.frame.size
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  
                                  // Only update the thumbnail if the cell tag hasn't changed. Otherwise, the cell has been re-used.
                                  if (cell.tag == currentTag) {
                                      cell.cellImage.image = result;
                                  }
                                  
                              }];
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMGrabCell *selectedCell = (CJMGrabCell *)[collectionView cellForItemAtIndexPath:indexPath];
    selectedCell.cellSelectCover.hidden = NO;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMGrabCell *selectedCell = (CJMGrabCell *)[collectionView cellForItemAtIndexPath:indexPath];
    selectedCell.cellSelectCover.hidden = YES;
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
        PHAsset *asset = _fetchResult[indexPath.item];
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

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration //resizes collectionView cells per sizeForItemAtIndexPath when user rotates device.
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.collectionView.collectionViewLayout invalidateLayout];
    
}


@end

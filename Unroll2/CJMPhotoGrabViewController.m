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

@interface CJMPhotoGrabViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) PHFetchResult *fetchResult;
@property (strong) PHCachingImageManager *imageManager;

@end


@implementation CJMPhotoGrabViewController

static NSString * const reuseIdentifier = @"GrabCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _collectionView.allowsMultipleSelection = YES;
    
    self.imageManager = [[PHCachingImageManager alloc] init];
    _fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:nil];
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSInteger section = [self.collectionView numberOfSections] - 1 ;
    NSInteger item = [self.collectionView numberOfItemsInSection:section] - 1 ;
    NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:section] ;
    [self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:(UICollectionViewScrollPositionBottom) animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSInteger count = [self.fetchResult count];
    
    NSLog(@"%ld Photos", (long)count);
    
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMGrabCell *cell = (CJMGrabCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if ([collectionView.indexPathsForSelectedItems containsObject:indexPath]) {
        [collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        cell.cellSelectCover.hidden = NO;
    } else {
        cell.cellSelectCover.hidden = YES;
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

- (IBAction)cancelPressed:(id)sender
{
    self.pickedPhotos = nil;
    
    [self.delegate photoGrabViewControllerDidCancel:self];
}

- (IBAction)donePressed:(id)sender
{
    CJMHudView *hudView = [CJMHudView hudInView:self.view animated:YES];
    
    hudView.text = @"Importing";
    hudView.type = @"Pending";
    
    NSArray *selectedItems = [[NSArray alloc] initWithArray:[self.collectionView indexPathsForSelectedItems]];
    
    _pickedPhotos = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < selectedItems.count; i++) {
        NSIndexPath *indexPath = [selectedItems objectAtIndex:i];
        PHAsset *asset = _fetchResult[indexPath.item];
        
        [_pickedPhotos addObject:asset];
    }
    

    
    NSLog(@"There are %lu photos being sent to the album", (unsigned long)_pickedPhotos.count);
    [self.delegate photoGrabViewController:self didFinishSelectingPhotos:[_pickedPhotos copy]];
}


#pragma mark - image picker delegate

#pragma ALERT return here to complete image capture with in app camera.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //UIImage *image = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    
    [self dismissViewControllerAnimated:YES completion: ^{
        //do something with the image
    }];
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
    //[self.collectionView.collectionViewLayout invalidateLayout];
    
}


@end

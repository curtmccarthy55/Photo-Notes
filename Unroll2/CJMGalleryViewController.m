//
//  CJMGalleryViewController.m
//  Unroll
//
//  Created by Curt on 4/13/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMGalleryViewController.h"
#import "CJMFIGalleryViewController.h"
#import "CJMFullImageViewController.h"
#import "CJMServices.h"
#import "CJMPhotoAlbum.h"
#import "CJMAlbumManager.h"
#import "CJMPhotoCell.h"
#import "CJMImage.h"

#import "CJMFileSerializer.h"

@import Photos;

@interface CJMGalleryViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
//UICollectionViewDelegateFlowLayout is a sub-protocol of UICollectionViewDelegate, so there's no need to list both.

@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) CJMFIGalleryViewController *fullImageVC;

@end

@implementation CJMGalleryViewController

static NSString * const reuseIdentifier = @"GalleryCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.title = self.album.albumTitle;
    
    if (!_imageManager) {
        _imageManager = [[PHCachingImageManager alloc] init];
    }
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.navigationController.navigationBar.alpha < 1) {
    self.navigationController.navigationBar.alpha = 1;
    self.navigationController.toolbar.alpha = 1;
        
    [self.collectionView reloadData];
    }
    
    if (self.album.albumPhotos.count == 0) {
        UIAlertController *noPhotosAlert = [UIAlertController alertControllerWithTitle:@"No photos added yet" message:@"Tap the camera below to add photos" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
        
        [noPhotosAlert addAction:dismissAction];
        
        [self presentViewController:noPhotosAlert animated:YES completion:nil];
    }
    
    NSLog(@"Gallery view appeared");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark <UICollectionViewDataSource>


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.album.albumPhotos count];
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMPhotoCell *cell = (CJMPhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    [cell updateWithImage:_album.albumPhotos[indexPath.item]];
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ViewPhoto"]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];
        
        CJMFIGalleryViewController *vc = (CJMFIGalleryViewController *)segue.destinationViewController;
        //vc.album = _album;
        vc.albumName = _album.albumTitle;
        vc.albumCount = _album.albumPhotos.count;
        vc.initialIndex = indexPath.item;
    }
}

- (void)setAlbum:(CJMPhotoAlbum *)album
{
    _album = album;
    self.navigationItem.title = album.albumTitle;
}

#pragma mark - NavBar items


- (IBAction)photoGrab:(id)sender
{
    [self showPopUpMenu];
}

- (void)showPopUpMenu
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                        message:nil
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    //find a way to delay camera permission request to after user presses camera button
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionForCamera) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
            return;
        } else {
            UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
            mediaUI.sourceType = UIImagePickerControllerSourceTypeCamera;
            mediaUI.allowsEditing = NO;
            mediaUI.delegate = self;
            
            [self presentViewController:mediaUI animated:YES completion:nil];
        }
    }];
    
    UIAlertAction *libraryAction = [UIAlertAction actionWithTitle:@"Choose From Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionForLibrary) {
        NSString * storyboardName = @"Main";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
        CJMPhotoGrabViewController *vc = (CJMPhotoGrabViewController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoGrabViewController"];
        vc.delegate = self;
        [self presentViewController:vc animated:YES completion:nil];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *actionCancel) {}];
    
    [alertController addAction:cameraAction];
    [alertController addAction:libraryAction];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


#pragma mark <UICollectionViewDelegate>

//- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    _fullImageVC = [[CJMFIGalleryViewController alloc] init];
//    
//    _fullImageVC.initialIndex = indexPath.item;
//    _fullImageVC.album = _album;
//    
//    [self presentViewController:_fullImageVC animated:YES completion:nil];
//}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

#pragma mark - CJMPhotoGrabber Delegate


- (void)photoGrabViewControllerDidCancel:(CJMPhotoGrabViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)photoGrabViewController:(CJMPhotoGrabViewController *)controller didFinishSelectingPhotos:(NSArray *)photos
{
    NSLog(@"%lu photos received by the gallery", (unsigned long)photos.count);
    
    //Pull the images, image creation dates, and image locations from each PHAsset in the received array.
    CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
    
    
    dispatch_group_t imageLoadGroup = dispatch_group_create();
    
    for (int i = 0; i < photos.count; i++) {
        
        CJMImage *assetImage = [[CJMImage alloc] init];
        PHAsset *asset = (PHAsset *)photos[i];
        
        assetImage.photoLocation = [asset location];
        assetImage.photoCreationDate = [asset creationDate];
        
        dispatch_group_enter(imageLoadGroup);
        [self.imageManager requestImageForAsset:asset
                                     targetSize:CGSizeMake(asset.pixelWidth, asset.pixelHeight)
                                    contentMode:PHImageContentModeAspectFill
                                        options:nil
                                  resultHandler:^(UIImage *result, NSDictionary *info) {
                                      
                                      if(![info[PHImageResultIsDegradedKey] boolValue])
                                      {
                                          assetImage.photoImage = result;
                                          [fileSerializer writeObject:result toRelativePath:assetImage.fileName];
                                          dispatch_group_leave(imageLoadGroup);
                                      }
                                  }];
        
        dispatch_group_enter(imageLoadGroup);
        [self.imageManager requestImageForAsset:asset
                                     targetSize:[(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout itemSize]
                                    contentMode:PHImageContentModeAspectFill
                                        options:nil
                                  resultHandler:^(UIImage *result, NSDictionary *info) {
                                      
                                      if(![info[PHImageResultIsDegradedKey] boolValue])
                                      {
                                          [fileSerializer writeObject:result toRelativePath:assetImage.thumbnailFileName];
                                          dispatch_group_leave(imageLoadGroup);
                                      }
                                  }];
        
        [_album addCJMImage:assetImage];
    }

    dispatch_group_notify(imageLoadGroup, dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[CJMAlbumManager sharedInstance] save];
        
        NSLog(@"%lu photos added successfully", (unsigned long)self.album.albumPhotos.count);
        
        NSLog(@"There are %lu photos present in the album", (unsigned long)[self.album.albumPhotos count]);
    });
    
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
    //preparing to check...
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration //resizes collectionView cells per sizeForItemAtIndexPath when user rotates device.
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

@end

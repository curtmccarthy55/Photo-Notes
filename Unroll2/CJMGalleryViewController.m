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
#import "CJMAListPickerViewController.h"
#import "CJMServices.h"
#import "CJMPhotoAlbum.h"
#import "CJMAlbumManager.h"
#import "CJMPhotoCell.h"
#import "CJMImage.h"
#import "CJMHudView.h"
#import "CJMFileSerializer.h"
#import <dispatch/dispatch.h>

#define CellSize [(UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout itemSize]

@import Photos;

@interface CJMGalleryViewController () <CJMAListPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource>
//UICollectionViewDelegateFlowLayout is a sub-protocol of UICollectionViewDelegate, so there's no need to list both.

@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) CJMFIGalleryViewController *fullImageVC;
@property (nonatomic) BOOL editMode;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *exportButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (nonatomic, strong) NSArray *selectedCells;
@property (strong, nonatomic) IBOutlet UIView *noPhotosView;

@end

@implementation CJMGalleryViewController

static NSString * const reuseIdentifier = @"GalleryCell";

#pragma mark - View prep and display

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.title = self.album.albumTitle;
}

//Make sure nav bars and associated controls are visible whenever the scene appears.
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.editMode = NO;
    [self toggleEditControls];
    self.navigationController.navigationBar.alpha = 1;
    self.navigationController.toolbar.alpha = 1;
    [self confirmEditButtonEnabled];
    
    [self.collectionView reloadData];
}

//Add photo count footer to gallery.
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
    
    UILabel *footerLabel = (UILabel *)[footer viewWithTag:100];
    if (_album.albumPhotos.count > 1) {
        footerLabel.text = [NSString stringWithFormat:@"%lu Photos", (unsigned long)_album.albumPhotos.count];
    } else if (_album.albumPhotos.count == 1) {
        footerLabel.text = @"1 Photo";
    } else {
        footerLabel.text = nil;
    }
    
    return footer;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

//If any cells are selected when exiting the scene, set their cellSelectCover back to hidden.
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.collectionView.indexPathsForSelectedItems.count > 0) {
        for (NSIndexPath *indexPath in self.collectionView.indexPathsForSelectedItems) {
            CJMImage *selectedItem = [self.album.albumPhotos objectAtIndex:indexPath.item];
            selectedItem.selectCoverHidden = YES;
        }
    }
}

#pragma mark - collectionView data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.album.albumPhotos count];
}

//Add thumbnail to image and, if it's currently selected for editing, reveal it's cellSelectCover.
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMPhotoCell *cell = (CJMPhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    CJMImage *imageForCell = self.album.albumPhotos[indexPath.row];
    
    [cell updateWithImage:imageForCell];
    
    cell.cellSelectCover.hidden = imageForCell.selectCoverHidden;
    
    return cell;
}

#pragma mark - collectionView delegate

//If in editing mode, mark cell as selected and reveal cellCover and enable delete/transfer buttons.
//Otherwise, segue to full image.
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editMode == NO) {
        CJMImage *selectedImage = [self.album.albumPhotos objectAtIndex:indexPath.item];
        selectedImage.selectCoverHidden = YES;
        [self shouldPerformSegueWithIdentifier:@"ViewPhoto" sender:nil];
    } else if (self.editMode == YES) {
        [self shouldPerformSegueWithIdentifier:@"ViewPhoto" sender:nil];
        CJMPhotoCell *selectedCell = (CJMPhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        CJMImage *selectedImage = (CJMImage *)[self.album.albumPhotos objectAtIndex:indexPath.row];
        selectedImage.selectCoverHidden = NO;
        selectedCell.cellSelectCover.hidden = selectedImage.selectCoverHidden;
        self.deleteButton.enabled = YES;
        self.exportButton.enabled = YES;
    }
}

//Hide cellSelectCover and, if this was the last selected cell, disable the delete/transfer buttons.
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMPhotoCell *deselectedCell = (CJMPhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    CJMImage *deselectedImage = (CJMImage *)[self.album.albumPhotos objectAtIndex:indexPath.row];
    deselectedImage.selectCoverHidden = YES;
    deselectedCell.cellSelectCover.hidden = deselectedImage.selectCoverHidden;
    
    if ([self.collectionView indexPathsForSelectedItems].count == 0) {
        self.deleteButton.enabled = NO;
        self.exportButton.enabled = NO;
    }
}

//For all currently selected cells, switch their selected status to NO and hide cellSelectCovers.
- (void)clearCellSelections
{
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForSelectedItems])
    {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        CJMPhotoCell *cell = (CJMPhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        CJMImage *imageForCell = (CJMImage *)[self.album.albumPhotos objectAtIndex:indexPath.row];
        imageForCell.selectCoverHidden = YES;
        cell.cellSelectCover.hidden = imageForCell.selectCoverHidden;
    }
}

#pragma mark - Navigation

//Set up for segue to FullImageView.
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ViewPhoto"]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];
        CJMFIGalleryViewController *vc = (CJMFIGalleryViewController *)segue.destinationViewController;
        vc.albumName = _album.albumTitle;
        vc.albumCount = _album.albumPhotos.count;
        vc.initialIndex = indexPath.item;
    }
}

//Make navTitle = current album title.
- (void)setAlbum:(CJMPhotoAlbum *)album
{
    _album = album;
    self.navigationItem.title = album.albumTitle;
}

//Used to prevent FullImageView segue if currently in edit mode (multiple cells can be selected).
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if (self.editMode == YES) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - NavBar items

//Switch to determine edit conditions.
- (IBAction)toggleEditMode:(id)sender
{
    if ([self.editButton.title isEqualToString:@"Select"]) {
        [self.editButton setTitle:@"Cancel"];
        self.editMode = YES;
        [self toggleEditControls];
        self.collectionView.allowsMultipleSelection = YES;
    } else if ([self.editButton.title isEqualToString:@"Cancel"]) {
        [self.editButton setTitle:@"Select"];
        self.editMode = NO;
        [self clearCellSelections];
        [self toggleEditControls];
        self.selectedCells = nil;
        self.collectionView.allowsMultipleSelection = NO;
    }
}

//Changing navBar buttons based on current edit status.
- (void)toggleEditControls
{
    if (self.editMode == YES) {
        self.cameraButton.enabled = NO;
        self.deleteButton.title = @"Delete";
        self.deleteButton.enabled = NO;
        self.exportButton.title = @"Transfer";
        self.exportButton.enabled = NO;
    } else {
        self.cameraButton.enabled = YES;
        self.deleteButton.title = nil;
        self.deleteButton.enabled = NO;
        self.exportButton.title = nil;
        self.exportButton.enabled = NO;
    }
}

//Updates for scene if no photos are in the album.
- (void)confirmEditButtonEnabled
{
    if (self.album.albumPhotos.count == 0) {
        self.editButton.enabled = NO;
        
        UIAlertController *noPhotosAlert = [UIAlertController alertControllerWithTitle:@"No photos added yet" message:@"Tap the camera below to add photos" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
        [noPhotosAlert addAction:dismissAction];
        
        [self presentViewController:noPhotosAlert animated:YES completion:nil];
    } else {
        self.editButton.enabled = YES;
    }
}

//Acquire photo library permission and provide paths to user camera and photo library for photo import.
- (IBAction)photoGrab:(id)sender
{
    //__weak CJMGalleryViewController *weakSelf = self;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    //Access camera
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
    
    //Access photo library
    UIAlertAction *libraryAction = [UIAlertAction actionWithTitle:@"Choose From Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionForLibrary) {
        
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
            if (status != PHAuthorizationStatusAuthorized) {
                UIAlertController *adjustPrivacyController = [UIAlertController alertControllerWithTitle:@"Denied access to Photos" message:@"You will need to give Photo Notes permission to import from your Photo Library.\n\nPlease allow Photo Notes access to your Camera Roll by going to Settings>Privacy>Photos." preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
                
                [adjustPrivacyController addAction:dismiss];
                
                [self presentViewController:adjustPrivacyController animated:YES completion:nil];
            } else {
                [self presentPhotoGrabViewController];
            }
        }];
    }];
    
    //Adds a cancel button
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *actionCancel) {}];
    
    [alertController addAction:cameraAction];
    [alertController addAction:libraryAction];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

//Method to present users photo library
- (void)presentPhotoGrabViewController
{
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    UINavigationController *navigationVC = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoGrabViewController"];
    CJMPhotoGrabViewController *vc = (CJMPhotoGrabViewController *)[navigationVC topViewController];
    vc.title = @"Select Photos";
    vc.delegate = self;
    [self presentViewController:navigationVC animated:YES completion:nil];
}

//Mass delete options
- (IBAction)deleteSelcted:(id)sender
{
    self.selectedCells = [NSArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete photos?" message:@"You cannot recover these photos after deleting." preferredStyle:UIAlertControllerStyleActionSheet];
    
/* IMPROVING AND ADDING LATER : functionality for mass export and delete on images.
//TODO: Save selected photos to Photos app and then delete
    UIAlertAction *saveThenDeleteAction = [UIAlertAction actionWithTitle:@"Save to Photos app and then delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToSaveThenDelete){
        
        CJMHudView *hudView = [CJMHudView hudInView:self.navigationController.view
                                           withType:@"Pending"
                                           animated:YES];
        
        hudView.text = @"Exporting";
        
        __block UIImage *fullImage = [[UIImage alloc] init];
        
            for (NSIndexPath *itemPath in _selectedCells) {
                CJMImage *doomedImage = [_album.albumPhotos objectAtIndex:itemPath.row];
                [[CJMServices sharedInstance] fetchImage:doomedImage handler:^(UIImage *fetchedImage) {
                    fullImage = fetchedImage;
                }];
                UIImageWriteToSavedPhotosAlbum(fullImage, nil, nil, nil);
                fullImage = nil;
                
                [[CJMServices sharedInstance] deleteImage:doomedImage];
            }
            NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
            for (NSIndexPath *itemPath in _selectedCells) {
                [indexSet addIndex:itemPath.row];
            }
        [self.album removeCJMImagesAtIndexes:indexSet];
        
        [[CJMAlbumManager sharedInstance] save];
        
        [self.collectionView deleteItemsAtIndexPaths:_selectedCells];
        
        [self toggleEditMode:self];
        NSLog(@"photoAlbum count = %ld", (unsigned long)self.album.albumPhotos.count);
        
        [self confirmEditButtonEnabled];
        
        [self.collectionView performSelector:@selector(reloadData) withObject:nil afterDelay:0.4];
    }];
 */
    
    //Delete photos without saving to Photos app
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete Photos Permanently" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToDeletePermanently) {
       
        for (NSIndexPath *itemPath in _selectedCells) {
            CJMImage *doomedImage = [_album.albumPhotos objectAtIndex:itemPath.row];
            [[CJMServices sharedInstance] deleteImage:doomedImage];
        }
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        for (NSIndexPath *itemPath in _selectedCells) {
            [indexSet addIndex:itemPath.row];
        }
        [self.album removeCJMImagesAtIndexes:indexSet];
        
        [[CJMAlbumManager sharedInstance] save];
        
        [self.collectionView deleteItemsAtIndexPaths:_selectedCells];
        
        [self toggleEditMode:self];
        
        [self confirmEditButtonEnabled];
        
        [self.collectionView performSelector:@selector(reloadData) withObject:nil afterDelay:0.4];
        }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];

//    [alertController addAction:saveThenDeleteAction]; IMPROVING AND ADDING LATER : see above **
    [alertController addAction:deleteAction];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

//Mass transfer options
- (IBAction)exportSelected:(id)sender
{
    self.selectedCells = [NSArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Transfer:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
/* IMPROVING AND ADDING LATER : functionality for mass copy of selected photos
//TODO: Copy selected photos to Camera Roll in the Photos app.
    UIAlertAction *photosAppExport = [UIAlertAction actionWithTitle:@"Copies of photos to Photos App" style:UIAlertActionStyleDefault handler:^(UIAlertAction *sendToPhotosApp) {
        
        __block UIImage *fullImage = [[UIImage alloc] init];

        for (NSIndexPath *itemPath in _selectedCells) {
            CJMImage *copiedImage = [_album.albumPhotos objectAtIndex:itemPath.row];
            [[CJMServices sharedInstance] fetchImage:copiedImage handler:^(UIImage *fetchedImage) {
                fullImage = fetchedImage;
            }];
            //Run this asynchronously?
            UIImageWriteToSavedPhotosAlbum(fullImage, nil, nil, nil);
            //fullImage = nil;
        }
        
        CJMHudView *hudView = [CJMHudView hudInView:self.navigationController.view
                                           withType:@"Success"
                                           animated:YES];
        
        hudView.text = @"Done!";
        
        [hudView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.5f];
        self.navigationController.view.userInteractionEnabled = YES;
        
        [self toggleEditMode:self];
    }];
*/
    
    //Copy the selected photos to another album within Photo Notes.
    UIAlertAction *alternateAlbumExport = [UIAlertAction actionWithTitle:@"Photos And Notes To Alternate Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction *sendToAlternateAlbum) {
        NSString *storyboardName = @"Main";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
        UINavigationController *vc = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"AListPickerViewController"];
        CJMAListPickerViewController *aListPickerVC = (CJMAListPickerViewController *)[vc topViewController];
        aListPickerVC.delegate = self;
        aListPickerVC.title = @"Select Destination";
        [self presentViewController:vc animated:YES completion:nil];

    }];
    
    //Cancel action
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];
    
//    [alertController addAction:photosAppExport]; IMPROVING AND ADDING LATER : see above **
    [alertController addAction:alternateAlbumExport];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

#pragma mark - image picker delegate

//Converting photo captured by in-app camera to CJMImage.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *newPhoto = [info objectForKey:UIImagePickerControllerOriginalImage];
    CJMImage *newImage = [[CJMImage alloc] init];
    newImage.photoCreationDate = [NSDate date];

    UIImage *thumbnail = [self getCenterMaxSquareImageByCroppingImage:newPhoto andShrinkToSize:CellSize];
    
    CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
    
    [fileSerializer writeObject:newPhoto toRelativePath:newImage.fileName];
    [fileSerializer writeObject:thumbnail toRelativePath:newImage.thumbnailFileName];
    newImage.photoTitle = @"No Title Created ";
    newImage.photoNote = @"Tap Edit to change the title and note!";
    newImage.selectCoverHidden = YES;
    [_album addCJMImage:newImage];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [[CJMAlbumManager sharedInstance] save];
}

#pragma mark - Thumbnail Creation Code

//Holy Grail of of thumbnail creation.  Well... Holy Dixie Cup may be more appropriate.
//Takes full UIImage and compresses to thumbnail with size ~100KB.
- (UIImage *)getCenterMaxSquareImageByCroppingImage:(UIImage *)image andShrinkToSize:(CGSize)newSize
{
    //Get crop bounds
    CGSize centerSquareSize;
    double originalImageWidth = CGImageGetWidth(image.CGImage);
    double originalImageHeight = CGImageGetHeight(image.CGImage);
    if (originalImageHeight <= originalImageWidth) {
        centerSquareSize.width = originalImageHeight;
        centerSquareSize.height = originalImageHeight;
    } else {
        centerSquareSize.width = originalImageWidth;
        centerSquareSize.height = originalImageWidth;
    }
    //Determine crop origin
    double x = (originalImageWidth - centerSquareSize.width) / 2.0;
    double y = (originalImageHeight - centerSquareSize.height) / 2.0;
    
    //Crop and create CGImageRef.  This is where an improvement likely lies.
    CGRect cropRect = CGRectMake(x, y, centerSquareSize.height, centerSquareSize.width);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef scale:0.0 orientation:image.imageOrientation];
    
    //Scale the image down to the smaller file size and return
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [cropped drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGImageRelease(imageRef);
    return newImage;

}

#pragma mark - CJMPhotoGrabber Delegate

- (void)photoGrabViewControllerDidCancel:(CJMPhotoGrabViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

//iterate through array of selected photos, convert them to CJMImages, and add to the current album.  (uses PhotoKit)
- (void)photoGrabViewController:(CJMPhotoGrabViewController *)controller didFinishSelectingPhotos:(NSArray *)photos
{
    NSLog(@"%lu photos received by the gallery", (unsigned long)photos.count);
    
    //Pull the images, image creation dates, and image locations from each PHAsset in the received array.
    CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
    
    if (!_imageManager) {
        _imageManager = [[PHCachingImageManager alloc] init];
    }
    
    dispatch_group_t imageLoadGroup = dispatch_group_create();
    for (int i = 0; i < photos.count; i++) {
        @autoreleasepool {
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
                                          
                                          //Compression code
                                          UIImage *thumbnail = [self getCenterMaxSquareImageByCroppingImage:result
                                                                     andShrinkToSize:CellSize];
                                          [fileSerializer writeObject:thumbnail
                                                       toRelativePath:assetImage.thumbnailFileName];
                                          
                                          
                                          dispatch_group_leave(imageLoadGroup);
                                      }
                                  }];
        
        assetImage.photoTitle = @"No Title Created ";
        assetImage.photoNote = @"Tap Edit to change the title and note!";
        assetImage.selectCoverHidden = YES;
        [_album addCJMImage:assetImage];
        }
    }
    dispatch_group_notify(imageLoadGroup, dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[CJMAlbumManager sharedInstance] save];
        self.navigationController.view.userInteractionEnabled = YES;

    });
    
}

#pragma mark - CJMAListPicker Delegate

//Dismiss list of albums to transfer photos to and deselect previously selected photos.
- (void)aListPickerViewControllerDidCancel:(CJMAListPickerViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self toggleEditMode:self];
}

//take CJMImages in selected cells in current album (self.album) and transfer them to the picked album.
- (void)aListPickerViewController:(CJMAListPickerViewController *)controller didFinishPickingAlbum:(CJMPhotoAlbum *)album
{
    for (NSIndexPath *itemPath in _selectedCells) {
        CJMImage *imageToTransfer = [_album.albumPhotos objectAtIndex:itemPath.row];
        imageToTransfer.selectCoverHidden = YES;
        [album addCJMImage:imageToTransfer];
        if (imageToTransfer.isAlbumPreview == YES) {
            [imageToTransfer setIsAlbumPreview:NO];
            self.album.albumPreviewImage = nil;
        }
    }
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *itemPath in _selectedCells) {
        [indexSet addIndex:itemPath.row];
    }
    [self.album removeCJMImagesAtIndexes:indexSet];
    
    if (self.album.albumPreviewImage == nil && self.album.albumPhotos.count > 0) {
        [[CJMAlbumManager sharedInstance] albumWithName:self.album.albumTitle
                              createPreviewFromCJMImage:(CJMImage *)[self.album.albumPhotos objectAtIndex:0]];
    }
    
    [[CJMAlbumManager sharedInstance] save];
    [self.collectionView deleteItemsAtIndexPaths:_selectedCells];
    [self toggleEditMode:self];
    [self.collectionView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
    [self confirmEditButtonEnabled];
    
    //Presents and dismisses HUD confirming action complete.
    CJMHudView *hudView = [CJMHudView hudInView:self.navigationController.view
                                       withType:@"Success"
                                       animated:YES];
    hudView.text = @"Done!";
    [hudView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.5f];
    [self.collectionView performSelector:@selector(reloadData) withObject:nil afterDelay:0.2];
    self.navigationController.view.userInteractionEnabled = YES;
}

#pragma mark - collectionViewFlowLayout Delegate

//Establishes cell size based on device screen size.  4 cells across in portrait, 5 cells across in landscape.
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

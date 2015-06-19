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

@import Photos;

@interface CJMGalleryViewController () <CJMAListPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
//UICollectionViewDelegateFlowLayout is a sub-protocol of UICollectionViewDelegate, so there's no need to list both.

@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) CJMFIGalleryViewController *fullImageVC;
@property (nonatomic) BOOL editMode;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *exportButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (nonatomic, strong) NSArray *selectedCells;

@end

@implementation CJMGalleryViewController

static NSString * const reuseIdentifier = @"GalleryCell";

#pragma mark - View prep and display

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.editMode = NO;
    
    [self toggleEditControls];
    
    self.navigationController.navigationBar.alpha = 1;
    self.navigationController.toolbar.alpha = 1;
    
    [self.collectionView reloadData];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.album.albumPhotos.count == 0) {
        UIAlertController *noPhotosAlert = [UIAlertController alertControllerWithTitle:@"No photos added yet" message:@"Tap the camera below to add photos" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
        
        [noPhotosAlert addAction:dismissAction];
        
        [self presentViewController:noPhotosAlert animated:YES completion:nil];
    }
    
    NSLog(@"Gallery view appeared");
}

-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
    
    UILabel *footerLabel = (UILabel *)[footer viewWithTag:100];
    footerLabel.text = [NSString stringWithFormat:@"%lu Photos", (unsigned long)_album.albumPhotos.count];
    
    return footer;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - collectionView data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.album.albumPhotos count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMPhotoCell *cell = (CJMPhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    CJMImage *imageForCell = (CJMImage *)[self.album.albumPhotos objectAtIndex:indexPath.item];
    
    [cell updateWithImage:imageForCell];
    
    return cell;
}

#pragma mark - collectionView delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.editMode == NO) {
        [self shouldPerformSegueWithIdentifier:@"ViewPhoto" sender:nil];
    } else if (self.editMode == YES) {
        [self shouldPerformSegueWithIdentifier:@"ViewPhoto" sender:nil];
        CJMPhotoCell *selectedCell = (CJMPhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        CJMImage *selectedImage = (CJMImage *)[self.album.albumPhotos objectAtIndex:indexPath.row];
        [selectedImage toggleSelected];
        selectedCell.cellSelectCover.hidden = selectedImage.selected;
        self.deleteButton.enabled = YES;
        self.exportButton.enabled = YES;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMPhotoCell *deselectedCell = (CJMPhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    CJMImage *deselectedImage = (CJMImage *)[self.album.albumPhotos objectAtIndex:indexPath.row];
    [deselectedImage toggleSelected];
    deselectedCell.cellSelectCover.hidden = deselectedImage.selected;
    
    if ([self.collectionView indexPathsForSelectedItems].count == 0) {
        self.deleteButton.enabled = NO;
        self.exportButton.enabled = NO;
    }
}


- (void)clearCellSelections
{
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForSelectedItems])
    {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        CJMPhotoCell *cell = (CJMPhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        CJMImage *imageForCell = (CJMImage *)[self.album.albumPhotos objectAtIndex:indexPath.row];
        
        [imageForCell toggleSelected];
        cell.cellSelectCover.hidden = imageForCell.selected;
    }
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

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if (self.editMode == YES) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - NavBar items

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

- (IBAction)photoGrab:(id)sender
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

- (IBAction)deleteSelcted:(id)sender
{
    self.selectedCells = [NSArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete photos?" message:@"You cannot recover these photos after deleting." preferredStyle:UIAlertControllerStyleActionSheet];
    
    //Save selected photos to Photos app and then delete
    UIAlertAction *saveThenDeleteAction = [UIAlertAction actionWithTitle:@"Save to Photos app and then delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToSaveThenDelete){
        
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
        
        [self.collectionView reloadData];
    }];
    
    //Delete photos without saving to Photos app
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete photos permanently" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToDeletePermanently) {
       
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
        
        [self.collectionView reloadData];
        }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];
    
    [alertController addAction:saveThenDeleteAction];
    [alertController addAction:deleteAction];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)exportSelected:(id)sender
{
    self.selectedCells = [NSArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Transfer:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    //Copy selected photos to Camera Roll in the Photos app.
    UIAlertAction *photosAppExport = [UIAlertAction actionWithTitle:@"Copies of photos to Photos App" style:UIAlertActionStyleDefault handler:^(UIAlertAction *sendToPhotosApp) {
        
        __block UIImage *fullImage = [[UIImage alloc] init];
        
        for (NSIndexPath *itemPath in _selectedCells) {
            CJMImage *doomedImage = [_album.albumPhotos objectAtIndex:itemPath.row];
            [[CJMServices sharedInstance] fetchImage:doomedImage handler:^(UIImage *fetchedImage) {
                fullImage = fetchedImage;
            }];
            UIImageWriteToSavedPhotosAlbum(fullImage, nil, nil, nil);
            fullImage = nil;
        }
        
        CJMHudView *hudView = [CJMHudView hudInView:self.navigationController.view animated:YES];
        
        hudView.text = @"Done!";
        hudView.type = @"Success";
        
        [hudView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.5f];
        
        [self toggleEditMode:self];
    }];
    
    //Copy the selected photos to another album within Photo Notes.
    UIAlertAction *alternateAlbumExport = [UIAlertAction actionWithTitle:@"Photos and notes to alternate album" style:UIAlertActionStyleDefault handler:^(UIAlertAction *sendToAlternateAlbum) {
        NSString * storyboardName = @"Main";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
        UINavigationController *vc = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"AListPickerViewController"];
        CJMAListPickerViewController *aListPickerVC = (CJMAListPickerViewController *)[vc topViewController];
        aListPickerVC.delegate = self;
        [self presentViewController:vc animated:YES completion:nil];

    }];
    
    //Cancel action
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];
    
    [alertController addAction:photosAppExport];
    [alertController addAction:alternateAlbumExport];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

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
        
        assetImage.photoTitle = @"No Title";
        assetImage.photoNote = @"No Note Entered";
        [_album addCJMImage:assetImage];
    }

    dispatch_group_notify(imageLoadGroup, dispatch_get_main_queue(), ^{
        [self.collectionView reloadData];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[CJMAlbumManager sharedInstance] save];
        
        NSLog(@"%lu photos added successfully", (unsigned long)self.album.albumPhotos.count);
        
        NSLog(@"There are %lu photos present in the album", (unsigned long)[self.album.albumPhotos count]);
    });
    
    self.navigationController.view.userInteractionEnabled = YES;
    
}

#pragma mark - CJMAListPicker Delegate

- (void)aListPickerViewControllerDidCancel:(CJMAListPickerViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [self toggleEditMode:self];
}

- (void)aListPickerViewController:(CJMAListPickerViewController *)controller didFinishPickingAlbum:(CJMPhotoAlbum *)album
{
    //take CJMImages in selected cells in current album (self.album) and copy them to the picked album.
    for (NSIndexPath *itemPath in _selectedCells) {
        CJMImage *imageToTransfer = [_album.albumPhotos objectAtIndex:itemPath.row];
        [album addCJMImage:imageToTransfer];
    }
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *itemPath in _selectedCells) {
        [indexSet addIndex:itemPath.row];
    }
    [self.album removeCJMImagesAtIndexes:indexSet];
    
    [[CJMAlbumManager sharedInstance] save];
    
    [self.collectionView deleteItemsAtIndexPaths:_selectedCells];
    
    [self toggleEditMode:self];
    
    [self.collectionView reloadData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    CJMHudView *hudView = [CJMHudView hudInView:self.navigationController.view animated:YES];
    
    hudView.text = @"Done!";
    hudView.type = @"Success";
    
    [hudView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.5f];
    
    self.navigationController.view.userInteractionEnabled = YES;

}

#pragma mark - collectionViewFlowLayout Delegate

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

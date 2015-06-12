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
@property (nonatomic) BOOL editMode;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *exportButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cameraButton;

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
    
    [cell updateWithImage:_album.albumPhotos[indexPath.item]];
    
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
        selectedCell.cellSelectCover.hidden = NO;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMPhotoCell *deselectedCell = (CJMPhotoCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    deselectedCell.cellSelectCover.hidden = YES;
}

- (void)clearCellSelections
{
    //NSInteger collectonViewCount = [self.collectionView numberOfItemsInSection:0];
    for (CJMPhotoCell *cell in self.collectionView.visibleCells)
    {
        cell.cellSelectCover.hidden = YES;
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
    if ([self.editButton.title isEqualToString:@"Edit"]) {
        [self.editButton setTitle:@"Done"];
        self.editMode = YES;
        [self toggleEditControls];
        self.collectionView.allowsMultipleSelection = YES;
    } else if ([self.editButton.title isEqualToString:@"Done"]) {
        [self.editButton setTitle:@"Edit"];
        self.editMode = NO;
//        [self clearCellSelections];
        [self toggleEditControls];
        self.collectionView.allowsMultipleSelection = NO;
    }
}

- (void)toggleEditControls
{
    if (self.editMode == YES) {
        self.cameraButton.enabled = NO;
        self.deleteButton.title = @"Delete";
        self.deleteButton.enabled = YES;
        self.exportButton.title = @"Export";
        self.exportButton.enabled = YES;
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
    NSArray *selectedCells = [NSArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete photos?" message:@"You cannot recover these photos after deleting." preferredStyle:UIAlertControllerStyleActionSheet];
    
    //Save selected photos to Photos app and then delete
    UIAlertAction *saveThenDeleteAction = [UIAlertAction actionWithTitle:@"Save to Photos app and then delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToSaveThenDelete){
        
        __block UIImage *fullImage = [[UIImage alloc] init];
        
            for (NSIndexPath *itemPath in selectedCells) {
                CJMImage *doomedImage = [_album.albumPhotos objectAtIndex:itemPath.row];
                [[CJMServices sharedInstance] fetchImage:doomedImage handler:^(UIImage *fetchedImage) {
                    fullImage = fetchedImage;
                }];
                UIImageWriteToSavedPhotosAlbum(fullImage, nil, nil, nil);
                fullImage = nil;
                
                [[CJMServices sharedInstance] deleteImage:doomedImage];
            }
            NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
            for (NSIndexPath *itemPath in selectedCells) {
                [indexSet addIndex:itemPath.row];
            }
        [self.album removeCJMImagesAtIndexes:indexSet];
        
        [[CJMAlbumManager sharedInstance] save];
        
        [self.collectionView deleteItemsAtIndexPaths:selectedCells];
        
        [self toggleEditMode:self];
        
        [self.collectionView reloadData];
    }];
    
    //Delete photos without saving to Photos app
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete photos permanently" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToDeletePermanently) {
       
        for (NSIndexPath *itemPath in selectedCells) {
            CJMImage *doomedImage = [_album.albumPhotos objectAtIndex:itemPath.row];
            [[CJMServices sharedInstance] deleteImage:doomedImage];
        }
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        for (NSIndexPath *itemPath in selectedCells) {
            [indexSet addIndex:itemPath.row];
        }
        [self.album removeCJMImagesAtIndexes:indexSet];
        
        [[CJMAlbumManager sharedInstance] save];
        
        [self.collectionView deleteItemsAtIndexPaths:selectedCells];
        
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

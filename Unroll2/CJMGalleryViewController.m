//
//  CJMGalleryViewController.m
//  Unroll
//
//  Created by Curt on 4/13/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMGalleryViewController.h"
#import "CJMPageImageViewController.h"
#import "CJMFullImageViewController.h"
#import "CJMAListPickerViewController.h"
#import "CJMServices.h"
#import "CJMPhotoAlbum.h"
#import "CJMAlbumManager.h"
#import "CJMPhotoCell.h"
#import "CJMImage.h"
#import "CJMHudView.h"
#import "CJMFileSerializer.h"
#import "PHNPhotoGrabCompletionDelegate.h"
#import "PHNImportAlbumsVC.h"
#import <AVFoundation/AVFoundation.h>
#import <dispatch/dispatch.h>

@import Photos;

@interface CJMGalleryViewController () <CJMAListPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) CJMPageImageViewController *fullImageVC;
@property (nonatomic) BOOL editMode;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *exportButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (nonatomic, strong) NSArray *selectedCells;
@property (nonatomic, strong) NSMutableArray *pickerPhotos;

@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIImageView *capturedPhotos;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIButton *cameraCancelButton;
@property (nonatomic, strong) UIButton *cameraFlipButton;
@property (nonatomic) UIDeviceOrientation lastOrientation;

@property (nonatomic, readonly) CGSize cellSize;
@property (nonatomic) CGFloat newCellSize;


@end

@implementation CJMGalleryViewController

static NSString * const reuseIdentifier = @"GalleryCell";

#pragma mark - Scene set up
// override func viewDidLoad() {
- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.title = self.album.albumTitle;
    self.navigationItem.backBarButtonItem.title = @"Albums";
    
    //scroll to bottom before displaying
    CGSize viewSize = self.view.bounds.size;
    CGPoint contentOffset = CGPointMake(0, viewSize.height * self.album.albumPhotos.count - 1);
    [self.collectionView setContentOffset:contentOffset animated:NO];
}
// var cellSize: CGSize { get }
- (CGSize)cellSize {
    CGFloat columnSpaces;
    if (UIScreen.mainScreen.bounds.size.height > UIScreen.mainScreen.bounds.size.width) {
        //Portrait
        columnSpaces = 3.0;
    } else {
        //Landscape
        columnSpaces = 5.0;
    }
    
    CGFloat sideLength;
    sideLength = (self.view.bounds.size.width - self.view.safeAreaInsets.left - self.view.safeAreaInsets.right) / columnSpaces;
    CGSize returnSize = CGSizeMake(sideLength, sideLength);
    return returnSize;
}
// override var prefersStatusBarHidden: Bool {
-(BOOL)prefersStatusBarHidden {
    NSLog(@"GalleryVC prefersStatusBarHidden called.");
    return NO;
}

// override func viewWillAppear(_ animated: Bool) {
//Make sure nav bars and associated controls are visible whenever the gallery appears.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear called");
    self.editMode = NO;
    [self toggleEditControls];
    [self.navigationController.navigationBar setHidden:NO];
    [self.navigationController.toolbar setHidden:NO];
    [self.navigationController.navigationBar setPrefersLargeTitles:YES];
    [self confirmEditButtonEnabled];

    self.newCellSize = 0.0;
    [self.collectionView reloadData];
    
    if ([self.album.albumTitle isEqualToString:@"Favorites"]) {
        [self.cameraButton setEnabled:NO];
        if ([[CJMAlbumManager sharedInstance].favPhotosAlbum.albumPhotos count] < 1) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}
// func photoCellForWidth(_ saWidth: CGFloat) {
- (void)photoCellForWidth:(CGFloat)saWidth { //cjm cellSize
    CGFloat cellsPerRow = 0.0;
//    CGFloat cellSpacing = 1.0;
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (UIDeviceOrientationIsLandscape(orientation)) {
        cellsPerRow = 6.0;
    } else {
        cellsPerRow = 4.0;
    }
    self.newCellSize = (saWidth - (cellsPerRow + 1.0)/* * cellSpacing*/) / cellsPerRow;
    NSLog(@"photoCellForWidth newCellSize == %f", self.newCellSize);
}
// override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator { //cjm cellSize
    NSLog(@"viewWillTransitionToSize size.width == %f, size.height == %f", size.width, size.height);
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.newCellSize = 0.0;
    [self.collectionViewLayout invalidateLayout];
}

// override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//Add photo count footer to gallery.
-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *footer = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"Footer" forIndexPath:indexPath];
    
    UILabel *footerLabel = (UILabel *)[footer viewWithTag:100];
    if (self.album.albumPhotos.count > 1) {
        footerLabel.text = [NSString stringWithFormat:@"%lu Photos", (unsigned long)self.album.albumPhotos.count];
    } else if (self.album.albumPhotos.count == 1) {
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

//If any cells are selected when exiting the gallery, set their cellSelectCover property back to hidden.
// override func viewWillDisappear(_ animated: Bool) {
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
// override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.album.albumPhotos count];
}

//Add thumbnail to image and, if it's currently selected for editing, reveal it's cellSelectCover.
// override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CJMPhotoCell *cell = (CJMPhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    CJMImage *imageForCell = self.album.albumPhotos[indexPath.row];
    
    [cell updateWithImage:imageForCell];
    
    if (imageForCell.thumbnailNeedsRedraw) {
        CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
        __block UIImage *tempFullImage = [[UIImage alloc] init];
        [[CJMServices sharedInstance] fetchImage:imageForCell handler:^(UIImage *fetchedImage) {
            tempFullImage = fetchedImage;
        }];
        UIImage *thumbnail = [self getCenterMaxSquareImageByCroppingImage:tempFullImage andShrinkToSize:self.cellSize];
        imageForCell.thumbnailNeedsRedraw = NO;
        [fileSerializer writeImage:thumbnail toRelativePath:imageForCell.thumbnailFileName];
        [cell updateWithImage:imageForCell];
//        NSLog(@"a thumbnail was redrawn");
        [[CJMAlbumManager sharedInstance] save];
    }
    
    cell.cellSelectCover.hidden = imageForCell.selectCoverHidden;
    
    return cell;
}

#pragma mark - collectionView delegate

//If in editing mode, mark cell as selected and reveal cellCover and enable delete/transfer buttons.
//Otherwise, segue to full image.
// override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
        self.exportButton.enabled = [self.album.albumTitle isEqualToString:@"Favorites"] ? NO : YES;
    }
}

//Hide cellSelectCover and, if this was the last selected cell, disable the delete/transfer buttons.
// override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
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
// func clearCellSelections() {
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
// override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ViewPhoto"]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];
        CJMPageImageViewController *vc = (CJMPageImageViewController *)segue.destinationViewController;
        vc.albumName = self.album.albumTitle;
        vc.albumCount = self.album.albumPhotos.count;
        vc.initialIndex = indexPath.item;
    }
}
// var album: PHNPhotoAlbum { didSet { navigationItem.title = album.albumTitle } }
- (void)setAlbum:(CJMPhotoAlbum *)album {
    _album = album;
    self.navigationItem.title = album.albumTitle;
}
// override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if (self.editMode == YES) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - NavBar items
// @IBAction func toggleEditMode() {
- (IBAction)toggleEditMode:(id)sender {
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
// func toggleEditControls {
- (void)toggleEditControls {
    if (self.editMode == YES) {
        self.cameraButton.enabled = NO;
        self.deleteButton.title = @"Delete";
        self.deleteButton.enabled = NO;
        self.exportButton.title = @"Transfer";
        self.exportButton.enabled = NO;
    } else {
        if (![self.album.albumTitle isEqualToString:@"Favorites"])
            self.cameraButton.enabled = YES;
        
        self.deleteButton.title = nil;
        self.deleteButton.enabled = NO;
        self.exportButton.title = nil;
        self.exportButton.enabled = NO;
    }
}
// func confirmEditButtonEnabled() {
- (void)confirmEditButtonEnabled {
    if (self.album.albumPhotos.count == 0) {
        self.editButton.enabled = NO;
        if (![self.album.albumTitle isEqualToString:@"Favorites"]){
            UIAlertController *noPhotosAlert = [UIAlertController alertControllerWithTitle:@"No photos added yet" message:@"Tap the camera below to add photos" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Take Picture" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionCamera) {
                [self openCamera];
            }];
            
            UIAlertAction *fetchAction = [UIAlertAction actionWithTitle:@"Choose From Library" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionFetch) {
                [self photosFromLibrary];
            }];
            
            UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil];
            
            [noPhotosAlert addAction:cameraAction];
            [noPhotosAlert addAction:fetchAction];
            [noPhotosAlert addAction:dismissAction];
            
            [self presentViewController:noPhotosAlert animated:YES completion:nil];
        }
    } else {
        self.editButton.enabled = YES;
    }
}

//Acquire photo library permission and provide paths to user camera and photo library for photo import.
// @IBAction func photoGrab() {
- (IBAction)photoGrab:(id)sender {
    //__weak CJMGalleryViewController *weakSelf = self;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    //Access camera
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionForCamera) {
        [self openCamera];
    }];
    
    //Access photo library
    UIAlertAction *libraryAction = [UIAlertAction actionWithTitle:@"Choose From Library"       style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionForLibrary) {
            [self photosFromLibrary];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction *actionCancel) {}];
    
    [alertController addAction:cameraAction];
    [alertController addAction:libraryAction];
    [alertController addAction:cancel];
    
    alertController.popoverPresentationController.barButtonItem = self.cameraButton;
    [alertController.popoverPresentationController setPermittedArrowDirections:UIPopoverArrowDirectionDown];
    alertController.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:alertController animated:YES completion:nil];
}
// func photosFromLibrary() {
- (void)photosFromLibrary {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
        if (status != PHAuthorizationStatusAuthorized) {
            UIAlertController *adjustPrivacyController = [UIAlertController alertControllerWithTitle:@"Denied access to Photos" message:@"You will need to give Photo Notes permission to import from your Photo Library.\n\nPlease allow Photo Notes access to your Photo Library by going to Settings>Privacy>Photos." preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}];
            
            [adjustPrivacyController addAction:dismiss];
            
            [self presentViewController:adjustPrivacyController animated:YES completion:nil];
        } else {
            [self presentPhotoGrabViewController];
        }
    }];
}


//Present users photo library
// func presentPhotoGrabViewController() {
- (void)presentPhotoGrabViewController { //cjm album fetch
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    UINavigationController *navigationVC = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"NavPhotoGrabViewController"];
    PHNImportAlbumsVC *vc = (PHNImportAlbumsVC *)[navigationVC topViewController];
    vc.delegate = self;
    vc.userColor = self.userColor;
    vc.userColorTag = self.userColorTag;
    vc.singleSelection = NO;
    
    [self presentViewController:navigationVC animated:YES completion:nil];
}

//Mass delete options
// @IBAction func deleteSelected() {
- (IBAction)deleteSelcted:(id)sender {
    self.selectedCells = [NSArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete photos?" message:@"You cannot recover these photos after deleting." preferredStyle:UIAlertControllerStyleActionSheet];
    
// IMPROVING AND ADDING LATER : functionality for mass export and delete on images.
//TODO: Save selected photos to Photos app and then delete
    /*
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
        NSMutableArray *doomedArray = [NSMutableArray new];
        for (NSIndexPath *itemPath in self.selectedCells) {
            CJMImage *doomedImage = [self.album.albumPhotos objectAtIndex:itemPath.row];
            [doomedArray addObject:doomedImage];
        }
        [[CJMAlbumManager sharedInstance] albumWithName:self.album.albumTitle
                                               deleteImages:doomedArray];
        [[CJMAlbumManager sharedInstance] checkFavoriteCount];
        [[CJMAlbumManager sharedInstance] save];
        if (self.album.albumPhotos.count < 1) {
            [self.navigationController popViewControllerAnimated:YES];
        }
        [self.collectionView deleteItemsAtIndexPaths:self.selectedCells];
        [self toggleEditMode:self];
        [self confirmEditButtonEnabled];
        [self.collectionView performSelector:@selector(reloadData) withObject:nil afterDelay:0.4];
    }];

    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];

//    [alertController addAction:saveThenDeleteAction];
    [alertController addAction:deleteAction];
    [alertController addAction:cancel];
    
    alertController.popoverPresentationController.barButtonItem = self.deleteButton;
    alertController.popoverPresentationController.sourceView = self.view;
    [alertController.popoverPresentationController setPermittedArrowDirections:UIPopoverArrowDirectionDown];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

//Mass transfer options
// @IBAction func exportSelected() {
- (IBAction)exportSelected:(id)sender
{
    self.selectedCells = [NSArray arrayWithArray:[self.collectionView indexPathsForSelectedItems]];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Transfer:" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
// IMPROVING AND ADDING LATER : functionality for mass copy of selected photos
//TODO: Copy selected photos to Camera Roll in the Photos app.
    /*
    UIAlertAction *photosAppExport = [UIAlertAction actionWithTitle:@"Copies of photos to Photos App" style:UIAlertActionStyleDefault handler:^(UIAlertAction *sendToPhotosApp) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            __block UIImage *fullImage = [[UIImage alloc] init];

            for (NSIndexPath *itemPath in _selectedCells) {
                CJMImage *copiedImage = [_album.albumPhotos objectAtIndex:itemPath.row];
                [[CJMServices sharedInstance] fetchImage:copiedImage handler:^(UIImage *fetchedImage) {
                    fullImage = fetchedImage;
                }];
                UIImageWriteToSavedPhotosAlbum(fullImage, nil, nil, nil);

            }
        });
        
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
        aListPickerVC.currentAlbumName = self.album.albumTitle;
        aListPickerVC.userColor = self.userColor;
        aListPickerVC.userColorTag = self.userColorTag;
        [self presentViewController:vc animated:YES completion:nil]; //cjm 12/30
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];
    
//    [alertController addAction:photosAppExport];
    [alertController addAction:alternateAlbumExport];
    [alertController addAction:cancel];
    
    alertController.popoverPresentationController.barButtonItem = self.exportButton;
    [alertController.popoverPresentationController setPermittedArrowDirections:UIPopoverArrowDirectionDown];
    alertController.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - image picker delegate and controls
// func openCamera() {
- (void)openCamera { //cjm camera ui
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Camera Available" message:@"There's no camera available for Photo Notes to use." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionDismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *dismissAction) {}];
        [alert addAction:actionDismiss];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (authStatus != AVAuthorizationStatusAuthorized) {
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            if (granted) {
                [self prepAndDisplayCamera];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Camera Access Denied" message:@"You can give Photo Notes permission to use the camera in Settings>Privacy>Camera." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *actionDismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *dismissAction) {}];
                [alert addAction:actionDismiss];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    } else {
        [self prepAndDisplayCamera];
    }
}
// func prepAndDisplayCamera() {
- (void)prepAndDisplayCamera {
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.showsCameraControls = NO;
    self.imagePicker.allowsEditing = NO;
    self.imagePicker.delegate = self;
    self.imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    
    //determine if viewport needs translation, and find bottom bar height.
    CGFloat screenHeight = UIScreen.mainScreen.bounds.size.height;
    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
    CGFloat longDimension;
    CGFloat shortDimension;
    if (screenHeight > screenWidth) {
        longDimension = screenHeight;
        shortDimension = screenWidth;
    } else {
        longDimension = screenWidth;
        shortDimension = screenHeight;
    }
    CGFloat aspectRatio = 4.0 / 3.0;
    CGSize cameraFrame = CGSizeMake(shortDimension, shortDimension * aspectRatio);
    CGRect portraitFrame = CGRectMake(0, 0, shortDimension, longDimension);
    if (longDimension > 800) {
        //determine remaining space for buttonBar at bottom
        longDimension -= 44.0; //subtract top bar
        CGAffineTransform adjustHeight = CGAffineTransformMakeTranslation(0.0, 44.0); //cjm camera ui
        self.imagePicker.cameraViewTransform = adjustHeight;
    }
    CGFloat bottomBarHeight = longDimension - cameraFrame.height; //subtract viewport.
    
    UIView *overlay = [self cameraOverlayWithFrame:portraitFrame containerHeight:bottomBarHeight];
    [self.imagePicker setCameraOverlayView:overlay];
    self.imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    self.lastOrientation = UIDevice.currentDevice.orientation;
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(rotateCameraViews) name:UIDeviceOrientationDidChangeNotification object:nil]; //cjm 10/05
    
    [self presentViewController:self.imagePicker animated:YES completion:^{
        [self rotateCameraViews];
    }];
}
// @objc func rotateCameraViews() {
- (void)rotateCameraViews { //cjm 10/05
    UIDeviceOrientation orientation = UIDevice.currentDevice.orientation;
    double rotation = 1;
    switch (orientation) {
        case UIDeviceOrientationPortrait:
            rotation = 0;
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            rotation = M_PI_2;
            break;
            
        case UIDeviceOrientationLandscapeRight:
            rotation = -M_PI_2;
            break;
            
        default:
            break;
    }
    if (rotation != 1) {
        [UIView animateWithDuration:0.2 animations:^{
            self.capturedPhotos.transform = CGAffineTransformMakeRotation(rotation);
            self.flashButton.transform = CGAffineTransformMakeRotation(rotation);
            self.cameraFlipButton.transform = CGAffineTransformMakeRotation(rotation);
            self.doneButton.transform = CGAffineTransformMakeRotation(rotation);
            self.cameraCancelButton.transform = CGAffineTransformMakeRotation(rotation);
        }];
    }
    self.lastOrientation = orientation;
}
// func cameraOverlayWithFrame(_ overlayFrame: CGRect, containerHeight barHeight: CGFloat) -> UIView {
- (UIView *)cameraOverlayWithFrame:(CGRect)overlayFrame containerHeight:(CGFloat)barHeight {
    UIView *mainOverlay = [[UIView alloc] initWithFrame:overlayFrame];
    
    //create container view for buttons
    UIView *buttonBar = [[UIView alloc] init];
    [buttonBar setBackgroundColor:[UIColor clearColor]];
    [buttonBar setClipsToBounds:YES];
    [buttonBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    [mainOverlay addSubview:buttonBar];
    [buttonBar.centerXAnchor constraintEqualToAnchor:mainOverlay.centerXAnchor].active = YES;
    [buttonBar.bottomAnchor constraintEqualToAnchor:mainOverlay.bottomAnchor].active = YES;
    [buttonBar.widthAnchor constraintEqualToAnchor:mainOverlay.widthAnchor].active = YES;
    [buttonBar.heightAnchor constraintEqualToConstant:barHeight].active = YES;
    UILayoutGuide *saGuide = buttonBar.safeAreaLayoutGuide;
    
    //add top row of buttons
    //add top row container view
    UIView *topRow = [UIView new];
    [topRow setBackgroundColor:[UIColor clearColor]];
    [topRow setTranslatesAutoresizingMaskIntoConstraints:NO];
    [mainOverlay addSubview:topRow];
    [topRow.centerXAnchor constraintEqualToAnchor:saGuide.centerXAnchor].active = YES;
    [topRow.leadingAnchor constraintEqualToAnchor:saGuide.leadingAnchor].active = YES;
    [topRow.topAnchor constraintEqualToAnchor:saGuide.topAnchor].active = YES;
    [topRow.trailingAnchor constraintEqualToAnchor:saGuide.trailingAnchor].active = YES;
    [topRow.bottomAnchor constraintEqualToAnchor:saGuide.centerYAnchor].active = YES;
    UILayoutGuide *topGuide = topRow.safeAreaLayoutGuide;
    
    //add captured photos thumbnail
    self.capturedPhotos = [UIImageView new];
    [self.capturedPhotos.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [self.capturedPhotos.layer setBorderWidth:1.0];
    [self.capturedPhotos.layer setCornerRadius:5.0];
    [self.capturedPhotos setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.capturedPhotos setContentMode: UIViewContentModeScaleAspectFit];
    [self.capturedPhotos setImage:[UIImage imageNamed:@"NoImage"]];
    [topRow addSubview:self.capturedPhotos];
    [self.capturedPhotos.widthAnchor constraintEqualToAnchor:topGuide.heightAnchor multiplier:0.7].active = YES;
    [self.capturedPhotos.heightAnchor constraintEqualToAnchor:topGuide.heightAnchor multiplier:0.7].active = YES;
    [self.capturedPhotos.centerXAnchor constraintEqualToAnchor:topGuide.centerXAnchor].active = YES;
    //    [self.capturedPhotos.topAnchor constraintEqualToAnchor:saGuide.topAnchor constant:16.0].active = YES;
    [self.capturedPhotos.centerYAnchor constraintEqualToAnchor:topGuide.centerYAnchor].active = YES;
    
    //add flash button
    UIImage *currentFlash;
    if (self.imagePicker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOn) {
        currentFlash = [UIImage imageNamed:@"FlashOn"];
    } else {
        currentFlash = [UIImage imageNamed:@"FlashOff"];
    }
    self.flashButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.flashButton addTarget:self action:@selector(updateFlashMode) forControlEvents:UIControlEventTouchUpInside];
    [self.flashButton setImage:currentFlash forState:UIControlStateNormal];
    [self.flashButton setTintColor:[UIColor whiteColor]];
    self.flashButton.translatesAutoresizingMaskIntoConstraints = NO;
    [topRow addSubview:self.flashButton];
    [self.flashButton.topAnchor constraintEqualToAnchor:topGuide.topAnchor constant:8.0].active = YES;
    //    [self.flashButton.centerYAnchor constraintEqualToAnchor:topGuide.centerYAnchor].active = YES;
    [self.flashButton.leadingAnchor constraintEqualToAnchor:topGuide.leadingAnchor constant:8.0].active = YES;
    [self.flashButton.heightAnchor constraintEqualToConstant:44.0].active = YES;
    [self.flashButton.widthAnchor constraintEqualToConstant:44.0].active = YES;
    
    //add front/back camera toggle
    self.cameraFlipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cameraFlipButton setImage:[UIImage imageNamed:@"CamFlip"] forState:UIControlStateNormal];
    [self.cameraFlipButton addTarget:self action:@selector(reverseCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.cameraFlipButton setTintColor:[UIColor whiteColor]];
    self.cameraFlipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [topRow addSubview:self.cameraFlipButton];
    [self.cameraFlipButton.topAnchor constraintEqualToAnchor:saGuide.topAnchor constant:8.0].active = YES;
    //    [self.cameraFlipButton.centerYAnchor constraintEqualToAnchor:topGuide.centerYAnchor].active = YES;
    [self.cameraFlipButton.trailingAnchor constraintEqualToAnchor:topGuide.trailingAnchor constant:-8.0].active = YES;
    [self.cameraFlipButton.heightAnchor constraintEqualToConstant:44.0].active = YES;
    [self.cameraFlipButton.widthAnchor constraintEqualToConstant:44.0].active = YES;
    
    //add bottom row buttons
    //add bottom row container view
    UIView *bottomRow = [UIView new];
    [bottomRow setBackgroundColor:[UIColor clearColor]];
    [bottomRow setTranslatesAutoresizingMaskIntoConstraints:NO];
    [mainOverlay addSubview:bottomRow];
    [bottomRow.centerXAnchor constraintEqualToAnchor:saGuide.centerXAnchor].active = YES;
    [bottomRow.leadingAnchor constraintEqualToAnchor:saGuide.leadingAnchor].active = YES;
    [bottomRow.topAnchor constraintEqualToAnchor:saGuide.centerYAnchor].active = YES;
    [bottomRow.trailingAnchor constraintEqualToAnchor:saGuide.trailingAnchor].active = YES;
    [bottomRow.bottomAnchor constraintEqualToAnchor:saGuide.bottomAnchor].active = YES;
    UILayoutGuide *bottomGuide = bottomRow.safeAreaLayoutGuide;
    
    //add camera shutter button
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cameraButton setImage:[UIImage imageNamed:@"CameraShutter"] forState:UIControlStateNormal];
    [cameraButton setImage:[UIImage imageNamed:@"PressedCameraShutter"] forState:UIControlStateHighlighted]; //not selecting new image
    [cameraButton setTintColor:[UIColor whiteColor]];
    [cameraButton addTarget:self action:@selector(shutterPressed) forControlEvents:UIControlEventTouchUpInside];
    cameraButton.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomRow addSubview:cameraButton];
    [cameraButton.centerXAnchor constraintEqualToAnchor:bottomGuide.centerXAnchor].active = YES;
    [cameraButton.centerYAnchor constraintEqualToAnchor:bottomGuide.centerYAnchor].active = YES;
    
    //add done button
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(photoCaptureFinished) forControlEvents:UIControlEventTouchUpInside];
    self.doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    [bottomRow addSubview:self.doneButton];
    [self.doneButton setEnabled:NO];
    [self.doneButton.bottomAnchor constraintEqualToAnchor:bottomGuide.bottomAnchor constant:-8.0].active = YES;
    //    [self.doneButton.centerYAnchor constraintEqualToAnchor:bottomGuide.centerYAnchor].active = YES;
    [self.doneButton.trailingAnchor constraintEqualToAnchor:bottomGuide.trailingAnchor constant:-8.0].active = YES;
    
    //add cancel button
    self.cameraCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cameraCancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    self.cameraCancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.cameraCancelButton addTarget:self action:@selector(cancelCamera) forControlEvents:UIControlEventTouchUpInside];
    [bottomRow addSubview:self.cameraCancelButton];
    [self.cameraCancelButton.bottomAnchor constraintEqualToAnchor:bottomGuide.bottomAnchor constant:-8.0].active = YES;
    //    [self.cameraCancelButton.centerYAnchor constraintEqualToAnchor:bottomGuide.centerYAnchor].active = YES;
    [self.cameraCancelButton.leadingAnchor constraintEqualToAnchor:bottomGuide.leadingAnchor constant:8.0].active = YES;
    
    return mainOverlay;
}

//Converting photo captured by in-app camera to CJMImage.  Called whenever takePicture is called.
// func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info //cjm 01/12
{
    [self.doneButton setEnabled:YES];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    //    TODO: Use PHAsset instead of UIImage. cjm album fetch
//    PHAsset *newAsset = [info objectForKey:UIImagePickerControllerPHAsset];
    UIImage *newPhoto = [info objectForKey:UIImagePickerControllerOriginalImage];
//    NSData *newPhotoData = UIImageJPEGRepresentation(newPhoto, 1.0);
    NSData *nPhotoData = UIImagePNGRepresentation(newPhoto);
//    CJMImage *newImage = [[CJMImage alloc] init];
    UIImage *thumbnail = [self getCenterMaxSquareImageByCroppingImage:newPhoto andShrinkToSize:self.cellSize];
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjects:@[nPhotoData, thumbnail] forKeys:@[@"newImage", @"newThumbnail"]];
    
    if (!self.pickerPhotos) {
        self.pickerPhotos = [[NSMutableArray alloc] init];
    }
    [self.pickerPhotos addObject:dic];
}
// func photoCaptureFinished() {
- (void)photoCaptureFinished { //cjm 01/12
    CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
    
    for (NSDictionary *dic in self.pickerPhotos) {
        NSData *newPhotoData = [dic valueForKey:@"newImage"];
        UIImage *thumbnail = [dic valueForKey:@"newThumbnail"];
        CJMImage *newImage = [[CJMImage alloc] init];
        
        [fileSerializer writeObject:newPhotoData toRelativePath:newImage.fileName];
        [fileSerializer writeImage:thumbnail toRelativePath:newImage.thumbnailFileName];
        
        
        [newImage setInitialValuesForCJMImage:newImage inAlbum:self.album.albumTitle];
        newImage.photoCreationDate = [NSDate date];
        newImage.thumbnailNeedsRedraw = NO;
        [self.album addCJMImage:newImage];
    }
    self.flashButton = nil;
    self.capturedPhotos = nil;
    self.cameraCancelButton = nil;
    self.cameraFlipButton = nil;
    self.doneButton = nil;
    self.imagePicker = nil;
    self.pickerPhotos = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    [[CJMAlbumManager sharedInstance] save];
}
// func shutterPressed() {
- (void)shutterPressed { //cjm 01/12
    NSLog(@"TAKE THE PICTURE");
    [self.imagePicker takePicture];
}
// func updateFlashMode() {
- (void)updateFlashMode {
    if (self.imagePicker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
        [self.imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOn];
        [self.flashButton setImage:[UIImage imageNamed:@"FlashOn"] forState:UIControlStateNormal];
    } else {
        [self.imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];
        [self.flashButton setImage:[UIImage imageNamed:@"FlashOff"] forState:UIControlStateNormal];
    }
}
// func reverseCamera() {
- (void)reverseCamera {
    if (self.imagePicker.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    } else {
        self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
}
// func cancelCamera() {
- (void)cancelCamera { //cjm 01/12
    self.pickerPhotos = nil;
    self.imagePicker = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - CJMImage prep code

//Holy Grail of of thumbnail creation.  Well... Holy Dixie Cup may be more appropriate.
//Takes full UIImage and compresses to thumbnail with size ~100KB.
// func getCenterMaxSquareImageByCroppingImage(_ image: UIImage, andShrinkToSize newSize: CGSize) -> UIImage {
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

#pragma mark - PHNPhotoGrabDelegate Delegate
// func photoGrabSceneDidCancel() {
- (void)photoGrabSceneDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//iterate through array of selected photos, convert them to CJMImages, and add to the current album.
// func photoGrabSceneDidFinishSelectingPhotos(_ photos: [PHAsset]) {
- (void)photoGrabSceneDidFinishSelectingPhotos:(NSArray *)photos {
    NSMutableArray *newImages = [[NSMutableArray alloc] init]; //Will hold the images, image creation dates, and image locations from each PHAsset in the received array.
    
    CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
    
    if (!self.imageManager) {
        self.imageManager = [[PHCachingImageManager alloc] init];
    }
    
    __block NSInteger counter = [photos count];
    //    __weak CJMGalleryViewController *weakSelf = self;
    
    dispatch_group_t imageLoadGroup = dispatch_group_create();
    for (int i = 0; i < photos.count; i++) {
        __block CJMImage *assetImage = [[CJMImage alloc] init];
        PHAsset *asset = (PHAsset *)photos[i];
        
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.networkAccessAllowed = YES;
        options.version = PHImageRequestOptionsVersionCurrent;
        
        dispatch_group_enter(imageLoadGroup);
        /*
         Note about dispatch_group_enter:
         increments the current count of outstanding tasks in imageLoadGroup, thus requires a call to dispatch_group_leave.
         appears to handle tasks synchronously.
         dispatch_group_async(group, queue, block) manages this count for you while submitting the work asynchronously.
         test swapping out these dispatch_group_enter/dispatch_group_leave calls with dispatch_group_async and compare performance.
         dispatch_group_notify (and dispatch_group_wait) will wait until the group has zeroed out its outstanding tasks.
         */
        @autoreleasepool {
            [self.imageManager requestImageDataForAsset:asset
                                                options:options
                                          resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                              counter--;
                                              if(![info[PHImageResultIsDegradedKey] boolValue]) {
                                                  [fileSerializer writeObject:imageData toRelativePath:assetImage.fileName];
                                                  
                                                  dispatch_group_leave(imageLoadGroup);
                                              }
                                          }];
        }
        
        dispatch_group_enter(imageLoadGroup);
        @autoreleasepool {
            [self.imageManager requestImageForAsset:asset
                                         targetSize:self.cellSize
                                        contentMode:PHImageContentModeAspectFill
                                            options:options
                                      resultHandler:^(UIImage *result, NSDictionary *info) {
                                          if(![info[PHImageResultIsDegradedKey] boolValue]) {
                                              [fileSerializer writeImage:result toRelativePath:assetImage.thumbnailFileName];
                                              assetImage.thumbnailNeedsRedraw = NO;
                                              
                                              dispatch_group_leave(imageLoadGroup);
                                          }
                                      }];
        }
        
        [assetImage setInitialValuesForCJMImage:assetImage inAlbum:self.album.albumTitle];
        //        assetImage.photoLocation = [asset location];
        assetImage.photoCreationDate = [asset creationDate];
        
        [newImages addObject:assetImage];
    }
    
    [self.album addMultipleCJMImages:newImages];
    
    dispatch_group_notify(imageLoadGroup, dispatch_get_main_queue(), ^{
        self.navigationController.view.userInteractionEnabled = YES;
        [self.collectionView reloadData];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[CJMAlbumManager sharedInstance] save];
        self.navigationController.view.userInteractionEnabled = YES;
        
        //        NSLog(@"••••• FIN");
    });
}

#pragma mark - CJMAListPicker Delegate

//Dismiss list of albums to transfer photos to and deselect previously selected photos.
// func albumPickerViewControllerDidCancel(_ controller: PHNAlbumPickerViewController) {
- (void)aListPickerViewControllerDidCancel:(CJMAListPickerViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self toggleEditMode:self];
}

//take CJMImages in selected cells in current album and transfer them to the picked album.
// func albumPickerViewController(_ controller: PHNAlbumPickerViewController, didFinishPicking album: PHNPhotoAlbum) {
- (void)aListPickerViewController:(CJMAListPickerViewController *)controller didFinishPickingAlbum:(CJMPhotoAlbum *)album {
    NSMutableArray *transferringImages = [NSMutableArray new];
    
    for (NSIndexPath *itemPath in self.selectedCells) {
        CJMImage *imageToTransfer = [self.album.albumPhotos objectAtIndex:itemPath.row];
        imageToTransfer.selectCoverHidden = YES;
        if (imageToTransfer.isAlbumPreview == YES) {
            [imageToTransfer setIsAlbumPreview:NO];
            self.album.albumPreviewImage = nil;
        }
        [transferringImages addObject:imageToTransfer];
    }
    
    [album addMultipleCJMImages:transferringImages];
    
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSIndexPath *itemPath in self.selectedCells) {
        [indexSet addIndex:itemPath.row];
    }
    [self.album removeCJMImagesAtIndexes:indexSet];
    
    if (self.album.albumPreviewImage == nil && self.album.albumPhotos.count > 0) {
        [[CJMAlbumManager sharedInstance] albumWithName:self.album.albumTitle
                              createPreviewFromCJMImage:(CJMImage *)[self.album.albumPhotos objectAtIndex:0]];
    }
    
    [[CJMAlbumManager sharedInstance] save];
    if (self.album.albumPhotos.count < 1) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    [self.collectionView deleteItemsAtIndexPaths:self.selectedCells];
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
// func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{ //cjm cellSize
    if (self.newCellSize == 0.0) {
        CGFloat cvSize = self.collectionView.safeAreaLayoutGuide.layoutFrame.size.width;
        [self photoCellForWidth:cvSize];
    }
    return CGSizeMake(self.newCellSize, self.newCellSize);
}
// func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(1, 1, 1, 1);
}

//resizes collectionView cells per sizeForItemAtIndexPath when user rotates device.
// func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.collectionView.collectionViewLayout invalidateLayout];
}

@end

//
//  CJMAListViewController.m
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMAListViewController.h"
#import "CJMGalleryViewController.h"
#import "CJMAListTableViewCell.h"
#import "CJMAListPickerViewController.h"
#import "CJMPopoverViewController.h"
#import "CJMAlbumManager.h"
#import "CJMPhotoAlbum.h"
#import "CJMServices.h"
#import "CJMFileSerializer.h"
#import <AVFoundation/AVFoundation.h>


#define CJMAListCellIdentifier @"AlbumCell"

@interface CJMAListViewController () <UIPopoverPresentationControllerDelegate, CJMPopoverDelegate, CJMPhotoGrabViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CJMAListPickerDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (nonatomic) BOOL popoverPresent;
@property (nonatomic, strong) UIColor *userColor;
@property (nonatomic, strong) NSNumber *userColorTag;
@property (nonatomic, strong) NSArray *selectedPhotos;

@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) NSMutableArray *pickerPhotos;
@property (nonatomic, strong) PHCachingImageManager *imageManager;

@end

@implementation CJMAListViewController

#pragma mark - view prep and display

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"CJMAListTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CJMAListCellIdentifier];
    
    self.tableView.rowHeight = 80;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self userColors];
    [self.navigationController.toolbar setHidden:NO];
    [self.navigationController.toolbar setTranslucent:YES];
    
    [self.navigationController.navigationBar setPrefersLargeTitles:YES];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    [self noAlbumsPopUp];
    [self.tableView reloadData];
}

- (void)userColors {
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] valueForKey:@"PhotoNotesColor"];
    NSNumber *tag = [dic valueForKey:@"PhotoNotesColorTag"];
    if (dic) {
        NSNumber *red, *green, *blue;
        red = [dic valueForKey:@"PhotoNotesRed"];
        green = [dic valueForKey:@"PhotoNotesGreen"];
        blue = [dic valueForKey:@"PhotoNotesBlue"];
        tag = [dic valueForKey:@"PhotoNotesColorTag"];
        self.userColor = [UIColor colorWithRed:red.floatValue green:green.floatValue blue:blue.floatValue alpha:1.0];
        self.userColorTag = tag;
    } else {
        self.userColor = [UIColor colorWithRed:60.0/255.0 green:128.0/255.0 blue:194.0/255.0 alpha:1];
        self.userColorTag = tag;
    }
    if (tag.integerValue != 5 && tag.integerValue != 7) {
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
}

- (void)noAlbumsPopUp
{//If there are no albums, prompt the user to create one after a delay.
    dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    if ([[CJMAlbumManager sharedInstance] allAlbums].count == 0) {
        dispatch_after(waitTime, dispatch_get_main_queue(), ^{
            [self.navigationItem setPrompt:@"Tap + below to create a new Photo Notes album!"];
        });
    } else {
        [self.navigationItem setPrompt:nil];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.popoverPresent) {
        [self dismissViewControllerAnimated:YES completion:nil];
        self.popoverPresent = NO;
    }
}

#pragma mark - tableView data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{ 
    return [[CJMAlbumManager sharedInstance] allAlbums].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJMAListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CJMAListCellIdentifier forIndexPath:indexPath];
    
    CJMPhotoAlbum *album = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
    [cell configureTextForCell:cell withAlbum:album];
    [cell configureThumbnailForCell:cell forAlbum:album];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    cell.showsReorderControl = YES;
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{//replaces blank rows with blank space in the tableView
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1.0, 1.0)];
    return view;
}

                          

#pragma mark - tableView delegate methods

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
//    [self performSegueWithIdentifier:@"EditAlbum" sender:[tableView cellForRowAtIndexPath:indexPath]];
    
    //cjm 12/07
    NSString *sbName = @"Main";
    UIStoryboard *sb = [UIStoryboard storyboardWithName:sbName bundle:nil];
    CJMPopoverViewController *popVC = (CJMPopoverViewController *)[sb instantiateViewControllerWithIdentifier:@"CJMPopover"];
    CJMPhotoAlbum *album = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
    popVC.name = album.albumTitle;
    popVC.note = album.albumNote;
    popVC.indexPath = indexPath;
    popVC.delegate = self;
    
    popVC.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popController = popVC.popoverPresentationController;
    popController.delegate = self;
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [popController setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.67]];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    popController.sourceView = cell;
    popController.sourceRect = CGRectMake(cell.bounds.size.width - 33.0, cell.bounds.size.height / 2.0, 1.0, 1.0);
    
    self.popoverPresent = YES;
    [self presentViewController:popVC animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"ViewGallery" sender:[tableView cellForRowAtIndexPath:indexPath]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Photo Grab

//- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
//{
//    UIImage *newPhoto = [info objectForKey:UIImagePickerControllerOriginalImage];
//    NSData *newPhotoData = UIImageJPEGRepresentation(newPhoto, 1.0);
//    CJMImage *newImage = [[CJMImage alloc] init];
//    UIImage *thumbnail = [self getCenterMaxSquareImageByCroppingImage:newPhoto andShrinkToSize:CGSizeMake(120.0, 120.0)];
//    
//    CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
//    
//    [fileSerializer writeObject:newPhotoData toRelativePath:newImage.fileName];
//    [fileSerializer writeImage:thumbnail toRelativePath:newImage.thumbnailFileName];
//    
//    [newImage setInitialValuesForCJMImage:newImage inAlbum:self.album.albumTitle];
//    newImage.photoCreationDate = [NSDate date];
//    newImage.thumbnailNeedsRedraw = NO;
//    [self.album addCJMImage:newImage];
//    
//    [self dismissViewControllerAnimated:YES completion:nil];
//    
//    [[CJMAlbumManager sharedInstance] save];
//}

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

- (IBAction)photoGrab:(id)sender {
    //__weak CJMGalleryViewController *weakSelf = self;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    //Access camera
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionForCamera) {
        [self takePhoto];
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
- (void)presentPhotoGrabViewController { //cjm album list photo grab
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    UINavigationController *navigationVC = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"NavPhotoGrabViewController"];
    CJMPhotoGrabViewController *vc = (CJMPhotoGrabViewController *)[navigationVC topViewController];
    vc.delegate = self;
    vc.userColor = self.userColor;
    vc.userColorTag = self.userColorTag;
    vc.singleSelection = NO;
    [self presentViewController:navigationVC animated:YES completion:nil];
}

- (void)photoGrabViewControllerDidCancel:(CJMPhotoGrabViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)photoGrabViewController:(CJMPhotoGrabViewController *)controller didFinishSelectingPhotos:(NSArray *)photos {
    NSMutableArray *newImages = [[NSMutableArray alloc] init];
    //Pull the images, image creation dates, and image locations from each PHAsset in the received array.
    CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
    
    if (!self.imageManager) {
        self.imageManager = [[PHCachingImageManager alloc] init];
    }
    
    __block NSInteger counter = [photos count];
    //    __weak CJMGalleryViewController *weakSelf = self;
    
    dispatch_group_t imageLoadGroup = dispatch_group_create();
    for (int i = 0; i < photos.count; i++)
    {
        __block CJMImage *assetImage = [[CJMImage alloc] init];
        PHAsset *asset = (PHAsset *)photos[i];
        
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.networkAccessAllowed = YES;
        options.version = PHImageRequestOptionsVersionCurrent;
        
        dispatch_group_enter(imageLoadGroup);
        @autoreleasepool {
            [self.imageManager requestImageDataForAsset:asset
                                                options:options
                                          resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                              
                                              counter--;
                                              if(![info[PHImageResultIsDegradedKey] boolValue])
                                              {
                                                  [fileSerializer writeObject:imageData toRelativePath:assetImage.fileName];
                                                  dispatch_group_leave(imageLoadGroup);
                                              }
                                              
                                          }];
        }
        
        dispatch_group_enter(imageLoadGroup);
        @autoreleasepool {
            [self.imageManager requestImageForAsset:asset
                                         targetSize:CGSizeMake(120.0, 120.0)
                                        contentMode:PHImageContentModeAspectFill
                                            options:options
                                      resultHandler:^(UIImage *result, NSDictionary *info) {
                                          if(![info[PHImageResultIsDegradedKey] boolValue])
                                          {
                                              [fileSerializer writeImage:result toRelativePath:assetImage.thumbnailFileName];
                                              assetImage.thumbnailNeedsRedraw = NO;
                                              
                                              dispatch_group_leave(imageLoadGroup);
                                          }
                                      }];
        }
        
        assetImage.photoCreationDate = [asset creationDate];
        
        [newImages addObject:assetImage];
    }
    
    
    //cjm 01/12
    //We need to basically execute a Transfer of the selected images to the AListPickerVC once the newImages array is done being loaded.
    self.selectedPhotos = [NSArray arrayWithArray:newImages];
    
    
    dispatch_group_notify(imageLoadGroup, dispatch_get_main_queue(), ^{
        self.navigationController.view.userInteractionEnabled = YES;
        [self dismissViewControllerAnimated:YES completion:nil];
        
        NSString *storyboardName = @"Main";
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
        UINavigationController *vc = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"AListPickerViewController"];
        CJMAListPickerViewController *aListPickerVC = (CJMAListPickerViewController *)[vc topViewController];
        aListPickerVC.delegate = self;
        aListPickerVC.title = @"Select Destination";
        aListPickerVC.currentAlbumName = nil;
        aListPickerVC.userColor = self.userColor;
        aListPickerVC.userColorTag = self.userColorTag;
        [self presentViewController:vc animated:YES completion:nil];
        
        
        
//        self.navigationController.view.userInteractionEnabled = YES;
//        [self.tableView reloadData];
//        [self dismissViewControllerAnimated:YES completion:nil];
//        [[CJMAlbumManager sharedInstance] save];
//        self.navigationController.view.userInteractionEnabled = YES;
        
        //        NSLog(@"••••• FIN");
    });
}

- (void)aListPickerViewControllerDidCancel:(CJMAListPickerViewController *)controller {
    self.selectedPhotos = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)aListPickerViewController:(CJMAListPickerViewController *)controller didFinishPickingAlbum:(CJMPhotoAlbum *)album { //cjm 01/12
    [self.selectedPhotos enumerateObjectsUsingBlock:^(CJMImage *image, NSUInteger count, BOOL *stop) {
        image.selectCoverHidden = YES;
        image.photoTitle = @"No Title Created ";
        image.photoNote = @"Tap Edit to change the title and note!";
        image.photoFavorited = NO; //cjm favorites ImageVC set up
        image.originalAlbum = album.albumTitle;
    }];
    [album addMultipleCJMImages:self.selectedPhotos];
    [[CJMAlbumManager sharedInstance] save];
    self.selectedPhotos = nil;
    self.flashButton = nil;
    self.doneButton = nil;
    self.imagePicker = nil;
    self.pickerPhotos = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - image picker delegate and controls

- (void)takePhoto { //cjm 01/12
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Camera Available" message:@"There's no device camera available for Photo Notes to use." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionDismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *dismissAction) {}];
        [alert addAction:actionDismiss];
        [self presentViewController:alert animated:YES completion:nil];
    } else if (authStatus != AVAuthorizationStatusAuthorized) {
        //cjm 07/17 Camera Access issue.  Previously, only the below else clause that displays the alertController was present in this else-if section
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                NSLog(@"Permission for camera access granted.");
                [self prepAndDisplayCamera];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Camera Access Denied" message:@"Please allow Photo Notes permission to use the camera in Settings>Privacy>Camera." preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *actionDismiss = [UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:^(UIAlertAction *dismissAction) {}];
                [alert addAction:actionDismiss];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    } else {
        [self prepAndDisplayCamera];
    }
}

- (void)prepAndDisplayCamera {
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.showsCameraControls = NO;
    self.imagePicker.allowsEditing = NO;
    self.imagePicker.delegate = self;
    self.imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
    self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    
    //cjm 01/19 check orientation/trait collection and call the appropriate overlay
    UIView *overlay;
    if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        overlay = [self customLandscapeCameraOverlay];
    } else {
        overlay = [self customPortraitCameraOverlay];
    }
    [self.imagePicker setCameraOverlayView:overlay];
    self.imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}



- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    if (self.imagePicker) {
//        if (newCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
//            [self.imagePicker setCameraOverlayView:[self customLandscapeCameraOverlay]];
//        } else {
//            [self.imagePicker setCameraOverlayView:[self customPortraitCameraOverlay]];
//        }
//    }
}

- (UIView *)customLandscapeCameraOverlay {
    CGRect frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    
    UIView *mainOverlay = [[UIView alloc] initWithFrame:frame];
    [mainOverlay setBackgroundColor:[UIColor clearColor]];
    
    UIView *buttonBar = [[UIView alloc] init];
    [buttonBar setBackgroundColor:[UIColor clearColor]];
    buttonBar.translatesAutoresizingMaskIntoConstraints = NO;
    [mainOverlay addSubview:buttonBar];
    NSLayoutConstraint *horizontalConst = [NSLayoutConstraint constraintWithItem:buttonBar attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:mainOverlay attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint *bottomConst = [NSLayoutConstraint constraintWithItem:buttonBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:mainOverlay attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *widthConst = [NSLayoutConstraint constraintWithItem:buttonBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:mainOverlay attribute:NSLayoutAttributeWidth multiplier:1.0 constant:-16.0];
    NSLayoutConstraint *heightConst = [NSLayoutConstraint constraintWithItem:buttonBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:(frame.size.height / 4.0)];
    [mainOverlay addConstraints:@[horizontalConst, bottomConst, widthConst, heightConst]];
    
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cameraButton setImage:[UIImage imageNamed:@"CameraShutter"] forState:UIControlStateNormal];
    //    [cameraButton setImage:[UIImage imageNamed:@"PressedCameraShutter"] forState:UIControlStateHighlighted]; not selecting new image
    [cameraButton setTintColor:[UIColor whiteColor]];
    [cameraButton addTarget:self action:@selector(shutterPressed) forControlEvents:UIControlEventTouchUpInside];
    cameraButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonBar addSubview:cameraButton];
    NSLayoutConstraint *buttonHorizon = [NSLayoutConstraint constraintWithItem:cameraButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint *buttonVert = [NSLayoutConstraint constraintWithItem:cameraButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    [buttonBar addConstraints:@[buttonHorizon, buttonVert]];
    
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
    [buttonBar addSubview:self.flashButton];
    NSLayoutConstraint *flashTop = [NSLayoutConstraint constraintWithItem:self.flashButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeTop multiplier:1.0 constant:16.0];
    NSLayoutConstraint *flashLead = [NSLayoutConstraint constraintWithItem:self.flashButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeLeading multiplier:1.0 constant:8.0];
    NSLayoutConstraint *flashHeight = [NSLayoutConstraint constraintWithItem:self.flashButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:44.0];
    NSLayoutConstraint *flashWidth = [NSLayoutConstraint constraintWithItem:self.flashButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:44.0];
    [buttonBar addConstraints:@[flashTop, flashLead, flashHeight, flashWidth]];
    
    UIButton *camFlipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [camFlipButton setImage:[UIImage imageNamed:@"CamFlip"] forState:UIControlStateNormal];
    [camFlipButton addTarget:self action:@selector(reverseCamera) forControlEvents:UIControlEventTouchUpInside];
    [camFlipButton setTintColor:[UIColor whiteColor]];
    camFlipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonBar addSubview:camFlipButton];
    NSLayoutConstraint *flipTop = [NSLayoutConstraint constraintWithItem:camFlipButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.flashButton attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    NSLayoutConstraint *flipTrail = [NSLayoutConstraint constraintWithItem:camFlipButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-8.0];
    NSLayoutConstraint *flipWidth = [NSLayoutConstraint constraintWithItem:camFlipButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:44.0];
    NSLayoutConstraint *flipHeight = [NSLayoutConstraint constraintWithItem:camFlipButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:44.0];
    [buttonBar addConstraints:@[flipTop, flipTrail, flipWidth, flipHeight]];
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(photoCaptureFinished) forControlEvents:UIControlEventTouchUpInside];
    self.doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonBar addSubview:self.doneButton];
    [self.doneButton setEnabled:NO];
    NSLayoutConstraint *doneBottom = [NSLayoutConstraint constraintWithItem:self.doneButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0];
    NSLayoutConstraint *doneTrail = [NSLayoutConstraint constraintWithItem:self.doneButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-8.0];
    [buttonBar addConstraints:@[doneBottom, doneTrail]];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(cancelCamera) forControlEvents:UIControlEventTouchUpInside];
    [buttonBar addSubview:cancelButton];
    NSLayoutConstraint *cancelBottom = [NSLayoutConstraint constraintWithItem:cancelButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0];
    NSLayoutConstraint *cancelLead = [NSLayoutConstraint constraintWithItem:cancelButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeLeading multiplier:1.0 constant:8.0];
    [buttonBar addConstraints:@[cancelBottom, cancelLead]];
    
    return mainOverlay;
}

- (UIView *)customPortraitCameraOverlay { //cjm 01/12
    UIView *mainOverlay = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    UIView *buttonBar = [[UIView alloc] init];
    [buttonBar setBackgroundColor:[UIColor clearColor]];
    buttonBar.translatesAutoresizingMaskIntoConstraints = NO;
    [mainOverlay addSubview:buttonBar];
    NSLayoutConstraint *horizontalConst = [NSLayoutConstraint constraintWithItem:buttonBar attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:mainOverlay attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint *bottomConst = [NSLayoutConstraint constraintWithItem:buttonBar attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:mainOverlay attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0.0];
    NSLayoutConstraint *widthConst = [NSLayoutConstraint constraintWithItem:buttonBar attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:mainOverlay attribute:NSLayoutAttributeWidth multiplier:1.0 constant:-16.0];
    NSLayoutConstraint *heightConst = [NSLayoutConstraint constraintWithItem:buttonBar attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:([UIScreen mainScreen].bounds.size.height / 4.0)];
    [mainOverlay addConstraints:@[horizontalConst, bottomConst, widthConst, heightConst]];
    
    UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cameraButton setImage:[UIImage imageNamed:@"CameraShutter"] forState:UIControlStateNormal];
    //    [cameraButton setImage:[UIImage imageNamed:@"PressedCameraShutter"] forState:UIControlStateHighlighted]; not selecting new image
    [cameraButton setTintColor:[UIColor whiteColor]];
    [cameraButton addTarget:self action:@selector(shutterPressed) forControlEvents:UIControlEventTouchUpInside];
    cameraButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonBar addSubview:cameraButton];
    NSLayoutConstraint *buttonHorizon = [NSLayoutConstraint constraintWithItem:cameraButton attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    NSLayoutConstraint *buttonVert = [NSLayoutConstraint constraintWithItem:cameraButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    [buttonBar addConstraints:@[buttonHorizon, buttonVert]];
    
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
    [buttonBar addSubview:self.flashButton];
    NSLayoutConstraint *flashTop = [NSLayoutConstraint constraintWithItem:self.flashButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeTop multiplier:1.0 constant:16.0];
    NSLayoutConstraint *flashLead = [NSLayoutConstraint constraintWithItem:self.flashButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeLeading multiplier:1.0 constant:8.0];
    NSLayoutConstraint *flashHeight = [NSLayoutConstraint constraintWithItem:self.flashButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:44.0];
    NSLayoutConstraint *flashWidth = [NSLayoutConstraint constraintWithItem:self.flashButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:44.0];
    [buttonBar addConstraints:@[flashTop, flashLead, flashHeight, flashWidth]];
    
    UIButton *camFlipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [camFlipButton setImage:[UIImage imageNamed:@"CamFlip"] forState:UIControlStateNormal];
    [camFlipButton addTarget:self action:@selector(reverseCamera) forControlEvents:UIControlEventTouchUpInside];
    [camFlipButton setTintColor:[UIColor whiteColor]];
    camFlipButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonBar addSubview:camFlipButton];
    NSLayoutConstraint *flipTop = [NSLayoutConstraint constraintWithItem:camFlipButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.flashButton attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0.0];
    NSLayoutConstraint *flipTrail = [NSLayoutConstraint constraintWithItem:camFlipButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-8.0];
    NSLayoutConstraint *flipWidth = [NSLayoutConstraint constraintWithItem:camFlipButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0 constant:44.0];
    NSLayoutConstraint *flipHeight = [NSLayoutConstraint constraintWithItem:camFlipButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0 constant:44.0];
    [buttonBar addConstraints:@[flipTop, flipTrail, flipWidth, flipHeight]];
    
    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [self.doneButton addTarget:self action:@selector(photoCaptureFinished) forControlEvents:UIControlEventTouchUpInside];
    self.doneButton.translatesAutoresizingMaskIntoConstraints = NO;
    [buttonBar addSubview:self.doneButton];
    [self.doneButton setEnabled:NO];
    NSLayoutConstraint *doneBottom = [NSLayoutConstraint constraintWithItem:self.doneButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0];
    NSLayoutConstraint *doneTrail = [NSLayoutConstraint constraintWithItem:self.doneButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-8.0];
    [buttonBar addConstraints:@[doneBottom, doneTrail]];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    cancelButton.translatesAutoresizingMaskIntoConstraints = NO;
    [cancelButton addTarget:self action:@selector(cancelCamera) forControlEvents:UIControlEventTouchUpInside];
    [buttonBar addSubview:cancelButton];
    NSLayoutConstraint *cancelBottom = [NSLayoutConstraint constraintWithItem:cancelButton attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-8.0];
    NSLayoutConstraint *cancelLead = [NSLayoutConstraint constraintWithItem:cancelButton attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:buttonBar attribute:NSLayoutAttributeLeading multiplier:1.0 constant:8.0];
    [buttonBar addConstraints:@[cancelBottom, cancelLead]];
    
    return mainOverlay;
}

//Converting photo captured by in-app camera to CJMImage.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info //cjm 01/12
{
    [self.doneButton setEnabled:YES];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    UIImage *newPhoto = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSData *newPhotoData = UIImageJPEGRepresentation(newPhoto, 1.0);
    UIImage *thumbnail = [self getCenterMaxSquareImageByCroppingImage:newPhoto andShrinkToSize:CGSizeMake(120.0, 120.0)];
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjects:@[newPhotoData, thumbnail] forKeys:@[@"newImage", @"newThumbnail"]];
    
    if (!self.pickerPhotos) {
        self.pickerPhotos = [[NSMutableArray alloc] init];
    }
    [self.pickerPhotos addObject:dic];
}

- (void)photoCaptureFinished { //camera Done button selector
    CJMFileSerializer *fileSerializer = [[CJMFileSerializer alloc] init];
    NSMutableArray *tempAlbum = [[NSMutableArray alloc] init];
    
    for (NSDictionary *dic in self.pickerPhotos) {
        NSData *newPhotoData = [dic valueForKey:@"newImage"];
        UIImage *thumbnail = [dic valueForKey:@"newThumbnail"];
        CJMImage *newImage = [[CJMImage alloc] init];
        
        [fileSerializer writeObject:newPhotoData toRelativePath:newImage.fileName];
        [fileSerializer writeImage:thumbnail toRelativePath:newImage.thumbnailFileName];
        
        newImage.photoCreationDate = [NSDate date];
        newImage.thumbnailNeedsRedraw = NO;
        [tempAlbum addObject:newImage];
    }
    
    self.selectedPhotos = [NSArray arrayWithArray:tempAlbum];
    
    self.navigationController.view.userInteractionEnabled = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
    
    NSString *storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    UINavigationController *vc = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"AListPickerViewController"];
    CJMAListPickerViewController *aListPickerVC = (CJMAListPickerViewController *)[vc topViewController];
    aListPickerVC.delegate = self;
    aListPickerVC.title = @"Select Destination";
    aListPickerVC.currentAlbumName = nil;
    aListPickerVC.userColor = self.userColor;
    aListPickerVC.userColorTag = self.userColorTag;
    [self presentViewController:vc animated:YES completion:nil];
    
    [[CJMAlbumManager sharedInstance] save];
}

- (void)shutterPressed { //cjm 01/12
    [self.imagePicker takePicture];
}

- (void)updateFlashMode {
    if (self.imagePicker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
        [self.imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOn];
        [self.flashButton setImage:[UIImage imageNamed:@"FlashOn"] forState:UIControlStateNormal];
    } else {
        [self.imagePicker setCameraFlashMode:UIImagePickerControllerCameraFlashModeOff];
        [self.flashButton setImage:[UIImage imageNamed:@"FlashOff"] forState:UIControlStateNormal];
    }
}

- (void)reverseCamera {
    if (self.imagePicker.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    } else {
        self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    }
}

- (void)cancelCamera { 
    self.pickerPhotos = nil;
    self.imagePicker = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - QuickNotes
/*
- (void)photoIsFavorited:(BOOL)isFavorited {
    
}

- (void)toggleFullImageShow:(BOOL)yesOrNo forViewController:(CJMFullImageViewController *)viewController {
    
}
 */


#pragma mark - Editing the list

- (IBAction)editTableView:(id)sender
{
    if ([self.editButton.title isEqual:@"Edit"]) {
        [self.editButton setTitle:@"Done"];
        [self.tableView setEditing:YES animated:YES];
    } else {
        [self.editButton setTitle:@"Edit"];
        [self.tableView setEditing:NO animated:YES];
        
        [[CJMAlbumManager sharedInstance] save];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    CJMPhotoAlbum *album = [[CJMAlbumManager sharedInstance].allAlbums objectAtIndex:indexPath.row];
    if ([album.albumTitle isEqualToString:@"Favorites"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot delete the Favorites album" message:@"Removal of the favorites album is handled automatically when no Photo Notes are favorited." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionDismiss = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *dismissAction) {} ];
        [alert addAction:actionDismiss];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        NSUInteger favInt = [[CJMAlbumManager sharedInstance].allAlbums indexOfObject:[CJMAlbumManager sharedInstance].favPhotosAlbum];
        NSIndexPath *favPath = [NSIndexPath indexPathForRow:favInt inSection:0];
        BOOL favoritesActive = [CJMAlbumManager sharedInstance].favPhotosAlbum.albumPhotos.count > 0 ? YES : NO;
        [[CJMAlbumManager sharedInstance] removeAlbumAtIndex:indexPath.row];
        [[CJMAlbumManager sharedInstance] save];
        if ([CJMAlbumManager sharedInstance].favPhotosAlbum.albumPhotos.count < 1 && favoritesActive) {
            [tableView deleteRowsAtIndexPaths:@[indexPath, favPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        [tableView reloadData];
        [self noAlbumsPopUp];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [[CJMAlbumManager sharedInstance] replaceAlbumAtIndex:toIndexPath.row withAlbumFromIndex:fromIndexPath.row];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ViewGallery"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        CJMPhotoAlbum *sentAlbum = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
        sentAlbum.delegate = [CJMAlbumManager sharedInstance];
        CJMGalleryViewController *galleryVC = (CJMGalleryViewController *)segue.destinationViewController;
        galleryVC.album = sentAlbum;
        galleryVC.userColor = self.userColor;
        galleryVC.userColorTag = self.userColorTag;
    } else if ([segue.identifier isEqualToString:@"EditAlbum"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        CJMPhotoAlbum *sentAlbum = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
        UINavigationController *navigationController = segue.destinationViewController;
        CJMADetailViewController *detailVC = (CJMADetailViewController *)navigationController.viewControllers[0];
        detailVC.albumToEdit = sentAlbum;
        detailVC.title = @"Album Info";
        detailVC.delegate = self;
        detailVC.userColor = self.userColor;
        detailVC.userColorTag = self.userColorTag;
    } else if ([segue.identifier isEqualToString:@"AddAlbum"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        CJMADetailViewController *detailVC = navigationController.viewControllers[0];
        detailVC.title = @"Create Album";
        detailVC.delegate = self;
        detailVC.userColor = self.userColor;
        detailVC.userColorTag = self.userColorTag;
    } else if ([segue.identifier isEqualToString:@"ViewQuickNote"]) {
        CJMPhotoAlbum *album = [[CJMAlbumManager sharedInstance] userQuickNote];
        UINavigationController *nav = segue.destinationViewController;
        CJMFullImageViewController *vc = nav.viewControllers[0];
        vc.index = 0;
        vc.albumName = album.albumTitle;
        vc.delegate = self;
        vc.isQuickNote = YES;
        vc.userColor = self.userColor;
        vc.userColorTag = self.userColorTag;
        NSNumber *numOpac = [[NSUserDefaults standardUserDefaults] valueForKey:@"noteOpacity"];
        vc.noteOpacity = numOpac ? numOpac.floatValue : 0.75;
        //    [self.navigationController.toolbar setHidden:YES];
        [vc setViewsVisible:NO];
    } else if ([segue.identifier isEqualToString:@"ViewSettings"]) {
        //cjm quicknote
    }
}

#pragma mark - DetailVC delegate methods

- (void)albumDetailViewControllerDidCancel:(CJMADetailViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)albumDetailViewController:(CJMADetailViewController *)controller didFinishAddingAlbum:(CJMPhotoAlbum *)album {
    NSInteger newRowIndex = [[[CJMAlbumManager sharedInstance] allAlbums] count];
    
    [[CJMAlbumManager sharedInstance] addAlbum:album];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newRowIndex inSection:0];
    NSArray *indexPaths = @[indexPath];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [[CJMAlbumManager sharedInstance] save];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)albumDetailViewController:(CJMADetailViewController *)controller didFinishEditingAlbum:(CJMPhotoAlbum *)album {
    [self.tableView reloadData];
    [[CJMAlbumManager sharedInstance] save];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Popover Delegates

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.popoverPresent = NO;
}

- (void)editTappedForIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self performSegueWithIdentifier:@"EditAlbum" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
}

@end

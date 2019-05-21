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
#import "PHNPhotoGrabCompletionDelegate.h"
#import "PHNImportAlbumsVC.h"
#import <AVFoundation/AVFoundation.h>

#define CJMAListCellIdentifier @"AlbumCell"

@class PHNImportAlbumsVC;

@interface CJMAListViewController () <UIPopoverPresentationControllerDelegate, CJMPopoverDelegate, PHNPhotoGrabCompletionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CJMAListPickerDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (nonatomic) BOOL popoverPresent;
@property (nonatomic, strong) UIColor *userColor;
@property (nonatomic, strong) NSNumber *userColorTag;
@property (nonatomic, strong) NSArray *selectedPhotos;

@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic, strong) UIButton *flashButton;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIImageView *capturedPhotos;
@property (nonatomic, strong) UIButton *cameraCancelButton;
@property (nonatomic, strong) UIButton *cameraFlipButton;
@property (nonatomic) UIDeviceOrientation lastOrientation;

@property (nonatomic, strong) NSMutableArray *pickerPhotos;
@property (nonatomic, strong) PHCachingImageManager *imageManager;



@end

@implementation CJMAListViewController

#pragma mark - view prep and display

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"CJMAListTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CJMAListCellIdentifier];
    
    self.tableView.rowHeight = 120; /// was 80
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self userColors];
    [self.navigationController.toolbar setHidden:NO];
    [self.navigationController.toolbar setTranslucent:YES];
    
    [self.navigationController.navigationBar setPrefersLargeTitles:YES];
    [self.navigationController.navigationBar setTranslucent:YES];
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AlbumListBackground"]];
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    [self.tableView setBackgroundView:backgroundView];
    
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
    [cell configureWithTitle:album.albumTitle withAlbumCount:(int)album.albumPhotos.count];
    [cell configureThumbnailForCell:cell forAlbum:album];
//    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    cell.showsReorderControl = YES;
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1.0, 1.0)];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 4.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{//replaces blank rows with blank space in the tableView
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1.0, 1.0)];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 4.0;
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

#pragma mark - Photo Grab Scene Delegate
- (void)photoGrabSceneDidCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)photoGrabSceneDidFinishSelectingPhotos:(NSArray *)photos {
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
    self.capturedPhotos = nil;
    self.cameraCancelButton = nil;
    self.cameraFlipButton = nil;
    self.doneButton = nil;
    self.imagePicker = nil;
    self.pickerPhotos = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - image picker delegate and controls

- (void)openCamera { //cjm 01/12
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Camera Available" message:@"There's no camera available for Photo Notes to use." preferredStyle:UIAlertControllerStyleAlert];
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
    CGSize cameraFrame;
    CGFloat aspectRatio = 4.0 / 3.0;
    cameraFrame = CGSizeMake(shortDimension, shortDimension * aspectRatio);
    CGRect portraitFrame = CGRectMake(0, 0, shortDimension, longDimension);
    
    if (longDimension > 800) {
        //determine remaining space for bottom buttons
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

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//    if (self.imagePicker) {
//        if (newCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
//            [self.imagePicker setCameraOverlayView:[self customLandscapeCameraOverlay]];
//        } else {
//            [self.imagePicker setCameraOverlayView:[self customPortraitCameraOverlay]];
//        }
//    }
}

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

//Converting photo captured by in-app camera to CJMImage.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info //cjm 01/12
{
    [self.doneButton setEnabled:YES];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
//    TODO: Use PHAsset instead of UIImage. cjm album fetch
//    PHAsset *newAsset = [info objectForKey:UIImagePickerControllerPHAsset];
    UIImage *newPhoto = [info objectForKey:UIImagePickerControllerOriginalImage];
//    NSData *newPhotoData = UIImageJPEGRepresentation(newPhoto, 1.0);
    NSData *nPhotoData = UIImagePNGRepresentation(newPhoto);
    UIImage *thumbnail = [self getCenterMaxSquareImageByCroppingImage:newPhoto andShrinkToSize:CGSizeMake(120.0, 120.0)];
    
    //cjm album fetch
    NSDictionary *metaDic = [info objectForKey:UIImagePickerControllerMediaMetadata];
    NSLog(@"metaDic == %@", metaDic);
    
    NSDictionary *dic = [NSDictionary dictionaryWithObjects:@[nPhotoData, thumbnail] forKeys:@[@"newImage", @"newThumbnail"]];
    
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
        NSString *message = [NSString stringWithFormat:@"Any photo notes in %@ will be permanently deleted.", album.albumTitle];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Album?"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionDelete = [UIAlertAction actionWithTitle:@"Delete"
                                                               style:UIAlertActionStyleDestructive
                                                             handler:^(UIAlertAction *action) {
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
        }];
        UIAlertAction *actionCancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:actionDelete];
        [alert addAction:actionCancel];
        [self presentViewController:alert animated:YES completion:nil];
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
        vc.barsVisible = YES;
        NSNumber *numOpac = [[NSUserDefaults standardUserDefaults] valueForKey:@"noteOpacity"];
        vc.noteOpacity = numOpac ? numOpac.floatValue : 0.75;
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

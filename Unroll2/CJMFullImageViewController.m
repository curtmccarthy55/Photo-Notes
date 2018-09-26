//
//  CJMFullImageViewController.m
//  Unroll
//
//  Created by Curt on 4/24/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMFullImageViewController.h"
#import "CJMAlbumManager.h"
#import "CJMServices.h"
#import "CJMImage.h"
#import "CJMHudView.h"

@import Photos;

@interface CJMFullImageViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, UITextViewDelegate>
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *fullImage;
@property (nonatomic, strong) CJMImage *cjmImage;

#pragma mark ImageView Constraints
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *leftConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *rightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *bottomConstraint;

#pragma mark Gesture Recognizers
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *oneTap;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *twoTap;

#pragma mark Note View and Subviews
@property (strong, nonatomic) IBOutlet UIView *noteSection;
@property (strong, nonatomic) IBOutlet UITextField *noteTitle;
@property (strong, nonatomic) IBOutlet UITextView *noteEntry;
@property (strong, nonatomic) IBOutlet UILabel *photoLocAndDate;
@property (strong, nonatomic) IBOutlet UIButton *seeNoteButton;
@property (strong, nonatomic) IBOutlet UIButton *editNoteButton;
//Note View dynamic constraints
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *noteSectionDown;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *noteSectionUp;

#pragma mark Functionality Variables
@property (nonatomic) CGFloat lastZoomScale;
@property (nonatomic) float initialZoomScale;
@property (nonatomic) BOOL favoriteChanged;
@property (nonatomic) BOOL displayingNote;
@property (nonatomic) BOOL noteHidden;

@end

@implementation CJMFullImageViewController

#pragma mark - View preparation and display

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                            selector:@selector(showBars) name:@"ImageShowBars"
                                              object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(hideBars) name:@"ImageHideBars"
                                             object:nil];
    
    
    
    //this line prevents the image from jumping around when Nav bars are hidden/shown
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    self.displayingNote = NO;
    if (self.albumName == nil) { //cjm 12/30
        self.albumName = @"Favorites";
        self.index = 0;
    }
    [self prepareWithAlbumNamed:self.albumName andIndex:self.index];
    [[CJMServices sharedInstance] fetchImage:self.cjmImage handler:^(UIImage *fetchedImage) {
        self.fullImage = fetchedImage;
    }];
    
    self.editNoteButton.hidden = YES;
    [self.oneTap requireGestureRecognizerToFail:self.twoTap];
    
    //following lines moved from viewWillAppear
    [self.noteSection setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:self.noteOpacity]];
    
    self.imageView.image = self.fullImage ? self.fullImage : [UIImage imageNamed:@"IconPhoto"];
    if (@available(iOS 11.0, *)) {
        self.imageView.accessibilityIgnoresInvertColors = YES;
        self.noteSection.accessibilityIgnoresInvertColors = YES;
        self.scrollView.accessibilityIgnoresInvertColors = YES;
    }
    self.scrollView.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setPrefersLargeTitles:NO];
    if (!self.isQuickNote) {
        [self.delegate makeHomeIndicatorVisible:YES];
    }
    
    [self updateZoom];
    self.favoriteChanged = self.cjmImage.photoFavorited;
    self.noteTitle.text = self.cjmImage.photoTitle;
    self.noteTitle.textColor = [UIColor whiteColor];
    self.noteTitle.adjustsFontSizeToFitWidth = YES;
    if ([self.noteTitle.text isEqual:@"No Title Created "]) {
        self.noteTitle.text = @"";
    }
    self.noteEntry.text = self.cjmImage.photoNote;
    self.noteEntry.selectable = NO;
    self.noteEntry.textColor = [UIColor whiteColor];
    [self.noteEntry setAlpha:0.0];
    [self.photoLocAndDate setAlpha:0.0];
    
    if (self.cjmImage.photoCreationDate == nil) {
        self.photoLocAndDate.hidden = YES;
    } else {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterFullStyle];
        [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
        self.photoLocAndDate.hidden = NO;
        if (self.isQuickNote) {
            self.photoLocAndDate.text = [NSString stringWithFormat:@"Note edited %@", [dateFormatter stringFromDate:self.cjmImage.photoCreationDate]];
        } else {
            self.photoLocAndDate.text = [NSString stringWithFormat:@"Photo taken %@", [dateFormatter stringFromDate:self.cjmImage.photoCreationDate]];
        }
    }
    self.initialZoomScale = self.scrollView.zoomScale;
    
    //cjm 09/25 nav bar handling
    [self updateForBarVisibility:self.barsVisible animated:NO];
    if (!self.barsVisible) {
        [self.noteSection setHidden:NO];
        self.noteHidden = NO;
    }
    [self updateConstraints];
    
    if (!self.isQuickNote) {
        [self.delegate photoIsFavorited:self.cjmImage.photoFavorited];
    }//cjm favorites ImageVC -> PageVC
    
    if (self.fullImage == nil) {
        [self.scrollView setBackgroundColor:self.userColor];
        [self.scrollView setAlpha:0.90];
    }
    if (self.isQuickNote) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(clearNote)];
        [self.oneTap setEnabled:NO];
        self.scrollView.backgroundColor = !self.fullImage ? self.userColor : [UIColor blackColor];
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
        
        if (self.isQuickNote) {
            [self.navigationController setToolbarHidden:YES animated:NO];
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateZoom];
    
    if (self.isQuickNote) {
        [self shiftNote:nil];
    }
}

- (void)prepareWithAlbumNamed:(NSString *)name andIndex:(NSInteger)index {
    CJMImage *image = [[CJMAlbumManager sharedInstance] albumWithName:name returnImageAtIndex:index];
    self.index = index;
    self.cjmImage = image;
    self.imageIsFavorite = image.photoFavorited; //cjm favorites ImageVC set up
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.displayingNote) {
        [self shiftNote:nil];
    }
    
    
    if ([self.seeNoteButton.titleLabel.text isEqualToString:@"Dismiss"]) {
        [self handleNoteSectionDismissal];
    }
    
    [self updateZoom];
    
    if (self.favoriteChanged != self.cjmImage.photoFavorited) {
        [self handleFavoriteDidChange];
    }
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)handleFavoriteDidChange {
    if (self.favoriteChanged == NO) { //cjm favorites adding new photos to [CJMAlbumManager sharedInstance].favPhotosAlbum
        self.cjmImage.photoFavorited = NO;
        [[CJMAlbumManager sharedInstance].favPhotosAlbum removeCJMImage:self.cjmImage]; //cjm 12/23
        if (self.cjmImage.isFavoritePreview && [CJMAlbumManager sharedInstance].favPhotosAlbum.albumPhotos.count > 0) {
            CJMImage *newThumImage = [CJMAlbumManager sharedInstance].favPhotosAlbum.albumPhotos[0];
            [[CJMAlbumManager sharedInstance] albumWithName:@"Favorites" createPreviewFromCJMImage:newThumImage];
        }
    } else {
        self.cjmImage.photoFavorited = YES;
        [[CJMAlbumManager sharedInstance].favPhotosAlbum addCJMImage:self.cjmImage];
        if (!self.cjmImage.originalAlbum && ![self.albumName isEqualToString:@"Favorites"]) {
            self.cjmImage.originalAlbum = self.albumName;
        }
    }
    [[CJMAlbumManager sharedInstance] checkFavoriteCount];
    [[CJMAlbumManager sharedInstance] save]; //cjm favorites ImageVC set up/save
    
    if ([self.albumName isEqualToString:@"Favorites"] && [[CJMAlbumManager sharedInstance].favPhotosAlbum.albumPhotos count] < 1){
        NSArray *array = [self.navigationController viewControllers];
        [self.navigationController popToViewController:[array objectAtIndex:0] animated:YES];
    }
}

#pragma mark - scrollView zoom handling

// Update zoom scale and constraints
// It will also animate because willAnimateRotationToInterfaceOrientation
// is called from within an animation block
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
    
    [self updateZoom];
    self.initialZoomScale = self.scrollView.zoomScale;
//    cjm 09/19 note shift
//    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
//        self.noteSectionUp.constant = 0.0;
//        self.constr_TitleTop.constant = 0.0;
//    }
//    [self.noteSection setNeedsUpdateConstraints];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self updateConstraints];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    if (self.initialZoomScale < self.scrollView.zoomScale) {
        self.scrollView.scrollEnabled = YES;
    } else {
        self.scrollView.scrollEnabled = NO;
    }
}

- (void)updateConstraints
{ //cjm note shift.  Image position is bouncing around when zoomed in and showing/hiding the top and bottom bars.
    float imageWidth = self.imageView.image.size.width;
    float imageHeight = self.imageView.image.size.height;
    
    float viewWidth = self.view.bounds.size.width;
    float viewHeight = self.view.bounds.size.height;
    
    // center image if it is smaller than screen
    float horizontalPadding = (viewWidth - self.scrollView.zoomScale * imageWidth) / 2;
    if (horizontalPadding < 0) {
        horizontalPadding = 0;
    }
    
    float verticalPadding = (viewHeight - self.scrollView.zoomScale * imageHeight) / 2;
    if (verticalPadding < 0) {
        verticalPadding = 0;
    }

    self.leftConstraint.constant = horizontalPadding;
    self.rightConstraint.constant = horizontalPadding;
    
    self.topConstraint.constant = verticalPadding;
    self.bottomConstraint.constant = verticalPadding;
    
    // Makes zoom out animation smooth and starting from the right point not from (0, 0)
    [self.view layoutIfNeeded];
}

// Zoom to show as much image as possible unless image is smaller than screen
- (void)updateZoom
{
    float minZoom = MIN(self.view.bounds.size.width / self.imageView.image.size.width,
                        self.view.bounds.size.height / self.imageView.image.size.height);
    
    if (minZoom > 1) minZoom = 1;
    
    self.scrollView.minimumZoomScale = minZoom;
    
    // Force scrollViewDidZoom fire if zoom did not change
    if (minZoom == self.lastZoomScale) minZoom += 0.000001;
    
    self.lastZoomScale = self.scrollView.zoomScale = minZoom;
    self.scrollView.zoomScale = minZoom -= 0.000001;  //TODO: see if we can remove this +/- tweak.  Was in place to make sure scrollview content corrected itself, but probably shouldn't be necessary.
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

#pragma mark - Note Shift

//first button press: Slide the note section up so it touches the bottom of the navbar
//second button press: Slide the note section back down to just above the toolbar
- (IBAction)shiftNote:(id)sender { //cjm note shift
    if (!self.displayingNote) {
        self.noteTitle.text = self.cjmImage.photoTitle;
        
        //Display the note section
        [self setDisplayingNote:YES];
        self.noteSectionUp.active = YES;
        self.noteSectionDown.active = NO;
        [self.noteSection setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:0.25 animations:^{
            [self.noteSection.superview layoutIfNeeded];
            
            self.editNoteButton.hidden = NO;
            [self.seeNoteButton setTitle:@"Dismiss" forState:UIControlStateNormal];
            [self.editNoteButton setTitle:@"Edit" forState:UIControlStateNormal];
            
            [self.noteEntry setAlpha:1.0];
            [self.photoLocAndDate setAlpha:1.0];
        }];
    } else {
        //Dismiss the note section
        [self setDisplayingNote:NO];
        self.noteSectionUp.active = NO;
        self.noteSectionDown.active = YES;
        [self.noteSection setNeedsUpdateConstraints];
        [self handleNoteSectionDismissal];
    }
}

- (void)setDisplayingNote:(BOOL)shown { //cjm note shift
    _displayingNote = shown;
    /*
    if (shown) {
        self.noteSectionUp.active = YES;
        self.noteSectionDown.active = NO;
    } else {
        self.noteSectionUp.active = NO;
        self.noteSectionDown.active = YES;
    }
    [self.noteSection setNeedsUpdateConstraints];
     */
    
    NSLog(@"UIScreen Height == %f", UIScreen.mainScreen.bounds.size.height);
}

- (void)handleNoteSectionDismissal { //cjm note shift
    if ([self.editNoteButton.titleLabel.text isEqual:@"Done"]) {
        [self enableEdit:self];
    }
    if ([self.noteTitle.text isEqual:@"No Title Created "]) {
        self.noteTitle.text = @"";
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.noteSection.superview layoutIfNeeded];
        if (!self.barsVisible) {
            [self.editNoteButton setTitle:@"Hide" forState:UIControlStateNormal];
            [self.editNoteButton setHidden:NO];
        }else {
            self.editNoteButton.hidden = YES;
        }
        
        [self.seeNoteButton setTitle:@"See Note" forState:UIControlStateNormal];
        [self.noteEntry setAlpha:0.0];
        [self.photoLocAndDate setAlpha:0.0];
    }];
}

- (IBAction)dismissQuickNote:(id)sender {
    if ([self.seeNoteButton.titleLabel.text isEqualToString:@"Dismiss"]) {
        [self handleNoteSectionDismissal];
    }
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Nav Bar adjustments
- (void)hideBars {
    self.barsVisible = NO;
}

- (void)showBars {
    self.barsVisible = YES;
}

- (BOOL)prefersStatusBarHidden {
    NSLog(@"fullImageVC prefersStatusBarHidden called");
    if (!self.barsVisible) {
        return YES;
    } else {
        return NO;
    }
}

- (void)updateForBarVisibility:(BOOL)visible animated:(BOOL)animated {
    //if called from viewWillAppear: animated == false, else animated == true
    NSTimeInterval duration = animated ? 0.2 : 0.0;
    if (visible) {
        if (!self.isQuickNote) {
            [self.delegate makeHomeIndicatorVisible:YES];
        }
        [UIView animateWithDuration:duration animations:^{
            //toggleBars
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            [self.navigationController setToolbarHidden:NO animated:YES];
            
            //update note appearance
            self.scrollView.backgroundColor = [UIColor groupTableViewBackgroundColor];
            [self.noteSection setHidden:NO];
            self.noteHidden = NO;
            [self.editNoteButton setTitle:@"Edit" forState:UIControlStateNormal];
            [self.editNoteButton setHidden:YES];
        }];
    } else if (!visible)  {
        [UIView animateWithDuration:duration animations:^{
            //toggleBars
            [self.navigationController setNavigationBarHidden:YES animated:YES];
            [self.navigationController setToolbarHidden:YES animated:YES];
            
            //update note appearance
            self.scrollView.backgroundColor = [UIColor blackColor];
            [self.editNoteButton setTitle:@"Hide" forState:UIControlStateNormal];
            [self.editNoteButton setHidden:NO];
        }];
    }
}

#pragma mark - Buttons and taps

- (void)clearNote {
    self.cjmImage.photoTitle = @"";
    self.cjmImage.photoNote = @"";
    [self.noteTitle setText:@""];
    [self.noteEntry setText:@""];
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    if (self.noteHidden == YES) {
        return YES;
    }
    return NO;
}

//Implements control states for the note section:
//Note down, bars visible: button is hidden.
//Note down, bars hidden: button displays "Hide".  Tapping in this state hides the note section.
//Note up, text edit disabled: button displays  "Edit".  Tapping enables note section text fields, makes note text field first responsder, changes button text to "Done".
//Note up, text edit enabled: button displays "Done".  Tapping disables text fields, all fields are checked for text with values being loaded into appropriate cjmImage variables.
- (IBAction)enableEdit:(id)sender {
    if ([self.editNoteButton.titleLabel.text isEqualToString:@"Hide"]) {
        [self.noteSection setHidden:YES];
        self.noteHidden = YES;
        if (!self.isQuickNote) {
            [self.delegate makeHomeIndicatorVisible:NO];
        }
    } else if ([self.editNoteButton.titleLabel.text isEqual:@"Edit"]) {
        [self registerForKeyboardNotifications];
        self.noteTitle.enabled = YES;
        self.noteEntry.editable = YES;
        self.noteEntry.selectable = YES;
        [self.editNoteButton setTitle:@"Done" forState:UIControlStateNormal];
        [self.noteEntry becomeFirstResponder];
        self.noteEntry.selectedRange = NSMakeRange([self.noteEntry.text length], 0);
    } else {
        [self confirmTextFieldNotBlank];
        [self confirmTextViewNotBlank];
        self.cjmImage.photoTitle = self.noteTitle.text;
        self.cjmImage.photoNote = self.noteEntry.text;
        if (self.isQuickNote) {
            self.cjmImage.photoCreationDate = [NSDate date];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterFullStyle];
            [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            self.photoLocAndDate.text = [NSString stringWithFormat:@"Note edited %@", [dateFormatter stringFromDate:self.cjmImage.photoCreationDate]];
        }
        self.noteTitle.enabled = NO;
        self.noteEntry.editable = NO;
        self.noteEntry.selectable = NO;
        [self.editNoteButton setTitle:@"Edit" forState:UIControlStateNormal];
        [self.editNoteButton sizeToFit];
//        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardDidShowNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
        
        [[CJMAlbumManager sharedInstance] save];
    }
}

- (IBAction)imageViewTapped:(id)sender {
    NSLog(@"****IMAGEVIEW TAPPED****");
    if (self.isQuickNote) {
        if (self.navigationController.navigationBar.isHidden == YES) {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
        } else {
            [self.navigationController setNavigationBarHidden:YES animated:YES];
        }
    } else {
        BOOL updateBars = !self.barsVisible;
        self.barsVisible = updateBars;
        [self updateForBarVisibility:self.barsVisible animated:YES];
        [self.delegate updateBarsHidden:self.barsVisible];
    }
}

//double tap to zoom in/zoom out
- (IBAction)imageViewDoubleTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    if (self.scrollView.zoomScale == self.initialZoomScale) {
        CGPoint centerPoint = [gestureRecognizer locationInView:self.scrollView];
        
        //current content size back to content scale of 1.0f
        CGSize contentSize;
        contentSize.width = (self.scrollView.contentSize.width / self.initialZoomScale);
        contentSize.height = (self.scrollView.contentSize.height / self.initialZoomScale);
        
        //translate the zoom point to relative to the content rect
        centerPoint.x = (centerPoint.x / self.scrollView.bounds.size.width) * contentSize.width;
        centerPoint.y = (centerPoint.y / self.scrollView.bounds.size.height) * contentSize.height;
        
        //get the size of the region to zoom to
        CGSize zoomSize;
        zoomSize.width = self.scrollView.bounds.size.width / (self.initialZoomScale * 4.0);
        zoomSize.height = self.scrollView.bounds.size.height / (self.initialZoomScale * 4.0);
        
        //offset the zoom rect so the actual zoom point is in the middle of the rectangle
        CGRect zoomRect;
        zoomRect.origin.x = centerPoint.x - zoomSize.width / 2.0f;
        zoomRect.origin.y = centerPoint.y - zoomSize.height / 2.0f;
        zoomRect.size.width = zoomSize.width;
        zoomRect.size.height = zoomSize.height;
        
        //resize
        [self.scrollView zoomToRect:zoomRect animated:YES];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            [self updateZoom];
        }];
        self.scrollView.scrollEnabled = NO;
    }
}


#pragma mark - Button responses

- (void)showPopUpMenu {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                         message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *setPreviewImage = [UIAlertAction actionWithTitle:@"Use For Album List Thumbnail" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionForPreview) {
        [[CJMAlbumManager sharedInstance] albumWithName:self.albumName
                         createPreviewFromCJMImage:self.cjmImage];
        [[CJMAlbumManager sharedInstance] save];
        
        CJMHudView *hudView = [CJMHudView hudInView:self.navigationController.view
                                           withType:@"Success"
                                           animated:YES];
        hudView.text = @"Done!";
        [hudView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.5f];

        self.navigationController.view.userInteractionEnabled = YES;
    }];
    
    UIAlertAction *saveImageAction = [UIAlertAction actionWithTitle:@"Save To Camera Roll" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToSave){
        UIImageWriteToSavedPhotosAlbum(self.fullImage, nil, nil, nil);
        
        CJMHudView *hudView = [CJMHudView hudInView:self.navigationController.view
                                           withType:@"Success"
                                           animated:YES];
        
        hudView.text = @"Done!";
        
        [hudView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.5f];
        
        self.navigationController.view.userInteractionEnabled = YES;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];
    
    [alertController addAction:saveImageAction];
    [alertController addAction:setPreviewImage];
    [alertController addAction:cancelAction];
    
    alertController.popoverPresentationController.sourceRect = CGRectMake(self.view.frame.size.width - 27.0, self.view.frame.size.height - 40.0, 1.0, 1.0);
    [alertController.popoverPresentationController setPermittedArrowDirections:UIPopoverArrowDirectionDown];
    alertController.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)confirmImageDelete {
    BOOL albumIsFavorites = [self.albumName isEqualToString:@"Favorites"];
    NSString *message = albumIsFavorites ? @"Delete from all albums or unfavorite?" : @"You cannot recover this photo after deleting";
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Photo?"
                                             message:message
                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *saveToPhotosAndDelete = [UIAlertAction actionWithTitle:@"Save To Camera Roll And Then Delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToSaveThenDelete) {
        UIImageWriteToSavedPhotosAlbum(self.fullImage, nil, nil, nil);
        self.favoriteChanged = NO;
        [self.delegate photoIsFavorited:NO];
        [[CJMServices sharedInstance] deleteImage:self.cjmImage];
        [[CJMAlbumManager sharedInstance] albumWithName:self.albumName removeImageWithUUID:self.cjmImage.fileName];
        if (albumIsFavorites)
            [[CJMAlbumManager sharedInstance] albumWithName:self.cjmImage.originalAlbum removeImageWithUUID:self.cjmImage.fileName];
        
        [[CJMAlbumManager sharedInstance] checkFavoriteCount];
        [[CJMAlbumManager sharedInstance] save];
    
        [self.delegate viewController:self deletedImageAtIndex:self.index];
    }];
    
    UIAlertAction *deletePhoto = [UIAlertAction actionWithTitle:@"Delete Permanently" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToDeletePermanently) {
        self.favoriteChanged = NO;
        [self.delegate photoIsFavorited:NO];
        
        [[CJMServices sharedInstance] deleteImage:self.cjmImage];
        [[CJMAlbumManager sharedInstance] albumWithName:self.albumName removeImageWithUUID:self.cjmImage.fileName];
        if (albumIsFavorites)
            [[CJMAlbumManager sharedInstance] albumWithName:self.cjmImage.originalAlbum removeImageWithUUID:self.cjmImage.fileName];
    
        [[CJMAlbumManager sharedInstance] checkFavoriteCount];
        [[CJMAlbumManager sharedInstance] save];
        [self.delegate viewController:self deletedImageAtIndex:self.index];
    }];
    
    UIAlertAction *unfavoritePhoto = [UIAlertAction actionWithTitle:@"Unfavorite and Remove" style:UIAlertActionStyleDefault handler:^(UIAlertAction *unfavAction) {
        self.favoriteChanged = NO;
        [self.delegate photoIsFavorited:NO];
        [[CJMAlbumManager sharedInstance] albumWithName:self.albumName removeImageWithUUID:self.cjmImage.fileName];
        [self.delegate viewController:self deletedImageAtIndex:self.index];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];
    
    [alertController addAction:saveToPhotosAndDelete];
    [alertController addAction:deletePhoto];
    if (albumIsFavorites) 
        [alertController addAction:unfavoritePhoto];
    [alertController addAction:cancel];
    
    alertController.popoverPresentationController.sourceRect = CGRectMake(26.0, self.view.frame.size.height - 40.0, 1.0, 1.0);
    [alertController.popoverPresentationController setPermittedArrowDirections:UIPopoverArrowDirectionDown];
    alertController.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)actionFavorite:(BOOL)userFavorited { //cjm favorites PageVC -> ImageVC
    self.favoriteChanged = userFavorited;
    
    if ([self.albumName isEqualToString:@"Favorites"]) {
        [self handleFavoriteDidChange];
        [self.delegate viewController:self deletedImageAtIndex:self.index];
    }
}

#pragma mark - TextView and TextField Delegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqual:@"Tap Edit to change the title and note!"]) {
        textView.text = @"";
    }
}

- (void)confirmTextViewNotBlank
{
    if ([self.noteEntry.text length] == 0) {
        self.noteEntry.text = @"Tap Edit to change the title and note!";
    }
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if ([textField.text isEqual:@"No Title Created "]) {
        textField.text = @"";
    }
}

- (void)confirmTextFieldNotBlank
{
    if ([self.noteTitle.text length] == 0) {
        self.noteTitle.text = @"No Title Created ";
    }
}

#pragma mark - Keyboard shift

//Below methods make sure the note section isn't covered by the keyboard.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                       selector:@selector(keyboardWasShown:)
                                           name:UIKeyboardDidShowNotification
                                         object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)keyboardWasShown:(NSNotification *)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height - 20, 0.0);
    self.noteEntry.contentInset = contentInsets;
    self.noteEntry.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillBeHidden:(NSNotification *)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.noteEntry.contentInset = contentInsets;
    self.noteEntry.scrollIndicatorInsets = contentInsets;
}



@end

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

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *fullImage;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *leftConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *rightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) CJMImage *cjmImage;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *oneTap;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *twoTap;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *noteShiftConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *noteSectionHeight;

@property (strong, nonatomic) IBOutlet UIView *noteSection;
@property (strong, nonatomic) IBOutlet UITextField *noteTitle;
@property (strong, nonatomic) IBOutlet UITextView *noteEntry;
@property (strong, nonatomic) IBOutlet UILabel *photoLocAndDate;

@property (strong, nonatomic) IBOutlet UIButton *seeNoteButton;
@property (strong, nonatomic) IBOutlet UIButton *editNoteButton;

@property (nonatomic) CGFloat lastZoomScale;
@property (nonatomic) float initialZoomScale;
@property (nonatomic) BOOL focusIsOnImage;
@property (nonatomic) BOOL favoriteChanged;

@end

@implementation CJMFullImageViewController

#pragma mark - View preparation and display

- (void)viewDidLoad {
    [super viewDidLoad];
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.imageView.image = self.fullImage;
    self.scrollView.delegate = self;
    [self updateZoom];
    self.favoriteChanged = self.cjmImage.photoFavorited;
    NSLog(@"*cjm* self.favoriteChanged == %@, self.cjmImage.photoFavorited == %@", [NSNumber numberWithBool:self.favoriteChanged], [NSNumber numberWithBool:self.cjmImage.photoFavorited]);

    self.noteTitle.text = self.cjmImage.photoTitle;
    self.noteTitle.textColor = [UIColor whiteColor];
    self.noteTitle.adjustsFontSizeToFitWidth = YES;
    
    if ([self.noteTitle.text isEqual:@"No Title Created "]) {
        self.noteTitle.text = @"";
    }
    
    //Transform shifts title up to make it level with noteSection buttons.
//    self.noteTitle.layer.sublayerTransform = CATransform3DMakeTranslation(0, -3, 0);
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
        self.photoLocAndDate.text = [NSString stringWithFormat:@"Photo taken %@", [dateFormatter stringFromDate:self.cjmImage.photoCreationDate]];
    }
    self.initialZoomScale = self.scrollView.zoomScale;
//cjm 12/30    self.focusIsOnImage = NO;
    self.viewsVisible = YES;
    [self handleNoteSectionAlignment];
    [self updateConstraints];
    
    [self.delegate photoIsFavorited:self.cjmImage.photoFavorited]; //cjm favorites ImageVC -> PageVC
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateZoom];
}

- (void)prepareWithAlbumNamed:(NSString *)name andIndex:(NSInteger)index {
    CJMImage *image = [[CJMAlbumManager sharedInstance] albumWithName:name returnImageAtIndex:index];
    self.index = index;
    self.cjmImage = image;
    self.imageIsFavorite = image.photoFavorited; //cjm favorites ImageVC set up
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    //if note section is visible and the user swipes to the next page, slide the section out with animation.
    if ([self.seeNoteButton.titleLabel.text isEqualToString:@"Dismiss"]) {
        [self handleNoteSectionDismissal];
    }
    
    //cjm 12/30
    if (!self.viewsVisible) {
        [self imageViewTapped:self];
    }
    
//    if (self.focusIsOnImage) {
//        [self imageViewTapped:self];
//    }
    
    [self updateZoom];
    
    if (self.favoriteChanged != self.cjmImage.photoFavorited) {
        [self handleFavoriteDidChange];
    }
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

#pragma mark - View adjustments

//Sets the note section height equal to the space between the toolbar and navbar
- (void)fullSizeForNoteSection { //cjm shiftNote method
    if (self.isQuickNote) {
        self.noteSectionHeight.constant = (self.view.frame.size.height);
    } else if (self.viewsVisible == YES) {
        self.noteSectionHeight.constant = (self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - self.navigationController.toolbar.frame.size.height - [UIApplication sharedApplication].statusBarFrame.size.height);
    } else if (self.viewsVisible == NO) {
        self.noteSectionHeight.constant = self.view.frame.size.height;
    }
}

#pragma mark - scrollView handling

// Update zoom scale and constraints
// It will also animate because willAnimateRotationToInterfaceOrientation
// is called from within an animation block
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
    
    //cjm 12/30
    if (!self.viewsVisible) {
        [self imageViewTapped:self];
    }
    
//    if (self.focusIsOnImage) {
//        [self imageViewTapped:self];
//    }
    
    if ([self.seeNoteButton.titleLabel.text isEqual:@"Dismiss"]) {
        [self handleNoteSectionDismissal];
    } else if ([self.seeNoteButton.titleLabel.text isEqual:@"See Note"]) {
        [self handleNoteSectionAlignment];
    }
    
    [self updateZoom];
    
    self.initialZoomScale = self.scrollView.zoomScale;
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
{
    float imageWidth = self.imageView.image.size.width;
    float imageHeight = self.imageView.image.size.height;
    
    float viewWidth = self.view.bounds.size.width;
    float viewHeight = self.view.bounds.size.height;
    
    // center image if it is smaller than screen
    float hPadding = (viewWidth - self.scrollView.zoomScale * imageWidth) / 2;
    if (hPadding < 0) hPadding = 0;
    
    float vPadding = (viewHeight - self.scrollView.zoomScale * imageHeight) / 2;
    if (vPadding < 0) vPadding = 0;
    
    self.leftConstraint.constant = hPadding;
    self.rightConstraint.constant = hPadding;
    
    self.topConstraint.constant = vPadding;
    self.bottomConstraint.constant = vPadding;
    
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
    self.scrollView.zoomScale = minZoom -= 0.000001;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

#pragma mark - Buttons and taps

- (IBAction)dismissQuickNote:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


//first button press: Slide the note section up so it touches the bottom of the navbar
//second button press: Slide the note section back down to just above the toolbar
- (IBAction)shiftNote:(id)sender { //cjm shiftNote method
    [self fullSizeForNoteSection];
    
    CGFloat shiftConstant;
    if (self.isQuickNote) {
        shiftConstant = -(self.view.bounds.size.height);
    } else if (self.viewsVisible == YES) {
        CGFloat topBarsHeight = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
        shiftConstant = -(self.view.bounds.size.height - 44 - topBarsHeight);
    } else {
        shiftConstant = -(self.view.bounds.size.height - 44);
    }
    
    if ([self.seeNoteButton.titleLabel.text isEqual:@"See Note"]) {
        self.noteShiftConstraint.constant = shiftConstant;
        [self.noteSection setNeedsUpdateConstraints];
        self.noteTitle.text = self.cjmImage.photoTitle;
        
        [UIView animateWithDuration:0.25 animations:^{
            [self.noteSection.superview layoutIfNeeded];
            
            self.editNoteButton.hidden = NO;
            [self.seeNoteButton setTitle:@"Dismiss" forState:UIControlStateNormal];
            [self.editNoteButton setTitle:@"Edit" forState:UIControlStateNormal];
            
            [self.noteEntry setAlpha:1.0];
            [self.photoLocAndDate setAlpha:1.0];
        }];
    } else {
        [self handleNoteSectionDismissal];
    }
}

- (void)handleNoteSectionDismissal { //cjm shiftNote method
    if ([self.editNoteButton.titleLabel.text isEqual:@"Done"]) {
        [self enableEdit:self];
    }
    [self handleNoteSectionAlignment];
    if ([self.noteTitle.text isEqual:@"No Title Created "]) {
        self.noteTitle.text = @"";
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.noteSection.superview layoutIfNeeded];
        if (!self.viewsVisible) {
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

- (void)handleNoteSectionAlignment { //cjm shiftNote method
    if (self.viewsVisible)
        self.noteShiftConstraint.constant = -44.0;
    else
        self.noteShiftConstraint.constant = 0;
    
    [self.noteSection setNeedsUpdateConstraints];
}

//Enables editing the note and title sections
- (IBAction)enableEdit:(id)sender {
    if ([self.editNoteButton.titleLabel.text isEqualToString:@"Hide"]) {
        [self.noteSection setHidden:YES];
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
        self.noteTitle.enabled = NO;
        self.noteEntry.editable = NO;
        self.noteEntry.selectable = NO;
        [self.editNoteButton setTitle:@"Edit" forState:UIControlStateNormal];
        [self.editNoteButton sizeToFit];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        [[CJMAlbumManager sharedInstance] save];
    }
}

- (void)setViewsVisible:(BOOL)viewsVisible {
    _viewsVisible = viewsVisible;
    [self updateForSingleTap];
}

- (void)updateForSingleTap {
    if (self.viewsVisible == YES) {
        [UIView animateWithDuration:0.2 animations:^{
            self.scrollView.backgroundColor = [UIColor groupTableViewBackgroundColor];
            self.noteShiftConstraint.constant = -44.0;
            [self.noteSection setHidden:NO];
            [self.editNoteButton setTitle:@"Edit" forState:UIControlStateNormal];
            [self.editNoteButton setHidden:YES];
        }];
    } else if (self.viewsVisible == NO) {
        [UIView animateWithDuration:0.2 animations:^{
            self.scrollView.backgroundColor = [UIColor blackColor];
            self.noteShiftConstraint.constant = 0;
            [self.editNoteButton setTitle:@"Hide" forState:UIControlStateNormal];
            [self.editNoteButton setHidden:NO];
        }];
    }
}

- (IBAction)imageViewTapped:(id)sender {
    //cjm 12/30 viewsVisible. this is the first method called when the user taps once on the UIScrollView.
    if (self.isQuickNote) {
        if (self.navigationController.navigationBar.isHidden == YES) {
            [self.navigationController.navigationBar setHidden:NO];
        } else {
            [self.navigationController.navigationBar setHidden:YES];
        }
    } else {
        [self.delegate toggleFullImageShow:self.viewsVisible forViewController:self];
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

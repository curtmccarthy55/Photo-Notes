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

@interface CJMFullImageViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

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


@property (strong, nonatomic) IBOutlet UIView *noteSection;
@property (strong, nonatomic) IBOutlet UITextField *noteTitle;
@property (strong, nonatomic) IBOutlet UITextView *noteEntry;
@property (strong, nonatomic) IBOutlet UILabel *photoLocAndDate;


@property (strong, nonatomic) IBOutlet UIButton *seeNoteButton;
@property (strong, nonatomic) IBOutlet UIButton *editNoteButton;

@property (nonatomic) CGFloat lastZoomScale;

@end

@implementation CJMFullImageViewController
{
    float _initialZoomScale;
    BOOL _focusIsOnImage;
}

#pragma mark - View preparation and display

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareWithAlbumNamed:_albumName andIndex:_index];
    
    [[CJMServices sharedInstance] fetchImage:_cjmImage handler:^(UIImage *fetchedImage) {
        self.fullImage = fetchedImage;
    }];
    
    self.editNoteButton.hidden = YES;
    
    [self.oneTap requireGestureRecognizerToFail:self.twoTap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.imageView.image = _fullImage;
    self.scrollView.delegate = self;
    [self updateZoom];

    self.noteTitle.text = _cjmImage.photoTitle;
    self.noteTitle.textColor = [UIColor whiteColor];
    self.noteTitle.adjustsFontSizeToFitWidth = YES;
    
    self.noteEntry.text = _cjmImage.photoNote;
    self.noteEntry.textColor = [UIColor whiteColor];
    self.noteEntry.font = [UIFont fontWithName:@"Verdana" size:14];
    
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
    
    _initialZoomScale = self.scrollView.zoomScale;
    NSLog(@"_initialZoomScale set to %f", _initialZoomScale);
    _focusIsOnImage = NO;
    
    [self handleNoteSectionAlignment];
    
    [self updateConstraints];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateZoom];
    

}

- (void)prepareWithAlbumNamed:(NSString *)name andIndex:(NSInteger)index
{
    CJMImage *image = [[CJMAlbumManager sharedInstance] albumWithName:name returnImageAtIndex:index];
    
    _index = index;
    _cjmImage = image;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    //if note section is visible and the user swipes to the next page, slide the section out with animation.
    if ([self.seeNoteButton.titleLabel.text isEqualToString:@"Dismiss"]) {
        [self handleNoteSectionDismissal];
    }
    
    if (_focusIsOnImage) {
        [self imageViewTapped:self];
    }
    
    [self updateZoom];
    
    NSLog(@"fullImageViewer disappearing");
}

#pragma mark - scrollView handling

// Update zoom scale and constraints
// It will also animate because willAnimateRotationToInterfaceOrientation
// is called from within an animation block
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
    
    if ([self.seeNoteButton.titleLabel.text isEqual:@"Dismiss"]) {
        [self handleNoteSectionDismissal];
    } else if ([self.seeNoteButton.titleLabel.text isEqual:@"See Note"]) {
        [self handleNoteSectionAlignment];
    }
    
    [self updateZoom];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self updateConstraints];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    if (_initialZoomScale < self.scrollView.zoomScale) {
        self.scrollView.scrollEnabled = YES;
    } else if (_initialZoomScale >= self.scrollView.zoomScale) {
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
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}


#pragma mark - Buttons and taps

- (IBAction)shiftNote:(id)sender
{
    CGFloat topBarsHeight = self.navigationController.navigationBar.frame.size.height + [UIApplication sharedApplication].statusBarFrame.size.height;
    
    CGFloat shiftConstant = -(self.view.bounds.size.height - topBarsHeight);
    
    if ([self.seeNoteButton.titleLabel.text isEqual:@"See Note"]) {
        self.noteShiftConstraint.constant = shiftConstant;
        [self.noteSection setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:0.25 animations:^{
            [self.noteSection layoutIfNeeded];
            
            self.editNoteButton.hidden = NO;
            [self.seeNoteButton setTitle:@"Dismiss" forState:UIControlStateNormal];
            
            [self.noteEntry setAlpha:1.0];
            [self.photoLocAndDate setAlpha:1.0];
        }];

    } else {
        [self handleNoteSectionDismissal];
    }
}

- (void)handleNoteSectionDismissal
{
    if ([self.editNoteButton.titleLabel.text isEqual:@"Done"]) {
        [self enableEdit:self];
    }
    [self handleNoteSectionAlignment];
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.noteSection layoutIfNeeded];
        self.editNoteButton.hidden = YES;
        
        [self.seeNoteButton setTitle:@"See Note" forState:UIControlStateNormal];
        
        [self.noteEntry setAlpha:0.0];
        [self.photoLocAndDate setAlpha:0.0];
    }];
}

- (void)handleNoteSectionAlignment
{
    self.noteShiftConstraint.constant = -(32.0 + self.navigationController.toolbar.frame.size.height);
    [self.noteSection setNeedsUpdateConstraints];
}

- (IBAction)enableEdit:(id)sender
{
    if ([self.editNoteButton.titleLabel.text isEqual:@"Edit"]) {
        self.noteTitle.enabled = YES;
        self.noteEntry.editable = YES;
        [self.editNoteButton setTitle:@"Done" forState:UIControlStateNormal];
        

        [self.noteEntry becomeFirstResponder];
    } else {
        self.cjmImage.photoTitle = self.noteTitle.text;
        self.cjmImage.photoNote = self.noteEntry.text;
        
        self.noteTitle.enabled = NO;
        self.noteEntry.editable = NO;
        [self.editNoteButton setTitle:@"Edit" forState:UIControlStateNormal];
        [self.editNoteButton sizeToFit];
        
        [[CJMAlbumManager sharedInstance] save];
    }
}

- (void)setViewsVisible:(BOOL)viewsVisible
{
    _viewsVisible = viewsVisible;
    
    [self updateForSingleTap];
    
}

- (void)updateForSingleTap
{
    if (self.viewsVisible == YES) {
        [UIView animateWithDuration:0.2 animations:^{
        self.scrollView.backgroundColor = [UIColor whiteColor];
        self.noteSection.alpha = 1;
        }];
    } else if (self.viewsVisible == NO) {
        [UIView animateWithDuration:0.2 animations:^{
        self.scrollView.backgroundColor = [UIColor blackColor];
        self.noteSection.alpha = 0;
        }];
    }
}

- (IBAction)imageViewTapped:(id)sender
{
    if (!_focusIsOnImage) {
        _focusIsOnImage = YES;
    } else {
        _focusIsOnImage = NO;
    }
    
    [self.delegate toggleFullImageShowForViewController:self];
}

- (IBAction)imageViewDoubleTapped:(UITapGestureRecognizer *)gestureRecognizer
{
    CGFloat scaleDifference = _initialZoomScale / self.scrollView.zoomScale;
    
    if (scaleDifference >= 0.99 && scaleDifference <= 1.01) {
        CGPoint centerPoint = [gestureRecognizer locationInView:self.scrollView];
        
        //current content size back to content scale of 1.0f
        CGSize contentSize;
        contentSize.width = (self.scrollView.contentSize.width / _initialZoomScale);
        contentSize.height = (self.scrollView.contentSize.height / _initialZoomScale);
        
        //translate the zoom point to relative to the content rect
        centerPoint.x = (centerPoint.x / self.scrollView.bounds.size.width) * contentSize.width;
        centerPoint.y = (centerPoint.y / self.scrollView.bounds.size.height) * contentSize.height;
        
        //get the size of the region to zoom to
        CGSize zoomSize;
        zoomSize.width = self.scrollView.bounds.size.width / (_initialZoomScale * 4.0);
        zoomSize.height = self.scrollView.bounds.size.height / (_initialZoomScale * 4.0);
        
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
    }
}


#pragma mark - Button responses

- (void)showPopUpMenu
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                         message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *setPreviewImage = [UIAlertAction actionWithTitle:@"Use For Album List Thumbnail" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionForPreview) {
        [[CJMAlbumManager sharedInstance] albumWithName:self.albumName
                         createPreviewFromCJMImage:self.cjmImage];
        
        [[CJMAlbumManager sharedInstance] save];
        
        CJMHudView *hudView = [CJMHudView hudInView:self.navigationController.view animated:YES];
        
        hudView.text = @"Done!";
        hudView.type = @"Success";
        
        [hudView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.5f];

        self.navigationController.view.userInteractionEnabled = YES;
        NSLog(@"Save called from popUpMenu");
    }];
    
    UIAlertAction *saveImageAction = [UIAlertAction actionWithTitle:@"Save To Camera Roll" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToSave){
        UIImageWriteToSavedPhotosAlbum(self.fullImage, nil, nil, nil);
        
        CJMHudView *hudView = [CJMHudView hudInView:self.navigationController.view animated:YES];
        
        hudView.text = @"Done!";
        hudView.type = @"Success";
        
        [hudView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:1.5f];
        
        self.navigationController.view.userInteractionEnabled = YES;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];
    
    [alertController addAction:saveImageAction];
    [alertController addAction:setPreviewImage];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)confirmImageDelete
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Delete Photo?"
                                             message:@"You cannot recover this photo after deleting."
                                      preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *saveToPhotosAndDelete = [UIAlertAction actionWithTitle:@"Save to Photos app and then delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToSaveThenDelete) {
            UIImageWriteToSavedPhotosAlbum(self.fullImage, nil, nil, nil);
            [[CJMServices sharedInstance] deleteImage:self.cjmImage];
            [[CJMAlbumManager sharedInstance] albumWithName:self.albumName removeImageWithUUID:self.cjmImage.fileName];
        
            [[CJMAlbumManager sharedInstance] save];
        
            [self.delegate viewController:self deletedImageAtIndex:self.index];
    }];
    
    UIAlertAction *deletePhoto = [UIAlertAction actionWithTitle:@"Delete permanently" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToDeletePermanently) {
            [[CJMServices sharedInstance] deleteImage:self.cjmImage];
            [[CJMAlbumManager sharedInstance] albumWithName:self.albumName removeImageWithUUID:self.cjmImage.fileName];
        
            [[CJMAlbumManager sharedInstance] save];
        
            [self.delegate viewController:self deletedImageAtIndex:self.index];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];
    
    [alertController addAction:saveToPhotosAndDelete];
    [alertController addAction:deletePhoto];
    [alertController addAction:cancel];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


@end

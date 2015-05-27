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

@import Photos;

@interface CJMFullImageViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *fullImage;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *topConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *leftConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *rightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (nonatomic, strong) CJMImage *cjmImage;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *noteShiftConstraint;

@property (strong, nonatomic) IBOutlet UIView *noteSection;
@property (strong, nonatomic) IBOutlet UITextField *noteTitle;
@property (strong, nonatomic) IBOutlet UITextView *noteEntry;
@property (strong, nonatomic) IBOutlet UILabel *photoLocAndDate;
@property (strong, nonatomic) IBOutlet UIView *noteEntryShush;


@property (strong, nonatomic) IBOutlet UIButton *seeNoteButton;
@property (strong, nonatomic) IBOutlet UIButton *editNoteButton;

@property (nonatomic) CGFloat lastZoomScale;

@end

@implementation CJMFullImageViewController
{
    float _initialZoomScale;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareWithAlbumNamed:_albumName andIndex:_index];
    
    [[CJMServices sharedInstance] fetchImage:_cjmImage handler:^(UIImage *fetchedImage) {
        self.fullImage = fetchedImage;
    }];
    
    self.editNoteButton.hidden = YES;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSLog(@"pageVC viewWillAppear called");
    
    self.imageView.image = _fullImage;
    self.scrollView.delegate = self;
    
    self.noteTitle.text = _cjmImage.photoTitle;
    self.noteEntry.text = _cjmImage.photoNote;
    
    if (self.cjmImage.photoCreationDate == nil && self.cjmImage.photoLocation == nil) {
        self.photoLocAndDate.hidden = YES;
    } else if (self.cjmImage.photoCreationDate != nil && self.cjmImage.photoLocation == nil) {
        self.photoLocAndDate.text = [NSString stringWithFormat:@"%@", self.cjmImage.photoCreationDate];
    } else if (self.cjmImage.photoCreationDate == nil && self.cjmImage.photoLocation != nil) {
        self.photoLocAndDate.text = [NSString stringWithFormat:@"%@", self.cjmImage.photoLocation];
    } else if (self.cjmImage.photoCreationDate != nil && self.cjmImage.photoLocation != nil) {
        self.photoLocAndDate.text = [NSString stringWithFormat:@"%@, %@", self.cjmImage.photoLocation, self.cjmImage.photoCreationDate];
    }
    
    _initialZoomScale = self.scrollView.zoomScale;
    NSLog(@"initialZoomScale is %f", _initialZoomScale);
    
    [self updateConstraints];
}



- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.scrollView.zoomScale = _initialZoomScale * 0.9999;
    [self updateZoom];
    self.scrollView.zoomScale = _initialZoomScale;
    [self updateZoom];
}
- (void)prepareWithAlbumNamed:(NSString *)name andIndex:(NSInteger)index
{
    CJMImage *image = [[CJMAlbumManager sharedInstance] albumWithName:name returnImageAtIndex:index];
    
    _index = index;
    _cjmImage = image;
}


// Update zoom scale and constraints
// It will also animate because willAnimateRotationToInterfaceOrientation
// is called from within an animation block
//
// DEPRECATION NOTICE: This method is said to be deprecated in iOS 8.0. But it still works.
- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:interfaceOrientation duration:duration];
    
    if ([self.seeNoteButton.titleLabel.text isEqualToString:@"Dismiss"]) {
        if ([self.editNoteButton.titleLabel.text  isEqual:@"Done"]) {
            [self enableEdit:self.seeNoteButton];
        }
        
        self.noteShiftConstraint.constant = -88.0f;
        [self.noteSection setNeedsUpdateConstraints];        

        [self.noteSection layoutIfNeeded];
        self.editNoteButton.hidden = YES;
        
        [self.seeNoteButton setTitle:@"See Note" forState:UIControlStateNormal];
    
        self.noteEntryShush.hidden = NO;
    }
    
    [self updateZoom];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self updateConstraints];
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

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}


#pragma mark - Screen reactions

- (IBAction)shiftNote:(id)sender
{
    CGFloat shiftConstant = -(self.view.bounds.size.height - 64);
    
    if (self.noteShiftConstraint.constant == -88.0f) {
        self.noteShiftConstraint.constant = shiftConstant;
        [self.noteSection setNeedsUpdateConstraints];
        
        self.noteEntryShush.hidden = YES;
        
        [UIView animateWithDuration:0.25 animations:^{
            [self.noteSection layoutIfNeeded];
            
            self.editNoteButton.hidden = NO;
            [self.seeNoteButton setTitle:@"Dismiss" forState:UIControlStateNormal];
        }];
        
    } else {
        if ([self.editNoteButton.titleLabel.text  isEqual:@"Done"]) {
            [self enableEdit:(id)sender];
        }
        
        self.noteShiftConstraint.constant = -88.0f;
        [self.noteSection setNeedsUpdateConstraints];
        
        [UIView animateWithDuration:0.25 animations:^{
            [self.noteSection layoutIfNeeded];
            self.editNoteButton.hidden = YES;
            
            [self.seeNoteButton setTitle:@"See Note" forState:UIControlStateNormal];
        }];
        self.noteEntryShush.hidden = NO;
    }
}

- (IBAction)enableEdit:(id)sender
{
    if (self.noteTitle.enabled == NO) {
        self.noteTitle.enabled = YES;
        self.noteEntry.editable = YES;
        [self.editNoteButton setTitle:@"Done" forState:UIControlStateNormal];
        [self.noteEntry becomeFirstResponder];
    } else {
        self.cjmImage.photoTitle = self.noteTitle.text;
        self.cjmImage.photoNote = self.noteEntry.text;
        
        NSLog(@"The photo title should be %@ and the photo note should be %@", self.cjmImage.photoTitle, self.cjmImage.photoNote);
        
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
        [UIView animateWithDuration:0.5 animations:^{
        self.scrollView.backgroundColor = [UIColor whiteColor];
        self.noteSection.alpha = 1;
        }];
    } else if (self.viewsVisible == NO) {
        [UIView animateWithDuration:0.5 animations:^{
        self.scrollView.backgroundColor = [UIColor blackColor];
        self.noteSection.alpha = 0;
        }];
    }
}

- (IBAction)imageViewTapped:(id)sender
{
    [self.delegate toggleFullImageShowForViewController:self];
}

#pragma mark Button Presses

- (void)showPopUpMenu
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                         message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *setPreviewImage = [UIAlertAction actionWithTitle:@"Use For Album List Thumbnail" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionForPreview) {
        [[CJMAlbumManager sharedInstance] albumWithName:self.albumName
                         createPreviewFromCJMImage:self.cjmImage];
        
        [[CJMAlbumManager sharedInstance] save];
        
        NSLog(@"Save called from popUpMenu");
    }];
    
    UIAlertAction *saveImageAction = [UIAlertAction actionWithTitle:@"Save To Camera Roll" style:UIAlertActionStyleDefault handler:^(UIAlertAction *actionToSave){
        UIImageWriteToSavedPhotosAlbum(self.fullImage, nil, nil, nil);
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *cancelAction) {} ];
    
    [alertController addAction:saveImageAction];
    [alertController addAction:setPreviewImage];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


@end

//
//  CJMFIGalleryViewController.m
//  Unroll
//
//  Created by Curt on 5/1/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMFIGalleryViewController.h"

@interface CJMFIGalleryViewController ()

@property (nonatomic) BOOL makeViewsVisible;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonFavorite;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *barButtonOptions;
@property (nonatomic) CGFloat noteOpacity;


@end

@implementation CJMFIGalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.automaticallyAdjustsScrollViewInsets = NO;
    self.dataSource = self;
    self.makeViewsVisible = YES;
    [self prefersStatusBarHidden];
    [self setNeedsStatusBarAppearanceUpdate];
    self.view.backgroundColor = [UIColor whiteColor];
    NSNumber *numOpacity = [[NSUserDefaults standardUserDefaults] valueForKey:@"noteOpacity"];
    self.noteOpacity = numOpacity ? numOpacity.floatValue : 0.75;
    
    CJMFullImageViewController *fullImageVC = [self fullImageViewControllerForIndex:self.initialIndex];
    [self setViewControllers:@[fullImageVC]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
//    NSLog(@"PageVC deallocated!");
}

-(BOOL)prefersStatusBarHidden {
    if (self.makeViewsVisible && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(CJMFullImageViewController *)currentImageVC {
    NSInteger previousIndex = currentImageVC.index - 1;
//    NSLog(@"Creating previous VC.");
    return [self fullImageViewControllerForIndex:previousIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(CJMFullImageViewController *)currentImageVC {
    NSInteger nextIndex = currentImageVC.index + 1;
//    NSLog(@"Creating next VC.");
    return [self fullImageViewControllerForIndex:nextIndex];
}

- (CJMFullImageViewController *)fullImageViewControllerForIndex:(NSInteger)index {
    if (index >= self.albumCount || index < 0) {
        return nil;
    } else {
        CJMFullImageViewController *fullImageController = [self.storyboard instantiateViewControllerWithIdentifier:@"FullImageVC"];
        fullImageController.index = index;
        fullImageController.albumName = self.albumName;
        fullImageController.delegate = self;
        fullImageController.noteOpacity = self.noteOpacity;
        [fullImageController setViewsVisible:self.makeViewsVisible];
            
        return fullImageController;
    }
}

#pragma mark - navBar and toolbar visibility

- (void)setMakeViewsVisible:(BOOL)makeViewsVisible {
    _makeViewsVisible = makeViewsVisible;
    [self toggleViewVisibility];
}

#pragma mark - navBar and toolbar buttons

- (IBAction)favoriteImage:(UIBarButtonItem *)sender { //cjm favorites PageVC -> ImageVC
    CJMFullImageViewController *currentVC = (CJMFullImageViewController *)self.viewControllers[0];
    
    if ([sender.image isEqual:[UIImage imageNamed:@"WhiteStarEmpty"]]) {
        [sender setImage:[UIImage imageNamed:@"WhiteStarFull"]];
        [currentVC actionFavorite:YES];
    } else {
        [sender setImage:[UIImage imageNamed:@"WhiteStarEmpty"]];
        [currentVC actionFavorite:NO];
    }
}


- (IBAction)currentPhotoOptions:(id)sender {
    CJMFullImageViewController *currentVC = (CJMFullImageViewController *)self.viewControllers[0];
    
    [currentVC showPopUpMenu];
}

- (IBAction)deleteCurrentPhoto:(id)sender {
    CJMFullImageViewController *currentVC = (CJMFullImageViewController *)self.viewControllers[0];
    
    [currentVC confirmImageDelete];
}

- (void)toggleViewVisibility {
    if (self.makeViewsVisible == NO) {
//        [self prefersStatusBarHidden];
        [self setNeedsStatusBarAppearanceUpdate];
        [UIView animateWithDuration:0.2 animations:^{
            self.navigationController.navigationBar.alpha = 0;
            self.navigationController.toolbar.alpha = 0;
        }];
    } else if (self.makeViewsVisible == YES) {
//        [self prefersStatusBarHidden];
        [self setNeedsStatusBarAppearanceUpdate];
        [UIView animateWithDuration:0.2 animations:^{
            self.navigationController.navigationBar.alpha = 1;
            self.navigationController.toolbar.alpha = 1;
        }];
    }
}

#pragma mark - CJMFullImageVC Delegate Methods

- (void)toggleFullImageShow:(BOOL)yesOrNo forViewController:(CJMFullImageViewController *)viewController {
//    self.makeViewsVisible = !self.makeViewsVisible;
    self.makeViewsVisible = !yesOrNo; //cjm 12/30 viewsVisible
    [viewController setViewsVisible:self.makeViewsVisible];
}

//deletes the currently displayed image and updates screen based on position in album
- (void)viewController:(CJMFullImageViewController *)currentVC deletedImageAtIndex:(NSInteger)imageIndex {
    if (self.albumCount - 1 == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    } else if ((imageIndex + 1) >= self.albumCount) {
        CJMFullImageViewController *previousVC = (CJMFullImageViewController *)[self pageViewController:self viewControllerBeforeViewController:currentVC];
        self.albumCount -= 1;
        
        [self setViewControllers:@[previousVC]
                                          direction:UIPageViewControllerNavigationDirectionReverse
                                           animated:YES
                                         completion:nil];
    } else {
        CJMFullImageViewController *nextVC = (CJMFullImageViewController *)[self pageViewController:self viewControllerAfterViewController:currentVC];
        nextVC.index = imageIndex;
        self.albumCount -= 1;
    
        [self setViewControllers:@[nextVC]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:YES
                      completion:NULL];
    }
}

- (void)photoIsFavorited:(BOOL)isFavorited { //cjm favorites ImageVC -> PageVC
    if (!isFavorited) {
        [self.barButtonFavorite setImage:[UIImage imageNamed:@"WhiteStarEmpty"]];
    } else {
        [self.barButtonFavorite setImage:[UIImage imageNamed:@"WhiteStarFull"]];
    }
}

@end

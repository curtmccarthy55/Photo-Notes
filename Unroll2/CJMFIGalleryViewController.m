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

@end

@implementation CJMFIGalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataSource = self;
    self.makeViewsVisible = YES;
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CJMFullImageViewController *fullImageVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"FullImageVC"];
    fullImageVC.albumName = _albumName;
    fullImageVC.index = _initialIndex;
    fullImageVC.delegate = self;
    
    NSLog(@"pageViewController didLoad");
    
    [self setViewControllers:@[fullImageVC]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:NULL];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    NSLog(@"PageVC deallocated!");
}

-(BOOL)prefersStatusBarHidden
{
    if (self.navigationController.navigationBar.hidden == NO) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(CJMFullImageViewController *)currentImageVC
{
    NSInteger previousIndex = currentImageVC.index - 1;
    NSLog(@"Creating previous VC. makeViewsVisible == %@", [NSNumber numberWithBool:self.makeViewsVisible]);
    return [self fullImageViewControllerForIndex:previousIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(CJMFullImageViewController *)currentImageVC
{
    NSInteger nextIndex = currentImageVC.index + 1;
    NSLog(@"Creating next VC. makeViewsVisible == %@", [NSNumber numberWithBool:self.makeViewsVisible]);
    return [self fullImageViewControllerForIndex:nextIndex];
}

- (CJMFullImageViewController *)fullImageViewControllerForIndex:(NSInteger)index
{
    if (index >= _albumCount || index < 0) {
        return nil;
    } else {
    CJMFullImageViewController *fullImageController = [self.storyboard instantiateViewControllerWithIdentifier:@"FullImageVC"];
    fullImageController.index = index;
    fullImageController.albumName = _albumName;
    fullImageController.delegate = self;
    [fullImageController setViewsVisible:_makeViewsVisible];
        
    return fullImageController;
    }
    
}

#pragma mark - navBar and toolbar visibility

- (void)setMakeViewsVisible:(BOOL)makeViewsVisible
{
    _makeViewsVisible = makeViewsVisible;

    [self toggleViewVisibility];
}

#pragma mark navBar and toolbar buttons

- (IBAction)currentPhotoOptions:(id)sender
{
    NSLog(@"photoOptions button pressed");
    CJMFullImageViewController *currentVC = (CJMFullImageViewController *)self.viewControllers[0];
    
    [currentVC showPopUpMenu];
}

- (IBAction)deleteCurrentPhoto:(id)sender
{
    CJMFullImageViewController *currentVC = (CJMFullImageViewController *)self.viewControllers[0];
    
    [currentVC confirmImageDelete];
}

- (void)toggleViewVisibility
{
    if (_makeViewsVisible == NO) {
        [UIView animateWithDuration:0.5 animations:^{
        self.navigationController.navigationBar.alpha = 0;
        self.navigationController.toolbar.alpha = 0;
        [self setNeedsStatusBarAppearanceUpdate];
        }];
    } else if (_makeViewsVisible == YES) {
        [UIView animateWithDuration:0.5 animations:^{
        self.navigationController.navigationBar.alpha = 1;
        self.navigationController.toolbar.alpha = 1;
        [self setNeedsStatusBarAppearanceUpdate];
        }];
    }
}

#pragma mark - CJMFullImageVC Delegate Methods

- (void)toggleFullImageShowForViewController:(CJMFullImageViewController *)viewController
{
    self.makeViewsVisible = !self.makeViewsVisible;
    NSLog(@"makeViewsVisible is %@", [NSNumber numberWithBool:self.makeViewsVisible]);
    
    //[self pageViewController:self viewControllerBeforeViewController:viewController];
    //[self pageViewController:self viewControllerAfterViewController:viewController];
    
    [viewController setViewsVisible:self.makeViewsVisible];
}

- (void)viewController:(CJMFullImageViewController *)currentVC deletedImageAtIndex:(NSInteger)imageIndex
{
    if ((imageIndex + 1) >= _albumCount) {
        CJMFullImageViewController *previousVC = (CJMFullImageViewController *)[self pageViewController:self viewControllerBeforeViewController:currentVC];
        NSLog(@"We need to go to the previous image");
        //previousVC.index = imageIndex;
        self.albumCount -= 1;
        
        [self setViewControllers:@[previousVC]
                                          direction:UIPageViewControllerNavigationDirectionReverse
                                           animated:YES
                                         completion:nil];
    } else {
        CJMFullImageViewController *nextVC = (CJMFullImageViewController *)[self pageViewController:self viewControllerAfterViewController:currentVC];
    NSLog(@"%@", nextVC);
        nextVC.index = imageIndex;
        self.albumCount -= 1;
    
        [self setViewControllers:@[nextVC]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:YES
                      completion:NULL];
    
    }
    //pageview not moving to new image after deletion
}



@end

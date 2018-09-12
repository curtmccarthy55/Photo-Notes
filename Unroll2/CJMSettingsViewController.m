//
//  CJMSettingsViewController.m
//  Photo Notes
//
//  Created by Curtis McCarthy on 1/4/17.
//  Copyright © 2017 Bluewraith. All rights reserved.
//

#import "CJMSettingsViewController.h"
#import "CJMFileSerializer.h"
#import "CJMAlbumManager.h"
#import "CJMPhotoAlbum.h"
#import "CJMImage.h"
#import "CJMServices.h"

@import SafariServices;
@import MessageUI;
@import StoreKit;

typedef enum {
    kPhotoNotesBlue,
    kPhotoNotesRed,
    kPhotoNotesBlack,
    kPhotoNotesPurple,
    kPhotoNotesOrange,
    kPhotoNotesYellow,
    kPhotoNotesGreen,
    kPhotoNotesWhite
} ThemeColor;

@interface CJMSettingsViewController () <SFSafariViewControllerDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnDone;
@property (weak, nonatomic) IBOutlet UISlider *sldOpacity;
@property (weak, nonatomic) IBOutlet UIView *noteView;
@property (weak, nonatomic) IBOutlet UITextField *lblOpacity;
@property (nonatomic) CGFloat finalVal;

@property (nonatomic, strong) PHFetchResult *fetchResult;
@property (strong) PHCachingImageManager *imageManager;

@property (weak, nonatomic) IBOutlet UIButton *whiteButton;

@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *colorButtons;
@property (nonatomic, strong) NSNumber *userColorTag;
@property (nonatomic, strong) UIColor *userColor;
@property (nonatomic) BOOL colorChanged;

@property (weak, nonatomic) IBOutlet UIImageView *qnThumbnail;


@end

@implementation CJMSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.btnDone setEnabled:NO];
    
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] valueForKey:@"PhotoNotesColor"];
    NSNumber *currentTag = [dic valueForKey:@"PhotoNotesColorTag"];
    self.userColorTag = currentTag ? currentTag : 0;
    
//    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] valueForKey:@"PhotoNotesColor"];
    if (dic) {
        NSNumber *red, *green, *blue;
        red = [dic valueForKey:@"PhotoNotesRed"];
        green = [dic valueForKey:@"PhotoNotesGreen"];
        blue = [dic valueForKey:@"PhotoNotesBlue"];
        self.userColor = [UIColor colorWithRed:red.floatValue green:green.floatValue blue:blue.floatValue alpha:1.0];
    } else {
        self.userColor = [UIColor colorWithRed:60.0/255.0 green:128.0/255.0 blue:194.0/255.0 alpha:1];
    }
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
    
    //Set current opacity
    NSNumber *currentOpacity = [[NSUserDefaults standardUserDefaults] valueForKey:@"noteOpacity"];
    CGFloat opacity = currentOpacity.floatValue ? currentOpacity.floatValue : 0.75;
    [self.noteView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:opacity]];
    [self.lblOpacity setText:[NSString stringWithFormat:@"%.f%%", roundf(opacity * 100)]];
    [self.sldOpacity setValue:(opacity * 100.0) animated:NO];
    
    //Set current color
    [[self.whiteButton layer] setBorderWidth:1.0f];
    [[self.whiteButton layer] setBorderColor:[UIColor blackColor].CGColor];
    UIButton *button = [self.colorButtons objectAtIndex:self.userColorTag.integerValue];
    [[button layer] setBorderWidth:2.0f];
    [[button layer] setBorderColor:[UIColor greenColor].CGColor];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setPrefersLargeTitles:YES];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self displayQNThumnail];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons

- (IBAction)doneAction:(id)sender {
    NSNumber *opacity = [[NSUserDefaults standardUserDefaults] valueForKey:@"noteOpacity"];
    if (opacity.floatValue != self.sldOpacity.value) {
        NSNumber *newOpac = [NSNumber numberWithFloat:(self.sldOpacity.value / 100)];
        [[NSUserDefaults standardUserDefaults] setValue:newOpac forKey:@"noteOpacity"];
    }
    
    if (self.colorChanged) {
        NSDictionary *dic = [self selectedColorWithTag:self.userColorTag.integerValue];
        [[NSUserDefaults standardUserDefaults] setValue:dic forKey:@"PhotoNotesColor"];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAction:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)standardColor:(UIButton *)sender {
    if (self.btnDone.enabled == NO) {
        [self.btnDone setEnabled:YES];
    }
    self.colorChanged = YES;
    
    UIButton *currentColor = [self.colorButtons objectAtIndex:self.userColorTag.integerValue];
    if (currentColor.tag == 7) {
        [[currentColor layer] setBorderWidth:1.0f];
        [[currentColor layer] setBorderColor:[UIColor blackColor].CGColor];
    } else {
        [[currentColor layer] setBorderWidth:0.0];
    }
    
    [[sender layer] setBorderWidth:2.0f];
    [[sender layer] setBorderColor:[UIColor greenColor].CGColor];
    
    NSNumber *numTag = [NSNumber numberWithInteger:sender.tag];
    self.userColorTag = numTag;
    
    NSDictionary *dic = [self selectedColorWithTag:sender.tag];
    NSNumber *red, *green, *blue;
    red = [dic valueForKey:@"PhotoNotesRed"];
    green = [dic valueForKey:@"PhotoNotesGreen"];
    blue = [dic valueForKey:@"PhotoNotesBlue"];
    
    if (self.userColorTag.integerValue != 5 && self.userColorTag.integerValue != 7) {
        [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        [self.navigationController.navigationBar setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor whiteColor] }];
    } else {
        [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
        [self.navigationController.navigationBar setTintColor:[UIColor blackColor]];
        [self.navigationController.navigationBar setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor blackColor] }];
    }
    self.userColor = [UIColor colorWithRed:red.floatValue green:green.floatValue blue:blue.floatValue alpha:1.0];
    [self.navigationController.navigationBar setBarTintColor:self.userColor];
//    [self.sldOpacity setThumbTintColor:userColor];
}

- (NSDictionary *)selectedColorWithTag:(NSInteger)tag {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    NSNumber *red, *green, *blue;
    NSNumber *selectedTag;
    
    switch (tag) {
        case kPhotoNotesBlue:
            red = [NSNumber numberWithFloat:60.0/255.0];
            green = [NSNumber numberWithFloat:128.0/255.0];
            blue = [NSNumber numberWithFloat:194.0/255.0];
            selectedTag = @0;
            break;
        case kPhotoNotesRed:
            red = [NSNumber numberWithFloat:0.81];
            green = [NSNumber numberWithFloat:0.21];
            blue = [NSNumber numberWithFloat:0.2];
            selectedTag = @1;
            break;
        case kPhotoNotesBlack:
            red = [NSNumber numberWithFloat:0.26];
            green = [NSNumber numberWithFloat:0.26];
            blue = [NSNumber numberWithFloat:0.26];
            selectedTag = @2;
            break;
        case kPhotoNotesPurple:
            red = [NSNumber numberWithFloat:0.67];
            green = [NSNumber numberWithFloat:0.26];
            blue = [NSNumber numberWithFloat:0.73];
            selectedTag = @3;
            break;
        case kPhotoNotesOrange:
            red = [NSNumber numberWithFloat:0.93];
            green = [NSNumber numberWithFloat:0.55];
            blue = [NSNumber numberWithFloat:0.01];
            selectedTag = @4;
            break;
        case kPhotoNotesYellow:
            red = [NSNumber numberWithFloat:0.95];
            green = [NSNumber numberWithFloat:0.95];
            blue = [NSNumber numberWithFloat:0.34];
            selectedTag = @5;
            break;
        case kPhotoNotesGreen:
            red = [NSNumber numberWithFloat:-0.08];
            green = [NSNumber numberWithFloat:0.56];
            blue = [NSNumber numberWithFloat:-0.01];
            selectedTag = @6;
            break;
        case kPhotoNotesWhite:
            red = [NSNumber numberWithFloat:1.0];
            green = [NSNumber numberWithFloat:1.0];
            blue = [NSNumber numberWithFloat:1.0];
            selectedTag = @7;
            break;
        default:
            break;
    }
    [dictionary setValue:red forKey:@"PhotoNotesRed"];
    [dictionary setValue:green forKey:@"PhotoNotesGreen"];
    [dictionary setValue:blue forKey:@"PhotoNotesBlue"];
    [dictionary setValue:selectedTag forKey:@"PhotoNotesColorTag"];
    
    return dictionary;
}

#pragma mark - Opacity Slider

- (IBAction)slider:(UISlider*)sender {
    float oVal = sender.value;
    [self.lblOpacity setText:[NSString stringWithFormat:@"%.f%%", roundf(oVal)]];
    [self.noteView setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:(oVal / 100)]];
    [self.lblOpacity setAlpha:1.0];
    
    if (self.btnDone.enabled == NO) {
        [self.btnDone setEnabled:YES];
    }
}


#pragma mark - CJMPhotoGrabber Methods and Delegate

- (void)presentPhotoGrabViewController {
    NSString *storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    UINavigationController *navigationVC = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"NavPhotoGrabViewController"];
    CJMPhotoGrabViewController *vc = (CJMPhotoGrabViewController *)[navigationVC topViewController];
    vc.delegate = self;
    vc.userColor = self.userColor;
    vc.userColorTag = self.userColorTag;
    vc.singleSelection = YES;
    
    [self presentViewController:navigationVC animated:YES completion:nil];
}

- (void)photoGrabViewControllerDidCancel:(CJMPhotoGrabViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

//iterate through array of selected photos, convert them to CJMImages, and add to the current album.
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

        
        [assetImage setInitialValuesForCJMImage:assetImage inAlbum:@"CJMQuickNote"];
        assetImage.photoCreationDate = [NSDate date];
        
        [newImages addObject:assetImage];
    }
    
    CJMPhotoAlbum *album = [[CJMAlbumManager sharedInstance] userQuickNote];
    CJMImage *newImage = newImages[0];
    if (album.albumPhotos.count > 0) {
        CJMImage *oldImage = album.albumPhotos[0];
        newImage.photoTitle = oldImage.photoTitle;
        newImage.photoNote = oldImage.photoNote;
        newImage.photoCreationDate = oldImage.photoCreationDate;
    }
    [[CJMAlbumManager sharedInstance] albumWithName:@"CJMQuickNote" deleteImages:album.albumPhotos];
    [album addCJMImage:newImage];
    [self.btnDone setEnabled:YES];
    
    dispatch_group_notify(imageLoadGroup, dispatch_get_main_queue(), ^{
        self.navigationController.view.userInteractionEnabled = YES;
//        [self.collectionView reloadData];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[CJMAlbumManager sharedInstance] save];
        [self displayQNThumnail];
        self.navigationController.view.userInteractionEnabled = YES;
    });
}


- (void)displayQNThumnail {
    CJMPhotoAlbum *album = [[CJMAlbumManager sharedInstance] userQuickNote];
    if (album.albumPhotos.count > 0) {
        CJMImage *qnImage = album.albumPhotos[0];
        
        [[CJMServices sharedInstance] fetchThumbnailForImage:qnImage handler:^(UIImage *thumbnail) {
            //if thumbnail not properly captured during import, create one
            if (thumbnail.size.width == 0) {
                qnImage.thumbnailNeedsRedraw = YES;
                [[CJMServices sharedInstance] removeImageFromCache:qnImage];
            } else {
                self.qnThumbnail.image = thumbnail;
            }
        }];
    } else {
        [self.qnThumbnail setImage:[UIImage imageNamed:@"QuickNote PN Background"]];
    }
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [self photosFromLibrary];
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
//            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:]];
//            NSString *str_URL = @"https://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=1021742238&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&type=Purple+Software&mt=8";
            NSString *str_URL = @"https://itunes.apple.com/us/app/photo-notes-add-context-to-your-photos/id1021742238?mt=8";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:str_URL] options:@{UIApplicationOpenURLOptionUniversalLinksOnly : @NO} completionHandler:nil];
            
        } else if (indexPath.row == 1) {
            SFSafariViewController *vc = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:@"https://www.twitter.com/beDevCurt"]];
            vc.delegate = self;
            [self presentViewController:vc animated:YES completion:nil];
        } else {
            MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
            vc.mailComposeDelegate = self;
            vc.modalPresentationStyle = UIModalPresentationPageSheet;
            [vc setToRecipients:@[@"bedevcurt@gmail.com"]];
            [vc setSubject:@"Photo Notes - Add context to your photos"];
            [vc setMessageBody:@"Hey Curt!" isHTML:NO];
            if ([MFMailComposeViewController canSendMail]) {
                [self presentViewController:vc animated:YES completion:nil];
            }
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Safari and Mail delegates

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    if (result == MFMailComposeResultCancelled || result == MFMailComposeResultSent) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else if (result == MFMailComposeResultFailed) {
        [self dismissViewControllerAnimated:YES completion:nil];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Email Fail" message:@"Uh-oh... looks like the message failed to send.  Please try again or email me at bedevcurt@gmail.com direct from your Mail app" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionDismiss = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *dismissAction) {}];
        [alert addAction:actionDismiss];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end

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


@interface CJMSettingsViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *btnDone;

@property (nonatomic, strong) PHFetchResult *fetchResult;
@property (strong) PHCachingImageManager *imageManager;

@end

@implementation CJMSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.btnDone setEnabled:NO];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Buttons

- (IBAction)cancelAction:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnTwitter:(id)sender {
    NSLog(@"*cjm* direct user to twitter.com/beDevCurt");
}

#pragma mark - CJMPhotoGrabber Methods and Delegate

- (void)presentPhotoGrabViewController {
    NSString * storyboardName = @"Main";
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:storyboardName bundle: nil];
    UINavigationController *navigationVC = (UINavigationController *)[storyboard instantiateViewControllerWithIdentifier:@"PhotoGrabViewController"];
    CJMPhotoGrabViewController *vc = (CJMPhotoGrabViewController *)[navigationVC topViewController];
    vc.delegate = self;
    [self presentViewController:navigationVC animated:YES completion:nil];
}

- (void)photoGrabViewControllerDidCancel:(CJMPhotoGrabViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
        
        [assetImage setInitialValuesForCJMImage:assetImage inAlbum:@"CJMQuickNote"];
        //        assetImage.photoLocation = [asset location];
        assetImage.photoCreationDate = [asset creationDate];
        
        [newImages addObject:assetImage];
    }
    
    CJMPhotoAlbum *album = [[CJMAlbumManager sharedInstance] userQuickNote];
    [album addMultipleCJMImages:newImages];
    
    dispatch_group_notify(imageLoadGroup, dispatch_get_main_queue(), ^{
        self.navigationController.view.userInteractionEnabled = YES;
//        [self.collectionView reloadData];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[CJMAlbumManager sharedInstance] save];
        self.navigationController.view.userInteractionEnabled = YES;
    });
}

#pragma mark - Table view data source

/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

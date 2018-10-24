//
//  PHNImportAlbumsVC.m
//  Unroll2
//
//  Created by Curtis McCarthy on 10/16/18.
//  Copyright © 2018 Bluewraith. All rights reserved.
//

#import "CJMAListTableViewCell.h"
#import "PHNImportAlbumsVC.h"
#import "PHNPhotoGrabCompletionDelegate.h"
#import "CJMPhotoGrabViewController.h"

@import Photos;

#define SEGUE_IDENTIFIER @"ViewCollection"
#define CJMAListCellIdentifier @"AlbumCell"

@interface PHNImportAlbumsVC ()

typedef enum {
    kAllPhotos,
    kSmartAlbums,
    kUserCollections,
} Section;

@property (nonatomic, strong) PHFetchResult<PHAsset *> *allPhotos;
@property (nonatomic, strong) PHFetchResult<PHAssetCollection *> *smartAlbums;
@property (nonatomic, strong) PHFetchResult<PHCollection *> *userCollections;
@property (nonatomic, strong) NSArray *sectionLocalizedTitles;
@property (strong) PHCachingImageManager *imageManager;
@property (nonatomic, strong) PHFetchOptions *ascendingOptions;

@property (nonatomic, strong) NSIndexPath *selectedIndex;

@end

@implementation PHNImportAlbumsVC

- (void)viewDidLoad { //cjm album fetch
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"CJMAListTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CJMAListCellIdentifier];
    self.tableView.rowHeight = 80;
    
    self.imageManager = [PHCachingImageManager new];
    self.sectionLocalizedTitles = @[@"", @"Smart Albums", @"Albums"];
    
    //Create a PHFetchResult object for each section in the table view.
    self.ascendingOptions = [PHFetchOptions new];
    self.ascendingOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    self.allPhotos = [PHAsset fetchAssetsWithOptions:self.ascendingOptions];
    self.smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil]; //PHAssetCollection
    self.userCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil]; //PHCollectionList
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelPressed)];
    
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
    [self.navigationController.toolbar setBarTintColor:self.userColor];
}

- (void)cancelPressed {
    [self.delegate photoGrabSceneDidCancel];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 1;
        case 1:
            return self.smartAlbums.count;
        case 2:
            return self.userCollections.count;
        default:
            //display some error message
            return 1;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJMAListTableViewCell *cell = (CJMAListTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CJMAListCellIdentifier forIndexPath:indexPath];
    
    PHAsset *asset;
    if (indexPath.section == 0) {
        NSLog(@"should be showing All Photos cell");
        [cell configureWithTitle:@"All Photos" withAlbumCount:(int)self.allPhotos.count];
        asset = self.allPhotos.lastObject;
    } else if (indexPath.section == 1) {
        PHAssetCollection *assetCollection = self.smartAlbums[indexPath.row];
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:self.ascendingOptions];
        asset = result.lastObject;
        
        [cell configureWithTitle:assetCollection.localizedTitle withAlbumCount:(int)result.count];
    } else if (indexPath.section == 2) {
        NSLog(@"fetching collection from self.userCollections[%ld]", (long)indexPath.row);
        //            PHCollection *collection = self.userCollections[indexPath.row];
        //            cell.textLabel.text = collection.localizedTitle;
        //
        //            PHFetchResult *result = []
        //            asset = result.firstObject;
    }
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:cell.frame.size
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  cell.cellThumbnail.image = result;
                              }];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionLocalizedTitles[section];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndex = indexPath;
    [self performSegueWithIdentifier:SEGUE_IDENTIFIER sender:nil];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender { //cjm album fetch
    if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER]) {
        CJMPhotoGrabViewController *vc = (CJMPhotoGrabViewController *)segue.destinationViewController;
        //         vc.title =
         vc.delegate = self.delegate;
        vc.userColor = self.userColor;
        vc.userColorTag = self.userColorTag;
        vc.singleSelection = NO;
    }
    
    
    
    
    /*
    destination.title = cell.textLabel?.text
    
    switch SegueIdentifier(rawValue: segue.identifier!)! {
    case .showAllPhotos:
        destination.fetchResult = allPhotos
    case .showCollection:
        // Fetch the asset collection for the selected row.
        let indexPath = tableView.indexPath(for: cell)!
        let collection: PHCollection
        switch Section(rawValue: indexPath.section)! {
        case .smartAlbums:
            collection = smartAlbums.object(at: indexPath.row)
        case .userCollections:
            collection = userCollections.object(at: indexPath.row)
        default: return // The default indicates that other segues have already handled the photos section.
        }
        
        // configure the view controller with the asset collection
        guard let assetCollection = collection as? PHAssetCollection
        else { fatalError("Expected an asset collection.") }
        destination.fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
        destination.assetCollection = assetCollection
    }
    */
}

@end

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
    self.navigationItem.title = @"Photos";
    self.imageManager = [PHCachingImageManager new];
    self.sectionLocalizedTitles = @[@"", @"Library", @"My Albums"];
    
    //Create a PHFetchResult object for each section in the table view.
    self.ascendingOptions = [PHFetchOptions new];
    self.ascendingOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    
    self.allPhotos = [PHAsset fetchAssetsWithOptions:self.ascendingOptions];
    self.smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil]; //PHAssetCollection
    /*
     TODO we should remove Recently Deleted and All Photos from this collection.  Need to see what All Photos collection name actually is though.
     We'll need to set up a fetchOption that excludes these albums and include that in the smartAlbums fetch.
     I should also filter out FetchResults that have count == 0.
     */
    
    
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
// func cancelPressed() {
- (void)cancelPressed {
    [self.delegate photoGrabSceneDidCancel];
}

#pragma mark - Table view data source
// override func numberOfSections(in tableView: UITableView) -> Int {
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}
// override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        PHCollection *collection = self.userCollections[indexPath.row];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:self.ascendingOptions];
            asset = result.lastObject;
            
            [cell configureWithTitle:assetCollection.localizedTitle withAlbumCount:(int)result.count];
        } else if ([collection isKindOfClass:[PHCollectionList class]]) {
            
        }
    }
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:cell.frame.size
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  if (result != nil) {
                                      cell.cellThumbnail.image = result;
                                  } else {
                                      cell.cellThumbnail.image = [UIImage imageNamed:@"NoImage"];
                                  }
                              }];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionLocalizedTitles[section];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColor.whiteColor];
    header.backgroundColor = UIColor.clearColor;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedIndex = indexPath;
    [self performSegueWithIdentifier:SEGUE_IDENTIFIER sender:nil];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender { //cjm album fetch
    CJMPhotoGrabViewController *vc = (CJMPhotoGrabViewController *)segue.destinationViewController;
    vc.delegate = self.delegate;
    vc.userColor = self.userColor;
    vc.userColorTag = self.userColorTag;
    vc.singleSelection = self.singleSelection;
    
    if (self.selectedIndex.section == 0) {
        NSLog(@"should be showing All Photos cell");
        vc.fetchResult = self.allPhotos;
        vc.title = @"All Photos";
    } else if (self.selectedIndex.section == 1) {
        PHAssetCollection *assetCollection = self.smartAlbums[self.selectedIndex.row];
        PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:self.ascendingOptions];
        vc.fetchResult = result;
        vc.title = assetCollection.localizedTitle;
    } else if (self.selectedIndex.section == 2) {
        PHCollection *collection = self.userCollections[self.selectedIndex.row];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:self.ascendingOptions];
            vc.fetchResult = result;
            vc.title = assetCollection.localizedTitle;
        } else if ([collection isKindOfClass:[PHCollectionList class]]) {
            
        }
    }
}

@end

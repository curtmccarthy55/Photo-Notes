//
//  PHNImportAlbumsVC.m
//  Unroll2
//
//  Created by Curtis McCarthy on 10/16/18.
//  Copyright © 2018 Bluewraith. All rights reserved.
//

#import "CJMAListTableViewCell.h"
#import "PHNImportAlbumsVC.h"
#import "CJMPhotoGrabViewController.h"

@import Photos;

#define SEGUE_IDENTIFIER @"ViewCollection"

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

@property (nonatomic, strong) NSIndexPath *selectedIndex;

@end

@implementation PHNImportAlbumsVC

- (void)viewDidLoad { //cjm album fetch
    [super viewDidLoad];
    
    self.imageManager = [PHCachingImageManager new];
    self.sectionLocalizedTitles = @[@"", @"Smart Albums", @"Albums"];
    
    //Create a PHFetchResult object for each section in the table view.
    PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    self.allPhotos = [PHAsset fetchAssetsWithOptions:allPhotosOptions];
    self.smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    self.userCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelPressed)];
}

- (void)cancelPressed {
    [self.delegate photoGrabViewControllerDidCancel:self];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    
    PHAsset *asset;
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    switch (indexPath.section) {
        case 0:
            cell.textLabel.text = @"All Photos";
            asset = self.allPhotos.lastObject; 
            break;
        case 1:
        { //brackets create separate scope to allow for variable assignments...
            PHAssetCollection *assetCollection = self.smartAlbums[indexPath.row];
            cell.textLabel.text = assetCollection.localizedTitle;
            
            PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
            asset = result.lastObject;
            
            break;
        }
            case 2:
        {
//            PHCollection *collection = self.userCollections[indexPath.row];
//            cell.textLabel.text = collection.localizedTitle;
//            
//            PHFetchResult *result = []
//            asset = result.firstObject;
            
            
            
            break;
        }
        default:
            break;
    }
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:cell.frame.size
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
                                  cell.imageView.image = result;
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
        //         vc.delegate = self;
        //         vc.userColor = self.userColor;
        //         vc.userColorTag = self.userColorTag;
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

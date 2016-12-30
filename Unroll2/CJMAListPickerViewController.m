//
//  CJMAListPickerViewController.m
//  Photo Notes
//
//  Created by Curt on 6/13/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMAListPickerViewController.h"
#import "CJMAListTableViewCell.h"
#import "CJMAlbumManager.h"
#import "CJMServices.h"

#define CJMAListCellIdentifier @"AlbumCell"

@interface CJMAListPickerViewController ()

@property (nonatomic, strong) CJMPhotoAlbum *selectedAlbum;
@property (nonatomic, strong) NSMutableArray *nonFavAlbums;

@end

@implementation CJMAListPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"CJMAListTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CJMAListCellIdentifier];
    self.tableView.rowHeight = 80;
    
    self.nonFavAlbums = [NSMutableArray new];
    NSArray *albumArray = [[CJMAlbumManager sharedInstance].allAlbums copy];
    for (CJMPhotoAlbum *album in albumArray) {
        if (![album.albumTitle isEqualToString:@"Favorites"]) {
            [self.nonFavAlbums addObject:album];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelPressed)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(donePressed)];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    return [[[CJMAlbumManager sharedInstance] allAlbums] count] - 1;
    return self.nonFavAlbums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJMAListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CJMAListCellIdentifier forIndexPath:indexPath];
    
//    CJMPhotoAlbum *album = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
    CJMPhotoAlbum *album = [self.nonFavAlbums objectAtIndex:indexPath.row];
    
    [cell configureTextForCell:cell withAlbum:album];
    [cell configureThumbnailForCell:cell forAlbum:album];
    
    return cell;
}

//- (void)configureTextForCell:(CJMAListTableViewCell *)cell withAlbum:(CJMPhotoAlbum *)album
//{
//    cell.cellAlbumName.text = album.albumTitle;
//    
//    if (album.albumPhotos.count == 0) {
//        cell.cellAlbumCount.text = @"No Photos";
//    } else if (album.albumPhotos.count == 1) {
//        cell.cellAlbumCount.text = @"1 Photo";
//    } else {
//        cell.cellAlbumCount.text = [NSString stringWithFormat:@"%lu Photos", (unsigned long)album.albumPhotos.count];
//    }
//}
//
//- (void)configureThumbnailForCell:(CJMAListTableViewCell *)cell forAlbum:(CJMPhotoAlbum *)album
//{
//    [[CJMServices sharedInstance] fetchThumbnailForImage:album.albumPreviewImage
//                                                 handler:^(UIImage *thumbnail) {
//                                                     cell.cellThumbnail.image = thumbnail;
//                                                 }];
//    
//    if (cell.cellThumbnail.image == nil) {
//        if (album.albumPhotos.count >= 1) {
//            CJMImage *firstImage = album.albumPhotos[0];
//            
//            [[CJMServices sharedInstance] fetchThumbnailForImage:firstImage handler:^(UIImage *thumbnail) {
//                cell.cellThumbnail.image = thumbnail;
//            }];
//            
//        } else {
//            cell.cellThumbnail.image = [UIImage imageNamed:@"no_image.jpg"];
//        }
//    }
//}

//replaces blank rows with blank space in the tableView
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    return view;
}

#pragma mark - tableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedAlbum = [self.nonFavAlbums objectAtIndex:indexPath.row];
}

#pragma mark - Buttons actions

- (void)cancelPressed
{
    [self.delegate aListPickerViewControllerDidCancel:self];
}

//If user picks the current album, display an alert.  Otherwise, move photos to new album.
- (void)donePressed {
    if ([self.selectedAlbum.albumTitle isEqual:self.currentAlbumName]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Choose Alternate Album" message:@"The selected Photo Notes are already in this album.\n  Please choose a different album." preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) { }];
        [alertController addAction:dismissAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [self.delegate aListPickerViewController:self didFinishPickingAlbum:self.selectedAlbum];
    }
}


@end

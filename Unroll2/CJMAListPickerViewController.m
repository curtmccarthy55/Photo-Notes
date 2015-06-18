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

@end

@implementation CJMAListPickerViewController
{
    CJMPhotoAlbum *_selectedAlbum;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"CJMAListTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CJMAListCellIdentifier];
    
    self.tableView.rowHeight = 80;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[CJMAlbumManager sharedInstance] allAlbums] count];
}

- (void)configureTextForCell:(CJMAListTableViewCell *)cell withAlbum:(CJMPhotoAlbum *)album
{
    cell.cellAlbumName.text = album.albumTitle;
    
    if (album.albumPhotos.count == 0) {
        cell.cellAlbumCount.text = @"No Photos";
    } else {
        cell.cellAlbumCount.text = [NSString stringWithFormat:@"%lu Photos", (unsigned long)album.albumPhotos.count];
    }
}

- (void)configureThumbnailForCell:(CJMAListTableViewCell *)cell forAlbum:(CJMPhotoAlbum *)album
{
    [[CJMServices sharedInstance] fetchThumbnailForImage:album.albumPreviewImage
                                                 handler:^(UIImage *thumbnail) {
                                                     cell.cellThumbnail.image = thumbnail;
                                                 }];
    
    if (cell.cellThumbnail.image == nil) {
        if (album.albumPhotos.count >= 1) {
            CJMImage *firstImage = album.albumPhotos[0];
            
            [[CJMServices sharedInstance] fetchThumbnailForImage:firstImage handler:^(UIImage *thumbnail) {
                cell.cellThumbnail.image = thumbnail;
            }];
            
        } else {
            cell.cellThumbnail.image = [UIImage imageNamed:@"no_image.jpg"];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CJMAListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CJMAListCellIdentifier forIndexPath:indexPath];
    
    CJMPhotoAlbum *album = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
    
    [self configureTextForCell:cell withAlbum:album];
    [self configureThumbnailForCell:cell forAlbum:album];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{  //replaces blank rows with blank space in the tableView
    UIView *view = [[UIView alloc] init];
    
    return view;
}

#pragma mark - tableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedAlbum = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
}

#pragma mark - Buttons actions

- (void)cancelPressed
{
    [self.delegate aListPickerViewControllerDidCancel:self];
}

- (void)donePressed
{
    [self.delegate aListPickerViewController:self didFinishPickingAlbum:_selectedAlbum];
}


@end

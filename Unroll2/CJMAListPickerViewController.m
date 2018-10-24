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
@property (nonatomic, strong) NSMutableArray *transferAlbums;

@end

@implementation CJMAListPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"CJMAListTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CJMAListCellIdentifier];
    self.tableView.rowHeight = 80;
    
    self.transferAlbums = [NSMutableArray new];
    NSArray *albumArray = [[CJMAlbumManager sharedInstance].allAlbums copy];
    for (CJMPhotoAlbum *album in albumArray) {
        if (![album.albumTitle isEqualToString:@"Favorites"] && ![album.albumTitle isEqualToString:@"CJMQuickNote"]) {
            [self.transferAlbums addObject:album];
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
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    return [[[CJMAlbumManager sharedInstance] allAlbums] count] - 1;
    return self.transferAlbums.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJMAListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CJMAListCellIdentifier forIndexPath:indexPath];
    
//    CJMPhotoAlbum *album = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
    CJMPhotoAlbum *album = [self.transferAlbums objectAtIndex:indexPath.row];
    
    [cell configureWithTitle:album.albumTitle withAlbumCount:(int)album.albumPhotos.count];
    [cell configureThumbnailForCell:cell forAlbum:album];
    
    return cell;
}

//replaces blank rows with blank space in the tableView
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] init];
    return view;
}

#pragma mark - tableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.navigationItem.rightBarButtonItem setEnabled:YES];
    self.selectedAlbum = [self.transferAlbums objectAtIndex:indexPath.row];
}

#pragma mark - Buttons actions

- (void)cancelPressed {
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

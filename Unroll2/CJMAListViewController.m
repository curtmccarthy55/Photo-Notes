//
//  CJMAListViewController.m
//  Unroll
//
//  Created by Curt on 4/12/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMAListViewController.h"
#import "CJMGalleryViewController.h"
#import "CJMAListTableViewCell.h"
#import "CJMPopoverViewController.h"
#import "CJMAlbumManager.h"
#import "CJMPhotoAlbum.h"
#import "CJMServices.h"


#define CJMAListCellIdentifier @"AlbumCell"

@interface CJMAListViewController () <UIPopoverPresentationControllerDelegate, CJMPopoverDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (nonatomic) BOOL popoverPresent;
@property (nonatomic, strong) UIColor *userColor;

@end

@implementation CJMAListViewController

#pragma mark - view prep and display

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"CJMAListTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:CJMAListCellIdentifier];
    
    self.tableView.rowHeight = 80;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSDictionary *dic = [[NSUserDefaults standardUserDefaults] valueForKey:@"PhotoNotesColor"];
    if (dic) {
        NSNumber *red, *green, *blue;
        red = [dic valueForKey:@"PhotoNotesRed"];
        green = [dic valueForKey:@"PhotoNotesGreen"];
        blue = [dic valueForKey:@"PhotoNotesBlue"];
        self.userColor = [UIColor colorWithRed:red.floatValue green:green.floatValue blue:blue.floatValue alpha:1.0];
    } else {
        self.userColor = [UIColor colorWithRed:60.0/255.0 green:128.0/255.0 blue:194.0/255.0 alpha:1];
    }
    
    [self.navigationController.navigationBar setBarTintColor:self.userColor];
    [self.navigationController.toolbar setBarTintColor:self.userColor];
    
    [self.navigationController.toolbar setHidden:NO];
    [self noAlbumsPopUp];
    [self.tableView reloadData];
}


- (void)noAlbumsPopUp
{//If there are no albums, prompt the user to create one after a delay.
    dispatch_time_t waitTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    if ([[CJMAlbumManager sharedInstance] allAlbums].count == 0) {
        dispatch_after(waitTime, dispatch_get_main_queue(), ^{
            [self.navigationItem setPrompt:@"Tap + below to create a new Photo Notes album!"];
        });
    } else {
        [self.navigationItem setPrompt:nil];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (self.popoverPresent) {
        [self dismissViewControllerAnimated:YES completion:nil];
        self.popoverPresent = NO;
    }
}

#pragma mark - tableView data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{ 
    return [[CJMAlbumManager sharedInstance] allAlbums].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CJMAListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CJMAListCellIdentifier forIndexPath:indexPath];
    
    CJMPhotoAlbum *album = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
    [cell configureTextForCell:cell withAlbum:album];
    [cell configureThumbnailForCell:cell forAlbum:album];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    cell.showsReorderControl = YES;
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{//replaces blank rows with blank space in the tableView
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1.0, 1.0)];
    return view;
}

                          

#pragma mark - tableView delegate methods

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
//    [self performSegueWithIdentifier:@"EditAlbum" sender:[tableView cellForRowAtIndexPath:indexPath]];
    
    //cjm 12/07
    NSString *sbName = @"Main";
    UIStoryboard *sb = [UIStoryboard storyboardWithName:sbName bundle:nil];
    CJMPopoverViewController *popVC = (CJMPopoverViewController *)[sb instantiateViewControllerWithIdentifier:@"CJMPopover"];
    CJMPhotoAlbum *album = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
    popVC.name = album.albumTitle;
    popVC.note = album.albumNote;
    popVC.indexPath = indexPath;
    popVC.delegate = self;
    
    popVC.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popController = popVC.popoverPresentationController;
    popController.delegate = self;
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    [popController setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.67]];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    popController.sourceView = cell;
    popController.sourceRect = CGRectMake(cell.bounds.size.width - 33.0, cell.bounds.size.height / 2.0, 1.0, 1.0);
    
    self.popoverPresent = YES;
    [self presentViewController:popVC animated:YES completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"ViewGallery" sender:[tableView cellForRowAtIndexPath:indexPath]];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - QuickNotes

- (IBAction)actionQuicknote:(id)sender {
    CJMFullImageViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"FullImageVC"];
    vc.index = 0;
    vc.albumName = @"Favorites";
    vc.delegate = self;
    vc.isQuickNote = YES;
//    [self.navigationController.toolbar setHidden:YES];
    [vc setViewsVisible:NO];
}

- (void)photoIsFavorited:(BOOL)isFavorited {
    
}

- (void)toggleFullImageShow:(BOOL)yesOrNo forViewController:(CJMFullImageViewController *)viewController {
    
}


#pragma mark - Editing the list

- (IBAction)editTableView:(id)sender
{
    if ([self.editButton.title isEqual:@"Edit"]) {
        [self.editButton setTitle:@"Done"];
        [self.tableView setEditing:YES animated:YES];
    } else {
        [self.editButton setTitle:@"Edit"];
        [self.tableView setEditing:NO animated:YES];
        
        [[CJMAlbumManager sharedInstance] save];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    CJMPhotoAlbum *album = [[CJMAlbumManager sharedInstance].allAlbums objectAtIndex:indexPath.row];
    if ([album.albumTitle isEqualToString:@"Favorites"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cannot delete the Favorites album" message:@"Removal of the favorites album is handled automatically when no Photo Notes are favorited." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *actionDismiss = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *dismissAction) {} ];
        [alert addAction:actionDismiss];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        NSUInteger favInt = [[CJMAlbumManager sharedInstance].allAlbums indexOfObject:[CJMAlbumManager sharedInstance].favPhotosAlbum];
        NSIndexPath *favPath = [NSIndexPath indexPathForRow:favInt inSection:0];
        BOOL favoritesActive = [CJMAlbumManager sharedInstance].favPhotosAlbum.albumPhotos.count > 0 ? YES : NO;
        [[CJMAlbumManager sharedInstance] removeAlbumAtIndex:indexPath.row];
        [[CJMAlbumManager sharedInstance] save];
        if ([CJMAlbumManager sharedInstance].favPhotosAlbum.albumPhotos.count < 1 && favoritesActive) {
            [tableView deleteRowsAtIndexPaths:@[indexPath, favPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
        [tableView reloadData];
        [self noAlbumsPopUp];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [[CJMAlbumManager sharedInstance] replaceAlbumAtIndex:toIndexPath.row withAlbumFromIndex:fromIndexPath.row];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ViewGallery"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        CJMPhotoAlbum *sentAlbum = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
        sentAlbum.delegate = [CJMAlbumManager sharedInstance];
        CJMGalleryViewController *galleryVC = (CJMGalleryViewController *)segue.destinationViewController;
        galleryVC.album = sentAlbum;
    } else if ([segue.identifier isEqualToString:@"EditAlbum"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        CJMPhotoAlbum *sentAlbum = [[[CJMAlbumManager sharedInstance] allAlbums] objectAtIndex:indexPath.row];
        UINavigationController *navigationController = segue.destinationViewController;
        CJMADetailViewController *detailVC = (CJMADetailViewController *)navigationController.viewControllers[0];
        detailVC.albumToEdit = sentAlbum;
        detailVC.title = @"Album Info";
        detailVC.delegate = self;
        detailVC.userColor = self.userColor;
    } else if ([segue.identifier isEqualToString:@"AddAlbum"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        CJMADetailViewController *detailVC = navigationController.viewControllers[0];
        detailVC.title = @"Create Album";
        detailVC.delegate = self;
        detailVC.userColor = self.userColor;
    } else if ([segue.identifier isEqualToString:@"ViewQuickNote"]) {
        CJMPhotoAlbum *album = [[CJMAlbumManager sharedInstance] userQuickNote];
        UINavigationController *nav = segue.destinationViewController;
        CJMFullImageViewController *vc = nav.viewControllers[0];
        vc.index = 0;
        vc.albumName = album.albumTitle;
        vc.delegate = self;
        vc.isQuickNote = YES;
        vc.userColor = self.userColor;
        NSNumber *numOpac = [[NSUserDefaults standardUserDefaults] valueForKey:@"noteOpacity"];
        vc.noteOpacity = numOpac ? numOpac.floatValue : 0.75;
        //    [self.navigationController.toolbar setHidden:YES];
        [vc setViewsVisible:NO];
    } else if ([segue.identifier isEqualToString:@"ViewSettings"]) {
        //cjm quicknote
    }
}

#pragma mark - DetailVC delegate methods

- (void)albumDetailViewControllerDidCancel:(CJMADetailViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)albumDetailViewController:(CJMADetailViewController *)controller didFinishAddingAlbum:(CJMPhotoAlbum *)album {
    NSInteger newRowIndex = [[[CJMAlbumManager sharedInstance] allAlbums] count];
    
    [[CJMAlbumManager sharedInstance] addAlbum:album];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newRowIndex inSection:0];
    NSArray *indexPaths = @[indexPath];
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [[CJMAlbumManager sharedInstance] save];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)albumDetailViewController:(CJMADetailViewController *)controller didFinishEditingAlbum:(CJMPhotoAlbum *)album {
    [self.tableView reloadData];
    [[CJMAlbumManager sharedInstance] save];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Popover Delegates

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
    return UIModalPresentationNone;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self.popoverPresent = NO;
}

- (void)editTappedForIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self performSegueWithIdentifier:@"EditAlbum" sender:[self.tableView cellForRowAtIndexPath:indexPath]];
}

@end

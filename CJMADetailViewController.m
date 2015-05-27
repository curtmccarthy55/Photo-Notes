//
//  CJMADetailViewController.m
//  Unroll
//
//  Created by Curt on 4/13/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMADetailViewController.h"
#import "CJMPhotoAlbum.h"
#import "CJMAlbumManager.h"

@interface CJMADetailViewController () <UIImagePickerControllerDelegate, UITextFieldDelegate>


@end

@implementation CJMADetailViewController
{
//    NSString *_note;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //self.navigationItem.title = self.album.albumTitle;
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];

    
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
    
    if (self.albumToEdit != nil) {
        //_note = self.albumToEdit.albumNote;
        
        self.nameField.text = self.albumToEdit.albumTitle;
        self.noteField.text = self.albumToEdit.albumNote;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    [self.nameField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - NavBar Button Actions

- (void)cancelPressed
{
    [self.nameField resignFirstResponder];
    [self.noteField resignFirstResponder];
    
    [self.delegate albumDetailViewControllerDidCancel:self];
}

- (void)donePressed
{
    if (!self.albumToEdit) {
    
    NSString *name = self.nameField.text;
    NSString *note = self.noteField.text;
    
    CJMPhotoAlbum *album = [[CJMPhotoAlbum alloc] initWithName:name andNote:note];
    
    [self.delegate albumDetailViewController:self didFinishAddingAlbum:album];
    } else {
        
        self.albumToEdit.albumTitle = self.nameField.text;
        self.albumToEdit.albumNote = self.noteField.text;
        
        [self.nameField resignFirstResponder];
        [self.noteField resignFirstResponder];
        
        [self.delegate albumDetailViewController:self didFinishEditingAlbum:self.albumToEdit];
    }
}

#pragma mark - keyboard dismissal

- (void)hideKeyboard:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint point = [gestureRecognizer locationInView:self.tableView];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
    
    if (indexPath == nil) {
        return;
    }
    
    if ([self.noteField isFirstResponder]) {
        [self.noteField resignFirstResponder];
    } else {
        [self.nameField resignFirstResponder];
    }
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.noteField becomeFirstResponder];
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

@end

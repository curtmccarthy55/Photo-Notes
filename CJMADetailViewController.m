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
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
    if (self.albumToEdit == nil) {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(donePressed)];
        
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    } else if (self.albumToEdit != nil) {
        
        self.nameField.text = self.albumToEdit.albumTitle;
        self.noteField.text = self.albumToEdit.albumNote;
        self.nameField.enabled = NO;
        self.noteField.editable = NO;
        
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(cancelPressed)];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit"
                                                                                  style:UIBarButtonItemStyleDone
                                                                                 target:self
                                                                                 action:@selector(donePressed)];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    if (self.albumToEdit == nil) {
    [self.nameField becomeFirstResponder];
    };
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
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
        if ([self confirmNameNonDuplicate:name]) {
            return;
        };
        NSString *note = self.noteField.text;
        CJMPhotoAlbum *album = [[CJMPhotoAlbum alloc] initWithName:name andNote:note];
        
        [self.delegate albumDetailViewController:self didFinishAddingAlbum:album];
    } else {
        if ([self.navigationItem.rightBarButtonItem.title isEqual:@"Done"]) {
            
        if ([self confirmNameNonDuplicate:self.nameField.text]) {
            return;
        };
        self.albumToEdit.albumTitle = self.nameField.text;
        self.albumToEdit.albumNote = self.noteField.text;
        
        [self.nameField resignFirstResponder];
        [self.noteField resignFirstResponder];
        
        [self.delegate albumDetailViewController:self didFinishEditingAlbum:self.albumToEdit];
        } else if ([self.navigationItem.rightBarButtonItem.title isEqual:@"Edit"]) {
            self.nameField.enabled = YES;
            self.noteField.editable = YES;
            [self.noteField becomeFirstResponder];
            self.navigationItem.rightBarButtonItem.title = @"Done";
        }
    }
}

- (BOOL)confirmNameNonDuplicate:(NSString *)name
{//prevent the user from making an album with the same name as another album
    if ([[CJMAlbumManager sharedInstance] containsAlbumNamed:name] && ![self.albumToEdit.albumTitle isEqualToString:name]) {
        UIAlertController *nameExistsAlert = [UIAlertController alertControllerWithTitle:@"Duplicate Album Name!" message:@"You have already created an album with this name." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Ok"
                                                                style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction *action) {} ];
        [nameExistsAlert addAction:dismissAction];
        [self presentViewController:nameExistsAlert animated:YES completion:nil];
        return YES;
    } else {
        return NO;
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

#pragma mark - tableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

#pragma mark - tableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        [self.nameField becomeFirstResponder];
    } else if (indexPath.section == 1) {
        [self.noteField becomeFirstResponder];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - textView delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *currentTitleText = [self.nameField.text stringByReplacingCharactersInRange:range
                                                                         withString:string];
    if ([currentTitleText length] > 0) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    return YES;
}

@end

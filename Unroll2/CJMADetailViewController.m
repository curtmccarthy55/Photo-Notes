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

@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextView *noteField;

@end

@implementation CJMADetailViewController
{
//    NSString *_note;
    //cjm SourceTree test
    
}
// override func viewDidLoad() {
- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:gestureRecognizer];
}
// override func viewWillAppear(_ animated: Bool) {
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(cancelPressed)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(donePressed)];
    if (self.albumToEdit == nil) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else if (self.albumToEdit != nil) {
        self.nameField.text = self.albumToEdit.albumTitle;
        self.noteField.text = self.albumToEdit.albumNote;
    }
    
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
    
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"AlbumListBackground"]];
    backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    [self.tableView setBackgroundView:backgroundView];
}
// override func viewDidAppear(_ animated: Bool) {
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    [self.nameField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - NavBar Button Actions
// @objc func cancelPressed() {
- (void)cancelPressed {
    [self.nameField resignFirstResponder];
    [self.noteField resignFirstResponder];
    [self.delegate albumDetailViewControllerDidCancel:self];
}
// @objc func donePressed() {
- (void)donePressed {
    if (!self.albumToEdit) {
        NSString *name = self.nameField.text;
        if ([self confirmNameNonDuplicate:name]) {
            return;
        };
        NSString *note = self.noteField.text;
        CJMPhotoAlbum *album = [[CJMPhotoAlbum alloc] initWithName:name andNote:note];
        
        [self.delegate albumDetailViewController:self didFinishAddingAlbum:album];
    } else {
//        if ([self.navigationItem.rightBarButtonItem.title isEqual:@"Done"]) {
            if ([self confirmNameNonDuplicate:self.nameField.text]) {
                return;
            };
            self.albumToEdit.albumTitle = self.nameField.text;
            self.albumToEdit.albumNote = self.noteField.text;
            
            [self.nameField resignFirstResponder];
            [self.noteField resignFirstResponder];
            
            [self.delegate albumDetailViewController:self didFinishEditingAlbum:self.albumToEdit];
//        } else if ([self.navigationItem.rightBarButtonItem.title isEqual:@"Edit"]) {
//            self.nameField.enabled = YES;
//            self.noteField.editable = YES;
//            [self.noteField becomeFirstResponder];
//            self.navigationItem.rightBarButtonItem.title = @"Done";
//        }
    }
}
// func confirmNameNonDuplicate(_ name: String) -> Bool {
- (BOOL)confirmNameNonDuplicate:(NSString *)name {//prevent the user from making an album with the same name as another album or using "Favorites"
    if ([name isEqualToString:@"Favorites"]) {
        UIAlertController *favoritesAlert = [UIAlertController alertControllerWithTitle:@"Cannot Use \"Favorites\"" message:@"The album name \"Favorites\" is reserved for when you favorite existing Photo Notes." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:@"Ok"
                                                                style:UIAlertActionStyleCancel
                                                              handler:^(UIAlertAction *action) {} ];
        [favoritesAlert addAction:dismissAction];
        [self presentViewController:favoritesAlert animated:YES completion:nil];
        return YES;
    } else if ([[CJMAlbumManager sharedInstance] containsAlbumNamed:name] && ![self.albumToEdit.albumTitle isEqualToString:name]) {
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
// @objc func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer) {
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
// func textFieldShouldReturn(_ textField: UITextField) -> Bool {
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.noteField becomeFirstResponder];
    return YES;
}

#pragma mark - tableView data source
// override func numberOfSections(in tableView: UITableView) -> Int {
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
// override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

#pragma mark - tableView delegate
// func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        [self.nameField becomeFirstResponder];
    } else if (indexPath.section == 1) {
        [self.noteField becomeFirstResponder];
    } else if (indexPath.section == 2) {
        //cjm 12/13
    }
}
// func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - textView delegate
// func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
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

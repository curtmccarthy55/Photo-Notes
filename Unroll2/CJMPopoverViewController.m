//
//  CJMViewController.m
//  Photo Notes
//
//  Created by Curtis McCarthy on 12/6/16.
//  Copyright © 2016 Bluewraith. All rights reserved.
//

#import "CJMPopoverViewController.h"

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

@interface CJMPopoverViewController ()
@property (weak, nonatomic) IBOutlet UILabel *lblName;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation CJMPopoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.lblName setText:self.name];
    if (self.note.length == 0) {
        [self.textView setText:@"No album note created."];
    } else {
        [self.textView setText:self.note];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.textView setContentOffset:CGPointZero animated:NO]; //scrollView displays top of contents
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGFloat fixedWidth = SCREEN_WIDTH * 0.75;
    CGSize newSize = [self.textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];
    CGRect newFrame = self.textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height - 10.0);
    self.textView.frame = newFrame;
    
    NSDictionary *dic = @{ NSFontAttributeName : [UIFont boldSystemFontOfSize:17.0] };
    CGFloat titleSize = [self.name boundingRectWithSize:CGSizeMake((SCREEN_WIDTH * 0.75 - 60.0), 2000) options:NSStringDrawingUsesLineFragmentOrigin attributes:dic context:nil].size.height;
    CGFloat txtViewHeight = self.textView.bounds.size.height;
    CGFloat height = titleSize + txtViewHeight + 24.0;
    
    if (height > SCREEN_WIDTH) {
        [self.textView setScrollEnabled:YES];
        self.preferredContentSize = CGSizeMake(SCREEN_WIDTH * 0.75, SCREEN_WIDTH);
    } else {
        self.preferredContentSize = CGSizeMake(SCREEN_WIDTH * 0.75, height);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnEditAction:(id)sender {
    [self.delegate editTappedForIndexPath:self.indexPath];
}

@end

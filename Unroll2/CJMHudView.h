//
//  CJMHudView.h
//  Photo Notes
//
//  Created by Curt on 6/16/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CJMHudView : UIView

+ (instancetype)hudInView:(UIView *)view withType:(NSString *)type animated:(BOOL)animated;
- (void)removeHudView:(CJMHudView *)hudView;

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *type;

@end

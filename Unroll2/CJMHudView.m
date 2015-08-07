//
//  CJMHudView.m
//  Photo Notes
//
//  Created by Curt on 6/16/15.
//  Copyright (c) 2015 Bluewraith. All rights reserved.
//

#import "CJMHudView.h"

@implementation CJMHudView

+ (instancetype)hudInView:(UIView *)view withType:(NSString *)type animated:(BOOL)animated
{
    CJMHudView *hudView = [[CJMHudView alloc] initWithFrame:view.bounds];
    hudView.type = type;
    hudView.opaque = NO;
    [view addSubview:hudView];
    view.userInteractionEnabled = NO;
    
    if ([hudView.type isEqual:@"Success"]) {
        [hudView showAnimated:animated];
    }
    
    return hudView;
}

- (void)drawRect:(CGRect)rect
{
    const CGFloat boxWidth = 96.0f;
    const CGFloat boxHeight = 96.0f;
    
    CGRect boxRect = CGRectMake(
                                roundf(self.bounds.size.width - boxWidth) / 2.0f,
                                roundf(self.bounds.size.height - boxHeight) / 2.0f,
                                boxWidth,
                                boxHeight);
    
    UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:boxRect
                                                           cornerRadius:10.0f];
    
    [[UIColor colorWithWhite:0.3f alpha:0.8f] setFill];
    [roundedRect fill];
    
    if ([self.type isEqual:@"Success"]) {
    UIImage *image = [UIImage imageNamed:@"Checkmark"];
    
    CGPoint imagePoint = CGPointMake(
                                     self.center.x - roundf(image.size.width / 2.0f),
                                     self.center.y - roundf(image.size.height / 2.0f)
                                                                  - boxHeight / 8.0f);
    
    [image drawAtPoint:imagePoint];
    } else if ([self.type isEqual:@"Pending"]) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] init];
        
        activityIndicator.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y - (boxHeight / 8.0f), self.bounds.size.width, self.bounds.size.height);
        
        activityIndicator.transform = CGAffineTransformMakeScale(1.5, 1.5);
        
        [self addSubview:activityIndicator];
        
        [activityIndicator startAnimating];
    }
    
    NSDictionary *attributes = @{
                                 NSFontAttributeName : [UIFont systemFontOfSize:16.0f],
                                 NSForegroundColorAttributeName : [UIColor whiteColor]
                                 };
    
    CGSize textSize = [self.text sizeWithAttributes:attributes];
    
    CGPoint textPoint = CGPointMake(
        self.center.x - roundf(textSize.width / 2.0f),
        self.center.y - roundf(textSize.height / 2.0f) + boxHeight / 4.0f);
    
    [self.text drawAtPoint:textPoint withAttributes:attributes];
}

- (void)showAnimated:(BOOL)animated
{
    if (animated) {
        self.alpha = 0.0f;
        self.transform = CGAffineTransformMakeScale(1.3f, 1.3f);
        
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 1.0f;
            self.transform = CGAffineTransformIdentity;
        }];
    }
    
    [self performSelector:@selector(removeHudView:) withObject:self afterDelay:0.7];
}

- (void)removeHudView:(CJMHudView *)hudView
{
    [UIView animateWithDuration:0.5 animations:^{
        hudView.alpha = 0.0f;
    }];
}


@end

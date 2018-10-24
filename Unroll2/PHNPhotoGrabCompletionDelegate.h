//
//  PHNPhotoGrabCompletionDelegate.h
//  Photo Notes
//
//  Created by Curtis McCarthy on 10/23/18.
//  Copyright © 2018 Bluewraith. All rights reserved.
//

@protocol PHNPhotoGrabCompletionDelegate <NSObject>

- (void)photoGrabSceneDidCancel;
- (void)photoGrabSceneDidFinishSelectingPhotos:(NSArray *)photos;

@end

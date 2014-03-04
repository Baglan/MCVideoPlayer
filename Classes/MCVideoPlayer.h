//
//  MCVideoPlayer.h
//  MCVideoPlayer
//
//  Created by Baglan on 2/23/14.
//  Copyright (c) 2014 MobileCreators. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MCVideoPlayerDelegate;

@interface MCVideoPlayer : NSObject

@property (nonatomic, assign) BOOL fullScreen;
@property (nonatomic, assign) NSInteger currentSegmentIndex;
@property (nonatomic, copy) NSString * videoGravity;

@property (nonatomic, weak) id <MCVideoPlayerDelegate> delegate;

- (void)play;
- (void)pause;
- (void)addToView:(UIView *)view;

/**
 * Segments
 */
- (void)prepareWithURL:(NSURL *)videoURL segments:(NSArray *)segments;

@end

@protocol MCVideoPlayerDelegate <NSObject>

@optional

/**
 * Playback
 */
- (void)playbackEndedForVideoPlayer:(MCVideoPlayer *)videoPlayer;
- (void)currentSegmentIndexChangedForVideoPlayer:(MCVideoPlayer *)videoPlayer;

/**
 * Device rotation
 */
- (BOOL)videoPlayer:(MCVideoPlayer *)videoPlayer shouldRotateToDeviceOrientation:(UIDeviceOrientation)orientation;
- (void)videoPlayer:(MCVideoPlayer *)videoPlayer willRotateToDeviceOrientation:(UIDeviceOrientation)orientation;
- (void)videoPlayer:(MCVideoPlayer *)videoPlayer didRotateToDeviceOrientation:(UIDeviceOrientation)orientation;

@end
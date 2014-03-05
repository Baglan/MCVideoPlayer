//
//  MCVideoPlayer.m
//  MCVideoPlayer
//
//  Created by Baglan on 2/23/14.
//  Copyright (c) 2014 MobileCreators. All rights reserved.
//

#import "MCVideoPlayer.h"
#import <AVFoundation/AVFoundation.h>

#define MCVideoPlayer_AnimationDuration 0.4
#define MCVideoPlayer_PrecisionScale    100
#define MCVideoPlayer_SeekingPrecision  0.01
#define MCVideoPlayer_CheckingPrecision 0.1

@implementation MCVideoPlayer {
    AVPlayer * _player;
    AVPlayerLayer * _playerLayer;
    UIWindow * _fullScreenWindow;
    UIView * _superView;
    NSArray * _segments;
}

- (id)init
{
    self = [super init];
    if (self) {
        _fullScreenWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _fullScreenWindow.windowLevel = UIWindowLevelStatusBar;
        // [_fullScreenWindow addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];
        _fullScreenWindow.backgroundColor = [UIColor blackColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustPlayerLayer) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playedToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)reportSegmentChange
{
    if ([self.delegate respondsToSelector:@selector(currentSegmentIndexChangedForVideoPlayer:)]) {
        [self.delegate currentSegmentIndexChangedForVideoPlayer:self];
    }
}

- (void)playedToEnd:(NSNotification *)notification
{
    if (_player.currentItem == notification.object) {
        _isPlaying = NO;
        
        if ([self.delegate respondsToSelector:@selector(playbackEndedForVideoPlayer:)]) {
            [self.delegate playbackEndedForVideoPlayer:self];
        }
        
        [_player seekToTime:CMTimeMakeWithSeconds(0, 1) completionHandler:^(BOOL finished) {
            [self reportSegmentChange];
        }];
    }
}

- (void)addToView:(UIView *)view
{
    _superView = view;
    [self adjustPlayerLayer];
}

- (void)setFullScreen:(BOOL)fullScreen
{
    _fullScreen = fullScreen;
    
    if (_fullScreen) {
        _fullScreenWindow.alpha = 0.0;
        [_fullScreenWindow makeKeyAndVisible];
        
        [UIView animateWithDuration:MCVideoPlayer_AnimationDuration animations:^{
            _fullScreenWindow.alpha = 1.0;
            [self adjustPlayerLayer];
        }];
        
    } else {
        [_superView.window makeKeyAndVisible];
        
        [UIView animateWithDuration:MCVideoPlayer_AnimationDuration animations:^{
            _fullScreenWindow.alpha = 0.0;
            [self adjustPlayerLayer];
        }];
    }

}

- (void)play
{
    _isPlaying = YES;
    [_player play];
}

- (void)pause
{
    _isPlaying = NO;
    [_player pause];
}

- (void)prepareWithURL:(NSURL *)videoURL segments:(NSArray *)segments
{
    _segments = segments;
    
    if (_player && _player.status == AVPlayerStatusFailed) {
        [_playerLayer removeFromSuperlayer];
        _playerLayer = nil;
        _player = nil;
        [_player removeTimeObserver:self];
    }
    
    if (!_player) {
        _player = [[AVPlayer alloc] init];
        _player.actionAtItemEnd = AVPlayerActionAtItemEndPause;
        
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        _playerLayer.needsDisplayOnBoundsChange = YES;
        
        [self adjustPlayerLayer];
    }
    
    [_player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:videoURL]];
    
    if (segments) {
        NSMutableArray * times = [NSMutableArray array];
        for (NSNumber * segment in segments) {
            [times addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds([segment floatValue], MCVideoPlayer_PrecisionScale)]];
        }
        
        AVPlayer * player = _player;
        MCVideoPlayer * weakSelf = self;
        [_player addBoundaryTimeObserverForTimes:times queue:dispatch_get_main_queue() usingBlock:^{
            float time = (float)player.currentTime.value / (float)player.currentTime.timescale;
            NSArray * reverseSegments = [segments reverseObjectEnumerator].allObjects;
            for (NSNumber * segment in reverseSegments) {
                float delta = fabsf(time - [segment floatValue]);
                if (delta < MCVideoPlayer_CheckingPrecision) {
                    [weakSelf reportSegmentChange];
                    break;
                }
            }
        }];
        
        [self reportSegmentChange];
    }
}

- (void)adjustPlayerLayer
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    BOOL shouldRotate = NO;
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    if (self.fullScreen) {
        /**
         * Rotate in case:
         * - videoPlayer:shouldRotateToDeviceOrientation: is not implemented (presumed YES); or
         * - videoPlayer:shouldRotateToDeviceOrientation: returned YES
         */
        
        shouldRotate = ![self.delegate respondsToSelector:@selector(videoPlayer:shouldRotateToDeviceOrientation:)] || [self.delegate videoPlayer:self shouldRotateToDeviceOrientation:deviceOrientation];
        
        if (shouldRotate) {
            switch (deviceOrientation) {
                case UIDeviceOrientationPortraitUpsideDown:
                    transform = CGAffineTransformMakeRotation(M_PI);
                    break;
                    
                case UIDeviceOrientationLandscapeLeft:
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                    break;
                    
                case UIDeviceOrientationLandscapeRight:
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                    break;
                    
                case UIDeviceOrientationPortrait:
                default:
                    break;
            }
        }
    }
    
    UIView * superView = self.fullScreen ? _fullScreenWindow : _superView;
    CALayer * superLayer = superView.layer;
    if (_playerLayer.superlayer != superLayer) {
        [_playerLayer removeFromSuperlayer];
        [superLayer addSublayer:_playerLayer];
    }
    
    if (shouldRotate && [self.delegate respondsToSelector:@selector(videoPlayer:willRotateToDeviceOrientation:)]) {
        [self.delegate videoPlayer:self willRotateToDeviceOrientation:deviceOrientation];
    }
    
    _playerLayer.transform = CATransform3DMakeAffineTransform(transform);
    _playerLayer.frame = superView.bounds;
    
    if (shouldRotate && [self.delegate respondsToSelector:@selector(videoPlayer:didRotateToDeviceOrientation:)]) {
        [self.delegate videoPlayer:self didRotateToDeviceOrientation:deviceOrientation];
    }
}

#pragma mark - Segments

- (NSInteger)currentSegmentIndex
{
    CMTime playerTime = _player.currentTime;
    float playbackTime = (float)playerTime.value / (float)playerTime.timescale;
    
    NSInteger numberOfSegmets = _segments.count;
    for (NSInteger i = numberOfSegmets - 1; i >= 0 ; i--) {
        if (playbackTime >= [_segments[i] floatValue] - MCVideoPlayer_CheckingPrecision) {
            return i;
        }
    }
    
    return NSNotFound;
}

- (void)setCurrentSegmentIndex:(NSInteger)currentSegmentIndex
{
    [_player seekToTime:CMTimeMakeWithSeconds([_segments[currentSegmentIndex] floatValue], MCVideoPlayer_PrecisionScale) toleranceBefore:CMTimeMakeWithSeconds(MCVideoPlayer_SeekingPrecision, MCVideoPlayer_PrecisionScale) toleranceAfter:CMTimeMakeWithSeconds(MCVideoPlayer_SeekingPrecision, MCVideoPlayer_PrecisionScale)];
}

#pragma mark - VideoGravity

- (void)setVideoGravity:(NSString *)videoGravity
{
    _playerLayer.videoGravity = [videoGravity copy];
}

- (NSString *)videoGravity
{
    return _playerLayer.videoGravity;
}

@end

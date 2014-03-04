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
        [_fullScreenWindow addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];
        _fullScreenWindow.backgroundColor = [UIColor blackColor];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientation:) name:UIDeviceOrientationDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playedToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    }
    return self;
}

- (void)playedToEnd:(NSNotification *)notification
{
    if (_player.currentItem == notification.object) {
        if ([self.delegate respondsToSelector:@selector(playbackEndedForVideoPlayer:)]) {
            [self.delegate playbackEndedForVideoPlayer:self];
        }
    }
}

- (void)orientation:(NSNotification *)notification
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch ([UIDevice currentDevice].orientation) {
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
    
    // [_fullScreenWindow.layer setAnchorPoint:CGPointMake(1, 1)];
    
    [UIView animateWithDuration:MCVideoPlayer_AnimationDuration delay:0 options:(UIViewAnimationOptionBeginFromCurrentState) animations:^{
        // _fullScreenWindow.transform = transform;
        // _fullScreenWindow.frame = [UIScreen mainScreen].bounds;
        
        _playerLayer.transform = CATransform3DMakeAffineTransform(transform);
    } completion:nil];
}

- (void)tap
{
    self.fullScreen = NO;
}

- (void)addToView:(UIView *)view
{
    [_playerLayer removeFromSuperlayer];
    
    _superView = view;
    _playerLayer.frame = _superView.bounds;
    [_superView.layer addSublayer:_playerLayer];
}

- (void)setFullScreen:(BOOL)fullScreen
{
    _fullScreen = fullScreen;
    if (_fullScreen) {
        
        _fullScreenWindow.alpha = 0.0;
        
        [_fullScreenWindow makeKeyAndVisible];
        [_fullScreenWindow.layer addSublayer:_playerLayer];
        
        [UIView animateWithDuration:MCVideoPlayer_AnimationDuration animations:^{
            _playerLayer.frame = _fullScreenWindow.bounds;
            _fullScreenWindow.alpha = 1.0;
        }];
        
    } else {
        [_superView.layer addSublayer:_playerLayer];
        [_superView.window makeKeyAndVisible];
        
        [UIView animateWithDuration:MCVideoPlayer_AnimationDuration animations:^{
            _playerLayer.frame = _superView.bounds;
            _fullScreenWindow.alpha = 0.0;
        }];
    }
}

- (void)play
{
    [_player play];
}

- (void)pause
{
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
        _player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        _playerLayer.needsDisplayOnBoundsChange = YES;
        
        [self adjustPlayerLayer];
    }
    
    [_player replaceCurrentItemWithPlayerItem:[AVPlayerItem playerItemWithURL:videoURL]];
    
    if (segments) {
        NSMutableArray * times = [NSMutableArray array];
        for (NSNumber * segment in segments) {
            [times addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds([segment floatValue], 1)]];
        }
        
        AVPlayer * player = _player;
        MCVideoPlayer * weakSelf = self;
        [_player addBoundaryTimeObserverForTimes:times queue:dispatch_get_main_queue() usingBlock:^{
            double time = (double)player.currentTime.value / (double)player.currentTime.timescale;
            NSArray * reverseSegments = [segments reverseObjectEnumerator].allObjects;
            for (NSNumber * segment in reverseSegments) {
                if (time >= [segment doubleValue]) {
                    weakSelf.currentSegmentIndex = [segments indexOfObject:segment];
                    break;
                }
            }
        }];
    }
}

- (void)adjustPlayerLayer
{
    if (self.fullScreen) {
        [_fullScreenWindow.layer addSublayer:_playerLayer];
    } else {
        [_superView.layer addSublayer:_playerLayer];
    }
}

#pragma mark - Segments

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

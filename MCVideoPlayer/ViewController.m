//
//  ViewController.m
//  MCVideoPlayer
//
//  Created by Baglan on 2/23/14.
//  Copyright (c) 2014 MobileCreators. All rights reserved.
//

#import "ViewController.h"
#import "MCVideoPlayer.h"
#import "MCSelectorView.h"

#define SEGMENT_TIMES   @[@0.0, @16.68, @41.91, @80.33]

@interface ViewController () <MCVideoPlayerDelegate, MCSelectorViewDataSource, MCSelectorViewDelegate>

@end

@implementation ViewController {
    __weak IBOutlet UIView *_containerView;
    MCVideoPlayer * _videoPlayer;
    __weak IBOutlet UILabel *_sampleLabel;
    __weak IBOutlet UIView *_selectorContainer;
    MCSelectorView * _timesSelector;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _videoPlayer = [[MCVideoPlayer alloc] init];
    [_videoPlayer addToView:_containerView];
    [_videoPlayer prepareWithURL:[[NSBundle mainBundle] URLForResource:@"espresso.mp4" withExtension:nil] segments:SEGMENT_TIMES];
    [_videoPlayer play];
    _videoPlayer.delegate = self;
    
    _timesSelector = [[MCSelectorView alloc] init];
    _timesSelector.dataSource = self;
    _timesSelector.delegate = self;
    [_sampleLabel.superview addSubview:_timesSelector];
    [_timesSelector present];
    
    _sampleLabel.hidden = YES;
    
    [_containerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationChanged) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)deviceOrientationChanged
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    _videoPlayer.fullScreen = deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIDeviceOrientationLandscapeRight;
}

- (void)tap
{
    if (_videoPlayer.isPlaying) {
        [_videoPlayer pause];
    } else {
        [_videoPlayer play];
    }
}

#pragma mark - MCSelectorView

- (CGRect)optionRectForSelectorView:(MCSelectorView *)view
{
    return _sampleLabel.frame;
}

- (NSArray *)optionViewsForSelectorView:(MCSelectorView *)view
{
    NSMutableArray * options = [NSMutableArray array];
    
    for (NSNumber * time in SEGMENT_TIMES) {
        UILabel * label = [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:_sampleLabel]];
        label.hidden = NO;
        label.text = [NSString stringWithFormat:@"%02d:%02d", [time intValue] / 60, [time intValue] % 60];
        [options addObject:label];
    }

    return options;
}

- (void)selectorView:(MCSelectorView *)selectorView didSelectOptionAtIndex:(NSUInteger)index
{
    if (_videoPlayer.currentSegmentIndex != index) {
        _videoPlayer.currentSegmentIndex = index;
    }
}

- (BOOL)selectorView:(MCSelectorView *)selectorView shouldSelectOptionAtIndex:(NSUInteger)index
{
    return selectorView.hasStopped;
}

#pragma mark - MCVideoPlayerDelegate

- (void)currentSegmentIndexChangedForVideoPlayer:(MCVideoPlayer *)videoPlayer
{
    if (_timesSelector.index != videoPlayer.currentSegmentIndex) {
        [_timesSelector scrollToIndex:videoPlayer.currentSegmentIndex animated:YES];
    }
    
}

@end

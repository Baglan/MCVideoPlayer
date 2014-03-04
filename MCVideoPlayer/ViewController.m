//
//  ViewController.m
//  MCVideoPlayer
//
//  Created by Baglan on 2/23/14.
//  Copyright (c) 2014 MobileCreators. All rights reserved.
//

#import "ViewController.h"
#import "MCVideoPlayer.h"

@interface ViewController () <MCVideoPlayerDelegate>

@end

@implementation ViewController {
    __weak IBOutlet UIView *_containerView;
    MCVideoPlayer * _videoPlayer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _videoPlayer = [[MCVideoPlayer alloc] init];
    [_videoPlayer addToView:_containerView];
    [_videoPlayer prepareWithURL:[[NSBundle mainBundle] URLForResource:@"espresso.mp4" withExtension:nil] segments:@[@0.0, @16.68, @41.91, @80.33]];
    [_videoPlayer play];
    
    [_containerView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];
}

- (void)tap
{
    NSLog(@"--- tap!");
    _videoPlayer.fullScreen = !_videoPlayer.fullScreen;
}

@end

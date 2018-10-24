//
//  ViewController.m
//  AVPlayerDemo
//
//  Created by Lee on 2018/10/23.
//  Copyright © 2018 Lee. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

@property (nonatomic, strong) AVPlayer *player;

@property (weak, nonatomic) IBOutlet UIView *playView;
@property (weak, nonatomic) IBOutlet UIButton *start_Pause;
@property (weak, nonatomic) IBOutlet UISlider *progressSlider;

/**
 正在拖拽
 */
@property (nonatomic, assign) BOOL isChangeValue;

@end

@implementation ViewController

- (AVPlayer *)player {
    if (nil == _player) {
        NSURL *url = [NSURL URLWithString:@"http://220.249.115.46:18080/wav/day_by_day.mp4"];
        _player = [AVPlayer playerWithURL:url];
        [self addProgressObserver];
        [self addObserverToPlayerItem:_player.currentItem];
    }
    return _player;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupUI];
    [self.player play];
}

- (void)setupUI {
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    playerLayer.frame = self.playView.bounds;
    [self.playView.layer addSublayer:playerLayer];
}

- (IBAction)startOrPauseClick:(UIButton *)sender {
    if (self.player.rate == 0) {
        [sender setTitle:@"pause" forState:UIControlStateNormal];
        [self.player play];
    } else if (self.player.rate > 0) {
        [sender setTitle:@"start" forState:UIControlStateNormal];
        [self.player pause];
    }
}

#pragma mark - 监听
- (void)addProgressObserver {
    __weak typeof(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (weakSelf.isChangeValue) {
            return;
        }
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([weakSelf.player.currentItem duration]);
        if (current) {
            [weakSelf.progressSlider setValue:(current / total) animated:YES];
        }
    }];
}

- (void)addObserverToPlayerItem:(AVPlayerItem *)playerItem {
  
    [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    AVPlayerItem *playerItem = object;
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerStatus status = [[change objectForKey:@"new"] intValue];
        NSLog(@"状态%ld", status);
        if (status == AVPlayerStatusReadyToPlay) {
        }
    } else {
        NSArray *array = playerItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;;
        NSLog(@"缓存总时长：%0.2f", totalBuffer);
    }
}

#pragma mark - 拖拽进度

- (IBAction)sliderChangeClick:(UISlider *)sender {
    
    //拖拽的时候先暂停
    BOOL isPlaying = false;
    if (self.player.rate > 0) {
        isPlaying = true;
        [self.player pause];
    }
    // 先不跟新进度
    self.isChangeValue = true;
    
    float fps = [[[self.player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] nominalFrameRate];
    CMTime time = CMTimeMakeWithSeconds(CMTimeGetSeconds(self.player.currentItem.duration) * sender.value, fps);
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        
        if (isPlaying) {
            [weakSelf.player play];
        }
        weakSelf.isChangeValue = false;
    }];
}

#pragma mark - 点击调进度
- (IBAction)handleTap:(UITapGestureRecognizer *)sender {
    
    CGPoint touchPoint = [sender locationInView:self.progressSlider];
    CGFloat value = touchPoint.x / CGRectGetWidth(self.progressSlider.bounds);
    [self.progressSlider setValue:value animated:YES];
    [self sliderChangeClick:self.progressSlider];
}

- (IBAction)changeRateClick:(UIButton *)sender {
    if (![self.player.currentItem canPlayFastForward]) {
        return;
    }
    switch (sender.tag) {
        case 100:
            self.player.rate = 1.0;
            break;
        case 125:
            self.player.rate = 1.25;
            break;
        case 150:
            self.player.rate = 1.5;
            break;
        case 200:
            self.player.rate = 2.0;
            break;
        default:
            self.player.rate = 1.0;
            break;
    }
}


-(void)dealloc {
    [self.player.currentItem removeObserver:self forKeyPath:@"status"];
    [self.player.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
}
@end

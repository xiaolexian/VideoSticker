//
//  VideoStickerViewController.m
//  VideoSticker
//
//  Created by zf on 2017/6/21.
//  Copyright © 2017年 baidu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "VideoStickerViewController.h"
#import "StickerListView.h"
#import "StickerImageView.h"

typedef void (^StickerVideoOutputCompletion)(NSURL *outputUrl, NSError *error);

#define kTempVideoFolderName @"TempVideoDir"
#define kTempVideoFileName   @"StickerTempVideo.mp4"

@interface VideoStickerViewController () <StickerListViewDelegate>

// 界面各种按钮
@property (nonatomic, strong) UIButton *closeBtn;
@property (nonatomic, strong) UIButton *stickerBtn;
@property (nonatomic, strong) UIButton *voiceBtn;
@property (nonatomic, strong) UIButton *saveBtn;

// 贴纸选取view
@property (nonatomic, strong) StickerListView *stickersListView;

// 贴纸的容器view
@property (nonatomic, strong) UIView *stickersContainerView;

// 视频原声开启标志
@property (nonatomic, assign) BOOL isVoiceOff;

// 本地原始视频URl
@property (nonatomic, strong) NSURL *srcVideoURL;
// 原始视频处理以后输出的URl
@property (nonatomic, strong) NSURL *tmpVideoOuputURL;

// 播放video的容器view
@property (nonatomic, strong) UIView *playerContainerView;
// 播放器资源的控制器
@property (nonatomic, strong) AVPlayer *player;
// 显示播放器的layer
@property (nonatomic, strong) AVPlayerLayer *playerLayer;


@end

@implementation VideoStickerViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self stopVideo];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupVideoDatas];
    [self setupUI];
}

#pragma mark - UI相关函数

- (void)setupUI
{
    self.view.backgroundColor = [UIColor blackColor];
    
    [self setupVideoUI];
    
    [self setupStickersContainerView];
    [self setupCloseBtn];
    [self setupStickerBtn];
    [self setupVoiceBtn];
    [self setupSaveBtn];
    
    // 开始播放视频
    [self replayVideo];
}

- (void)setupStickersContainerView
{
    if (self.stickersContainerView)
    {
        return;
    }
    
    UIView *stickersContainerView = [[UIView alloc] initWithFrame:self.view.bounds];
    stickersContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:stickersContainerView];
    
    self.stickersContainerView = stickersContainerView;
}

- (void)setupCloseBtn
{
    if (self.closeBtn != nil)
    {
        return;
    }
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.backgroundColor = [UIColor clearColor];
    [closeBtn setFrame:CGRectMake(10, 30, 30, 30)];
    [closeBtn setImage:[UIImage imageNamed:@"close.png"] forState:UIControlStateNormal];
    [self.view addSubview:closeBtn];
    
    [closeBtn addTarget:self action:@selector(closeViewController) forControlEvents:UIControlEventTouchUpInside];
    
    self.closeBtn = closeBtn;
}

- (void)setupStickerBtn
{
    if (self.stickerBtn != nil)
    {
        return;
    }
    
    CGFloat posX = self.view.bounds.size.width - 50;
    CGFloat posY = 30;
    
    UIButton *stickerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    stickerBtn.backgroundColor = [UIColor clearColor];
    [stickerBtn setFrame:CGRectMake(posX, posY, 30, 30)];
    [stickerBtn setImage:[UIImage imageNamed:@"sticker_1.png"] forState:UIControlStateNormal];
    [self.view addSubview:stickerBtn];
    
    [stickerBtn addTarget:self action:@selector(clickStickerButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.stickerBtn = stickerBtn;
}

- (void)setupVoiceBtn
{
    if (self.voiceBtn != nil)
    {
        return;
    }
    
    CGFloat posX = 10;
    CGFloat posY = self.view.bounds.size.height - 40;
    
    UIButton *voiceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    voiceBtn.backgroundColor = [UIColor clearColor];
    [voiceBtn setFrame:CGRectMake(posX, posY, 50, 24)];
    [voiceBtn setImage:[UIImage imageNamed:@"video_sound_on.png"] forState:UIControlStateNormal];
    [voiceBtn setImage:[UIImage imageNamed:@"video_sound_off.png"] forState:UIControlStateSelected];
    [self.view addSubview:voiceBtn];
    
    [voiceBtn addTarget:self action:@selector(clickVoiceButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.voiceBtn = voiceBtn;
}

- (void)setupSaveBtn
{
    if (self.saveBtn != nil)
    {
        return;
    }
    
    CGFloat posX = self.view.bounds.size.width - 50;
    CGFloat posY = self.view.bounds.size.height - 40;
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.backgroundColor = [UIColor clearColor];
    [saveBtn setFrame:CGRectMake(posX, posY, 30, 30)];
    [saveBtn setImage:[UIImage imageNamed:@"download.png"] forState:UIControlStateNormal];
    [self.view addSubview:saveBtn];
    
    [saveBtn addTarget:self action:@selector(clickSaveButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.saveBtn = saveBtn;
}

- (void)setupStickersListView
{
    if (self.stickersListView)
    {
        return;
    }
    
    StickerListView *stickersListView = [[StickerListView alloc] initWithFrame:self.view.bounds];
    stickersListView.hidden = YES;
    stickersListView.delegate = self;
    [self.view addSubview:stickersListView];
    
    self.stickersListView = stickersListView;
}

- (void)setupVideoUI
{
    [self setupVideoContainerView];
    
    [self setupVideoPlayer];
    [self setupVideoPlayerLayer];
}

- (void)setupVideoContainerView
{
    if (self.playerContainerView != nil)
    {
        return;
    }
    
    self.playerContainerView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.playerContainerView setContentMode:UIViewContentModeScaleAspectFill];
    [self.playerContainerView setBackgroundColor:[UIColor blackColor]];
    
    [self.view addSubview:self.playerContainerView];
}

- (void)setupVideoPlayer
{
    if (self.player != nil)
    {
        return;
    }
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:self.srcVideoURL];
    
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    
    // 接收视频播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(replayVideo)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.player.currentItem];
}

- (void)setupVideoPlayerLayer
{
    if (self.playerLayer != nil)
    {
        return;
    }
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.playerLayer.frame = self.playerContainerView.bounds;
    
    [self.playerContainerView.layer addSublayer:self.playerLayer];
}

#pragma mark - 视频路径相关

- (void)setupVideoDatas
{
    // 清空缓存视频
    [self clearTempVideoOutputDir];
    
    // 初始化视频相关路径
    [self setupVideoUrl];
    [self setupTempVideoOutputUrl];
}

// 初始化源视频路径
- (void)setupVideoUrl
{
    if (self.srcVideoURL != nil)
    {
        return;
    }
    
    NSString *videoPath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
    self.srcVideoURL = [NSURL fileURLWithPath:videoPath];
}

// 初始化贴纸和音频处理后的视频输出路径
- (void)setupTempVideoOutputUrl
{
    if (self.tmpVideoOuputURL != nil)
    {
        return;
    }
    
    NSString *tempVideoDir = [self getTempVideoOutputDirectory];
    NSString *tempVideoFullPath = [tempVideoDir stringByAppendingPathComponent: kTempVideoFileName];
    self.tmpVideoOuputURL = [NSURL fileURLWithPath:tempVideoFullPath];
}

// 获取缓存资源目录
- (NSString *)getTempVideoOutputDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *videoOutputPath = [documentsDirectory stringByAppendingFormat:@"/%@", kTempVideoFolderName];
    
    return videoOutputPath;
}

// 清空缓存目录
- (BOOL)clearTempVideoOutputDir
{
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tempVideoDir = [self getTempVideoOutputDirectory];
    
    // 文件夹不存在，创建文件夹
    if (![fileManager fileExistsAtPath:tempVideoDir])
    {
        // 新建文件夹
        [fileManager createDirectoryAtPath:tempVideoDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error)
        {
            return NO;
        }
    }
    
    // 获取文件夹内容
    NSArray *files = [fileManager contentsOfDirectoryAtPath:tempVideoDir error:&error];
    if(error)
    {
        return NO;
    }
    
    // 清空该文件夹
    for (NSString *file in files)
    {
        [fileManager removeItemAtPath:[tempVideoDir stringByAppendingPathComponent:file] error:&error];
        if(error)
        {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - 视频播放相关函数

// 重新开始播放视频
- (void)replayVideo
{
    // 播放完成后自动重新开始播放
    [self.player.currentItem seekToTime:kCMTimeZero];
    [self.player play];
}

// 停止视频播放
- (void)stopVideo
{
    [self.player pause];
}

#pragma mark - 视频声音处理相关函数

- (void)disableVoiceInVideo:(BOOL)disable
{
    if (disable)
    {
        [self.player setVolume:0.0];
    }
    else
    {
        [self.player setVolume:1.0];
    }
}

// 获取原始视频中的视频轨道的混合器，排除原始视频中的音轨
- (AVMutableComposition *)getAVMutableCompositionFromVideo:(NSURL *)srcVideoUrl excludeAudio:(BOOL)isExcludeAudio
{
    // 获取视频原始资源
    AVURLAsset *videoAsset = [AVURLAsset URLAssetWithURL:srcVideoUrl options:nil];
    
    // 获取视频混合器
    AVMutableComposition *mixComposition = [AVMutableComposition composition];
    
    // video track
    AVMutableCompositionTrack *compositionVideoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    if ([videoAsset tracksWithMediaType:AVMediaTypeVideo].count <= 0)
    {
        return nil;
    }
    
    // 从源视频中取出视频轨道，生成新的视频
    AVAssetTrack *videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    [compositionVideoTrack setPreferredTransform:videoTrack.preferredTransform];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [videoAsset duration]) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    
    // 消除声音的方法：只从源视频中取出视频轨道，生成新的视频即可
    if (isExcludeAudio == NO && [videoAsset tracksWithMediaType:AVMediaTypeAudio].count > 0)
    {
        AVMutableCompositionTrack *compositionAudioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        AVAssetTrack *audioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        
        [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
    }
    
    return mixComposition;
}

#pragma mark - 基础函数

// 显示提示框
- (void)showToastMessageAlertWithTitle:(NSString *)title andMessage:(NSString *)msg
{
    UIAlertView *toastView = [[UIAlertView alloc] initWithTitle:title message:msg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [toastView show];
}

// 保存视频至相册
- (void)saveVideoToAssetsLibrary:(NSURL *)videoUrl
{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:videoUrl])
    {
        [library writeVideoAtPathToSavedPhotosAlbum:videoUrl
                                    completionBlock:^(NSURL *assetURL, NSError *error)
         {
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (error)
                 {
                     [self showToastMessageAlertWithTitle:@"错误" andMessage:@"视频保存到相册失败!"];
                 }
                 else
                 {
                     [self showToastMessageAlertWithTitle:@"成功" andMessage:@"视频保存到相册成功!"];
                 }
                 
             });
         }];
    }
}

// 将混合后的视频输出视频到本地文件
- (void)exportVideoToPath:(NSURL *)outputUrl withAVAsset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition completionHandler:(StickerVideoOutputCompletion)handler
{
    // 有可能mix视频失败，导致回调不走，外面无响应！
    NSTimeInterval duration =  CMTimeGetSeconds([asset duration]);
    if (duration <= 0)
    {
        NSError *error = [NSError errorWithDomain:@"MixVideo" code:1000000 userInfo:nil];
        handler(nil, error);
        return;
    }
    
    // 输出前删除视频
    unlink([[outputUrl path] UTF8String]);
    
    // 输出视频
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = outputUrl;
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.videoComposition = videoComposition;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler: ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (exporter.status == AVAssetExportSessionStatusCompleted)
            {
                handler(outputUrl, nil);
            }
            else
            {
                handler(nil, [exporter error]);
            }
        });
        
    }];
}

#pragma mark - 视频贴纸处理相关

// 是否为当前视频增加了贴纸
- (BOOL)hasAddAnyStickers
{
    if (self.stickersContainerView.subviews.count > 0)
    {
        return YES;
    }
    
    return NO;
}

- (void)addOneStickerView:(UIImage *)image
{
    CGFloat posX = (self.stickersContainerView.bounds.size.width - kStickerImageViewInitWidth) / 2;
    CGFloat posY = (self.stickersContainerView.bounds.size.height - kStickerImageViewInitWidth) / 2;
    
    StickerImageView *stickerView = [[StickerImageView alloc] initWithFrame:CGRectMake(posX, posY, kStickerImageViewInitWidth, kStickerImageViewInitWidth)];
    stickerView.image = image;
    [self.stickersContainerView addSubview:stickerView];
}

- (CALayer *)getImageCALayerByStickerView:(StickerImageView *)stickerImgView videoSize:(CGSize)videoSize
{
    // 计算缩放比例
    CGSize viewSize = self.stickersContainerView.bounds.size;
    CGFloat widthFactor = videoSize.width / viewSize.width;
    CGFloat heightFactor = videoSize.height / viewSize.height;
    
    // 坐标系变换
    CGFloat imgPosX = (stickerImgView.frame.origin.x + stickerImgView.bounds.size.width/2) * widthFactor;
    CGFloat imgPosY = (viewSize.height - (stickerImgView.frame.origin.y + stickerImgView.bounds.size.height/2)) * heightFactor;
    CGFloat imgWidth = stickerImgView.bounds.size.width * widthFactor;
    CGFloat imgHeight = stickerImgView.bounds.size.height * heightFactor;
    
    CALayer *imageLayer = [CALayer layer];
    imageLayer.contents = (id)stickerImgView.image.CGImage;
    imageLayer.opacity = 1;
    imageLayer.bounds = CGRectMake(0, 0, imgWidth, imgHeight);
    
    CGAffineTransform t = stickerImgView.transform;
    
    // 进行旋转
    CGFloat radius = atan2f(t.b, t.a);
    imageLayer.transform = CATransform3DRotate(imageLayer.transform, radius, 0.0, 0.0, -1.0);
    
    // 进行缩放
    CGFloat scaleX = sqrt(t.a * t.a + t.c * t.c);
    CGFloat scaleY = sqrt(t.b * t.b + t.d * t.d);
    imageLayer.transform = CATransform3DScale(imageLayer.transform, scaleX, scaleY, 1.0f);
    
    // TODO: 坐标还有一些差距，应该是旋转角度还需要考虑进来
    CGFloat imgPosOffsetX = imgWidth * (scaleX - 1) / 2;
    CGFloat imgPosOffsetY = imgHeight * (scaleY - 1) / 2;
    imageLayer.position = CGPointMake(imgPosX + imgPosOffsetX, imgPosY - imgPosOffsetY);
    
    return imageLayer;
}

- (AVVideoCompositionCoreAnimationTool *)animationToolWithAllStickers:(CGSize)videoSize
{
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    [parentLayer addSublayer:videoLayer];
    
    CALayer *contentLayer = [CALayer layer];
    contentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    
    // 将所有贴纸添加到视频中
    for (UIView *subview in self.stickersContainerView.subviews)
    {
        if ([subview isKindOfClass:[StickerImageView class]])
        {
            StickerImageView *imgView = (StickerImageView *)subview;
            CALayer *imageLayer = [self getImageCALayerByStickerView:imgView videoSize:videoSize];
            
            [contentLayer addSublayer:imageLayer];
        }
    }
    
    // 添加文字水印
    CATextLayer *titleLayer = [CATextLayer layer];
    titleLayer.string = @"zf369";
    titleLayer.foregroundColor = [UIColor blackColor].CGColor;
    titleLayer.fontSize = 20;
    titleLayer.opacity = 0.7;
    titleLayer.shadowOpacity = 0.5;
    titleLayer.alignmentMode = kCAAlignmentCenter;
    titleLayer.frame = CGRectMake(0, 0, videoSize.width, 30);
    [contentLayer addSublayer:titleLayer];
    
    [parentLayer addSublayer:contentLayer];
    
    AVVideoCompositionCoreAnimationTool *tool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    return tool;
}

// 将所有贴纸依次放到视频中去
- (AVMutableVideoComposition *)addStickerViewsToAVMutableVideoComposition:(AVMutableComposition *)mixComposition
{
    AVMutableCompositionTrack *compositionTrackVideo = [[mixComposition tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.frameDuration = CMTimeMake(1, 30);
    CGSize videoSize = [compositionTrackVideo naturalSize];
    if (videoSize.height <= 0 || videoSize.width <= 0)
    {
        videoSize = CGSizeMake(720, 1280);
    }
    videoComposition.renderSize = videoSize;
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrackVideo];
    
    AVMutableVideoCompositionInstruction *instructionLayer = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instructionLayer.timeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration);
    instructionLayer.layerInstructions = [NSArray arrayWithObject:layerInstruction];
    
    videoComposition.instructions = [NSArray arrayWithObject:instructionLayer];
    
    // 生成所有贴纸的layer，设置成animationTool即可
    videoComposition.animationTool = [self animationToolWithAllStickers:videoSize];
    
    return videoComposition;
}

#pragma mark - StickerListViewDelegate

- (void)selectStickerImage:(UIImage *)image
{
    [self addOneStickerView:image];
}

#pragma mark - 按钮点击函数

// 点击贴纸按钮
- (void)clickStickerButton
{
    [self setupStickersListView];
    
    [self.stickersListView show];
}

// 点击声音处理按钮
- (void)clickVoiceButton
{
    if (self.isVoiceOff)
    {
        self.isVoiceOff = NO;
    }
    else
    {
        self.isVoiceOff = YES;
    }
    
    self.voiceBtn.selected = self.isVoiceOff;
    
    [self disableVoiceInVideo:self.isVoiceOff];
}

// 点击保存按钮
- (void)clickSaveButton
{
    if ([self hasAddAnyStickers] == NO && self.isVoiceOff == NO)
    {
        // 如果既没有关闭声音，也没有增加贴纸，直接导出原视频即可
        [self saveVideoToAssetsLibrary:self.srcVideoURL];
    }
    else
    {
        // 进行音频处理
        AVMutableComposition *mixComposition = [self getAVMutableCompositionFromVideo:self.srcVideoURL excludeAudio:self.isVoiceOff];
        if (mixComposition == nil)
        {
            [self showToastMessageAlertWithTitle:@"错误" andMessage:@"消除视频原声音失败!"];
            return;
        }
        
        
        AVMutableVideoComposition *videoComposition = nil;
        if ([self hasAddAnyStickers])
        {
            // 处理贴纸的情况
            videoComposition = [self addStickerViewsToAVMutableVideoComposition:mixComposition];
        }
        
        [self exportVideoToPath:self.tmpVideoOuputURL withAVAsset:mixComposition videoComposition:videoComposition completionHandler:^(NSURL *outputUrl, NSError *error) {
            if (outputUrl == nil)
            {
                [self showToastMessageAlertWithTitle:@"错误" andMessage:@"混合视频失败！"];
                return;
            }
            
            // 输出视频完成后，将视频存储到相册中去
            [self saveVideoToAssetsLibrary:outputUrl];
        }];
    }
}

// 关闭当前页面
- (void)closeViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end


//
//  StickerImageView.m
//  VideoSticker
//
//  Created by zf on 2017/6/22.
//  Copyright © 2017年 baidu. All rights reserved.
//

#import "StickerImageView.h"

@interface StickerImageView ()

@end

@implementation StickerImageView

#pragma mark - 初始化相关

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.userInteractionEnabled = YES;
        [self addAllGestureRecognizers];
    }
    
    return self;
}

#pragma mark - 手势相关

- (void)addAllGestureRecognizers
{
    // 点击手势，移动当前view到最前面
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandler)];
    [self addGestureRecognizer:tapGes];
    
    // 长按手势，从父view中移除
    UILongPressGestureRecognizer *longGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longGestureHandler)];
    [self addGestureRecognizer:longGes];
    
    // 拖动手势，移动贴纸
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesturehandler:)];
    [self addGestureRecognizer:panGes];
    
    // 旋转手势，修改贴纸的旋转角度
    UIRotationGestureRecognizer *rotateGes = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotationGesturehandler:)];
    [self addGestureRecognizer:rotateGes];
    
    // 捏合手势，放大缩小贴纸
    UIPinchGestureRecognizer *pinchGes = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesturehandler:)];
    [self addGestureRecognizer:pinchGes];
}

- (void)tapGestureHandler
{
    [self.superview bringSubviewToFront:self];
}

- (void)longGestureHandler
{
    [self removeFromSuperview];
}

- (void)panGesturehandler:(UIPanGestureRecognizer *)panGest
{
    if (panGest.state == UIGestureRecognizerStateBegan)
    {
        // 将当前贴纸放到最上面
        [self.superview bringSubviewToFront:self];
    }
    
    if (panGest.state == UIGestureRecognizerStateBegan || panGest.state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [panGest translationInView:self.superview];
        
        [self setCenter:CGPointMake(self.center.x + translation.x, self.center.y + translation.y)];
        
        // 将translation重置为0十分重要。否则translation每次都会叠加，很快你的view就会移除屏幕
        [panGest setTranslation:CGPointZero inView:self.superview];
    }
    
    CATransform3D test = self.layer.transform;
    CGAffineTransform testTransform = self.transform;
    CGRect viewFrame = self.frame;
    CGRect viewLayerFrame = self.layer.frame;
    NSLog(@"layer: test:%f", test.m11);
    NSLog(@"view: testTransform:%f", testTransform.a);
}

- (void)rotationGesturehandler:(UIRotationGestureRecognizer *)rotationGest
{
    if (rotationGest.state == UIGestureRecognizerStateBegan)
    {
        // 将当前贴纸放到最上面
        [self.superview bringSubviewToFront:self];
    }
    else if (rotationGest.state == UIGestureRecognizerStateChanged)
    {
        self.transform = CGAffineTransformRotate(self.transform, rotationGest.rotation);
        
        // 将手势的rotation设置为0，防止叠加
        rotationGest.rotation = 0;
    }
}

- (void)pinchGesturehandler:(UIPinchGestureRecognizer *)pinchGest
{
    if (pinchGest.state == UIGestureRecognizerStateBegan)
    {
        // 将当前贴纸放到最上面
        [self.superview bringSubviewToFront:self];
    }
    else if (pinchGest.state == UIGestureRecognizerStateChanged)
    {
        self.transform = CGAffineTransformScale(self.transform, pinchGest.scale, pinchGest.scale);
        
        // 将手势的rotation设置为0，防止叠加
        pinchGest.scale = 1.0f;
    }
}

@end

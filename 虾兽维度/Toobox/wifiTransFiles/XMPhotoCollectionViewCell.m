//
//  XMPhotoCollectionViewCell.m
//  虾兽维度
//
//  Created by Niki on 18/5/24.
//  Copyright © 2018年 admin. All rights reserved.
//

#import "XMPhotoCollectionViewCell.h"
#import "XMWifiTransModel.h"


@interface XMPhotoCollectionViewCell()<UIScrollViewDelegate>

@property (nonatomic, assign)  CGSize imgOriSize;     // 图片拉升适应之后的size

@end

@implementation XMPhotoCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        
        self.imgScroV = [[UIScrollView alloc] init];
        self.imgScroV.delegate = self;
//        self.imgScroV.backgroundColor = [UIColor orangeColor];
//        self.imgV.backgroundColor = [UIColor redColor];
        self.imgScroV.frame = self.bounds;
        self.imgScroV.showsHorizontalScrollIndicator = NO;
        self.imgScroV.showsVerticalScrollIndicator = NO;
        self.imgScroV.minimumZoomScale = 0.5;
        self.imgScroV.maximumZoomScale = 3.0;
        [self.contentView addSubview:self.imgScroV];
        
        self.gifPerTime = 0.08;
    }
    return self;
}


- (void)setWifiModle:(XMWifiTransModel *)wifiModle
{
    _wifiModle = wifiModle;

    //移除上一个imgV
    [self.imgV removeFromSuperview];
    UIImage *image = [UIImage imageWithContentsOfFile:wifiModle.fullPath];
    UIImageView *textimage = [[UIImageView alloc] initWithImage:image];
    
    self.imgV = [[UIImageView alloc] init];
    self.imgV.contentMode = UIViewContentModeScaleAspectFit;
    self.imgV.frame = [self setImage:textimage];
    [self.imgScroV addSubview:self.imgV];
    
    // 区分gif和静态图片
    if ([wifiModle.fullPath.pathExtension.lowercaseString isEqualToString:@"gif"]){
        self.imgV.animationImages = wifiModle.gifImageArr;

        //动画的总时长(1s播放12.5帧)
         self.imgV.animationDuration = self.gifPerTime * wifiModle.gifImageArr.count;
         self.imgV.animationRepeatCount = 0;//动画进行几次结束
        [self.imgV startAnimating];//开始动画
        // [imageView stopAnimating];//停止动画
    }else{
        self.imgV.image = image;
    }
    //设置scroll的contentsize的frame
    self.imgScroV.contentSize = self.imgV.frame.size;
    
}

//根据不同的比例设置尺寸
-(CGRect) setImage:(UIImageView *)imageView
{
    CGFloat imageX = imageView.frame.size.width;
    CGFloat imageY = imageView.frame.size.height;
    CGRect imgfram;
    CGFloat scale;
    
    BOOL flx = (XMScreenW / XMScreenH) > (imageX / imageY);
    if(flx){
        scale = XMScreenH / imageY;
        imageX = imageX * scale;
        imgfram = CGRectMake((XMScreenW - imageX) / 2, 0, imageX, XMScreenH);
    }else{
        scale = XMScreenW / imageX;
        imageY = imageY * scale;
        imgfram = CGRectMake(0, (XMScreenH - imageY) / 2, XMScreenW, imageY);
    }
    self.imgOriSize = imgfram.size;
    return imgfram;
}


/// 提供方法让外界获取计算的原始图片尺寸
- (CGSize)getImgOriginSize{
    return self.imgOriSize;
}

#pragma mark - UISCrollView的UIScrollViewDelegate

//这个方法的返回值决定了要缩放的内容(只能是UISCrollView的子控件)
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imgV;
}

//控制缩放是在中心
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    //来到这里表示,scrollView的consize已经变大,self.imgV的size也已经变大
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)?(scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    
    self.imgV.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX,scrollView.contentSize.height * 0.5 + offsetY);
}

@end

//
//  XMPhotoCollectionViewCell.h
//  虾兽维度
//
//  Created by Niki on 18/5/24.
//  Copyright © 2018年 admin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class XMWifiTransModel;

@interface XMPhotoCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) XMWifiTransModel *wifiModle;
@property (nonatomic, strong) UIScrollView *imgScroV;
@property (nonatomic, strong) UIImageView *imgV;
@property (nonatomic, assign) double gifPerTime;    // gif一帧的时间,默认12.5帧/s,即0.08s/帧


/// 提供方法让外界获取计算的原始图片尺寸
- (CGSize)getImgOriginSize;

@end

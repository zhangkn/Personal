//
//  XMSavePathUnit.h
//  虾兽维度
//
//  Created by Niki on 18/5/15.
//  Copyright © 2018年 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const XMWifiMainDirName;
extern NSString *const XMWifiGroupNameFileName;
extern NSString * const XMWifiGroupMarkZipFileName;
@interface XMSavePathUnit : NSObject

/// app的documents路径
+ (NSString *)getDocumentsPath;
/// app的tmp路径
+ (NSString *)getTmpPath;

/// web模块收藏网页的文件保存路径
+ (NSString *)getSaveWebModelArchicerPath;
/// web模块收藏网页的文件保存路径(新)
+ (NSString *)getSaveWebModelNewArchicerPath;

/// web模块浏览历史记录的文件保存路径
+ (NSString *)getWebModelHistoryUrlArchicerPath;

/// 浮窗webModle的归档文件路径
+ (NSString *)getFloatWindowWebmodelArchivePath;

/// hiweb主页路径
+ (NSString *)getHiwebHomeUrlPath;

/// wifi传输的图片缓存保存沙盒路径
+ (NSString *)getWifiImageTempDirPath;
/// wifi传输的保存沙盒路径
+ (NSString *)getWifiUploadDirPath;
/// wifi传输组名列表保存路径
+ (NSString *)getWifiGroupNameFilePath;
/// wifi传输需要压缩备份的组名列表保存路径
+ (NSString *)getWifiGroupMarkZipFilePath;

/// 主页频道文件的保存路径
+ (NSString *)getMainLeftSaveChannelPath;

/// 主页历史新闻存档路径,不同的channel的文件不一样
+ (NSString *)getMainHistoryNewsPathWithChannel:(NSString *)channel;

/// webmodule的网络下载的gif的本地缓存路径
+ (NSString *)getWebmoduleGifTempDirectory;

/// 返回一个数组,包含所有配置类文件的全路径
+ (NSArray *)getSettingFilesPaths;

@end

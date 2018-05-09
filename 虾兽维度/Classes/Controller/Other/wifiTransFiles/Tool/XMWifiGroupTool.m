//
//  XMWifiGroupTool.m
//  虾兽维度
//
//  Created by Niki on 2018/5/8.
//  Copyright © 2018年 admin. All rights reserved.
//

#import "XMWifiGroupTool.h"
#import "CommonHeader.h"
#import "XMWifiTransModel.h"

#define XMWifiGroupNameFileName @"XMWifiGroupName.wifign"
#define XMWifiGroupNameFilePath ([NSString stringWithFormat:@"%@/%@",XMWifiUploadDirPath,XMWifiGroupNameFileName])

@implementation XMWifiGroupTool

static NSString *defaultGroupName = @"默认";
static NSString *currentGroupName = @"默认";
static NSString *allFilesGroupName = @"所有";


/// 返回所有文件夹的名称
+ (NSArray *)groupNames{
    //    NSString *path = [NSString stringWithFormat:@"%@/XMWifiGroupName.wifign",XMWifiUploadDirPath];
    if([[NSFileManager defaultManager] fileExistsAtPath:XMWifiGroupNameFilePath]){
        return [NSArray arrayWithContentsOfFile:XMWifiGroupNameFilePath];
    }else{
        // 初始化默认分组
        NSArray *defaultArr = @[(defaultGroupName),@"分组1",@"分组2",@"分组3"];
        [self checkRootDirectry];
        // 先创建文件,同时"所有"不需要创建分组,先写进文件
        [self saveGroupMessageWithNewArray:@[allFilesGroupName]];
        // 在沙盒创建默认的分组
        for (NSString *name in defaultArr){
            [self creatNewWifiFilesGroupWithName:name];
        }
        return defaultArr;
    }
    return nil;
}

/// 创建一个新文件夹
+ (void)creatNewWifiFilesGroupWithName:(NSString *)name{
    NSString *newFilePath = [NSString stringWithFormat:@"%@/%@",XMWifiUploadDirPath,name];
    [self checkRootDirectry];
    // 文件名不可用则跳过
    if (![self isGroupNameEnable:name]) return;
    if ([[NSFileManager defaultManager] createDirectoryAtPath:newFilePath withIntermediateDirectories:YES attributes:nil error:nil]){
        NSMutableArray *fileArr = [NSMutableArray arrayWithArray:[self groupNames]];
        [fileArr addObject:name];
        [self saveGroupMessageWithNewArray:fileArr];
    }
}

/// 删除一个新文件夹
+ (void)deleteWifiFilesGroupWithName:(NSString *)name{
    // "默认"和"所有"文件夹不能删除
    if([name isEqualToString:defaultGroupName] || [name isEqualToString:allFilesGroupName]){
        return;
    }
    // 如果删除的文件夹是当前文件夹,则切换至默认文件夹
    if([name isEqualToString:currentGroupName]){
        [self upgradeCurrentGroupName:defaultGroupName];
    }
    NSMutableArray *arr = [NSMutableArray arrayWithContentsOfFile:XMWifiGroupNameFilePath];
    
    NSString *fullPath = [XMWifiUploadDirPath stringByAppendingPathComponent:name];
    // 删除整个文件夹目录
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]){
        [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
    }
    
    // 更新文件夹列表
    for (NSString *ele in arr){
        if ([ele isEqualToString:name]){
            [arr removeObject:ele];
            break;
        }
    }
    [self saveGroupMessageWithNewArray:arr];
}

/// 将文件夹组写进沙盒
+ (void)saveGroupMessageWithNewArray:(NSArray *)newArr{
    [newArr writeToFile:XMWifiGroupNameFilePath atomically:YES];
}

/// 更新当前文件夹
+ (void)upgradeCurrentGroupName:(NSString *)name{
    currentGroupName = name;
    NSLog(@"%s",__func__);
}

/// 获取当前文件夹根路径
+ (NSString *)getCurrentGroupPath{
    // 如果当前目录是"所有",则切换至documents文件夹
    if ([currentGroupName isEqualToString:allFilesGroupName]){
        return XMHomeDirectory;
    }else{
        return [NSString stringWithFormat:@"%@/%@",XMWifiUploadDirPath,currentGroupName];
    }
}


/// 返回默认文件夹名称
+ (NSString *)getDefaultGroupName{
    return defaultGroupName;
}

/// 返回文件夹目录下的所有文件
+ (NSMutableArray *)getCurrentGroupFiles{
    NSString *groupFullPath = [self getCurrentGroupPath];
    BOOL isAllFile = NO;
    if([currentGroupName isEqualToString:allFilesGroupName]){
        isAllFile = YES;
    }
    
    if([[NSFileManager defaultManager] fileExistsAtPath:groupFullPath]){
        NSMutableArray *fileFilterArr = [NSMutableArray array];
        NSArray *fileArr = [[NSFileManager defaultManager] subpathsAtPath:groupFullPath];
        BOOL dirFlag;
        NSDictionary *dict = @{};
        for (NSString *ele in fileArr) {
            if([ele containsString:@"DS_Store"]) continue;
            // "所有"要过滤空文件夹
            if (isAllFile){
                dirFlag = NO;
                [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/%@",groupFullPath,ele] isDirectory:&dirFlag];
                if(dirFlag ) continue;
            }
            // 转换为模型
            XMWifiTransModel *model = [[XMWifiTransModel alloc] init];
            dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithFormat:@"%@/%@",groupFullPath,ele] error:nil];
            model.fileName = ele;
            model.rootPath = groupFullPath;
            model.fullPath = [NSString stringWithFormat:@"%@/%@",groupFullPath,ele];
            model.size = dict.fileSize/1024.0/1024.0;
            [fileFilterArr addObject:model];
            
        }
        return fileFilterArr;
    }else{
        return nil;
    }
}

#pragma mark - 判断方法
/// 检查根目录是否存在
+ (void)checkRootDirectry{
    if(![[NSFileManager defaultManager] fileExistsAtPath:XMWifiUploadDirPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:XMWifiUploadDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

// 检查能否删除该文件
+ (BOOL)canDeleteFileAtPath:(NSString *)path{
    // todo  增加一个管理员权限,输入密码之类的
    return YES;
    if([path containsString:XMWifiMainDirName]){
        return YES;
    }else{
        return NO;
    }
    
}

// 检查文件名是否可用
+ (BOOL)isGroupNameEnable:(NSString *)name{
    // 关键词列表,以|隔开
    NSString *forbiStr = @"所有|关键词";
    if([forbiStr containsString:name]){
        return NO;
    }
    if (name.length > 6){
        return NO;
    }
    return YES;
}

@end

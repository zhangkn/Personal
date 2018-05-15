//
//  XMWebModelTool.m
//  虾兽维度
//
//  Created by Niki on 17/3/25.
//  Copyright © 2017年 admin. All rights reserved.
//

#import "XMWebModelTool.h"


@implementation XMWebModelTool

static NSMutableArray *_saveWebModelArr;

+ (void)initialize
{
    [super initialize];
    
    //  在这里创建一个全局变量
    _saveWebModelArr = (NSMutableArray *)[NSKeyedUnarchiver unarchiveObjectWithFile:[XMSavePathUnit getSaveWebModelArchicerPath]];
    if (!_saveWebModelArr)
    {
        _saveWebModelArr = [NSMutableArray array];
    }
}

+ (void)saveWebModel:(XMWebModel *)webModel
{
    //  将最新使用的表情插到数组的前面
    [_saveWebModelArr insertObject:webModel atIndex:0];
    //  将表情数组保存进沙盒
    [NSKeyedArchiver archiveRootObject:_saveWebModelArr toFile:[XMSavePathUnit getSaveWebModelArchicerPath]];
}

+ (void)deleteWebModelAtIndex:(NSUInteger)index
{
    //  将最新使用的表情插到数组的前面
    [_saveWebModelArr removeObjectAtIndex:index];
    //  将表情数组保存进沙盒
    [NSKeyedArchiver archiveRootObject:_saveWebModelArr toFile:[XMSavePathUnit getSaveWebModelArchicerPath]];
}

+ (NSArray *)webModels
{
    return _saveWebModelArr;
}

@end

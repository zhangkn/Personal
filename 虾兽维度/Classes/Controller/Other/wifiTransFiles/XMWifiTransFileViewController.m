//
//  XMWifiTransFileViewController.m
//  虾兽维度
//
//  Created by Niki on 18/5/6.
//  Copyright © 2018年 admin. All rights reserved.
//

#import "XMWifiTransFileViewController.h"
#import "HTTPServer.h"
#import "DDLog.h"
#import "DDTTYLogger.h"


#import "MyHTTPConnection.h"
#import "ZBTool.h"


#import "XMWifiTransModel.h"
//#import <AVFoundation/AVFoundation.h>
#import "XMFileDisplayWebViewViewController.h"
#import "MBProgressHUD+NK.h"
#import "CommonHeader.h"
#import "XMWifiLeftTableViewController.h"
#import "XMWifiGroupTool.h"

@interface XMWifiTransFileViewController ()<XMWifiLeftTableViewControllerDelegate>
@property (nonatomic, strong) HTTPServer *httpServer;
@property (nonatomic, assign)  BOOL connectFlag;

@property (nonatomic, strong) NSMutableArray *dataArr;

@property (weak, nonatomic)  UIView *toolBar;                // 批量编辑下的工具条
@property (weak, nonatomic)  UIButton *toolBarDeleBtn;       // 工具条删除按钮
@property (weak, nonatomic)  UIButton *toolBarSeleAllBtn;    // 工具条全选按钮
@property (weak, nonatomic)  UILabel *navTitleLab;           // 自定义导航栏标题

/** 强引用左侧边栏窗口 */
@property (nonatomic, strong) XMWifiLeftTableViewController *leftVC;
@property (weak, nonatomic)  UIView *leftContentView;
@property (weak, nonatomic)  UIView *cover;

@end

@implementation XMWifiTransFileViewController

- (UIView *)toolBar
{
    if (!_toolBar)
    {
        CGFloat toolH = 44;
        CGFloat margin = 10;
        UIView *toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, XMScreenH - toolH, XMScreenW, toolH)];
        toolBar.backgroundColor = [UIColor lightGrayColor];
        _toolBar = toolBar;
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:toolBar];
        // 全选/反选
        UIButton *allSelectBtn = [[UIButton alloc] initWithFrame:CGRectMake(margin, 0, toolH * 2, toolH)];
        self.toolBarSeleAllBtn = allSelectBtn;
        [toolBar addSubview:allSelectBtn];
        [allSelectBtn addTarget:self action:@selector(selectAllCell:) forControlEvents:UIControlEventTouchUpInside];
        [allSelectBtn setTitle:@"全选所有" forState:UIControlStateNormal];
        [allSelectBtn setTitle:@"取消全选" forState:UIControlStateSelected];
        [allSelectBtn setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        // 删除按钮
        UIButton *deleBtn = [[UIButton alloc] initWithFrame:CGRectMake(XMScreenW - toolH -margin, 0, toolH, toolH)];
        self.toolBarDeleBtn = deleBtn;
        [toolBar addSubview:deleBtn];
        [deleBtn addTarget:self action:@selector(deleteSelectCell:) forControlEvents:UIControlEventTouchUpInside];
        [deleBtn setTitle:@"删除" forState:UIControlStateNormal];
        [deleBtn setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        [deleBtn setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        deleBtn.enabled = NO;
    }
    return _toolBar;
}

- (NSMutableArray *)dataArr
{
    if (!_dataArr)
    {
        _dataArr = [NSMutableArray array];
        NSArray *array = [[NSFileManager defaultManager] subpathsAtPath:XMWifiUploadDirPath];
        NSDictionary *dict = @{};
        for (NSString *ele in array){
            XMWifiTransModel *model = [[XMWifiTransModel alloc] init];
            dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[XMWifiUploadDirPath stringByAppendingPathComponent:ele] error:nil];
            model.fileName = ele;
            model.fullPath = [XMWifiUploadDirPath stringByAppendingPathComponent:ele];
            model.size = dict.fileSize/1024.0/1024.0;
//            NSLog(@"%@---size:%.3fM",ele,dict.fileSize/1024.0/1024.0);
            [_dataArr addObject:model];
        }
    }
    return _dataArr;
}

- (UIView *)cover
{
    if (!_cover)
    {
        UIView *cover = [[UIView alloc] initWithFrame:CGRectMake(XMLeftViewTotalW, 0, XMScreenW - XMLeftViewTotalW, XMScreenH)];
        cover.backgroundColor = [UIColor clearColor];
        [self.view addSubview:cover];
        _cover = cover;
        
        // 添加手势点击和拖，触发蒙板隐藏左侧边栏
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideLeftView)];
        [cover addGestureRecognizer:tap];
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self  action:@selector(hideLeftView)];
        [cover addGestureRecognizer:pan];
        
    }
    return _cover;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.connectFlag = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    // 更新本地数据
    [self refreshDate];

    // 初始化导航栏
    [self createNav];
    
    // 添加左侧边栏
    [self addLeftVC];
    // 左侧抽屉手势
    UISwipeGestureRecognizer *swip = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showLeftView)];
    [self.view addGestureRecognizer:swip];
}



- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadFinish:) name:@"XMWifiTransfronFilesComplete" object:nil];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"XMWifiTransfronFilesComplete" object:nil];
}

 - (void)refreshDate{
     [_dataArr removeAllObjects];
     NSArray *array = [[NSFileManager defaultManager] subpathsAtPath:XMWifiUploadDirPath];
     NSDictionary *dict = @{};
     for (NSString *ele in array){
         XMWifiTransModel *model = [[XMWifiTransModel alloc] init];
         dict = [[NSFileManager defaultManager] attributesOfItemAtPath:[XMWifiUploadDirPath stringByAppendingPathComponent:ele] error:nil];
         model.fileName = ele;
         model.fullPath = [XMWifiUploadDirPath stringByAppendingPathComponent:ele];
         model.size = dict.fileSize/1024.0/1024.0;
    
         [_dataArr addObject:model];
     }
}


/// 初始化导航栏
- (void)createNav{
    CGFloat btnWH = 44;
    // 返回按钮
    UIBarButtonItem *backBtn = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(dismissCurrentViewController)];
    // 编辑模式
    UIBarButtonItem *editBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(setEditMode)];
    self.navigationItem.leftBarButtonItems = @[backBtn,editBtn];
    // 右边为打开wifi的按钮 wifiopen
    UIButton *wifiBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, btnWH, btnWH)];
    [wifiBtn setImage:[UIImage imageNamed:@"wifiopen"] forState:UIControlStateSelected];
    [wifiBtn setImage:[UIImage imageNamed:@"wificlose"] forState:UIControlStateNormal];
    [wifiBtn addTarget:self action:@selector(switchHttpServerConnect:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *wifiBarBtn = [[UIBarButtonItem alloc] initWithCustomView:wifiBtn];
    UIBarButtonItem *ipBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(showIP)];
    self.navigationItem.rightBarButtonItems = @[wifiBarBtn,ipBtn];
    
    // 设置标题
    UILabel *titleLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    self.navTitleLab = titleLab;
    titleLab.font = [UIFont systemFontOfSize:17];
    titleLab.textColor = [UIColor blackColor];
    titleLab.textAlignment = NSTextAlignmentCenter;
    titleLab.text = @"Wifi-ON";
    // 添加刷新手势
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(navTitleViewDidDoubleTap)];
    doubleTap.numberOfTapsRequired = 2;
    [titleLab addGestureRecognizer:doubleTap];
    self.navigationItem.titleView = titleLab;
    self.navigationItem.titleView.userInteractionEnabled = YES;
    
}
#pragma mark - 导航栏/toolbar及点击事件
#pragma mark 导航栏
/// 打开/关闭一个http服务
- (void)switchHttpServerConnect:(UIButton *)wifiBtn{
    wifiBtn.selected = !wifiBtn.selected;
    if (self.connectFlag){
        // 关闭http服务
        [self.httpServer stop];
        self.navTitleLab.text = @"Wifi-OFF";
        self.connectFlag = NO;
        [MBProgressHUD showMessage:@"Wifi传输已关闭" toView:self.view];
        return;
    }
    // Configure our logging framework.
    // To keep things simple and fast, we're just going to log to the Xcode console.
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    
    self.httpServer = [[HTTPServer alloc] init];
    
    // Tell the server to broadcast its presence via Bonjour.
    // This allows browsers such as Safari to automatically discover our service.
    [self.httpServer setType:@"_http._tcp."];
    
    // 指定端口号(用于测试),实际由系统随机分配即可
    [self.httpServer setPort:50914];
    
    // 设置index.html的路径
    NSString *webPath = [[NSBundle mainBundle] resourcePath];
    NSLog(@"设置根目录: %@", webPath);
    [self.httpServer setDocumentRoot:webPath];
    [self.httpServer setConnectionClass:[MyHTTPConnection class]];
    
    NSError *error = nil;
    if(![self.httpServer start:&error])
    {
        //        DDLogError(@"Error starting HTTP Server: %@", error);
        NSLog(@"打开HTTP服务失败: %@", error);
        [MBProgressHUD showMessage:@"打开HTTP服务失败" toView:self.view];
    }else{
        NSLog(@"打开HTTP服务成功");
        self.navTitleLab.text = @"Wifi-ON";
        self.connectFlag = YES;
        // 获得本机IP和端口号
        [self showIP];
    }


}

/// 弹出ip信息
- (void)showIP{
    if(self.connectFlag){
        // 获得本机IP和端口号
        unsigned short port = [self.httpServer listeningPort];
        NSString *ip = [NSString stringWithFormat:@"http://%@:%hu",[ZBTool getIPAddress:YES],port];
        [self showAlertWithTitle:@"浏览器传输网址" message:ip];
        
    }else{
        [MBProgressHUD showMessage:@"Wifi传输未打开" toView:self.view];
    }
    
}
/// 弹框
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *aleView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
        [aleView show];
    });
    
}

/// 导航栏双击刷新
- (void)navTitleViewDidDoubleTap{
    [self refreshDate];
    [self.tableView reloadData];
}

/// 创建分组文件夹
- (void)creatGroupDir{
#warning undo
    
}

/// 批量编辑模式
- (void)setEditMode{
    if (![self.tableView isEditing]){
        self.toolBar.hidden = NO;
        self.toolBarSeleAllBtn.selected = NO;
        self.toolBarDeleBtn.enabled = NO;
    }else{
        self.toolBar.hidden = YES;
    }
    [self.tableView setEditing:![self.tableView isEditing] animated:YES];
}

/// 退出模块
- (void)dismissCurrentViewController{
    dispatch_async(dispatch_get_main_queue(),^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

#pragma mark toolbar
/// 全选/取消全选所有cell
- (void)selectAllCell:(UIButton *)btn{
    btn.selected = !btn.selected;
    if (btn.selected){
        // 全选状态
        if (self.dataArr.count == 0) return;
        for (NSInteger i = 0; i < self.dataArr.count; i++) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        }
        self.toolBarDeleBtn.enabled = YES;
    }else{
        // 取消全选状态
        NSArray *seleArr = [self.tableView indexPathsForSelectedRows];
        for (NSIndexPath *indexPath in seleArr){
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        self.toolBarDeleBtn.enabled = NO;
    }
}

/// 数组降序,即arr[0]的数值最大
- (NSArray *)sortArray:(NSArray *)arr{
    NSComparator comp = ^(NSIndexPath *obj1,NSIndexPath *obj2){
        if (obj1.row > obj2.row){
            return (NSComparisonResult)NSOrderedAscending;
        }
        if (obj1.row < obj2.row){
            return (NSComparisonResult)NSOrderedDescending;
        }
        return (NSComparisonResult)NSOrderedSame;
    };
    return [arr sortedArrayUsingComparator:comp];
}

/// 删除所选的cell
- (void)deleteSelectCell:(UIButton *)btn{
    btn.enabled = NO;
    NSArray *seleArr = [self.tableView indexPathsForSelectedRows];
    // 先对数组进行降序处理,将indexPath.row最大(即最底下的数据先删除),防止序号紊乱
    NSArray *sortArr = [self sortArray:seleArr];
    if (seleArr.count > 0){
        for (NSIndexPath *indexPath in sortArr){
            [self deleteOneCellAtIndexPath:indexPath];
        }
    }
    [self.tableView setEditing:NO animated:YES];
    self.toolBar.hidden = YES;
}

/// 根据indexPath删除单个cell
- (void)deleteOneCellAtIndexPath:(NSIndexPath *)indexPath{
    if (self.dataArr.count - 1 < indexPath.row){
        return;
    }
    XMWifiTransModel *model = self.dataArr[indexPath.row];
    NSError *error;
    BOOL succesFlag = [[NSFileManager defaultManager] removeItemAtPath:model.fullPath error:&error];
    if(succesFlag){
        [self.dataArr removeObjectAtIndex:indexPath.row];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
    }else{
        
        [MBProgressHUD showMessage:[NSString stringWithFormat:@"删除失败__>%@",error] toView:self.view];
        
    }
}

#pragma mark 左侧栏
/**  添加左侧边栏*/
-(void)addLeftVC
{
    // 创建左侧边栏容器
    UIView *leftContentView = [[UIView alloc] initWithFrame:CGRectMake(-XMLeftViewTotalW, 0, XMLeftViewTotalW, XMScreenH)];
    leftContentView.backgroundColor = [UIColor grayColor];
    self.leftContentView = leftContentView;
    
    // 创建左侧边栏
    self.leftVC = [[XMWifiLeftTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    self.leftVC.delegate = self;
    self.leftVC.view.frame = CGRectMake(XMLeftViewPadding, 40, XMLeftViewTotalW - 2 *XMLeftViewPadding, XMScreenH - XMLeftViewPadding - 20);
    [self.leftContentView addSubview:self.leftVC.view];
    
    // 添加到导航条之上
    [self.navigationController.view insertSubview:self.leftContentView aboveSubview:self.navigationController.navigationBar];
    
    // 左侧边栏添加左划取消手势
    UISwipeGestureRecognizer *swip = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hideLeftView)];
    swip.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.leftVC.tableView addGestureRecognizer:swip];
}

/** 显示左侧边栏 */
- (void)showLeftView
{
    // 显示蒙板
    self.cover.hidden = NO;
    
    // 添加到导航栏的上面
    [self.navigationController.view insertSubview:self.cover aboveSubview:self.navigationController.navigationBar];
    // 添加到导航条之上
    [self.navigationController.view insertSubview:self.leftContentView aboveSubview:self.navigationController.navigationBar];
    
    // 设置动画弹出左侧边栏
    [UIView animateWithDuration:0.5 animations:^{
        self.leftContentView.transform = CGAffineTransformMakeTranslation(XMLeftViewTotalW, 0);
    }];
    
}

/** 隐藏左侧边栏 */
- (void)hideLeftView
{
    // 隐藏蒙板
    self.cover.hidden = YES;
    
    [UIView animateWithDuration:0.5 animations:^{
        // 恢复到最左边的位置
        self.leftContentView.transform = CGAffineTransformIdentity;
        
    }];
}

#pragma mark
-(void)leftWifiTableViewControllerDidSelectChannel:(NSIndexPath *)indexPath{
    
}

#pragma mark - 监听上传的结果
- (void)uploadFinish:(NSNotification *)noti{
    NSLog(@"%@",noti.userInfo);
    [self refreshDate];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
#pragma mark cell的初始化方法
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:ID];
    }
    
    // 添加长按重命名收税
    UILongPressGestureRecognizer *longGest = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressToEditCell:)];
    [cell.contentView addGestureRecognizer:longGest];
    
    XMWifiTransModel *model = self.dataArr[indexPath.row];
    cell.textLabel.text = model.fileName;
    if(model.size < 0.001){
        cell.detailTextLabel.text = [NSString stringWithFormat:@"文件大小:%.2f Byte",model.size * 1024.0 * 1024.0];
    }else if (model.size < 1){
        cell.detailTextLabel.text = [NSString stringWithFormat:@"文件大小:%.2fK",model.size  * 1024.0];
    }else{
        cell.detailTextLabel.text = [NSString stringWithFormat:@"文件大小:%.2fM",model.size];
    }
    return cell;
}

#pragma mark 选中与反选
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (tableView.isEditing){
        // 编辑模式下如果没有选中按钮则删除按钮不可用
        if([tableView indexPathsForSelectedRows].count ==  0){
            self.toolBarDeleBtn.enabled = NO;
            self.toolBarSeleAllBtn.selected = NO;
        }
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(tableView.isEditing){
        // 编辑模式下,启用删除按钮
        self.toolBarDeleBtn.enabled = YES;
        if ([tableView indexPathsForSelectedRows].count == self.dataArr.count){
            self.toolBarSeleAllBtn.selected = YES;
        }
        return;
    }
    
    XMWifiTransModel *model = self.dataArr[indexPath.row];
    NSString *extesionStr = [[model.fileName lowercaseString] pathExtension];
    // 不支持的格式
    if ([@"zip|rar" containsString:extesionStr]){
        [MBProgressHUD showMessage:@"尚未支持该格式" toView:self.view];
        return;
    }
    
    // 用webview去预览
    XMFileDisplayWebViewViewController *displayVC = [[XMFileDisplayWebViewViewController alloc] init];
    displayVC.view.frame = self.view.bounds;
    [displayVC loadLocalFileWithPath:model.fullPath];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController pushViewController:displayVC animated:YES];
    });
    
    
//    NSString *extesionStr = [[model.fileName lowercaseString] pathExtension];
//    if ([@"jpg|png" containsString:extesionStr]){
//    
//    }else if ([@"mp4|avi" containsString:extesionStr]){
//        NSURL *sourceMovieURL = [NSURL fileURLWithPath:model.fullPath];
//        
//        AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:sourceMovieURL options:nil];
//        
//        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
//        
//        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
//        
//        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//        
//        playerLayer.frame = self.view.layer.bounds;
//        
//        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
//        
//        [self.view.layer addSublayer:playerLayer];
//        
//        [player play];
//    }
}

#pragma mark 编辑
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete){
        [self deleteOneCellAtIndexPath:indexPath];
    }
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    return UITableViewCellEditingStyleDelete;
}

#pragma mark - cell长按编辑手势
- (void)longPressToEditCell:(UILongPressGestureRecognizer *)gest{
    if (gest.state == UIGestureRecognizerStateBegan){
        // 根据触摸点t推算indexPath
        CGPoint point = [gest locationInView:self.tableView];
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:point];
        // 提取模型,获得文件名称,后缀,然后把不带后缀的名称提取出来当做输入框的文字以便修改
        XMWifiTransModel *model = self.dataArr[indexPath.row];
        NSString *extesionStr = [[model.fileName lowercaseString] pathExtension];
        NSString *fileName = [model.fileName componentsSeparatedByString:@"."][0];
        //弹出
        UIAlertController *tips = [UIAlertController alertControllerWithTitle:@"重命名" message:@"输入新的名称(不带后缀)" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        __weak typeof(self) weakSelf = self;
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action){
            
            // 获得输入内容
            UITextField *textF = tips.textFields[0];
            
            NSString *newName = [NSString stringWithFormat:@"%@.%@",textF.text,extesionStr];
            NSString *newFullPath = [XMWifiUploadDirPath stringByAppendingPathComponent:newName];
            // 重命名,自己覆盖自己
            NSError *error;
            if ([[NSFileManager defaultManager] moveItemAtPath:model.fullPath toPath:newFullPath error:&error]){
                [weakSelf refreshDate];
                [weakSelf.tableView reloadData];
            }else{
                [MBProgressHUD showMessage:@"名称已存在" toView:weakSelf.view];
            }
            
        }];
        
        [tips addAction:cancelAction];
        [tips addAction:okAction];
        [tips addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.text = fileName;
        }];
        [self presentViewController:tips animated:YES completion:nil];
        
    }
    
}

@end

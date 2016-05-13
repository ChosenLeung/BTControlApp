//
//  BTFilesViewController.m
//  BTControlApp
//
//  Created by ChosenLeung on 15/3/22.
//  Copyright (c) 2015年 ChosenLeung. All rights reserved.
//

#import "BTFilesViewController.h"
#import "BTSocketManager.h"
#import <MBProgressHUD.h>
#import <RACEXTScope.h>

@interface BTFilesViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *files;

@property (nonatomic, strong) BTSocketManager *socketManager;
@property (nonatomic, strong) MBProgressHUD *hud;

@end

@implementation BTFilesViewController

- (instancetype)initWithFiles:(NSArray *)flies {
    if (self = [super init]) {
        _files = flies;
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.socketManager cutOffSocket];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"filesTableViewCell"];
    
    @weakify(self);
    self.socketManager = [[BTSocketManager alloc] initWithWriteDataCallBack:^(BTOperationType type, NSString *result) {
        @strongify(self);
        if (type == kBTOperationTypeSelectFile) {
//            NSString *msg = @"M24\n";
//            [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeExcuteFile stop:YES];
    
        }else if (type == kBTOperationTypeExcuteFile) {
            if ([result isEqualToString:@"ok\n"]) {
                self.hud.mode = MBProgressHUDModeText;
                self.hud.labelText = @"The 3Dprinter start printing";
                [self.hud show:YES];
                [self.hud hide:YES afterDelay:2.0];
            }
        }
    }];
    
    self.socketManager.socket.userData = SocketOfflineByUser;
    [self.socketManager cutOffSocket];
    
    self.socketManager.socket.userData = SocketOfflineByServer;
    [self.socketManager socketConnectHost];
}

- (MBProgressHUD *)hud {
    if (!_hud) {
        _hud = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:_hud];
    }
    [self.view bringSubviewToFront:_hud];
    return _hud;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"filesTableViewCell" forIndexPath:indexPath];
    cell.textLabel.text = self.files[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *fileName = self.files[indexPath.row];
    NSString *msg = [NSString stringWithFormat:@"M23 %@\n", fileName.lowercaseString];
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeSelectFile stop:NO];
    msg = @"M24\n";
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeExcuteFile stop:NO];
    self.hud.mode = MBProgressHUDModeText;
    self.hud.labelText = @"The 3Dprinter start printing";
    [self.hud show:YES];
    [self.hud hide:YES afterDelay:2.0];
}
@end

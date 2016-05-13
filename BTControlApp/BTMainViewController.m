//
//  BTMainViewController.m
//  BTControlApp
//
//  Created by ChosenLeung on 15/1/6.
//  Copyright (c) 2015年 ChosenLeung. All rights reserved.
//

#import "BTMainViewController.h"
#import "BTSocketManager.h"
#import "BTHelpViewController.h"
#import "BTFilesViewController.h"
#import <ReactiveCocoa.h>

@interface BTMainViewController()
@property (nonatomic, strong) BTSocketManager *socketManager;
@property (nonatomic, assign) BOOL fanOpen;
@property (nonatomic, assign) BOOL pause;

@property (nonatomic, weak) IBOutlet UITextField *xTextField;
@property (nonatomic, weak) IBOutlet UITextField *YTextField;
@property (nonatomic, weak) IBOutlet UITextField *ZTextField;
@property (nonatomic, weak) IBOutlet UITextField *extruderTextField;
@property (nonatomic, weak) IBOutlet UITextField *bedTextField;

@property (nonatomic, strong) NSMutableArray *files;
@end

@implementation BTMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    self.title = @"Borlee";
    
    self.fanOpen = NO;
    self.pause = NO;
    
    @weakify(self);
    self.socketManager = [[BTSocketManager alloc] initWithWriteDataCallBack:^(BTOperationType type, NSString *result) {
        @strongify(self);
        [self operation:type result:result];
    }];
    
    self.socketManager.socket.userData = SocketOfflineByUser;
    [self.socketManager cutOffSocket];
    
    self.socketManager.socket.userData = SocketOfflineByServer;
//    [self.socketManager socketConnectHost];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.socketManager socketConnectHost];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.socketManager cutOffSocket];
}

- (void)operation:(BTOperationType)type result:(NSString *)result {
    switch (type) {
        case kBTOperationTypeXMove:{
            if ([result isEqualToString:@"ok\n"]) {
                 NSString *msg = @"G92 X0\n";
                [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:type stop:YES];
            }
        }
            break;
        case kBTOperationTypeYMove:{
            if ([result isEqualToString:@"ok\n"]) {
                NSString *msg = @"G92 Y0\n";
                [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:type stop:YES];
            }
        }
            break;
            
        case kBTOperationTypeZMove:{
            if ([result isEqualToString:@"ok\n"]) {
                NSString *msg = @"G92 Z0\n";
                [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:type stop:YES];
            }
        }
            break;
            
        case kBTOperationTypeSDReadFiles: {
            NSArray *ar = [result componentsSeparatedByString:@"\n"];
            NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, ar.count-4)];
            self.files = [[ar objectsAtIndexes:set] mutableCopy];
            BTFilesViewController *vc = [[BTFilesViewController alloc] initWithFiles:self.files];
            [self.navigationController pushViewController:vc animated:YES];
            
            
        }
            break;
            
            
        default:
            break;
    }
}


// X operation
- (IBAction)MoveX:(id)sender {
    NSString *msg = [NSString stringWithFormat:@"G1 X%@F10000\n", self.xTextField.text];
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeXMove stop:NO];
}

- (IBAction)ZeroX:(id)sender {
    NSString *msg = @"G28 X\n";
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeXMove stop:YES];
}

// Y operation
- (IBAction)moveY:(id)sender {
    NSString *msg = [NSString stringWithFormat:@"G1 Y%@F10000\n", self.YTextField.text];
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeYMove stop:NO];
}

- (IBAction)zeroY:(id)sender {
    NSString *msg = @"G28 Y\n";
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeYMove stop:YES];
}

// Z operation
- (IBAction)moveZ:(id)sender {
    NSString *msg = [NSString stringWithFormat:@"G1 Z%@F10000\n", self.ZTextField.text];
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeZMove stop:NO];
}

- (IBAction)zeroZ:(id)sender {
    NSString *msg = @"G28 Z\n";
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeZMove stop:YES];
}

// extruder operation
- (IBAction)extruderHeat:(id)sender {
    NSString *msg = [NSString stringWithFormat:@"M104 S%@\n", self.extruderTextField.text];
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeEHeat stop:YES];
}

- (IBAction)extruderCool:(id)sender {
    NSString *msg = @"M104 S0\n";
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeECool stop:YES];
}

// bed operation
- (IBAction)bedHeat:(id)sender {
    NSString *msg = [NSString stringWithFormat:@"M140 S%@\n", self.bedTextField.text];
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeBHeat stop:YES];
}

- (IBAction)bedCool:(id)sender {
    NSString *msg = @"M140 S0\n";
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeBCool stop:YES];
}

//fan operation
- (IBAction)fanOperation:(UIButton *)sender {
    
    self.fanOpen = !self.fanOpen;
    
    if (self.fanOpen) {
        [sender setTitle:@"ON" forState:UIControlStateNormal];
        NSString *msg = @"M106\n";
        [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeFanOff stop:YES];
    }else {
        [sender setTitle:@"OFF" forState:UIControlStateNormal];
        NSString *msg = @"M107\n";
        [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeFanOn stop:YES];
    }
}

// emergency operation
- (IBAction)emergencyStop:(id)sender {
    NSString *msg = @"M112\n";
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeEmergemcyStop stop:YES];
}

// SD Read
- (IBAction)readFiles:(id)sender {
    NSString *msg = @"M20\n";
    [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeSDReadFiles stop:YES];
}

- (IBAction)pause:(UIButton *)sender {
    self.pause = !self.pause;
    if (self.pause) {
        [sender setTitle:@"restart" forState:UIControlStateNormal];
        NSString *msg = @"M25\n";
        [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeSDPause stop:YES];
    }else {
        [sender setTitle:@"pause" forState:UIControlStateNormal];
        NSString *msg = @"M24\n";
        [self.socketManager writeData:[msg dataUsingEncoding:NSUTF8StringEncoding] operationType:kBTOperationTypeRestart stop:YES];
    }
    
}

- (IBAction)help:(id)sender {
    [self.navigationController pushViewController:[BTHelpViewController new]
                                         animated:YES];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self.view endEditing:YES];
}

@end

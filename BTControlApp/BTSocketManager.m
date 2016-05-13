//
//  BTSocketManager.m
//  BTControlApp
//
//  Created by ChosenLeung on 15/3/9.
//  Copyright (c) 2015年 ChosenLeung. All rights reserved.
//

#import "BTSocketManager.h"
#import <ReactiveCocoa.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

static NSString *hostAddress = @"192.168.1.1";
static NSInteger hostPort = 8080;


@interface BTSocketManager()

@property (nonatomic, copy) void(^writeDataCallBack)(BTOperationType type, NSString *result);
@property (nonatomic, assign) BTOperationType operationType;
@property (nonatomic, assign) BOOL stop;

@end


@implementation BTSocketManager

//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//        _xmoveCommand = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
//            return [self xmoveSignal];
//        }];
//    }
//    return self;
//}

- (instancetype)initWithWriteDataCallBack:(void(^)(BTOperationType type, NSString *result))block {
    if (self = [super init]) {
        _writeDataCallBack = [block copy];
    }
    return self;
}

//+(BTSocketManager *) sharedInstance {
//    
//    static BTSocketManager *sharedInstace = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        sharedInstace = [[self alloc] init];
//    });
//    
//    return sharedInstace;
//}

// socket连接
-(void)socketConnectHost {
    self.socket = [[AsyncSocket alloc] initWithDelegate:self];
    
    NSError *error = nil;
    
    [self.socket connectToHost:hostAddress onPort:hostPort withTimeout:3 error:&error];
    
}

- (void)writeData:(NSData *)data operationType:(BTOperationType)type stop:(BOOL)stop{
    self.stop = stop;
    self.operationType = type;
    [self.socket writeData:data withTimeout:-1 tag:0];
}

// 连接成功回调
#pragma mark  - 连接成功回调
-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    NSLog(@"socket连接成功");
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    [self.connectTimer fire];
}

// 心跳连接
-(void)longConnectToSocket {
    
    // 根据服务器要求发送固定格式的数据，假设为指令@"longConnect"，但是一般不会是这么简单的指令
    
//    NSString *longConnect = @"longConnect";
//    NSData   *dataStream  = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
//    [self.socket writeData:dataStream withTimeout:1 tag:1];
}

// 切断socket
-(void)cutOffSocket {
    self.socket.userData = SocketOfflineByUser;
    [self.connectTimer invalidate];
    [self.socket disconnect];
}

-(void)onSocketDidDisconnect:(AsyncSocket *)sock {
    NSLog(@"sorry the connect is failure %ld",sock.userData);
    if (sock.userData == SocketOfflineByServer) {
        // 服务器掉线，重连
        [self socketConnectHost];
    }
    else if (sock.userData == SocketOfflineByUser) {
        // 如果由用户断开，不进行重连
        return;
    }
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString* result = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"%@", result);
    
    if (self.operationType == kBTOperationTypeDefault) {
        return;
    }
    
    if (self.operationType == kBTOperationTypeSDReadFiles || self.operationType == kBTOperationTypeExcuteFile) {
        if (self.writeDataCallBack) {
            self.writeDataCallBack(self.operationType, result);
            self.operationType = kBTOperationTypeDefault;
            return;
        }
    }
    if (self.writeDataCallBack && !self.stop) {
        self.writeDataCallBack(self.operationType, result);
    }
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag{
    [sock readDataWithTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didSecure:(BOOL)flag {
    NSLog(@"onSocket:%p didSecure:YES", sock);
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    NSLog(@"onSocket:%p willDisconnectWithError:%@", sock, err);
}
@end

//
//  BTSocketManager.h
//  BTControlApp
//
//  Created by ChosenLeung on 15/3/9.
//  Copyright (c) 2015年 ChosenLeung. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"

enum{
    SocketOfflineByServer,
    SocketOfflineByUser,
};

typedef NS_ENUM(NSInteger, BTOperationType){
    kBTOperationTypeXMove,
    kBTOperationTypeXHome,
    kBTOperationTypeYMove,
    kBTOperationTypeYHome,
    kBTOperationTypeZMove,
    kBTOperationTypeZHome,
    
    kBTOperationTypeEHeat,
    kBTOperationTypeECool,
    kBTOperationTypeBHeat,
    kBTOperationTypeBCool,
    
    kBTOperationTypeFanOff,
    kBTOperationTypeFanOn,
    
    kBTOperationTypeEmergemcyStop,

    kBTOperationTypeSDReadFiles,
    kBTOperationTypeSDPause,
    kBTOperationTypeRestart,
    
    kBTOperationTypeSelectFile,
    kBTOperationTypeExcuteFile,
    
    kBTOperationTypeDefault
};

@class RACCommand;

@interface BTSocketManager : NSObject<AsyncSocketDelegate>

@property (nonatomic, strong) AsyncSocket    *socket;       // socket
@property (nonatomic, strong) NSTimer        *connectTimer; // 计时器

@property (nonatomic, strong) RACCommand *xmoveCommand;
@property (nonatomic, strong) NSString *xMoveStr;

//+ (BTSocketManager *)sharedInstance;

- (instancetype)initWithWriteDataCallBack:(void(^)(BTOperationType type, NSString *result))block;

-(void)socketConnectHost;// socket连接

-(void)cutOffSocket;// 断开socket连接

- (void)writeData:(NSData *)data operationType:(BTOperationType)type stop:(BOOL)stop;

@end

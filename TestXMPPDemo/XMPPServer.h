//
//  XMPPServer.h
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-25.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMPP.h"
#import "User.h"
#import "Statics.h"
#import "XMPPRoster.h"
#import "XMPPRosterCoreDataStorage.h"
#import "XMPPReconnect.h"


//聊天室相关
typedef void(^ roomBackBlock)(id);
//登录相关
typedef void(^ loginAction) (NSDictionary *result);


//用户信息相关
@protocol chatDelegate <NSObject>

@optional
-(void)userOnline:(User *)user;
-(void)userOffline:(User *)user;
- (void)friendsArray:(NSArray *)array;//好友列表

@end

//聊天信息相关
@protocol messageDelegate <NSObject>

- (void)newMessage:(NSDictionary *)messageDic;

@end


@interface XMPPServer : NSObject
{
    roomBackBlock callBack;
    loginAction loginBack;
}

@property (nonatomic,retain)XMPPStream *xmppStream;
@property (nonatomic,retain)XMPPRoster *xmppRoster;
@property (nonatomic,retain)XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic,retain)XMPPReconnect *xmppReconnect;

@property (nonatomic,assign)id<chatDelegate>chatDelegate;
@property (nonatomic,assign)id<messageDelegate>messageDelegate;

+(id)shareInstance;

-(void)setupStream;//设置XMPPStream

-(BOOL)connect;//是否连接

-(void)disconnect;//断开连接

-(void)goOnline;//上线

-(void)goOffline;//下线

- (void)getExistRooms:(roomBackBlock)roomBack;//获取存在房间

- (void)login:(loginAction)loginBack;//登录

@end



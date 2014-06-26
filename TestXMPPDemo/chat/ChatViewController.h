//
//  ChatViewController.h
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-25.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import <UIKit/UIKit.h>

@class User;

typedef enum
{
    TOPERSON  = 0,//个人对个人
    TOGROUP //群组聊
    
}CHATSTYLE;

@interface ChatViewController : UIViewController

@property (nonatomic,retain)NSString *chatWithUser;//对话用户
@property (nonatomic,retain)User *chatUser;//对话用户
@property (nonatomic,retain)NSString *chatRoom;//群聊room

-(id)initWithChatStyle:(CHATSTYLE)style;

@end

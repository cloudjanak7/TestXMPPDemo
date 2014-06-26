//
//  ChatViewController.m
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-25.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import "ChatViewController.h"
#import "XMPPServer.h"
#import "KKMessageCell.h"
#import "CWInputView.h"

#import "XMPPRoom.h"
#import "XMPPRoomCoreDataStorage.h"

#define padding 20

@interface ChatViewController ()<messageDelegate,CWInputDelegate>
{
    //在线用户
    NSMutableArray *messages;
    XMPPServer *xmppServer;
    
    XMPPRoom *xmppRoom;
    
    CWInputView *inputBar;
    CHATSTYLE chatStyle;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ChatViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(id)initWithChatStyle:(CHATSTYLE)style
{
    self = [super init];
    if (self) {
        chatStyle = style;
    }
    return self;
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated]
;
    xmppServer.messageDelegate = nil;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    messages = [NSMutableArray array];
    
    xmppServer = [XMPPServer shareInstance];
    
    //输入框
    
    //键盘
    inputBar = [[CWInputView alloc]initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height - 44, 320, 44)];
    inputBar.delegate = self;
    inputBar.clearInputWhenSend = YES;
    inputBar.resignFirstResponderWhenSend = YES;
    
    [self.view addSubview:inputBar];
    
    if (chatStyle == TOGROUP) {
        
        self.navigationItem.title = self.chatRoom;
        
        [self initRoom];
        
    }else
    {
        self.navigationItem.title = self.chatUser.jid;
        
        xmppServer.messageDelegate = self;
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma - mark messageDelegate 消息代理 <NSObject>

- (void)newMessage:(NSDictionary *)messageDic
{
    NSLog(@"newMessage %@",messageDic);
    
    [messages addObject:messageDic];
    [self.tableView reloadData];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count - 1 inSection:0];;
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma - mark UITableView 代理

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [messages count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *identifier = @"msgCell";
    
    KKMessageCell *cell =(KKMessageCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil) {
        cell = [[KKMessageCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }
    
    NSMutableDictionary *dict = [messages objectAtIndex:indexPath.row];
    
    //发送者
    NSString *sender = [dict objectForKey:@"sender"];
    //消息
    NSString *message = [dict objectForKey:@"msg"];
    //时间
    NSString *time = [dict objectForKey:@"time"];
    
    CGSize textSize = {260.0 ,10000.0};
    CGSize size = [message sizeWithFont:[UIFont boldSystemFontOfSize:13] constrainedToSize:textSize lineBreakMode:NSLineBreakByCharWrapping];
    
    size.width +=(padding/2);
    size.height += 10;
    
    cell.messageContentView.text = message;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.userInteractionEnabled = NO;
    
    UIImage *bgImage = nil;
    
    //发送消息
    if ([sender isEqualToString:@"you"]) {
        //背景图
        bgImage = [[UIImage imageNamed:@"orange"] stretchableImageWithLeftCapWidth:20 topCapHeight:15];
        [cell.messageContentView setFrame:CGRectMake(padding, padding*2, size.width, size.height)];
        
        [cell.bgImageView setFrame:CGRectMake(cell.messageContentView.frame.origin.x - padding/2, cell.messageContentView.frame.origin.y - padding/2, size.width + padding, size.height + padding)];
    }else {
        
        bgImage = [[UIImage imageNamed:@"aqua"] stretchableImageWithLeftCapWidth:14 topCapHeight:15];
        
        [cell.messageContentView setFrame:CGRectMake(320-size.width - padding, padding*2, size.width, size.height)];
        [cell.bgImageView setFrame:CGRectMake(cell.messageContentView.frame.origin.x - padding/2, cell.messageContentView.frame.origin.y - padding/2, size.width + padding, size.height + padding)];
    }
    
    cell.messageContentView.center = cell.bgImageView.center;
    
    cell.bgImageView.image = bgImage;
    cell.senderAndTimeLabel.text = [NSString stringWithFormat:@"%@ %@", sender, time];
    
    return cell;
    
}

//每一行的高度
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSMutableDictionary *dict  = [messages objectAtIndex:indexPath.row];
    NSString *msg = [dict objectForKey:@"msg"];
    
    CGSize textSize = {260.0 , 10000.0};
    CGSize size = [msg sizeWithFont:[UIFont boldSystemFontOfSize:13] constrainedToSize:textSize lineBreakMode:UILineBreakModeCharacterWrap];
    
    size.height += padding*2 + 50;
    
    CGFloat height = size.height < 65 ? 65 : size.height;
    
    return height;
    
}

#pragma - mark CWInputDelegate

- (void)inputView:(CWInputView *)inputView sendBtn:(UIButton*)sendBtn inputText:(NSString*)text
{
    NSLog(@"text %@",text);
    
    //本地输入框中的信息
    NSString *message = inputBar.textView.text;
    
    if (message.length > 0) {
        
        [self sendMessage:message isGroup:chatStyle];
        
        [self localSendMessage:message];
    }
}

#pragma - mark XMPP发送消息

- (void)xmppSendMessage:(NSString *)messageText
{
    //XMPPFramework主要是通过KissXML来生成XML文件
    //生成<body>文档
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:messageText];
    
    //生成XML消息文档
    NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
    //消息类型
    [mes addAttributeWithName:@"type" stringValue:@"chat"];
    //发送给谁
    
    NSString *toUser = [NSString stringWithFormat:@"%@@%@",_chatWithUser,[[NSUserDefaults standardUserDefaults] stringForKey:SERVER]];
    [mes addAttributeWithName:@"to" stringValue:toUser];
    //由谁发送
    [mes addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults] stringForKey:USERID]];
    //组合
    [mes addChild:body];
    
    //发送消息
    [[xmppServer xmppStream] sendElement:mes];
}

#pragma mark - 发送消息(单聊或者私聊)

- (void)sendMessage:(NSString *)message isGroup:(BOOL)group{
    //XMPPFramework主要是通过KissXML来生成XML文件
    //生成<body>文档
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:message];
    //生成XML消息文档
    NSXMLElement *mes = [NSXMLElement elementWithName:@"message"];
    //消息类型：群聊
    
    NSString *type = (group == YES) ? @"groupchat" : @"chat";//单聊还是群聊
    [mes addAttributeWithName:@"type" stringValue:type];
    
    //发送给谁
    
    NSString *toUser = nil;
    if (_chatWithUser) {
        toUser = [NSString stringWithFormat:@"%@@%@",_chatWithUser,[[NSUserDefaults standardUserDefaults] stringForKey:SERVER]];
    }else
    {
        toUser = _chatUser.jid;
    }
    
    toUser = _chatUser.jid;
    NSString *to = (group == YES) ? self.chatRoom : toUser;
    [mes addAttributeWithName:@"to" stringValue:to];
    
    //由谁发送
    [mes addAttributeWithName:@"from" stringValue:[[NSUserDefaults standardUserDefaults] stringForKey:USERID]];
    //组合
    [mes addChild:body];
    //发送消息
    [[xmppServer xmppStream] sendElement:mes];
}


#pragma - mark 更新当前页发送信息

- (void)localSendMessage:(NSString *)message
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    
    [dictionary setObject:message forKey:@"msg"];
    [dictionary setObject:@"you" forKey:@"sender"];
    //加入发送时间
    [dictionary setObject:[Statics getCurrentTime] forKey:@"time"];
    
    [messages addObject:dictionary];
    
    //重新刷新tableView
    [self.tableView reloadData];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count - 1 inSection:0];;
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

#pragma - mark -----------群组聊天---------

//创建room

- (void)initRoom
{
    XMPPRoomCoreDataStorage *storage = [[XMPPRoomCoreDataStorage alloc]init];
    if (storage == nil) {
        storage = [[XMPPRoomCoreDataStorage alloc]init];
    }
    
    NSString *roomJid = [NSString stringWithFormat:@"%@",self.chatRoom];
    XMPPJID *jid = [XMPPJID jidWithString:roomJid];
    XMPPRoom *room = [[XMPPRoom alloc]initWithRoomStorage:storage jid:jid dispatchQueue:dispatch_get_main_queue()];
    xmppRoom = room;
    
    XMPPStream *stream = [xmppServer xmppStream];
    [xmppRoom activate:stream];
    [xmppRoom joinRoomUsingNickname:@"nickName" history:Nil];
    [xmppRoom configureRoomUsingOptions:Nil];
    [xmppRoom fetchConfigurationForm];
    [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
}

#pragma mark - XMPPRoom delegate
//创建结果
-(void)xmppRoomDidCreate:(XMPPRoom *)sender{
    NSLog(@"xmppRoomDidCreate");
}

//是否已经加入房间
-(void)xmppRoomDidJoin:(XMPPRoom *)sender{
    NSLog(@"xmppRoomDidJoin");
}

//是否已经离开
-(void)xmppRoomDidLeave:(XMPPRoom *)sender{
    NSLog(@"xmppRoomDidLeave");
}

//收到群聊消息

-(void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID{
   
    NSString *msg = [[message elementForName:@"body"] stringValue];
    NSString *from = [[message attributeForName:@"from"] stringValue];
    
    if (![[sender myNickname] isEqualToString:occupantJID.resource]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        if (msg !=nil) {
            [dict setObject:msg forKey:@"msg"];
            if (occupantJID.resource) {
                [dict setObject:occupantJID.resource forKey:@"sender"];
            }else{
                [dict setObject:from forKey:@"sender"];
            }
            
            //消息接收到的时间
            [dict setObject:[Statics getCurrentTime] forKey:@"time"];
            [messages addObject:dict];
            [self.tableView reloadData];
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:messages.count - 1 inSection:0];;
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
}

//房间人员加入
- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    
    NSLog(@"occupantDidJoin");
    NSString *jid = occupantJID.user;
    NSString *domain = occupantJID.domain;
    NSString *resource = occupantJID.resource;
    NSString *presenceType = [presence type];
    NSString *userId = [sender myRoomJID].user;
    NSString *presenceFromUser = [[presence from] user];
    
    NSLog(@"occupantDidJoin----jid=%@,domain=%@,resource=%@,当前用户:%@ ,出席用户:%@,presenceType:%@",jid,domain,resource,userId,presenceFromUser,presenceType);
    
    if (![presenceFromUser isEqualToString:userId]) {
        //对收到的用户的在线状态的判断在线状态
        
        //在线用户
        if ([presenceType isEqualToString:@"available"]) {
            NSString *buddy = [NSString stringWithFormat:@"%@@%@", presenceFromUser, @"localhost"] ;
            NSLog(@"上线 %@ buddy %@",jid,buddy);
        }
        
        //用户下线
        else if ([presenceType isEqualToString:@"unavailable"]) {
            NSLog(@"下线 %@",jid);
        }
    }
}

//房间人员离开
-(void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    NSString *jid = occupantJID.user;
    NSString *domain = occupantJID.domain;
    NSString *resource = occupantJID.resource;
    NSString *presenceType = [presence type];
    NSString *userId = [sender myRoomJID].user;
    NSString *presenceFromUser = [[presence from] user];
    NSLog(@"occupantDidLeave----jid=%@,domain=%@,resource=%@,当前用户:%@ ,出席用户:%@,presenceType:%@",jid,domain,resource,userId,presenceFromUser,presenceType);
}

//房间人员加入
-(void)xmppRoom:(XMPPRoom *)sender occupantDidUpdate:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence{
    NSString *jid = occupantJID.user;
    NSString *domain = occupantJID.domain;
    NSString *resource = occupantJID.resource;
    NSString *presenceType = [presence type];
    NSString *userId = [sender myRoomJID].user;
    NSString *presenceFromUser = [[presence from] user];
    NSLog(@"occupantDidUpdate----jid=%@,domain=%@,resource=%@,当前用户:%@ ,出席用户:%@,presenceType:%@",jid,domain,resource,userId,presenceFromUser,presenceType);
}


@end

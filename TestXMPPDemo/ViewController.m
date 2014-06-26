//
//  ViewController.m
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-25.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import "ViewController.h"
#import "XMPPServer.h"
#import "LoginViewController.h"
#import "ChatViewController.h"
#import "GroupViewController.h"
#import "XMPPRoster.h"
#import "XMPPRosterCoreDataStorage.h"

@interface ViewController ()<chatDelegate,UIActionSheetDelegate>
{
    //在线用户
    NSMutableArray *onlineUsers;
    NSString *chatUserName;
    XMPPServer *xmppServer;
}

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    onlineUsers = [NSMutableArray array];
    
    xmppServer = [XMPPServer shareInstance];
    
    xmppServer.chatDelegate = self;
    
    self.navigationItem.title =  @"好友列表";
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc]initWithTitle:@"群组" style:UIBarButtonItemStyleBordered target:self action:@selector(goToRoom)];
    self.navigationItem.rightBarButtonItem = right;
    
    UIBarButtonItem *left = [[UIBarButtonItem alloc]initWithTitle:@"好友" style:UIBarButtonItemStyleBordered target:self action:@selector(addOrQueryFriends)];
    self.navigationItem.leftBarButtonItem = left;
    
    BOOL isConnect = [xmppServer connect];
    if (!isConnect) {
        
        LoginViewController *login = [[LoginViewController alloc]init];
        [self presentViewController:login animated:NO completion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}



#pragma - mark 进入群组

- (void)goToRoom
{
    GroupViewController *group = [[GroupViewController alloc]initWithStyle:UITableViewStylePlain];
    [self.navigationController pushViewController:group animated:YES];
}

#pragma - mark chatDelegate 用户状态代理 <NSObject>

-(void)userOnline:(User *)user
{
    NSLog(@"userOnline:%@  type:%@",user.userName,user.presentType);
    
    //用户上线
    
    user.jid = [NSString stringWithFormat:@"%@@%@",user.userName,[[NSUserDefaults standardUserDefaults]objectForKey:SERVER]];
    
    [self changeOnlineState:user];
}
-(void)userOffline:(User *)user
{
    NSLog(@"userOffline %@ %@",user.userName,user.presentType);
    
    user.jid = [NSString stringWithFormat:@"%@@%@",user.userName,[[NSUserDefaults standardUserDefaults]objectForKey:SERVER]];
    [self changeOnlineState:user];
}

- (void)friendsArray:(NSArray *)array //好友列表
{
    if (array.count > 0) {
        [onlineUsers removeAllObjects];
        [onlineUsers addObjectsFromArray:array];
        
        [self.tableView reloadData];
    }
}

//改变上线状态

- (void)changeOnlineState:(User *)user
{
    for (User *aUser in onlineUsers) {
        if ([aUser.jid isEqualToString:user.jid]) {
            aUser.presentType = user.presentType;
        }
    }
    [self.tableView reloadData];
}

//用户是否已在列表

- (BOOL)isUserAdded:(User *)user
{
    for (User *aUser in onlineUsers) {
        if ([user.userName isEqualToString:aUser.userName]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark UITableViewDataSource

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return [onlineUsers count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *identifier = @"userCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    
    User *aUser = [onlineUsers objectAtIndex:[indexPath row]];
    //文本
    cell.textLabel.text = aUser.jid;
    
    NSString *sub = aUser.subscription ? aUser.subscription : @"";
    NSString *group = aUser.groupName ? aUser.groupName : @"无";
    NSString *state = aUser.presentType ? aUser.presentType : @"离线";
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"关系:%@ | 组:%@ | 状态:%@",sub,group,state];
    //标记
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

#pragma mark UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    //start a Chat
    
    User *aUser = [onlineUsers objectAtIndex:indexPath.row];
    ChatViewController *chat = [[ChatViewController alloc]init];
    chat.chatWithUser = aUser.userName;
    chat.chatUser = aUser;
    [self.navigationController pushViewController:chat animated:YES];
    
}

#pragma - mark 获取好友列表(两种方式)

//1、从xmpp自带coreData中获取好友
//2、用以下方式获取好友

-(void)queryRoster2{
    /*
     <iq type="get"
     　　from="xiaoming@example.com"
     　　to="example.com"
     　　id="1234567">
     　　<query xmlns="jabber:iq:roster"/>
     <iq />
     */
    NSLog(@"------queryRoster------");
    NSXMLElement *queryElement = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
    NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
    XMPPJID *myJID = [xmppServer xmppStream].myJID;
    [iq addAttributeWithName:@"from" stringValue:myJID.description];
    [iq addAttributeWithName:@"to" stringValue:myJID.domain];
    [iq addAttributeWithName:@"id" stringValue:@""];
    [iq addAttributeWithName:@"type" stringValue:@"get"];
    [iq addChild:queryElement];
    NSLog(@"组装后的xml:%@",iq.stringValue);
    [[xmppServer xmppStream] sendElement:iq];
    
}

#pragma - mark 获取好友列表


- (void)freindArray
{
    NSManagedObjectContext *context = [[xmppServer xmppRosterStorage] mainThreadManagedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    NSError *error ;
    NSArray *friends = [context executeFetchRequest:request error:&error];
    
    for (XMPPUserCoreDataStorageObject *object in friends) {
        
        NSString *name = [object displayName];
        if (!name) {
            name = [object nickname];
        }
        if (!name) {
            name = [object jidStr];
        }
        
        NSLog(@"aa %@",name);
    }
}

- (void)addOrQueryFriends
{
    UIActionSheet *sheet = [[UIActionSheet alloc]initWithTitle:@"好友" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:Nil otherButtonTitles:@"添加好友",@"好友列表", nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"buttonIndex : %d",buttonIndex);
    if (buttonIndex == 0) {
        
        NSLog(@"add");
        [self addNewFriend];
        
    }else if (buttonIndex == 1)
    {
        NSLog(@"query");
        [self freindArray];
    }
}

- (void)addNewFriend
{
    UIAlertView *editAlert = [[UIAlertView alloc]initWithTitle:Nil message:@"添加好友" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    editAlert.tag = 1001;
    editAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [editAlert show];
    
    UITextField *inputTF = [editAlert textFieldAtIndex:0];
    inputTF.placeholder = @"好友名称";
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        if (alertView.tag == 1001) {
            UITextField *inputTF = [alertView textFieldAtIndex:0];
            
            XMPPJID *jid = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@%@",inputTF.text,[[NSUserDefaults standardUserDefaults]objectForKey:SERVER]]];
             
            [[xmppServer xmppRoster]addUser:jid withNickname:inputTF.text];
            
            //to 仅验证
            //both 互相加好友
        }
    }
}



@end

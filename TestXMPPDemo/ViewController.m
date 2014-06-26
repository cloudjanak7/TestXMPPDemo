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

@interface ViewController ()<chatDelegate>
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
    
    UIBarButtonItem *left = [[UIBarButtonItem alloc]initWithTitle:@"好友" style:UIBarButtonItemStyleBordered target:self action:@selector(freindArray)];
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
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@ : %@",aUser.subscription,aUser.groupName,aUser.presentType];
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
//2、用一下方式获取好友

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
    
    NSLog(@"friends %@ %d",friends,friends.count);
}


@end

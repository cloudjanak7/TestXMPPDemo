//
//  GroupViewController.m
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-25.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import "GroupViewController.h"
#import "ChatViewController.h"
#import "XMPPServer.h"
#import "Room.h"
#import "XMPPRoom.h"
#import "XMPPRoomCoreDataStorage.h"

@interface GroupViewController ()
{
    NSMutableArray *groupArray;
    XMPPRoom *xmppRoom;
    XMPPRoomCoreDataStorage *roomStorage;
}

@end


@implementation GroupViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc]initWithTitle:@"新建房间" style:UIBarButtonItemStyleBordered target:self action:@selector(createNewRoom)];
    self.navigationItem.rightBarButtonItem = right;
    
    groupArray = [NSMutableArray array];
    
    //获取已存在房间
    [self getExistRooms];
    
}

#pragma - mark 获取房间列表

- (void)getExistRooms
{
    __block NSMutableArray *weakArray = groupArray;
    __block typeof(GroupViewController) *weakSelf = self;
    
    [[XMPPServer shareInstance]getExistRooms:^(id result) {
        XMPPIQ *iq = (XMPPIQ *)result;
        
        for (DDXMLElement *element in iq.children) {
            if ([element.name isEqualToString:@"query"]) {
                for (DDXMLElement *item in element.children) {
                    if ([item.name isEqualToString:@"item"]) {
                        
                        NSString *jid = [item attributeStringValueForName:@"jid"];
                        NSString *name = [item attributeStringValueForName:@"name"];
                        Room *aRoom = [[Room alloc]initWithName:name jid:jid];
                        
                        [weakArray addObject:aRoom];
                    }
                }
            }
        }
        
        [weakSelf.tableView reloadData];
        
    }];
}

#pragma - mark 创建房间

- (void)createNewRoom
{
    UIAlertView *editAlert = [[UIAlertView alloc]initWithTitle:Nil message:@"新建房间" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    editAlert.tag = 1001;
    editAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [editAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        if (alertView.tag == 1001) {
            UITextField *inputTF = [alertView textFieldAtIndex:0];
            
            [self createNewRoom:inputTF.text nickName:inputTF.text];
        }
    }
}


- (void)createNewRoom:(NSString *)roomName nickName:(NSString *)nickName
{
    NSString *server = [[NSUserDefaults standardUserDefaults]objectForKey:SERVER];
    XMPPJID *roomJID = [XMPPJID jidWithString:[NSString stringWithFormat:@"%@@conference.%@",roomName,server]];
    
    if (roomStorage == Nil) {
        roomStorage = [[XMPPRoomCoreDataStorage alloc]init];
    }
    
    xmppRoom = [[XMPPRoom alloc] initWithRoomStorage:roomStorage jid:roomJID dispatchQueue:dispatch_get_main_queue()];
    
    XMPPServer *xmppServer = [XMPPServer shareInstance];
    [xmppRoom activate:xmppServer.xmppStream];
    [xmppRoom addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppRoom joinRoomUsingNickname:nickName history:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return groupArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *cellIdntifier = @"reuseIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdntifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdntifier];
    }
    Room *room = [groupArray objectAtIndex:indexPath.row];
    
    cell.textLabel.text = room.name;
    cell.detailTextLabel.text = room.jid;
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatViewController *chat = [[ChatViewController alloc]initWithChatStyle:TOGROUP];
    Room *room = [groupArray objectAtIndex:indexPath.row];
    chat.chatRoom = room.jid;
    [self.navigationController pushViewController:chat animated:YES];
}

#pragma mark - xmpproom delegate
- (void)xmppRoomDidCreate:(XMPPRoom *)sender
{
    NSLog(@"%@",sender);
    [sender configureRoomUsingOptions:nil];
}
- (void)xmppRoom:(XMPPRoom *)sender didFetchConfigurationForm:(NSXMLElement *)configForm
{
    NSLog(@"%s",__func__);
//    [_roomVC configurateRoomWithData:configForm];
}

- (void)xmppRoom:(XMPPRoom *)sender willSendConfiguration:(XMPPIQ *)roomConfigForm
{
    NSLog(@"%@",roomConfigForm);
}

- (void)xmppRoom:(XMPPRoom *)sender didConfigure:(XMPPIQ *)iqResult
{
    NSLog(@"%@",iqResult);
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:nil message:@"seccuss" delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
    [alert show];
}
- (void)xmppRoom:(XMPPRoom *)sender didNotConfigure:(XMPPIQ *)iqResult
{
    NSLog(@"%@",iqResult);
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"failed" message:iqResult.description delegate:self cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)xmppRoomDidJoin:(XMPPRoom *)sender
{
    NSLog(@"%@",sender.description);
    
//    _roomVC.roomName = sender.roomJID.user;
//    _roomVC.xmppRoom = _xmppRoom;
//    [self.navigationController pushViewController:_roomVC animated:YES];
}
- (void)xmppRoomDidLeave:(XMPPRoom *)sender
{
    NSLog(@"%@",sender.description);
}

- (void)xmppRoomDidDestroy:(XMPPRoom *)sender
{
    NSLog(@"%@",sender.description);
}

- (void)xmppRoom:(XMPPRoom *)sender occupantDidJoin:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"jid:%@  presence ; %@",occupantJID,presence);
}
- (void)xmppRoom:(XMPPRoom *)sender occupantDidLeave:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"jid:%@  presence ; %@",occupantJID,presence);
    
}
- (void)xmppRoom:(XMPPRoom *)sender occupantDidUpdate:(XMPPJID *)occupantJID withPresence:(XMPPPresence *)presence
{
    NSLog(@"jid:%@  presence ; %@",occupantJID,presence);
    
}

/**
 * Invoked when a message is received.
 * The occupant parameter may be nil if the message came directly from the room, or from a non-occupant.
 **/
- (void)xmppRoom:(XMPPRoom *)sender didReceiveMessage:(XMPPMessage *)message fromOccupant:(XMPPJID *)occupantJID
{
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchBanList:(NSArray *)items
{
    NSLog(@"%@",items);
//    [_roomVC  listMemberWithData:items type:memberType_ban];
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchBanList:(XMPPIQ *)iqError
{
    NSLog(@"%@",iqError);
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchMembersList:(NSArray *)items
{
    NSLog(@"%@",items);
//    [_roomVC listMemberWithData:items type:memberType_members];
    
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchMembersList:(XMPPIQ *)iqError
{
    NSLog(@"%@",iqError);
    
}

- (void)xmppRoom:(XMPPRoom *)sender didFetchModeratorsList:(NSArray *)items
{
    NSLog(@"%@",items);
//    [_roomVC listMemberWithData:items type:memberType_moderators];
}
- (void)xmppRoom:(XMPPRoom *)sender didNotFetchModeratorsList:(XMPPIQ *)iqError
{
    NSLog(@"%@",iqError);
    
}

- (void)xmppRoom:(XMPPRoom *)sender didEditPrivileges:(XMPPIQ *)iqResult
{
    NSLog(@"%@",iqResult);
}
- (void)xmppRoom:(XMPPRoom *)sender didNotEditPrivileges:(XMPPIQ *)iqError
{
    NSLog(@"%@",iqError);
}

#pragma mark - XMPPRoom storage
- (BOOL)configureWithParent:(XMPPRoom *)aParent queue:(dispatch_queue_t)queue
{
    return YES;
}

/**
 * Updates and returns the occupant for the given presence element.
 * If the presence type is "available", and the occupant doesn't already exist, then one should be created.
 **/
- (void)handlePresence:(XMPPPresence *)presence room:(XMPPRoom *)room
{
    NSLog(@"%@",presence);
}

/**
 * Stores or otherwise handles the given message element.
 **/
- (void)handleIncomingMessage:(XMPPMessage *)message room:(XMPPRoom *)room
{
    NSLog(@"%@",message.XMLString);
}
- (void)handleOutgoingMessage:(XMPPMessage *)message room:(XMPPRoom *)room
{
    NSLog(@"%@",message.XMLString);
    
}

/**
 * Handles leaving the room, which generally means clearing the list of occupants.
 **/
- (void)handleDidLeaveRoom:(XMPPRoom *)room
{
    NSLog(@"%@",room);
}

@end

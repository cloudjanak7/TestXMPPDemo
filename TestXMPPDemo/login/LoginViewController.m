//
//  LoginViewController.m
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-25.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import "LoginViewController.h"
#import "Statics.h"
#import "XMPPServer.h"

@interface LoginViewController ()
{
    XMPPServer *xmppServer;
}

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    xmppServer = [XMPPServer shareInstance];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)clickToLogin:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.userName.text forKey:USERID];
    [defaults setObject:self.passWord.text forKey:PASS];
    [defaults setObject:self.server.text forKey:SERVER];
    
    [defaults setObject:[NSString stringWithFormat:@"%@@%@",self.userName.text,self.server.text] forKey:JID];
    
    [defaults synchronize];
    
    [xmppServer login:^(NSDictionary *result) {
        NSLog(@"result %@",result);
        if ([[result objectForKey:@"result"] isEqualToString:@"success"]) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }else
        {
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:Nil message:@"登录失败" delegate:Nil cancelButtonTitle:@"重新登录" otherButtonTitles:Nil, nil];
            [alert show];
        }
    }];
    
}
@end

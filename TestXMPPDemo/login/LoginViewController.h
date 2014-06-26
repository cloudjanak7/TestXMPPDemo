//
//  LoginViewController.h
//  TestXMPPDemo
//
//  Created by lichaowei on 14-6-25.
//  Copyright (c) 2014年 lcw. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextField *userName;
@property (strong, nonatomic) IBOutlet UITextField *passWord;
- (IBAction)clickToLogin:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *server;

@end

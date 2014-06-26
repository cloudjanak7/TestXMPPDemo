//
//  CWInputView.h
//  CWProject
//
//  Created by Lichaowei on 14-4-4.
//  Copyright (c) 2014年 Chaowei LI. All rights reserved.
//

/**
 *  1、 根据内容自动调整输入框frame
 *  2、 测试 emoji 表情
 */

#import <UIKit/UIKit.h>
#import "NSString+Emoji.h"

@class CWInputView;
@protocol CWInputDelegate <NSObject>

- (void)inputView:(CWInputView *)inputView sendBtn:(UIButton*)sendBtn inputText:(NSString*)text;

@end

@interface CWInputView : UIView<UITextFieldDelegate,UITextViewDelegate>
{
    CGFloat initFrameY;//最开始的frame y
    CGFloat current_FrameY;//inputView当前坐标Y
    CGFloat current_KeyBoard_Y;//当前键盘坐标Y
}

@property(assign,nonatomic)id<CWInputDelegate> delegate;
//@property(strong,nonatomic)UITextField *textField;
@property(strong,nonatomic)UITextView *textView;
@property(strong,nonatomic)UIButton *sendBtn;
@property(strong,nonatomic)UIButton *toolBtn;

//点击btn时候是否清空textfield  默认NO
@property(assign,nonatomic)BOOL clearInputWhenSend;
//点击btn时候是否隐藏键盘  默认NO
@property(assign,nonatomic)BOOL resignFirstResponderWhenSend;

//初始frame
@property(assign,nonatomic)CGRect originalFrame;

//隐藏键盘
- (BOOL)resignFirstResponder;

@end

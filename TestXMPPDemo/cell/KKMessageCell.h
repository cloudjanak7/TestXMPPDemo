//
//  KKMessageCell.h
//  XmppDemo
//

#import <UIKit/UIKit.h>

@interface KKMessageCell : UITableViewCell


@property(nonatomic, retain) UILabel *senderAndTimeLabel;
@property(nonatomic, retain) UITextView *messageContentView;
@property(nonatomic, retain) UIImageView *bgImageView;


@end

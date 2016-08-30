//
//  ViewController.m
//  @Demo
//
//  Created by chairman on 16/8/25.
//  Copyright © 2016年 LaiYoung. All rights reserved.
//

#import "ViewController.h"
#import "MMPlaceHolder/MMPlaceHolder.h"
/** 屏幕的SIZE */
#define SCREEN_SIZE [[UIScreen mainScreen] bounds].size
/** @开始位置 */
#define kStarIndex @"starIndex"
/** @结束位置 */
#define kEndIndex @"endIndex"
/** 有效 */
#define kIsValid @"isValid"
/** @的字符串 */
#define kUserName @"userName"


@interface ViewController ()
<
UITextViewDelegate
>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (weak, nonatomic) IBOutlet UITextView *textView;
/** 存放@ */
@property (nonatomic, strong) NSMutableArray *atArrays;
/** 光标位置 */
@property (nonatomic, assign) NSInteger cursorIndex;
@end

@implementation ViewController

#pragma mark - lazy loading
- (NSMutableArray *)atArrays
{
    if (!_atArrays) {
        _atArrays = [NSMutableArray new];
    }
    return _atArrays;
}


#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerNotification];
    self.textView.delegate = self;
    [self.textView showPlaceHolder];
    self.textView.font = [UIFont systemFontOfSize:17];
}

#pragma mark - registerNotification

- (void)registerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboadrWillChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

#pragma mark - Notification Action Event
- (void)keyboadrWillChangeFrameNotification:(NSNotification *)noti {
    CGFloat endY = [noti.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    self.bottomConstraint.constant = SCREEN_SIZE.height - endY;
}

#pragma mark - Btn Action Event

- (IBAction)clickedBtn:(UIButton *)sender {
    NSString *string = nil;
    switch (sender.tag) {
        case 100:
            NSLog(@"LaiYoung");
            string = @"LaiYoung";
            break;
        case 200:
            NSLog(@"中冶赛迪");
            string = @"中冶赛迪";
            break;
        case 300:
            NSLog(@"轻推");
            string = @"轻推";
            break;
        default:
            break;
    }
    [self hanleAtString:string];
}

#pragma mark - UITextViewDelegate Events

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSInteger location = textView.selectedRange.location;
    NSLog(@"location = %li",location);
    if (textView.text.length>range.location) {//删除操作
        NSLog(@"delete");
        if ([text isEqualToString:@""]) {
            /** 如果有@，处理@的index */
            NSString *deleteStr = [textView.text substringWithRange:NSMakeRange(range.location, 1)];
            /** 如果删除的是@，则整个@无效 */
            if ([deleteStr isEqualToString:@"@"]) {
                for (NSDictionary *atInfo in self.atArrays) {
                    NSInteger starIndex = [[atInfo objectForKey:kStarIndex] integerValue];
                    if (range.location == starIndex) {
                        [self.atArrays removeObject:atInfo];
                    }
                }
            }
            if (self.atArrays.count > 0) {
                [self deleteAtWithRange:range];
            }
        }
    }
    
    [self modifyHeightConstraintWithString:textView.text];
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    [self modifyHeightConstraintWithString:textView.text];
}

#pragma mark - handle @ Events
/** 处理@操作 */
- (void)hanleAtString:(NSString *)string {
    /** 获取@左边的字符串 */
    NSString *leftString = [self.textView.text substringToIndex:self.textView.selectedRange.location];
    /** 获取@右边的字符串 */
    NSString *rightString = [self.textView.text substringFromIndex:self.textView.selectedRange.location];
    NSLog(@"leftString = %@,rightString = %@",leftString,rightString);
    /** 草稿 */
    NSString *draftString = [NSString stringWithFormat:@"%@@%@ %@",leftString,string,rightString];
    NSLog(@"draft = %@",draftString);
    /** 开始位置 */
    NSInteger atStarIndex = self.textView.selectedRange.location;
    /** 计算@结束的位置，+2是因为`@`字符和空格 */
    NSInteger atEndIndex = self.textView.selectedRange.location + string.length + 2;
    [self changeAtIndexWithDeletaLength:atEndIndex - atStarIndex starIndex:atStarIndex];
    
    NSDictionary *atInfo = @{kIsValid:@YES,kUserName:string,kStarIndex:@(atStarIndex),kEndIndex:@(atEndIndex)};
    [self.atArrays addObject:atInfo];
    /** 如果添加@的位置在已有@的中间，那么原先的@作废 */
    for (NSDictionary *atInfo in self.atArrays) {
        if (![atInfo[kIsValid] boolValue]) {
            [self.atArrays removeObject:atInfo];
            break;//每次新增一个@都会检查,所以每次最多只会存在一个不合法的@
        }
    }
    [self modifyHeightConstraintWithString:draftString];
    self.textView.text = draftString;
    /** 重新定位选择的位置 */
    self.textView.selectedRange = NSMakeRange(atEndIndex, 0);
}

/** 删除@ */
- (void)deleteAtWithRange:(NSRange)range {
    /** 标记这个@的长度 */
    NSInteger atLength = 0;
    /** 标记初始光标位置 */
    _cursorIndex = range.location;
    /** 遍历所有@信息 */
    for (NSDictionary *atInfo in self.atArrays) {
        
        NSInteger endIndex = [[atInfo objectForKey:kEndIndex] integerValue];
        NSInteger startIndex = [[atInfo objectForKey:kStarIndex] integerValue];

        /** 如果当前删除的位置是某个@的最后位置，那么就删除整个@ */
        if (range.location == endIndex -1) {// -1是因为在@完之后加了一个空格
            atLength = endIndex - startIndex;
            /** 获取@左边的文本 */
            NSString *leftString = [self.textView.text substringWithRange:NSMakeRange(0, startIndex)];
            /** 获取@右边的文本 */
            NSString *rightString = [self.textView.text substringFromIndex:endIndex - 1];
            /** 删除完@文本以后，从数组中删除该@的字典 */
            [self.atArrays removeObject:atInfo];
            /** 修改这个@之后的其它@的坐标 */
            [self changeAtIndexWithDeletaLength:atLength starIndex:startIndex];
            /** 修改文本 */
            self.textView.text = [NSString stringWithFormat:@"%@%@",leftString,rightString];
            /** 删除完以后，修改光标位置 */
            range.location = startIndex;
            self.textView.selectedRange = range;
            break;
        }
    }
}

/**
 *  修改@的index和isValid
 *
 *  @param deltaLengh 文本长度
 *  @param starIndex  开始位置
 */
- (void)changeAtIndexWithDeletaLength:(NSInteger)deltaLengh starIndex:(NSInteger)starIndex {
    NSMutableArray *newAtArray = [NSMutableArray array];
    for (NSDictionary *atInfo in self.atArrays) {
        NSInteger itemStarIndex = [atInfo[kStarIndex] integerValue];
        NSInteger itemEndIndex = [atInfo[kEndIndex] integerValue];
        //* 判断新的@是否合法 */
        if (itemStarIndex >= starIndex) {//新的@在原有的@之前,有效
            NSDictionary *newAtInfo = @{kIsValid:@YES,kUserName:atInfo[kUserName],kStarIndex:@(itemStarIndex+deltaLengh),kEndIndex:@(itemEndIndex+deltaLengh)};
            [newAtArray addObject:newAtInfo];
        } else if (starIndex > itemStarIndex && starIndex < itemEndIndex) {//新的@在原有的@中间,无效
            NSDictionary *newAtInfo = @{kIsValid:@NO,kUserName:atInfo[kUserName],kStarIndex:@(itemStarIndex),kEndIndex:@(itemEndIndex + deltaLengh)};
            [newAtArray addObject:newAtInfo];
        } else {//新的@在原有的@之后,有效
            [newAtArray addObject:atInfo];
        }
    }
    [self.atArrays removeAllObjects];
    if (newAtArray.count!=0) {
        [self.atArrays addObjectsFromArray:newAtArray];
    }
}

#pragma mark - modify UI Contrain

/** 计算文本的高度 */
- (CGFloat)calculateHeightWithString:(NSString *)string {
    CGSize size = [string boundingRectWithSize:CGSizeMake(self.textView.bounds.size.width,CGFLOAT_MAX ) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:17]} context:nil].size;
    return size.height;
}
/** 修改高度约束 */
- (void)modifyHeightConstraintWithString:(NSString *)string {
   CGFloat height = [self calculateHeightWithString:string];
    /**
     +16是因为UITextView在containerView的上下边距各为8
     +(50-20.287109-16)是因为当文本为空的时候高20.287109 所以50-16-空文本的height
     公式：父容器的height-子控件距离父容器的距离(上下)-空文本的height
     */
    [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.heightConstraint.constant = height + 16 + (50-20.287109-16);
    } completion:^(BOOL finished) {
        [self.textView scrollRangeToVisible:self.textView.selectedRange];
    }];
    
}

#pragma mark - system Events

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

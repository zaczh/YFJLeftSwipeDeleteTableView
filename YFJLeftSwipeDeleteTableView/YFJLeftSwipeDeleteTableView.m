//
//  YFJLeftSwipeDeleteTableView.m
//  YFJLeftSwipeDeleteTableView
//
//  Created by Yuichi Fujiki on 6/27/13.
//  Copyright (c) 2013 Yuichi Fujiki. All rights reserved.
//  Modified by everfly on 12/09/13
//

#import "YFJLeftSwipeDeleteTableView.h"
#import <objc/runtime.h>

const static CGFloat kEditViewWidth = 128.f;
const static CGFloat kEditViewHeight = 44.0f;

#define screenWidth() (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? [[UIScreen mainScreen] bounds].size.width : [[UIScreen mainScreen] bounds].size.height)

const static char * kYFJLeftSwipeDeleteTableViewCellIndexPathKey = "YFJLeftSwipeDeleteTableViewCellIndexPathKey";

@interface UIView (NSIndexPath)

- (void)setIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPath;

@end

@implementation UIView (NSIndexPath)

- (void)setIndexPath:(NSIndexPath *)indexPath {
    objc_setAssociatedObject(self, kYFJLeftSwipeDeleteTableViewCellIndexPathKey, indexPath, OBJC_ASSOCIATION_RETAIN);
}

- (NSIndexPath *)indexPath {
    id obj = objc_getAssociatedObject(self, kYFJLeftSwipeDeleteTableViewCellIndexPathKey);
    if([obj isKindOfClass:[NSIndexPath class]]) {
        return (NSIndexPath *)obj;
    }
    return nil;
}

@end

@interface YFJLeftSwipeDeleteTableView() {
    UISwipeGestureRecognizer * _swipeGestureRecognizer;
    //    UISwipeGestureRecognizer * _leftGestureRecognizer;
    //    UISwipeGestureRecognizer * _rightGestureRecognizer;
    UITapGestureRecognizer * _tapGestureRecognizer;
    
    UIView *_editView;
    UIButton *_deleteButton;
    UIButton *_setTopButton;
    
    NSIndexPath * _editingIndexPath;
    
}

@end

@implementation YFJLeftSwipeDeleteTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:style];
    if (self) {
        _swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiped:)];
        _swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft|UISwipeGestureRecognizerDirectionRight;
        _swipeGestureRecognizer.delegate = self;
        [self addGestureRecognizer:_swipeGestureRecognizer];
        
        //i don't know why we need two gesture recognizers here. One is enough.
        //        _leftGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiped:)];
        //        _leftGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
        //        _leftGestureRecognizer.delegate = self;
        //        [self addGestureRecognizer:_leftGestureRecognizer];
        //
        //        _rightGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiped:)];
        //        _rightGestureRecognizer.delegate = self;
        //        _rightGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
        //        [self addGestureRecognizer:_rightGestureRecognizer];
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        _tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:_tapGestureRecognizer];
        
        _editView = [[UIView alloc] init];
        _editView.backgroundColor = [UIColor clearColor];
        
        _deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _deleteButton.backgroundColor = [UIColor redColor];
        _deleteButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
        [_deleteButton addTarget:self action:@selector(deleteItem:) forControlEvents:UIControlEventTouchUpInside];
        //        [self addSubview:_deleteButton];
        [_editView addSubview:_deleteButton];
        
        _setTopButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _setTopButton.backgroundColor = [UIColor lightGrayColor];
        _setTopButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_setTopButton addTarget:self action:@selector(setTopItem:) forControlEvents:UIControlEventTouchUpInside];
        [_editView addSubview:_setTopButton];
        
        _editView.frame = CGRectMake(screenWidth(), 0, kEditViewWidth, kEditViewHeight);
        [_setTopButton setTitle:@"Pin top" forState:UIControlStateNormal];
        _setTopButton.frame = CGRectMake(0, 0, 64, kEditViewHeight);
        _deleteButton.frame = CGRectMake(64, 0, 64, kEditViewHeight);
        
        [self addSubview:_editView];
        //        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)dealloc
{
#if !__has_feature(objc_arc)
    [_swipeGestureRecognizer release],_swipeGestureRecognizer = nil;
    [_tapGestureRecognizer release],_tapGestureRecognizer = nil;
    [_editView release],_editView = nil;
    [super dealloc];
#endif
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

- (void)swiped:(UISwipeGestureRecognizer *)gestureRecognizer {
    NSIndexPath * indexPath = [self cellIndexPathForGestureRecognizer:gestureRecognizer];
    if(indexPath == nil)
        return;
    
    if(gestureRecognizer == _swipeGestureRecognizer && ![_editingIndexPath isEqual:indexPath])
    {
        UITableViewCell * cell = nil;
        if(_editingIndexPath)
        {
            cell = [self cellForRowAtIndexPath:_editingIndexPath];
            [self setEditing:NO atIndexPath:_editingIndexPath cell:cell];
        }
        cell = [self cellForRowAtIndexPath:indexPath];
        [self setEditing:YES atIndexPath:indexPath cell:cell];
    }
    else if (gestureRecognizer == _swipeGestureRecognizer && [_editingIndexPath isEqual:indexPath])
    {
        UITableViewCell * cell = [self cellForRowAtIndexPath:indexPath];
        [self setEditing:NO atIndexPath:indexPath cell:cell];
    }
}

- (void)tapped:(UIGestureRecognizer *)gestureRecognizer
{
    if(_editingIndexPath) {
        UITableViewCell * cell = [self cellForRowAtIndexPath:_editingIndexPath];
        [self setEditing:NO atIndexPath:_editingIndexPath cell:cell];
    }
    else
    {
        NSIndexPath *indexpath = [self cellIndexPathForGestureRecognizer:gestureRecognizer];
        if(indexpath)
        {
            UITableViewCell *cell = [self cellForRowAtIndexPath:indexpath];
            [cell setHighlighted:YES];
            [self.delegate tableView:self didSelectRowAtIndexPath:indexpath];
        }
    }
}

- (NSIndexPath *)cellIndexPathForGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    UIView * view = gestureRecognizer.view;
    if(![view isKindOfClass:[UITableView class]]) {
        return nil;
    }
    
    CGPoint point = [gestureRecognizer locationInView:view];
    NSIndexPath * indexPath = [self indexPathForRowAtPoint:point];
    return indexPath;
}

- (void)setEditing:(BOOL)editing atIndexPath:indexPath cell:(UITableViewCell *)cell
{
    _editView.frame = CGRectMake(screenWidth(), 0, kEditViewWidth, kEditViewHeight);
    [_setTopButton setTitle:@"Pin top" forState:UIControlStateNormal];
    _setTopButton.frame = CGRectMake(0, 0, 64, kEditViewHeight);
    _deleteButton.frame = CGRectMake(64, 0, 64, kEditViewHeight);
    
    CGRect frame = cell.frame;
    
    CGFloat cellXOffset;
    CGFloat editViewXOffsetOld;
    CGFloat editViewXOffset;
    
    if(editing) {
        cellXOffset = - kEditViewWidth;
        editViewXOffset = screenWidth() - kEditViewWidth;
        editViewXOffsetOld = screenWidth();
        _editingIndexPath = indexPath;
    } else {
        cellXOffset = 0;
        editViewXOffset = screenWidth();
        editViewXOffsetOld = screenWidth() - kEditViewWidth;
        _editingIndexPath = nil;
    }
    
    CGFloat cellHeight = [self.delegate tableView:self heightForRowAtIndexPath:indexPath];
    _editView.frame = (CGRect) {editViewXOffsetOld, frame.origin.y, _editView.frame.size.width, cellHeight};
    _editView.indexPath = indexPath;
    
    [UIView animateWithDuration:0.2f animations:^{
        cell.frame = CGRectMake(cellXOffset, frame.origin.y, frame.size.width, frame.size.height);
        _editView.frame = (CGRect) {editViewXOffset, frame.origin.y, _editView.frame.size.width, cellHeight};
    }];
}

#pragma mark - Interaciton
- (void)deleteItem:(id)sender {
    NSIndexPath * indexPath = _editView.indexPath;
    
    [self.dataSource tableView:self commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:indexPath];
    
    _editingIndexPath = nil;
    
    [UIView animateWithDuration:0.2f animations:^{
        CGRect frame = _editView.frame;
        _editView.frame = (CGRect){frame.origin, frame.size.width, 0};
    } completion:^(BOOL finished) {
        CGRect frame = _editView.frame;
        _editView.frame = (CGRect){screenWidth(), frame.origin.y, frame.size.width, kEditViewHeight};
    }];
    
}

- (void)setTopItem:(id)sender {
    //    UIButton * setTopButton = (UIButton *)sender;
    NSIndexPath * indexPath = _editView.indexPath;
    
    [self.dataSource tableView:self commitEditingStyle:UITableViewCellEditingStyleInsert forRowAtIndexPath:indexPath];
    
    _editingIndexPath = nil;
    
    [UIView animateWithDuration:0.2f animations:^{
        //        CGRect frame = _deleteButton.frame;
        //        _deleteButton.frame = (CGRect){frame.origin, frame.size.width, 0};
        CGRect frame = _editView.frame;
        _editView.frame = (CGRect){frame.origin, frame.size.width, 0};
    } completion:^(BOOL finished) {
        //        CGRect frame = _deleteButton.frame;
        //        _deleteButton.frame = (CGRect){screenWidth(), frame.origin.y, frame.size.width, kDeleteButtonHeight};
        CGRect frame = _editView.frame;
        _editView.frame = (CGRect){screenWidth(), frame.origin.y, frame.size.width, kEditViewHeight};
    }];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES; // Recognizers of this class are the first priority
}

//NOTE:If you have more than one gesture recognizers(For instance, if your top view can also swipe), you may need to set other recognizers to fail here.
//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
//{
//    BOOL result = NO;
//    if(gestureRecognizer == _leftGestureRecognizer || gestureRecognizer == _rightGestureRecognizer)
//    {
//        result = YES;
//    }
//    
//    return result;
//}

@end

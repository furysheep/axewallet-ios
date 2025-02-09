//
//  Created by Andrew Podkovyrin
//  Copyright © 2019 Axe Core Group. All rights reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://opensource.org/licenses/MIT
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "DWSegmentedControl.h"

#import "DWOverlapControl.h"
#import "DWProgressAnimator.h"
#import "DWUIKit.h"

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval const ANIMATION_DURATION = 0.3;
static CGFloat const SEGMENTED_CONTROL_HEIGHT = 40.0;

static CGFloat DWInterpolate(CGFloat from, CGFloat to, CGFloat progress) {
    return from + (to - from) * progress;
}

static DWOverlapControl *SegmentedButton(NSString *text) {
    DWOverlapControl *button = [[DWOverlapControl alloc]
        initWithGenerator:^__kindof UIView *_Nonnull(NSUInteger overlapIndex) {
            UILabel *label = [[UILabel alloc] init];
            label.backgroundColor = [UIColor clearColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.font = [UIFont dw_fontForTextStyle:UIFontTextStyleCallout];
            label.adjustsFontForContentSizeCategory = YES;
            label.adjustsFontSizeToFitWidth = YES;
            label.minimumScaleFactor = 0.5;
            label.text = text;

            NSCAssert(overlapIndex == 0 || overlapIndex == 1, @"Invalid state");
            if (overlapIndex == 0) {
                label.textColor = [UIColor dw_lightTitleColor];
            }
            else {
                label.textColor = [UIColor dw_axeBlueColor];
            }

            return label;
        }];

    return button;
}

@interface DWSegmentedControl ()

@property (readonly, nonatomic, strong) NSMutableArray<DWOverlapControl *> *buttons;
@property (readonly, nonatomic, strong) UIView *contentView;
@property (readonly, nonatomic, strong) UIView *selectionView;

@property (nullable, nonatomic, strong) DWProgressAnimator *animator;

@end

@implementation DWSegmentedControl

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self segmentedControl_setup];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self segmentedControl_setup];
    }
    return self;
}

- (void)segmentedControl_setup {
    self.shouldAnimateSelection = YES;

    self.backgroundColor = [UIColor dw_backgroundColor];

    self.layer.cornerRadius = 4.0;
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [UIColor dw_axeBlueColor].CGColor;
    self.layer.masksToBounds = YES;

    _buttons = [NSMutableArray array];

    UIView *selectionView = [[UIView alloc] init];
    selectionView.backgroundColor = [UIColor dw_axeBlueColor];
    [self addSubview:selectionView];
    _selectionView = selectionView;

    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor clearColor];
    [self addSubview:contentView];
    _contentView = contentView;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateButtons)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric, SEGMENTED_CONTROL_HEIGHT);
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.buttons.count == 0) {
        return;
    }

    self.contentView.frame = self.bounds;

    const CGSize size = self.bounds.size;
    const CGFloat buttonWidth = size.width / self.buttons.count;
    const CGFloat buttonHeight = size.height;

    CGFloat x = 0.0;
    for (DWOverlapControl *button in self.buttons) {
        button.frame = CGRectMake(x, 0.0, buttonWidth, buttonHeight);
        x += buttonWidth;
    }

    NSAssert(self.selectedSegmentIndex != NSNotFound, @"Invalid state");
    DWOverlapControl *selectedButton = self.buttons[self.selectedSegmentIndex];
    self.selectionView.frame = selectedButton.frame;

    [self updateButtons];
}

- (void)setItems:(nullable NSArray<NSString *> *)items {
    _items = [items copy];

    [self.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.buttons removeAllObjects];
    _selectedSegmentIndexPercent = 0.0;

    for (NSString *item in items) {
        DWOverlapControl *button = SegmentedButton(item);
        [button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:button];
        [self.buttons addObject:button];
    }

    [self setNeedsLayout];
}

- (NSInteger)selectedSegmentIndex {
    return (NSInteger)self.selectedSegmentIndexPercent;
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex {
    [self setSelectedSegmentIndex:selectedSegmentIndex animated:NO];
}

- (void)setSelectedSegmentIndex:(NSInteger)selectedSegmentIndex animated:(BOOL)animated {
    if ((NSInteger)_selectedSegmentIndexPercent == selectedSegmentIndex) {
        return;
    }

    _selectedSegmentIndexPercent = selectedSegmentIndex;

    CGRect toFrame = self.buttons[selectedSegmentIndex].frame;

    if (animated) {
        CGRect fromFrame = self.selectionView.frame;
        self.animator = [[DWProgressAnimator alloc] init];
        __weak typeof(self) weakSelf = self;
        [self.animator animateWithDuration:ANIMATION_DURATION
            animations:^(CGFloat progress) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }

                CGFloat x = DWInterpolate(fromFrame.origin.x, toFrame.origin.x, progress);
                strongSelf.selectionView.frame = CGRectMake(x, toFrame.origin.y, toFrame.size.width, toFrame.size.height);

                [strongSelf updateButtons];
            }
            completion:^(BOOL finished) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) {
                    return;
                }

                strongSelf.animator = nil;
            }];
    }
    else {
        self.selectionView.frame = toFrame;
        [self updateButtons];
    }
}

- (void)setSelectedSegmentIndexPercent:(CGFloat)selectedSegmentIndexPercent {
    _selectedSegmentIndexPercent = selectedSegmentIndexPercent;

    CGRect selectionFrame = self.selectionView.frame;
    const CGFloat x = CGRectGetWidth(selectionFrame) * selectedSegmentIndexPercent;
    selectionFrame.origin.x = x;

    self.selectionView.frame = selectionFrame;
    [self updateButtons];
}

#pragma mark - Private

- (void)updateButtons {
    const NSUInteger count = self.buttons.count;
    if (count == 0) {
        return;
    }

    const NSUInteger extendFactor = count - 1;
    const NSInteger selectedIndex = MAX(0, MIN(count - 1, round(self.selectedSegmentIndexPercent)));
    DWOverlapControl *selectedButton = self.buttons[selectedIndex];

    for (DWOverlapControl *button in self.buttons) {
        button.selected = (button == selectedButton);

        const CGRect selectionFrame = [self.selectionView convertRect:self.selectionView.bounds toView:button];
        const CGFloat selectionWidth = CGRectGetWidth(selectionFrame);
        CGRect nonSelectionFrame = selectionFrame;
        if (CGRectGetMinX(selectionFrame) > 0) {
            // selectionView on the right side
            nonSelectionFrame.origin.x -= selectionWidth * extendFactor;
        }
        else {
            // selectionView on the left side
            nonSelectionFrame.origin.x += selectionWidth;
        }
        nonSelectionFrame.size.width *= extendFactor;

        [button overlapWithViewFrames:@[
            [NSValue valueWithCGRect:selectionFrame],
            [NSValue valueWithCGRect:nonSelectionFrame],
        ]];
    }
}

#pragma mark - Actions

- (void)buttonAction:(DWOverlapControl *)sender {
    if (sender.selected) {
        return;
    }

    NSUInteger selectedIndex = [self.buttons indexOfObject:sender];
    NSAssert(selectedIndex != NSNotFound, @"Invalid state");

    if (self.shouldAnimateSelection) {
        [self setSelectedSegmentIndex:selectedIndex animated:YES];
    }
    else {
        _selectedSegmentIndexPercent = selectedIndex;
    }

    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end

NS_ASSUME_NONNULL_END

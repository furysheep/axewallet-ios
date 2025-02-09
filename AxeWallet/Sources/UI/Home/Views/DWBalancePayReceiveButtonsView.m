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

#import "DWBalancePayReceiveButtonsView.h"

#import "DWBalanceDisplayOptionsProtocol.h"
#import "DWBalanceModel.h"
#import "DWUIKit.h"

NS_ASSUME_NONNULL_BEGIN

static CGFloat const BalanceButtonMinHeight(void) {
    if (IS_IPHONE_5_OR_LESS) {
        return 80.0;
    }
    else {
        return 120.0;
    }
}

static NSTimeInterval const ANIMATION_DURATION = 0.3;

@interface DWBalancePayReceiveButtonsView ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UIControl *balanceButton;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIView *hidingView;
@property (strong, nonatomic) IBOutlet UIImageView *eyeSlashImageView;
@property (strong, nonatomic) IBOutlet UILabel *tapToUnhideLabel;
@property (strong, nonatomic) IBOutlet UIView *amountsView;
@property (strong, nonatomic) IBOutlet UILabel *axeBalanceLabel;
@property (strong, nonatomic) IBOutlet UILabel *fiatBalanceLabel;
@property (strong, nonatomic) IBOutlet UIView *buttonsContainerView;
@property (strong, nonatomic) IBOutlet UIButton *payButton;
@property (strong, nonatomic) IBOutlet UIButton *receiveButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *balanceViewHeightContraint;

@end

@implementation DWBalancePayReceiveButtonsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
    [self addSubview:self.contentView];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.contentView.widthAnchor constraintEqualToAnchor:self.widthAnchor],
    ]];

    self.backgroundColor = [UIColor dw_backgroundColor];

    self.titleLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleSubheadline];
    self.titleLabel.textColor = [UIColor dw_darkBlueColor];

    self.eyeSlashImageView.tintColor = [UIColor dw_darkBlueColor];

    self.tapToUnhideLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleCaption2];
    self.tapToUnhideLabel.textColor = [UIColor dw_lightTitleColor];
    self.tapToUnhideLabel.alpha = 0.5;

    self.axeBalanceLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleTitle1];
    self.fiatBalanceLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleCallout];

    [self.payButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    self.payButton.titleLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleSubheadline];

    [self.receiveButton setTitle:NSLocalizedString(@"Receive", nil) forState:UIControlStateNormal];
    self.receiveButton.titleLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleSubheadline];

    self.balanceViewHeightContraint.constant = BalanceButtonMinHeight();

    UILongPressGestureRecognizer *recognizer =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(balanceLongPressAction:)];
    [self.balanceButton addGestureRecognizer:recognizer];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentSizeCategoryDidChangeNotification:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];

    // KVO

    [self mvvm_observe:DW_KEYPATH(self, model.balanceModel)
                  with:^(typeof(self) self, id value) {
                      [self reloadAttributedData];
                  }];

    [self mvvm_observe:DW_KEYPATH(self, model.balanceDisplayOptions.balanceHidden)
                  with:^(typeof(self) self, NSNumber *value) {
                      [self hideBalance:self.model.balanceDisplayOptions.balanceHidden];
                  }];
}

- (void)parentScrollViewDidScroll:(UIScrollView *)scrollView {
    const CGFloat offset = scrollView.contentOffset.y + scrollView.contentInset.top;
    const CGRect buttonsFrame = self.buttonsContainerView.frame;
    const CGFloat threshold = CGRectGetHeight(buttonsFrame) / 2.0;
    // start descreasing alpha when scroll offset reached the point before the half of buttons height until the center of the buttons
    CGFloat alpha = 1.0 - (threshold + offset - CGRectGetMinY(buttonsFrame)) / threshold;
    alpha = MAX(0.0, MIN(1.0, alpha));
    self.buttonsContainerView.alpha = alpha;
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    [self reloadAttributedData];
}

#pragma mark - Actions

- (IBAction)payButtonAction:(UIButton *)sender {
    [self.delegate balancePayReceiveButtonsView:self payButtonAction:sender];
}

- (IBAction)receiveButtonAction:(UIButton *)sender {
    [self.delegate balancePayReceiveButtonsView:self receiveButtonAction:sender];
}

- (IBAction)balanceButtonAction:(UIControl *)sender {
    id<DWBalanceDisplayOptionsProtocol> balanceDisplayOptions = self.model.balanceDisplayOptions;
    balanceDisplayOptions.balanceHidden = !balanceDisplayOptions.balanceHidden;
}

- (void)balanceLongPressAction:(UIControl *)sender {
    [self.delegate balancePayReceiveButtonsView:self balanceLongPressAction:sender];
}

#pragma mark - Notifications

- (void)contentSizeCategoryDidChangeNotification:(NSNotification *)notification {
    [self reloadAttributedData];
}

#pragma mark - Private

- (void)reloadAttributedData {
    UIColor *balanceColor = [UIColor dw_lightTitleColor];
    DWBalanceModel *balanceModel = self.model.balanceModel;
    if (balanceModel) {
        UIFont *font = [UIFont dw_fontForTextStyle:UIFontTextStyleTitle1];

        self.axeBalanceLabel.attributedText = [balanceModel axeAmountStringWithFont:font
                                                                            tintColor:balanceColor];
        self.fiatBalanceLabel.hidden = NO;
        self.fiatBalanceLabel.text = [balanceModel fiatAmountString];
    }
    else {
        // 😭 UI designes states so:
        self.axeBalanceLabel.textColor = [balanceColor colorWithAlphaComponent:0.44];
        self.axeBalanceLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleBody];

        self.axeBalanceLabel.text = NSLocalizedString(@"Please wait for the sync to complete", nil);
        self.fiatBalanceLabel.hidden = YES;
    }
}

- (void)hideBalance:(BOOL)hidden {
    const BOOL animated = self.window != nil;

    [UIView animateWithDuration:animated ? ANIMATION_DURATION : 0.0
                     animations:^{
                         self.hidingView.alpha = hidden ? 1.0 : 0.0;
                         self.amountsView.alpha = hidden ? 0.0 : 1.0;

                         self.tapToUnhideLabel.text = hidden
                                                          ? NSLocalizedString(@"Tap to unhide balance", nil)
                                                          : NSLocalizedString(@"Tap to hide balance", nil);

                         self.titleLabel.text = hidden
                                                    ? NSLocalizedString(@"Balance hidden", nil)
                                                    : NSLocalizedString(@"Available balance", nil);
                     }];
}

@end

NS_ASSUME_NONNULL_END

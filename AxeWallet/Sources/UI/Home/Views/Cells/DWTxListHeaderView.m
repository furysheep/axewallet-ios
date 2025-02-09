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

#import "DWTxListHeaderView.h"

#import "DWUIKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWTxListHeaderView ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIButton *filterButton;

@end

@implementation DWTxListHeaderView

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

    self.backgroundColor = [UIColor dw_secondaryBackgroundColor];

    self.titleLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleHeadline];
    self.titleLabel.text = NSLocalizedString(@"History", nil);

    self.filterButton.titleLabel.font = [UIFont dw_fontForTextStyle:UIFontTextStyleFootnote];
}

- (void)setModel:(nullable id<DWTxDisplayModeProtocol>)model {
    _model = model;

    UIButton *button = self.filterButton;
    switch (self.model.displayMode) {
        case DWHomeTxDisplayMode_All:
            [button setTitle:NSLocalizedString(@"All", nil) forState:UIControlStateNormal];
            break;
        case DWHomeTxDisplayMode_Received:
            [button setTitle:NSLocalizedString(@"Received", nil) forState:UIControlStateNormal];
            break;
        case DWHomeTxDisplayMode_Sent:
            [button setTitle:NSLocalizedString(@"Sent", nil) forState:UIControlStateNormal];
            break;
        case DWHomeTxDisplayMode_Rewards:
            [button setTitle:NSLocalizedString(@"Rewards", nil) forState:UIControlStateNormal];
            break;
    }
}

- (IBAction)filterButtonAction:(UIButton *)sender {
    [self.delegate txListHeaderView:self filterButtonAction:sender];
}

@end

NS_ASSUME_NONNULL_END

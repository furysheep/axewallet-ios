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

#import "DWTabBarView.h"

#import "DWPaymentsButton.h"
#import "DWSharedUIConstants.h"
#import "DWTabBarButton.h"
#import "DWUIKit.h"

NS_ASSUME_NONNULL_BEGIN

static CGFloat const DW_TABBAR_HEIGHT = 64.0;
static CGFloat const TABBAR_HEIGHT_LARGE = 77.0;
static CGFloat const TABBAR_BORDER_WIDTH = 1.0;
static CGFloat const CENTER_CIRCLE_SIZE = 68.0;

@interface DWTabBarView ()

@property (nonatomic, strong) CALayer *topLineLayer;
@property (nonatomic, strong) CAShapeLayer *centerCircleLayer;
@property (nonatomic, strong) CALayer *circleOverlayLayer;

@property (nonatomic, copy) NSArray<UIView *> *buttons;
@property (nonatomic, strong) DWTabBarButton *homeButton;
@property (nonatomic, strong) DWPaymentsButton *paymentsButton;
@property (nonatomic, strong) DWTabBarButton *othersButton;

@end

@implementation DWTabBarView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor dw_backgroundColor];
        self.clipsToBounds = NO;

        CALayer *topLineLayer = [CALayer layer];
        topLineLayer.backgroundColor = [UIColor dw_tabbarBorderColor].CGColor;
        [self.layer addSublayer:topLineLayer];
        _topLineLayer = topLineLayer;

        CAShapeLayer *centerCircleLayer = [CAShapeLayer layer];
        centerCircleLayer.fillColor = self.backgroundColor.CGColor;
        centerCircleLayer.strokeColor = [UIColor dw_tabbarBorderColor].CGColor;
        centerCircleLayer.lineWidth = TABBAR_BORDER_WIDTH;
        const CGFloat radius = CENTER_CIRCLE_SIZE / 2.0;
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(radius, radius)
                                                                  radius:radius
                                                              startAngle:0
                                                                endAngle:M_PI
                                                               clockwise:NO];
        centerCircleLayer.path = circlePath.CGPath;
        [self.layer addSublayer:centerCircleLayer];
        _centerCircleLayer = centerCircleLayer;

        CALayer *circleOverlayLayer = [CALayer layer];
        circleOverlayLayer.backgroundColor = self.backgroundColor.CGColor;
        [self.layer addSublayer:circleOverlayLayer];
        _circleOverlayLayer = circleOverlayLayer;

        NSMutableArray<UIView *> *buttons = [NSMutableArray array];

        {
            DWTabBarButton *button = [[DWTabBarButton alloc] initWithType:DWTabBarButtonType_Home];
            [button addTarget:self
                          action:@selector(tabBarButtonAction:)
                forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            [buttons addObject:button];
            _homeButton = button;
        }

        {
            DWPaymentsButton *button = [[DWPaymentsButton alloc] initWithFrame:CGRectZero];
            [button addTarget:self
                          action:@selector(paymentsButtonAction:)
                forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            [buttons addObject:button];
            _paymentsButton = button;

#if SNAPSHOT
            button.accessibilityIdentifier = @"tabbar_payments_button";
#endif /* SNAPSHOT */
        }

        {
            DWTabBarButton *button = [[DWTabBarButton alloc] initWithType:DWTabBarButtonType_Others];
            [button addTarget:self
                          action:@selector(tabBarButtonAction:)
                forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            [buttons addObject:button];
            _othersButton = button;

#if SNAPSHOT
            button.accessibilityIdentifier = @"tabbar_menu_button";
#endif /* SNAPSHOT */
        }

        _buttons = [buttons copy];

        [self updateSelectedTabButton:DWTabBarViewButtonType_Home];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(UIViewNoIntrinsicMetric,
                      DEVICE_HAS_HOME_INDICATOR ? TABBAR_HEIGHT_LARGE : DW_TABBAR_HEIGHT);
}

- (void)layoutSubviews {
    [super layoutSubviews];

    NSAssert(self.buttons.count > 0, @"Invalid state");

    const CGSize size = self.bounds.size;
    const CGFloat buttonWidth = size.width / self.buttons.count;
    CGFloat x = 0.0;
    for (UIButton *button in self.buttons) {
        if (button != self.paymentsButton) {
            button.frame = CGRectMake(x, 0.0, buttonWidth, MIN(DW_TABBAR_HEIGHT, size.height));
        }

        x += buttonWidth;
    }

    self.topLineLayer.frame = CGRectMake(0, 0, size.width, TABBAR_BORDER_WIDTH);

    const CGSize arcSize = CGSizeMake(CENTER_CIRCLE_SIZE, CENTER_CIRCLE_SIZE / 2.0);
    self.centerCircleLayer.frame = CGRectMake((size.width - arcSize.width) / 2.0,
                                              -DW_TABBAR_NOTCH,
                                              arcSize.width,
                                              arcSize.height);

    const CGSize overlaySize = CGSizeMake(CENTER_CIRCLE_SIZE + TABBAR_BORDER_WIDTH * 2,
                                          DW_TABBAR_HEIGHT - TABBAR_BORDER_WIDTH * 2);
    self.circleOverlayLayer.frame = CGRectMake((size.width - overlaySize.width) / 2.0,
                                               TABBAR_BORDER_WIDTH,
                                               overlaySize.width,
                                               overlaySize.height);

    self.paymentsButton.frame = CGRectMake((size.width - DW_PAYMENTS_BUTTON_SIZE.width) / 2.0,
                                           0.0,
                                           DW_PAYMENTS_BUTTON_SIZE.width,
                                           DW_PAYMENTS_BUTTON_SIZE.height);
}

- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    self.backgroundColor = [UIColor dw_backgroundColor];
    self.centerCircleLayer.fillColor = self.backgroundColor.CGColor;
    self.circleOverlayLayer.backgroundColor = self.backgroundColor.CGColor;

    UIColor *borderColor = [UIColor dw_tabbarBorderColor];
    self.centerCircleLayer.strokeColor = borderColor.CGColor;
    self.topLineLayer.backgroundColor = borderColor.CGColor;
}

- (void)setPaymentsButtonOpened:(BOOL)opened {
    self.paymentsButton.opened = opened;
}

- (void)togglePaymentsOpenState {
    [self paymentsButtonAction:self.paymentsButton];
}

#pragma mark - Actions

- (void)paymentsButtonAction:(DWPaymentsButton *)sender {
    if (sender.opened == NO) {
        [self.delegate tabBarViewDidOpenPayments:self];
    }
    else {
        [self.delegate tabBarViewDidClosePayments:self];
    }
}

- (void)tabBarButtonAction:(UIView *)sender {
    if (self.paymentsButton.opened) {
        [self.delegate tabBarViewDidClosePayments:self];
    }
    else {
        DWTabBarViewButtonType type;
        if (sender == self.homeButton) {
            type = DWTabBarViewButtonType_Home;
        }
        else if (sender == self.othersButton) {
            type = DWTabBarViewButtonType_Others;
        }
        else {
            type = DWTabBarViewButtonType_Home;
            NSAssert(NO, @"Invalid sender");
        }

        [self.delegate tabBarView:self didTapButtonType:type];
    }
}

- (void)updateSelectedTabButton:(DWTabBarViewButtonType)type {
    switch (type) {
        case DWTabBarViewButtonType_Home: {
            self.othersButton.selected = NO;
            self.homeButton.selected = YES;

            break;
        }
        case DWTabBarViewButtonType_Others: {
            self.othersButton.selected = YES;
            self.homeButton.selected = NO;

            break;
        }
    }
}

@end

NS_ASSUME_NONNULL_END

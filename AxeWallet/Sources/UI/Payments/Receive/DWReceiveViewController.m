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

#import "DWReceiveViewController.h"

#import "DWReceiveContentView.h"
#import "DWReceiveModel.h"
#import "DWRequestAmountViewController.h"
#import "DWSpecifyAmountViewController.h"
#import "DWUIKit.h"
#import "UIView+DWHUD.h"
#import "UIViewController+DWShareReceiveInfo.h"

NS_ASSUME_NONNULL_BEGIN

static CGFloat TopPadding(void) {
    if (IS_IPHONE_5_OR_LESS || IS_IPHONE_6) {
        return 8.0;
    }
    else {
        return 44.0;
    }
}

@interface DWReceiveViewController () <DWReceiveContentViewDelegate,
                                       DWSpecifyAmountViewControllerDelegate,
                                       DWRequestAmountViewControllerDelegate>

@property (nonatomic, strong) DWReceiveContentView *contentView;

@property (nonatomic, strong) id<DWReceiveModelProtocol> model;

@end

@implementation DWReceiveViewController

+ (instancetype)controllerWithModel:(id<DWReceiveModelProtocol>)receiveModel {
    DWReceiveViewController *controller = [[DWReceiveViewController alloc] init];
    controller.model = receiveModel;

    return controller;
}

- (void)setViewType:(DWReceiveViewType)viewType {
    _viewType = viewType;

    NSAssert(!self.isViewLoaded, @"Controller should be configured before presenting");
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSAssert(self.model, @"Use controllerWithModel: method to init the class");

    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.contentView viewDidAppear];
}

#pragma mark - DWReceiveContentViewDelegate

- (void)receiveContentView:(DWReceiveContentView *)view specifyAmountButtonAction:(UIButton *)sender {
    DWSpecifyAmountViewController *controller = [DWSpecifyAmountViewController controller];
    controller.delegate = self;
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)receiveContentView:(DWReceiveContentView *)view secondButtonAction:(UIButton *)sender {
    switch (self.viewType) {
        case DWReceiveViewType_Default: {
            [self dw_shareReceiveInfo:self.model sender:sender];

            break;
        }
        case DWReceiveViewType_QuickReceive: {
            [self.delegate receiveViewControllerExitButtonAction:self];

            break;
        }
    }
}

#pragma mark - DWSpecifyAmountViewControllerDelegate

- (void)specifyAmountViewController:(DWSpecifyAmountViewController *)controller
                     didInputAmount:(uint64_t)amount {
    DWReceiveModel *requestModel = [[DWReceiveModel alloc] initWithAmount:amount];
    DWRequestAmountViewController *requestController =
        [DWRequestAmountViewController controllerWithModel:requestModel];
    requestController.delegate = self;
    [self presentViewController:requestController animated:YES completion:nil];
}

#pragma mark - DWRequestAmountViewControllerDelegate

- (void)requestAmountViewController:(DWRequestAmountViewController *)controller
           didReceiveAmountWithInfo:(NSString *)info {
    [controller dismissViewControllerAnimated:YES
                                   completion:^{
                                       [self.navigationController popViewControllerAnimated:YES];

                                       const NSTimeInterval popAnimationDuration = 0.3;
                                       dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(popAnimationDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                           [self.navigationController.view dw_showInfoHUDWithText:info];
                                       });
                                   }];
}

#pragma mark - Private

- (void)setupView {
    UIColor *backgroundColor = nil;
    switch (self.viewType) {
        case DWReceiveViewType_Default: {
            backgroundColor = [UIColor dw_backgroundColor];

            break;
        }
        case DWReceiveViewType_QuickReceive: {
            backgroundColor = [UIColor dw_secondaryBackgroundColor];

            break;
        }
    }
    self.view.backgroundColor = backgroundColor;

    DWReceiveContentView *contentView = [[DWReceiveContentView alloc] initWithModel:self.model];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.delegate = self;
    contentView.viewType = self.viewType;
    [self.view addSubview:contentView];
    self.contentView = contentView;

    UILayoutGuide *marginsGuide = self.view.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:self.view.topAnchor
                                              constant:TopPadding()],
        [contentView.leadingAnchor constraintEqualToAnchor:marginsGuide.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:marginsGuide.trailingAnchor],
    ]];

    if (self.viewType == DWReceiveViewType_QuickReceive) {
        [contentView.bottomAnchor constraintEqualToAnchor:marginsGuide.bottomAnchor].active = YES;
    }
}

@end

NS_ASSUME_NONNULL_END

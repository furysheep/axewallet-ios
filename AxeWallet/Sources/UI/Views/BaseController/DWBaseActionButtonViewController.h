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

#import "DWBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DWActionButtonProtocol <NSObject>

@property (nonatomic, assign, getter=isEnabled) BOOL enabled;

@end

@interface DWBaseActionButtonViewController : DWBaseViewController

@property (readonly, nullable, nonatomic, strong) id<DWActionButtonProtocol> actionButton;

+ (BOOL)showsActionButton;
+ (BOOL)isActionButtonInNavigationBar;

- (NSString *)actionButtonTitle;
- (NSString *)actionButtonDisabledTitle;

- (void)setupContentView:(UIView *)contentView;

- (void)actionButtonAction:(id)sender;

- (void)reloadActionButtonTitles;

- (void)showActivityIndicator;
- (void)hideActivityIndicator;

@end

NS_ASSUME_NONNULL_END

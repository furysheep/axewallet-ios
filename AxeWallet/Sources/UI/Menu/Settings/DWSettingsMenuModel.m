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

#import "DWSettingsMenuModel.h"

#import "DWEnvironment.h"
#import "DWGlobalOptions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation DWSettingsMenuModel

- (NSString *)networkName {
    return [DWEnvironment sharedInstance].currentChain.name;
}

- (NSString *)localCurrencyCode {
    return [DSPriceManager sharedInstance].localCurrencyCode;
}

- (BOOL)notificationsEnabled {
    return [DWGlobalOptions sharedInstance].localNotificationsEnabled;
}

- (void)setNotificationsEnabled:(BOOL)notificationsEnabled {
    [DWGlobalOptions sharedInstance].localNotificationsEnabled = notificationsEnabled;
}

+ (void)switchToMainnetWithCompletion:(void (^)(BOOL success))completion {
    [[DWEnvironment sharedInstance] switchToMainnetWithCompletion:completion];
}

+ (void)switchToTestnetWithCompletion:(void (^)(BOOL success))completion {
    [[DWEnvironment sharedInstance] switchToTestnetWithCompletion:completion];
}

+ (void)rescanBlockchainActionFromController:(UIViewController *)controller
                                  sourceView:(UIView *)sourceView
                                  sourceRect:(CGRect)sourceRect
                                  completion:(void (^_Nullable)(BOOL confirmed))completion {
    UIAlertController *actionSheet = [UIAlertController
        alertControllerWithTitle:NSLocalizedString(@"Rescan Blockchain", nil)
                         message:nil
                  preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *rescanAction = [UIAlertAction
        actionWithTitle:DSLocalizedString(@"Confirm", nil)
                  style:UIAlertActionStyleDefault
                handler:^(UIAlertAction *action) {
                    DSChainManager *chainManager = [DWEnvironment sharedInstance].currentChainManager;
                    [chainManager rescan];

                    if (completion) {
                        completion(YES);
                    }
                }];

    UIAlertAction *cancelAction = [UIAlertAction
        actionWithTitle:NSLocalizedString(@"Cancel", nil)
                  style:UIAlertActionStyleCancel
                handler:^(UIAlertAction *_Nonnull action) {
                    if (completion) {
                        completion(NO);
                    }
                }];
    [actionSheet addAction:rescanAction];
    [actionSheet addAction:cancelAction];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        actionSheet.popoverPresentationController.sourceView = sourceView;
        actionSheet.popoverPresentationController.sourceRect = sourceRect;
    }
    [controller presentViewController:actionSheet animated:YES completion:nil];
}

@end

NS_ASSUME_NONNULL_END

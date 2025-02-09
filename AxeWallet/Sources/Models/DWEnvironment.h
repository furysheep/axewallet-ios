//
//  Created by Sam Westrich
//  Copyright © 2018-2019 Axe Core Group. All rights reserved.
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

#import <Foundation/Foundation.h>

#import <AxeSync/AxeSync.h>

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const DWCurrentNetworkDidChangeNotification;

@interface DWEnvironment : NSObject

@property (nonatomic, strong, nonnull) DSChain *currentChain;
@property (nonatomic, readonly) DSWallet *currentWallet;
@property (nonatomic, readonly) NSArray *allWallets;
@property (nonatomic, readonly) DSAccount *currentAccount;
@property (nonatomic, strong) DSChainManager *currentChainManager;

+ (instancetype)sharedInstance;

- (void)clearAllWallets;
- (void)clearAllWalletsAndRemovePin:(BOOL)shouldRemovePin;
- (void)switchToMainnetWithCompletion:(void (^)(BOOL success))completion;
- (void)switchToTestnetWithCompletion:(void (^)(BOOL success))completion;
- (void)reset;

@end

NS_ASSUME_NONNULL_END

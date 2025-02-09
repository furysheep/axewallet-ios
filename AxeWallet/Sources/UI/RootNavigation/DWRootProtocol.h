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

#import <Foundation/Foundation.h>

#import "DWHomeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@protocol DWRootProtocol <NSObject>

@property (readonly, nonatomic, assign) BOOL hasAWallet;

@property (readonly, nonatomic, strong) id<DWHomeProtocol> homeModel;

@property (nullable, nonatomic, copy) void (^currentNetworkDidChangeBlock)(void);

/**
 NO if running Axewallet is not allowed on this device for security reasons
 */
@property (readonly, nonatomic, assign) BOOL walletOperationAllowed;

- (void)applicationDidEnterBackground;
- (BOOL)shouldShowLockScreen;

- (void)setupDidFinish;

@end

NS_ASSUME_NONNULL_END

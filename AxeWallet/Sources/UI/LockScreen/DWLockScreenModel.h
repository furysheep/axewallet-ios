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
#import <LocalAuthentication/LocalAuthentication.h>

NS_ASSUME_NONNULL_BEGIN

@class DWLockScreenModel;

@protocol DWLockScreenModelDelegate <NSObject>

- (void)lockScreenModel:(DWLockScreenModel *)model
    shouldContinueAuthentication:(BOOL)shouldContinueAuthentication
                   authenticated:(BOOL)authenticated
                   shouldLockout:(BOOL)shouldLockout
                 attemptsMessage:(nullable NSString *)attemptsMessage;

@end

@interface DWLockScreenModel : NSObject

@property (readonly, nonatomic, assign, getter=isBiometricAuthenticationAllowed) BOOL biometricAuthenticationAllowed;
@property (readonly, nonatomic, assign) LABiometryType biometryType;
@property (nullable, nonatomic, weak) id<DWLockScreenModelDelegate> delegate;

- (void)authenticateUsingBiometricsOnlyCompletion:(void (^)(BOOL authenticated))completion;

- (void)startCheckingAuthState;
- (void)stopCheckingAuthState;

- (nullable NSString *)lockoutErrorMessage;

- (BOOL)checkPin:(NSString *)inputPin;

@end

NS_ASSUME_NONNULL_END

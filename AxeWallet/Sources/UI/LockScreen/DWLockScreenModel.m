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

#import "DWLockScreenModel.h"

#import <AxeSync/DSAuthenticationManager+Private.h>
#import <AxeSync/DSBiometricsAuthenticator.h>
#import <AxeSync/AxeSync.h>

#import "DWGlobalOptions.h"

NS_ASSUME_NONNULL_BEGIN

#define SHOULD_SIMULATE_BIOMETRICS 1

static NSTimeInterval const CHECK_INTERVAL = 1.0;

@interface DWLockScreenModel ()

@property (nonatomic, assign) BOOL checkingAuth;

@end

@implementation DWLockScreenModel

- (BOOL)isBiometricAuthenticationAllowed {
    return [DWGlobalOptions sharedInstance].biometricAuthEnabled &&
           [[DSAuthenticationManager sharedInstance] isBiometricAuthenticationAllowed];
}

- (LABiometryType)biometryType {
#if (TARGET_OS_SIMULATOR && SHOULD_SIMULATE_BIOMETRICS)
    return LABiometryTypeTouchID;
#else
    return DSBiometricsAuthenticator.biometryType;
#endif /* (TARGET_OS_SIMULATOR && SHOULD_SIMULATE_BIOMETRICS) */
}

- (void)authenticateUsingBiometricsOnlyCompletion:(void (^)(BOOL authenticated))completion {
    [[DSAuthenticationManager sharedInstance] authenticateUsingBiometricsOnlyWithPrompt:nil
                                                                             completion:^(BOOL authenticatedOrSuccess, BOOL usedBiometrics, BOOL cancelled) {
                                                                                 if (completion) {
                                                                                     completion(authenticatedOrSuccess);
                                                                                 }
                                                                             }];
}

- (void)startCheckingAuthState {
    if (self.checkingAuth) {
        return;
    }
    self.checkingAuth = YES;

    [self checkAuthState];
}

- (void)stopCheckingAuthState {
    self.checkingAuth = NO;

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkAuthState) object:nil];
}

- (BOOL)checkPin:(NSString *)inputPin {
    [self stopCheckingAuthState];

    DSAuthenticationManager *authManager = [DSAuthenticationManager sharedInstance];
    __block BOOL isPinValid = NO;
    [authManager performPinVerificationAgainstCurrentPin:inputPin
                                              completion:^(BOOL allowedNextVerificationRound,
                                                           BOOL authenticated,
                                                           BOOL cancelled,
                                                           BOOL shouldLockout) {
                                                  isPinValid = authenticated;

                                                  if (!authenticated) {
                                                      [self startCheckingAuthState];
                                                  }
                                              }];

    return isPinValid;
}

- (nullable NSString *)lockoutErrorMessage {
    DSAuthenticationManager *authManager = [DSAuthenticationManager sharedInstance];

    NSError *error = nil;
    uint64_t failCount = [authManager getFailCount:&error];
    if (error) {
        return nil;
    }
    NSString *message = nil;
    if (failCount < MAX_FAIL_COUNT) {
        NSTimeInterval wait = [authManager lockoutWaitTime];
        NSString *waitString = [NSString waitTimeFromNow:wait];
        message = [NSString stringWithFormat:DSLocalizedString(@"Try again in %@", nil), waitString];
    }
    else {
        message = DSLocalizedString(@"No attempts remaining", nil);
    }

    return message;
}

#pragma mark - Private

- (void)checkAuthState {
    if (!self.checkingAuth) {
        return;
    }

    DSAuthenticationManager *authManager = [DSAuthenticationManager sharedInstance];

    [authManager
        performAuthenticationPrecheck:^(BOOL shouldContinueAuthentication,
                                        BOOL authenticated,
                                        BOOL shouldLockout,
                                        NSString *_Nullable attemptsMessage) {
            if (!self.checkingAuth) {
                return;
            }

            [self.delegate lockScreenModel:self
                shouldContinueAuthentication:shouldContinueAuthentication
                               authenticated:authenticated
                               shouldLockout:shouldLockout
                             attemptsMessage:attemptsMessage];

            [self performSelector:@selector(checkAuthState)
                       withObject:nil
                       afterDelay:CHECK_INTERVAL];
        }];
}

@end

NS_ASSUME_NONNULL_END

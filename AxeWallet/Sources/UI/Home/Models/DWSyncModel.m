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

#import "DWSyncModel.h"

#import <AxeSync/DSNetworkActivityIndicatorManager.h>
#import <AxeSync/AxeSync.h>

#import "DWEnvironment.h"

NS_ASSUME_NONNULL_BEGIN

#define LOG_SYNCING 0

#if LOG_SYNCING
#define DWSyncLog(frmt, ...) DSLogVerbose(frmt, ##__VA_ARGS__)
#else
#define DWSyncLog(frmt, ...)
#endif /* LOG_SYNCING */

__unused static NSString *SyncStateToString(DWSyncModelState state) {
    switch (state) {
        case DWSyncModelState_Syncing:
            return @"Syncing";
        case DWSyncModelState_SyncDone:
            return @"Done";
        case DWSyncModelState_SyncFailed:
            return @"Failed";
        case DWSyncModelState_NoConnection:
            return @"NoConnection";
    }
}

NSString *const DWSyncStateChangedNotification = @"DWSyncStateChangedNotification";
NSString *const DWSyncStateChangedFromStateKey = @"DWSyncStateChangedFromStateKey";

static NSTimeInterval const SYNC_LOOP_INTERVAL = 0.2;
float const DW_SYNCING_COMPLETED_PROGRESS = 0.995;

@interface DWSyncModel ()

@property (readonly, nonatomic, strong) DSReachabilityManager *reachability;

@property (nonatomic, assign) DWSyncModelState state;
@property (nonatomic, assign) float progress;

@property (nonatomic, assign, getter=isSyncing) BOOL syncing;

@end

@implementation DWSyncModel

- (instancetype)initWithReachability:(DSReachabilityManager *)reachability {
    self = [super init];
    if (self) {
        _reachability = reachability;

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(transactionManagerSyncStartedNotification)
                                   name:DSTransactionManagerSyncStartedNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(transactionManagerSyncFinishedNotification)
                                   name:DSTransactionManagerSyncFinishedNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(transactionManagerSyncFailedNotification)
                                   name:DSTransactionManagerSyncFailedNotification
                                 object:nil];
        [notificationCenter addObserver:self
                               selector:@selector(chainBlocksDidChangeNotification)
                                   name:DSChainBlocksDidChangeNotification
                                 object:nil];

        if ([DWEnvironment sharedInstance].currentChainManager.peerManager.connected) {
            [self startSyncingActivity];
        }
    }
    return self;
}

- (void)dealloc {
    DSLogVerbose(@"☠️ %@", NSStringFromClass(self.class));
}

- (void)reachabilityStatusDidChange {
    DWSyncLog(@"[DW Sync] reachabilityStatusDidChange");

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncLoop) object:nil];
    [self syncLoop];
}

- (void)forceStartSyncingActivity {
    DWSyncLog(@"[DW Sync] forceStartSyncingActivity");

    [self startSyncingActivity];
}

#pragma mark Notifications

- (void)transactionManagerSyncStartedNotification {
    NSAssert([NSThread isMainThread], @"Main thread is assumed here");
    DWSyncLog(@"[DW Sync] transactionManagerSyncStartedNotification");

    [self startSyncingActivity];
}

- (void)transactionManagerSyncFinishedNotification {
    NSAssert([NSThread isMainThread], @"Main thread is assumed here");
    DWSyncLog(@"[DW Sync] transactionManagerSyncFinishedNotification");

    if (![self shouldStopSyncing]) {
        return;
    }

    [self stopSyncingActivityFailed:NO];
}

- (void)transactionManagerSyncFailedNotification {
    NSAssert([NSThread isMainThread], @"Main thread is assumed here");
    DWSyncLog(@"[DW Sync] transactionManagerSyncFailedNotification");

    [self stopSyncingActivityFailed:YES];
}

- (void)chainBlocksDidChangeNotification {
    // Fallback to show active syncing progress
    if (self.syncing) {
        return;
    }

    DWSyncLog(@"[DW Sync] chainBlocksDidChangeNotification");

    const double progress = [self chainSyncProgress];
    if (progress < DW_SYNCING_COMPLETED_PROGRESS) {
        [self startSyncingActivity];
    }
}

#pragma mark Private

- (void)setSyncing:(BOOL)syncing {
    NSAssert([NSThread isMainThread], @"Main thread is assumed here");

    if (_syncing == syncing) {
        return;
    }

    DWSyncLog(@"[DW Sync] setSyncing: %@", syncing ? @"YES" : @"NO");

    _syncing = syncing;

    [UIApplication sharedApplication].idleTimerDisabled = syncing;

    if (syncing) {
        [DSNetworkActivityIndicatorManager increaseActivityCounter];
    }
    else {
        [DSNetworkActivityIndicatorManager decreaseActivityCounter];
    }
}

- (void)setState:(DWSyncModelState)state {
    NSAssert([NSThread isMainThread], @"Main thread is assumed here");

    if (_state == state) {
        return;
    }

    DWSyncModelState previousState = _state;
    _state = state;

    DWSyncLog(@"[DW Sync] Sync state: %@ -> %@", SyncStateToString(previousState), SyncStateToString(state));

    [[NSNotificationCenter defaultCenter] postNotificationName:DWSyncStateChangedNotification
                                                        object:nil
                                                      userInfo:@{
                                                          DWSyncStateChangedFromStateKey : @(previousState)
                                                      }];
}

- (void)startSyncingActivity {
    if (self.syncing) {
        return;
    }

    DWSyncLog(@"[DW Sync] startSyncingActivity");

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncLoop) object:nil];
    [self syncLoop];
}

- (void)stopSyncingActivityFailed:(BOOL)failed {
    if (!self.syncing) {
        return;
    }

    DWSyncLog(@"[DW Sync] stopSyncingActivityFailed: %@", failed ? @"Failed" : @"Not Failed");

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncLoop) object:nil];

    self.syncing = NO;

    if (failed) {
        self.state = DWSyncModelState_SyncFailed;
    }
    else {
        self.state = DWSyncModelState_SyncDone;
    }
}

- (void)syncLoop {
    if (self.reachability.networkReachabilityStatus == DSReachabilityStatusNotReachable) {
        DWSyncLog(@"[DW Sync] Reachability: No Connection");

        self.state = DWSyncModelState_NoConnection;

        return;
    }

    const double progress = [self chainSyncProgress];

    DWSyncLog(@"[DW Sync] >>> %0.3f", progress);

    if (progress < DW_SYNCING_COMPLETED_PROGRESS) {
        self.syncing = YES;

        self.progress = progress;
        self.state = DWSyncModelState_Syncing;

        [self performSelector:@selector(syncLoop) withObject:nil afterDelay:SYNC_LOOP_INTERVAL];
    }
    else {
        self.progress = 1.0;
        self.state = DWSyncModelState_SyncDone;

        [self stopSyncingActivityFailed:NO];
    }
}

- (BOOL)shouldStopSyncing {
    const double progress = [self chainSyncProgress];

    if (progress > DBL_EPSILON && progress + DBL_EPSILON < 1.0) {
        return NO;
    }
    else {
        return YES;
    }
}

- (double)chainSyncProgress {
    const double progress = [DWEnvironment sharedInstance].currentChainManager.syncProgress;

    return progress;
}

@end

NS_ASSUME_NONNULL_END

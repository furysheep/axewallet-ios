//
//  DWStartModel.m
//  axewallet
//
//  Created by Andrew Podkovyrin on 10/11/2018.
//  Copyright © 2019 Axe Core. All rights reserved.
//

#import "DWStartModel.h"

#import "DWDataMigrationManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWStartModel ()

@property (assign, nonatomic) DWStartModelState state;

@end

@implementation DWStartModel

- (instancetype)initWithLaunchOptions:(NSDictionary *)launchOptions {
    self = [super init];
    if (self) {
        _deferredLaunchOptions = [launchOptions copy];
        _shouldMigrate = [DWDataMigrationManager sharedInstance].shouldMigrate;
        _applicationCrashedDuringLastMigration = ![DWDataMigrationManager sharedInstance].migrationSuccessful;
    }
    return self;
}

#pragma mark - Migration

- (void)startMigration {
    if (self.state != DWStartModelStateNone) {
        return;
    }

    self.state = DWStartModelStateInProgress;

#ifdef DEBUG
    NSDate *startTime = [NSDate date];
#endif /* DEBUG */

    __weak __typeof__(self) weakSelf = self;
    [[DWDataMigrationManager sharedInstance] migrate:^(BOOL completed) {
        __strong __typeof__(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

#ifdef DEBUG
        NSLog(@"⏲ Migration time: %f", -[startTime timeIntervalSinceNow]);
#endif /* DEBUG */

        strongSelf.state = DWStartModelStateDone;
    }];
}

- (void)cancelMigration {
    [[DWDataMigrationManager sharedInstance] destroyOldPersistentStore];
    self.state = DWStartModelStateDone;
}

- (void)cancelMigrationAndRescanBlockchain {
    [[DWDataMigrationManager sharedInstance] destroyOldPersistentStore];
    self.state = DWStartModelStateDoneAndRescan;
}

- (void)finalizeAsIs {
    self.state = DWStartModelStateDone;
}

@end

NS_ASSUME_NONNULL_END

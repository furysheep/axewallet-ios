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

#import "DWPaymentOutput+DWView.h"

#import <AxeSync/AxeSync.h>
#import <UIKit/UIKit.h>

#import "DWTitleDetailCellModel.h"
#import "DWTitleDetailItem.h"
#import "NSAttributedString+DWBuilder.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *sanitizeString(NSString *s) {
    NSMutableString *sane = [NSMutableString stringWithString:(s) ? s : @""];
    CFStringTransform((CFMutableStringRef)sane, NULL, kCFStringTransformToUnicodeName, NO);
    return sane;
}

@implementation DWPaymentOutput (DWView)

- (BOOL)hasCommonName {
    return self.name != nil;
}

- (uint64_t)amountToDisplay {
    return self.amount - self.fee;
}

- (nullable id<DWTitleDetailItem>)nameInfo {
    NSString *name = [self nameString];
    if (name == nil) {
        return nil;
    }

    DWTitleDetailCellModel *model =
        [[DWTitleDetailCellModel alloc] initWithStyle:DWTitleDetailItem_Default
                                  plainCenteredDetail:name];

    return model;
}

- (nullable id<DWTitleDetailItem>)generalInfo {
    NSString *detail = [self generalInfoString];
    if (detail == nil) {
        return nil;
    }

    DWTitleDetailCellModel *model =
        [[DWTitleDetailCellModel alloc] initWithStyle:DWTitleDetailItem_Default
                               plainLeftAlignedDetail:detail];

    return model;
}

- (nullable id<DWTitleDetailItem>)addressWithFont:(UIFont *)font tintColor:(UIColor *)tintColor {
    if (self.protocolRequest.commonName) {
        // don't show "send to" for BIP70 payment requests
        return nil;
    }
    else {
        NSString *title = NSLocalizedString(@"Send to", nil);
        NSString *address = self.address;
        NSAttributedString *detail = [NSAttributedString dw_axeAddressAttributedString:address withFont:font];
        DWTitleDetailCellModel *model =
            [[DWTitleDetailCellModel alloc] initWithStyle:DWTitleDetailItem_TruncatedSingleLine
                                                    title:title
                                         attributedDetail:detail];
        return model;
    }
}

- (nullable id<DWTitleDetailItem>)feeWithFont:(UIFont *)font tintColor:(UIColor *)tintColor {
    const uint64_t feeValue = self.fee;
    if (feeValue == 0) {
        return nil;
    }

    NSAttributedString *feeString = [NSAttributedString dw_axeAttributedStringForAmount:feeValue
                                                                               tintColor:tintColor
                                                                                    font:font];

    DWTitleDetailCellModel *fee =
        [[DWTitleDetailCellModel alloc] initWithStyle:DWTitleDetailItem_Default
                                                title:NSLocalizedString(@"Network fee", nil)
                                     attributedDetail:feeString];

    return fee;
}

- (id<DWTitleDetailItem>)totalWithFont:(UIFont *)font tintColor:(UIColor *)tintColor {
    NSAttributedString *detail = [NSAttributedString dw_axeAttributedStringForAmount:self.amount
                                                                            tintColor:tintColor
                                                                                 font:font];
    DWTitleDetailCellModel *total =
        [[DWTitleDetailCellModel alloc] initWithStyle:DWTitleDetailItem_Default
                                                title:NSLocalizedString(@"Total", nil)
                                     attributedDetail:detail];
    return total;
}

- (BOOL)copyAddressToPasteboard {
    NSString *address = self.address;
    NSParameterAssert(address);
    if (!address) {
        return NO;
    }

    [UIPasteboard generalPasteboard].string = address;

    return YES;
}

#pragma mark - Private

- (nullable NSString *)nameString {
    if (self.name.length > 0) {
        NSString *sanitizedName = sanitizeString(self.name);
        if (self.isSecure) {
            return [NSString stringWithFormat:@"🔒 %@", sanitizedName];
        }
        else {
            return sanitizedName;
        }
    }

    return nil;
}

- (nullable NSString *)generalInfoString {
    BOOL hasInfo = NO;
    NSString *info = @"";
    if (self.memo.length > 0) {
        info = sanitizeString(self.memo);
        hasInfo = YES;
    }

    DSPriceManager *priceManager = [DSPriceManager sharedInstance];
    if (self.localCurrency && ![self.localCurrency isEqualToString:priceManager.localCurrencyCode]) {
        NSString *requestedAmount = [[DSPriceManager sharedInstance] fiatCurrencyString:self.localCurrency forAxeAmount:self.amount];
        if (info.length > 0) {
            info = [info stringByAppendingString:@"\n"];
        }
        info = [info stringByAppendingFormat:NSLocalizedString(@"Local requested amount: %@", nil), requestedAmount];
        hasInfo = YES;
    }

    return hasInfo ? info : nil;
}

@end

NS_ASSUME_NONNULL_END

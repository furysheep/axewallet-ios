//
//  Created by Andrew Podkovyrin
//  Copyright © 2020 Axe Core Group. All rights reserved.
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

#import "DWUpholdTransactionObject+DWView.h"

#import "DWEnvironment.h"
#import "DWTitleDetailCellModel.h"
#import "DWTitleDetailItem.h"
#import "NSAttributedString+DWBuilder.h"

@implementation DWUpholdTransactionObject (DWView)

- (BOOL)hasCommonName {
    return NO;
}

- (uint64_t)amountToDisplay {
    NSDecimalNumber *haks = (NSDecimalNumber *)[NSDecimalNumber numberWithLongLong:HAKS];
    const uint64_t amountValue = [self.amount decimalNumberByMultiplyingBy:haks].longLongValue;

    return amountValue;
}

- (nullable id<DWTitleDetailItem>)nameInfo {
    return nil;
}

- (nullable id<DWTitleDetailItem>)generalInfo {
    if (![self feeWasDeductedFromAmount]) {
        return nil;
    }

    NSString *detail = NSLocalizedString(@"Fee will be deducted from requested amount.", nil);
    DWTitleDetailCellModel *info =
        [[DWTitleDetailCellModel alloc] initWithStyle:DWTitleDetailItem_Default
                                                title:nil
                                          plainDetail:detail];

    return info;
}

- (id<DWTitleDetailItem>)addressWithFont:(UIFont *)font tintColor:(UIColor *)tintColor {
    return nil;
}

- (nullable id<DWTitleDetailItem>)feeWithFont:(UIFont *)font tintColor:(UIColor *)tintColor {
    NSDecimalNumber *haks = (NSDecimalNumber *)[NSDecimalNumber numberWithLongLong:HAKS];
    const uint64_t feeValue = [self.fee decimalNumberByMultiplyingBy:haks].longLongValue;
    NSAttributedString *feeString = [NSAttributedString dw_axeAttributedStringForAmount:feeValue
                                                                               tintColor:tintColor
                                                                                    font:font];

    DWTitleDetailCellModel *fee =
        [[DWTitleDetailCellModel alloc] initWithStyle:DWTitleDetailItem_Default
                                                title:NSLocalizedString(@"Fee", nil)
                                     attributedDetail:feeString];

    return fee;
}

- (id<DWTitleDetailItem>)totalWithFont:(UIFont *)font tintColor:(UIColor *)tintColor {
    NSDecimalNumber *haks = (NSDecimalNumber *)[NSDecimalNumber numberWithLongLong:HAKS];
    const uint64_t totalValue = [self.total decimalNumberByMultiplyingBy:haks].longLongValue;
    NSAttributedString *detail = [NSAttributedString dw_axeAttributedStringForAmount:totalValue
                                                                            tintColor:tintColor
                                                                                 font:font];
    DWTitleDetailCellModel *total =
        [[DWTitleDetailCellModel alloc] initWithStyle:DWTitleDetailItem_Default
                                                title:NSLocalizedString(@"Total", nil)
                                     attributedDetail:detail];
    return total;
}

- (BOOL)copyAddressToPasteboard {
    // don't allow copying address
    return NO;
}

@end

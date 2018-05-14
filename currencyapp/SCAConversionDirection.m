//
//  SCAConversionDirection.m
//  currencyapp
//
//  Created by Виктор Стариков on 24.09.16.
//  Copyright © 2016 starikovvm. All rights reserved.
//

#import "SCAConversionDirection.h"


#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
NSString *const kRUBSymbol = @"RUB";
#pragma clang diagnostic pop
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
NSString *const kEURSymbol = @"EUR";
#pragma clang diagnostic pop
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
NSString *const kUSDSymbol = @"USD";
#pragma clang diagnostic pop


@implementation SCAConversionDirection

- (NSString *)description {
#pragma clang diagnostic push
#pragma ide diagnostic ignored "OCNotLocalizedStringInspection"
    return [NSString stringWithFormat:@"%@ → %@", self.fromSymbol, self.toSymbol];
#pragma clang diagnostic pop
}

+ (instancetype)conversionDirectionFrom:(NSString *)fromSymbol to:(NSString *)toSymbol {
    SCAConversionDirection *direction = [[self alloc] init];
    direction.fromSymbol = fromSymbol;
    direction.toSymbol = toSymbol;
    return direction;
}
@end

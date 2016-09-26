//
//  SCAConversionRate.m
//  currencyapp
//
//  Created by Виктор Стариков on 24.09.16.
//  Copyright © 2016 starikovvm. All rights reserved.
//

#import "SCAConversionRate.h"

@implementation SCAConversionRate

-(instancetype)initWithDictionary:(NSDictionary*)dictionary {
    self = [super init];
    if (self) {
        self.baseCurrency = [dictionary[@"base"] isKindOfClass:[NSString class]]?dictionary[@"base"]:nil;
        if ([dictionary[@"rates"] isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary* rates = [NSMutableDictionary new];
            //populate with NSDecimalNumber values, both strings and numbers should get formatted properly
            for (NSString* currencySymbol in dictionary[@"rates"]) {
                rates[currencySymbol] = [NSDecimalNumber decimalNumberWithString:[dictionary[@"rates"][currencySymbol] description]];
            }
            //make immutable
            self.currencyRates = [NSDictionary dictionaryWithDictionary:rates];
        }
    }
    return self;
}

-(NSDecimalNumber*)resultForConversionDirection:(SCAConversionDirection*)direction {
    if ([self.baseCurrency isEqualToString:direction.fromSymbol]) {
        return self.currencyRates[direction.toSymbol];
    } else if ([self.baseCurrency isEqualToString:direction.toSymbol]) {
        return [[NSDecimalNumber one] decimalNumberByDividingBy:self.currencyRates[direction.fromSymbol]];
    } else {
        return [self.currencyRates[direction.toSymbol] decimalNumberByDividingBy:self.currencyRates[direction.fromSymbol]];
    }
}
@end

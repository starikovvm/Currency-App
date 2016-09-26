//
//  SCAConversionDirection.m
//  currencyapp
//
//  Created by Виктор Стариков on 24.09.16.
//  Copyright © 2016 starikovvm. All rights reserved.
//

#import "SCAConversionDirection.h"

NSString* const kRUBSymbol = @"RUB";
NSString* const kEURSymbol = @"EUR";
NSString* const kUSDSymbol = @"USD";

@implementation SCAConversionDirection

-(NSString *)description {
    return [NSString stringWithFormat:@"%@ → %@", self.fromSymbol, self.toSymbol];
}

+(instancetype)conversionDirectionFrom:(NSString*)fromSymbol to:(NSString*)toSymbol {
    SCAConversionDirection* direction = [[self alloc] init];
    direction.fromSymbol = fromSymbol;
    direction.toSymbol = toSymbol;
    return direction;
}
@end

//
//  SCAConversionRate.h
//  currencyapp
//
//  Created by Виктор Стариков on 24.09.16.
//  Copyright © 2016 starikovvm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCAConversionDirection.h"

@interface SCAConversionRate : NSObject

-(instancetype)initWithDictionary:(NSDictionary*)dictionary;

@property (strong, nonatomic) NSString *baseCurrency;
@property (strong, nonatomic) NSDictionary<NSString*,NSDecimalNumber*> *currencyRates;
-(NSDecimalNumber*)resultForConversionDirection:(SCAConversionDirection*)direction;
@end

//
//  SCAConversionDirection.h
//  currencyapp
//
//  Created by Виктор Стариков on 24.09.16.
//  Copyright © 2016 starikovvm. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSString* const kRUBSymbol;
FOUNDATION_EXTERN NSString* const kEURSymbol;
FOUNDATION_EXTERN NSString* const kUSDSymbol;

@interface SCAConversionDirection : NSObject
@property (strong, nonatomic) NSString *fromSymbol;
@property (strong, nonatomic) NSString *toSymbol;
+(instancetype)conversionDirectionFrom:(NSString*)fromSymbol to:(NSString*)toSymbol;
@end

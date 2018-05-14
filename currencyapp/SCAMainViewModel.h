//
//  SCAMainViewModel.h
//  currencyapp
//
//  Created by Виктор Стариков on 23.09.16.
//  Copyright © 2016 starikovvm. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SCAMainViewModel : NSObject

//Contains strings representing conversion directions
@property (strong, nonatomic) RACSequence *possibleConversionDirectionsSequence;

//Contains index of current conversion direction in possibleConversionDirectionsSequence
@property (strong, nonatomic) RACSignal *currentConversionDirectionSignal;

//BOOL
@property (strong, nonatomic) RACSignal *showCurrencySelectionSignal;

//Result for conversion, NSDecimalNumber
@property (strong, nonatomic) RACSignal *todayPriceSignal;

//Result for conversion, NSDecimalNumber
@property (strong, nonatomic) RACSignal *yesterdayPriceSignal;

@property (assign, nonatomic) NSUInteger currentConversionDirectionIndex;
@property (strong, nonatomic) NSDate *dataUpdatedDate;

- (void)toggleShowCurrencySelection;
- (NSString *)currentToSymbolString;

@end

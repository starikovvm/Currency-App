//
//  currencyappTests.m
//  currencyappTests
//
//  Created by Виктор Стариков on 23.09.16.
//  Copyright © 2016 starikovvm. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "SCAConversionRate.h"
#import "SCAMainViewModel.h"

@interface SCAMainViewModel (hidden)
- (RACSignal *)fetchJSONFromURL:(NSURL *)url;
- (RACSignal *)fetchYesterdayRatesWithToday:(NSString*)today;
@end

@interface currencyappTests : XCTestCase
@property (strong, nonatomic) SCAMainViewModel *viewModel;

@end

@implementation currencyappTests

- (void)setUp {
    [super setUp];
    self.viewModel = [[SCAMainViewModel alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

-(void)testCurrencyConversion {
    SCAConversionRate* rate = [[SCAConversionRate alloc] init];
    rate.baseCurrency = kUSDSymbol;
    NSDecimalNumber* euroRate = [NSDecimalNumber decimalNumberWithString:@"0.89174"];
    NSDecimalNumber* rubleRate = [NSDecimalNumber decimalNumberWithString:@"63.51"];
    rate.currencyRates = @{kEURSymbol:euroRate, kRUBSymbol:rubleRate};
    
    NSDecimalNumber* dollarEuroConversionResult = [rate resultForConversionDirection:[SCAConversionDirection conversionDirectionFrom:kUSDSymbol to:kEURSymbol]];
    XCTAssertEqual(euroRate, dollarEuroConversionResult, @"Conversion from base rate failed");
    
    NSDecimalNumber* euroDollarConversionResult = [rate resultForConversionDirection:[SCAConversionDirection conversionDirectionFrom:kEURSymbol to:kUSDSymbol]];
    XCTAssertEqualWithAccuracy([[euroDollarConversionResult stringValue] floatValue], 1.1214, 0.001, @"Conversion to base value failed");
    
    NSDecimalNumber* rubleConversionResult = [rate resultForConversionDirection:[SCAConversionDirection conversionDirectionFrom:kEURSymbol to:kRUBSymbol]];
    XCTAssertEqualWithAccuracy([[rubleConversionResult stringValue] floatValue], 71.22, 0.001, @"Conversion between non-base values failed");
}

-(void)testJSONFetch {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Json fetching works"];
    [[self.viewModel fetchJSONFromURL:[NSURL URLWithString:@"https://jsonplaceholder.typicode.com/users"]] subscribeNext:^(id response) {
        XCTAssertNotNil(response, @"Failed to fetch json");
        [expectation fulfill];
    } error:^(NSError *error) {
        XCTFail(@"Download Failed with error: %@", error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        if(error)
        {
            XCTFail(@"Expectation Failed with error: %@", error);
        }
    }];
}

-(void)testYesterdayPriceFetch {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Yesterday fetching works"];
    [[self.viewModel fetchYesterdayRatesWithToday:@"2016-01-01"] subscribeNext:^(id response) {
        XCTAssertNotNil(response, @"Failed to fetch json");
        XCTAssertEqualObjects(response[@"date"], @"2015-12-31", @"Fetched for wrong date");
        [expectation fulfill];
    } error:^(NSError *error) {
        XCTFail(@"Download Failed with error: %@", error);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTFail(@"Expectation Failed with error: %@", error);
    }];
}

@end

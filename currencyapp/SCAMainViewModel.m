//
//  SCAMainViewModel.m
//  currencyapp
//
//  Created by Виктор Стариков on 23.09.16.
//  Copyright © 2016 starikovvm. All rights reserved.
//

#import "SCAMainViewModel.h"
#import "SCAConversionRate.h"

NSString* const kTodayURLString = @"https://api.fixer.io/latest?symbols=EUR,RUB&base=USD";
NSString* const kDateURLFormatString = @"https://api.fixer.io/%@?symbols=EUR,RUB&base=USD";


@interface SCAMainViewModel ()
@property (strong, readonly) NSArray<SCAConversionDirection*>* possibleConversionDirections;
//@property (strong, nonatomic) SCAConversionDirection* currentConversionDirection;
@property (strong, nonatomic) SCAConversionRate *todayConversionRate;
@property (strong, nonatomic) SCAConversionRate *yesterdayConversionRate;
@property (nonatomic) BOOL showCurrencySelection;

@end

@implementation SCAMainViewModel

-(NSArray<SCAConversionDirection *> *)possibleConversionDirections {
    static NSArray* conversionDirections;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        conversionDirections = @[[SCAConversionDirection conversionDirectionFrom:kUSDSymbol to:kRUBSymbol],
                                 [SCAConversionDirection conversionDirectionFrom:kUSDSymbol to:kEURSymbol],
                                 [SCAConversionDirection conversionDirectionFrom:kEURSymbol to:kRUBSymbol],
                                 [SCAConversionDirection conversionDirectionFrom:kEURSymbol to:kUSDSymbol],
                                 [SCAConversionDirection conversionDirectionFrom:kRUBSymbol to:kUSDSymbol],
                                 [SCAConversionDirection conversionDirectionFrom:kRUBSymbol to:kEURSymbol]
                                 ];
    });
    return conversionDirections;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

-(void)initialize {
    @weakify(self);
    self.currentConversionDirectionIndex = 0;
    self.showCurrencySelection = NO;
    self.possibleConversionDirectionsSequence = [[self.possibleConversionDirections rac_sequence] map:^id(id value) {
        return [value description];
    }];
    
    self.currentConversionDirectionSignal = [RACObserve(self, currentConversionDirectionIndex) deliverOnMainThread];
    
    self.showCurrencySelectionSignal = [RACObserve(self, showCurrencySelection) deliverOnMainThread];
    
    RACSignal* fetchTodayPriceSignal = [[[self fetchJSONFromURL:[NSURL URLWithString:kTodayURLString]] doNext:^(id response) {
        @strongify(self);
        if ([response isKindOfClass:[NSDictionary class]]) {
            NSLog(@"Response %@",response);
            SCAConversionRate* todayConvertionRate = [[SCAConversionRate alloc] initWithDictionary:response];
            if (todayConvertionRate.baseCurrency && todayConvertionRate.currencyRates) {
                self.todayConversionRate = todayConvertionRate;
            }
        }
    }] deliverOnMainThread];
    
    self.todayPriceSignal = [[RACSignal combineLatest:@[RACObserve(self, todayConversionRate), RACObserve(self, currentConversionDirectionIndex)] reduce:^id{
        @strongify(self);
        return [self.todayConversionRate resultForConversionDirection:self.possibleConversionDirections[self.currentConversionDirectionIndex]];
    }] deliverOnMainThread];
    
    RACSignal* fetchYesterdayPriceSignal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
      return [fetchTodayPriceSignal subscribeNext:^(id x) {
          @strongify(self);
          [[self fetchYesterdayRatesWithToday:x[@"date"]] subscribeNext:^(id yesterdayResponse) {
              if ([yesterdayResponse isKindOfClass:[NSDictionary class]]) {
                  NSLog(@"Response %@",yesterdayResponse);
                  SCAConversionRate* yesterdayConvertionRate = [[SCAConversionRate alloc] initWithDictionary:yesterdayResponse];
                  if (yesterdayConvertionRate.baseCurrency && yesterdayConvertionRate.currencyRates) {
                      self.yesterdayConversionRate = yesterdayConvertionRate;
                      self.dataUpdatedDate = [NSDate date];
                  }
                  [subscriber sendNext:self.yesterdayConversionRate];
              }
          } error:^(NSError *error) {
              [subscriber sendError:error];
          } completed:^{
              [subscriber sendCompleted];
          }];
      } error:^(NSError *error) {
          [subscriber sendError:error];
      }];
    }] deliverOnMainThread];
    
    self.yesterdayPriceSignal = [[RACSignal combineLatest:@[RACObserve(self, yesterdayConversionRate), RACObserve(self, currentConversionDirectionIndex), fetchYesterdayPriceSignal] reduce:^id{
        @strongify(self);
        //(today/yesterday-1)*100
        NSDecimalNumber* yesterdayPrice = [self.yesterdayConversionRate resultForConversionDirection:self.possibleConversionDirections[self.currentConversionDirectionIndex]];
        NSDecimalNumber* todayPrice = [self.todayConversionRate resultForConversionDirection:self.possibleConversionDirections[self.currentConversionDirectionIndex]];
        
        return [[[todayPrice decimalNumberByDividingBy:yesterdayPrice] decimalNumberBySubtracting:[NSDecimalNumber one]] decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]];
    }] deliverOnMainThread];
    
}

-(void)setCurrentConversionDirectionIndex:(NSInteger)currentConversionDirectionIndex {
    _currentConversionDirectionIndex = currentConversionDirectionIndex;
    [self toggleShowCurrencySelection];
}

-(void)toggleShowCurrencySelection {
    self.showCurrencySelection = !self.showCurrencySelection;
}

-(NSString*)currentToSymbolString {
    return self.possibleConversionDirections[self.currentConversionDirectionIndex].toSymbol;
}

#pragma mark - Data downlooading

//Executes GET request and returns a deserialized object
- (RACSignal *)fetchJSONFromURL:(NSURL *)url {
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (! error) {
                NSError *jsonError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                if (! jsonError) {
                    [subscriber sendNext:json];
                }
                else {
                    [subscriber sendError:jsonError];
                }
            }
            else {
                [subscriber sendError:error];
            }
            
            [subscriber sendCompleted];
        }];
        
        [dataTask resume];
        
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }];
}


-(RACSignal*)fetchYesterdayRatesWithToday:(NSString*)today {
    RACSignal* signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
        NSDate* todayDate = [dateFormatter dateFromString:today];
        if (!todayDate) {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Date formatting error"};
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:10 userInfo:userInfo];
            [subscriber sendError:error];
            return [RACDisposable disposableWithBlock:^{
            }];
        }
        NSDate* yesterdayDate = [todayDate dateByAddingTimeInterval:-60*60*24];
        NSString* yesterdayString = [dateFormatter stringFromDate:yesterdayDate];
        NSString* urlString = [NSString stringWithFormat:kDateURLFormatString, yesterdayString];
        return [[self fetchJSONFromURL:[NSURL URLWithString:urlString]] subscribeNext:^(id response) {
            [subscriber sendNext:response];
        } error:^(NSError *error) {
            [subscriber sendError:error];
        } completed:^{
            [subscriber sendCompleted];
        }];
        
    }];
    return signal;
}

@end

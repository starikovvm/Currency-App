//
//  SCAMainViewController.m
//  currencyapp
//
//  Created by Виктор Стариков on 23.09.16.
//  Copyright © 2016 starikovvm. All rights reserved.
//

#import "SCAMainViewController.h"
#import "SCACurrencySelectTableViewCell.h"
#import "SCAMainViewModel.h"

@interface SCAMainViewController () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>
@property (strong, nonatomic) IBOutlet UITableView *currencySelectTableView;
@property (strong, nonatomic) IBOutlet UIButton *selectCurrencyButton;
@property (strong, nonatomic) IBOutlet UILabel *currentConversionDirectionLabel;
@property (strong, nonatomic) IBOutlet UILabel *yesterdayDifferenceLabel;
@property (strong, nonatomic) IBOutlet UILabel *priceLabel;
@property (strong, nonatomic) IBOutlet UILabel *updateDateLabel;
@property (strong, nonatomic) UIGestureRecognizer *tapRecognizer;


@property (strong, nonatomic) NSArray<NSLayoutConstraint*> *verticalConstraints;

@property (strong, nonatomic) NSNumberFormatter *priceNumberFormatter;
@property (strong, nonatomic) NSNumberFormatter *percentNumberFormatter;


@property (strong, nonatomic) SCAMainViewModel *viewModel;

@end

@implementation SCAMainViewController

static const CGFloat kTableViewCellHeight = 43.0;

- (void)viewDidLoad {
    [super viewDidLoad];
    @weakify(self);
    
    self.viewModel = [SCAMainViewModel new];
    
    [self.currencySelectTableView registerNib:[UINib nibWithNibName:@"SCACurrencySelectTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"SCACurrencySelectTableViewCell"];
    self.currencySelectTableView.backgroundColor = self.currencySelectTableView.separatorColor = [UIColor blackColor];
    
    self.priceLabel.text = @"";
    self.yesterdayDifferenceLabel.text = @"";
    
    RAC(self.updateDateLabel, text, [NSLocalizedString(@"DATA_UPDATING", @"data updating status message") uppercaseString]) = [[RACObserve(self.viewModel, dataUpdatedDate) map:^NSString*(NSDate* date) {
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        NSString* dateString = [dateFormatter stringFromDate:date];
        if (!dateString) {
            return nil;
        }
        return [[NSString stringWithFormat:NSLocalizedString(@"DATA_UPDATED_AT", @"%@ for time/date value"), dateString] uppercaseString];
    }] deliverOnMainThread];
    
    [self.viewModel.currentConversionDirectionSignal subscribeNext:^(NSNumber* index) {
        @strongify(self);
        [self.currencySelectTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[index integerValue] inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
        self.currentConversionDirectionLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.possibleConversionDirectionsSequence.array[[index integerValue]]?:@"" attributes:[self currentConversionDirectionLabelTextAttributes]];
    }];
    
    [self.viewModel.todayPriceSignal subscribeNext:^(NSDecimalNumber* todayPrice) {
        @strongify(self);
        NSString* priceString = [self.priceNumberFormatter stringFromNumber:todayPrice]?:@"";
        self.priceLabel.attributedText = [[NSAttributedString alloc] initWithString:priceString attributes:[self priceLabelTextAttributes]];
    } error:^(NSError *error) {
        @strongify(self);
        self.updateDateLabel.text = NSLocalizedString(@"EROR_TODAY_PRICE", @"Error while fetching today price");
    }];
    
    [self.viewModel.yesterdayPriceSignal subscribeNext:^(NSDecimalNumber* yesterdayPrice) {
        @strongify(self);
        self.yesterdayDifferenceLabel.text  = [self.priceNumberFormatter stringFromNumber:yesterdayPrice];
        
        NSString* formatString;
        if ([yesterdayPrice compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
            formatString = NSLocalizedString(@"PRICE_GREATER_THAN_YESTERDAY", @"first %@ for currency, second %@ for percentage");
            static UIColor* positiveColor;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                positiveColor = [UIColor colorWithRed:126.0/255.0 green:211.0/255.0 blue:33.0/255.0 alpha:1.0];
            });
            self.yesterdayDifferenceLabel.textColor = positiveColor;
        } else {
            formatString = NSLocalizedString(@"PRICE_LESS_THAN_YESTERDAY", @"first %@ for currency, second %@ for percentage");
            static UIColor* negativeColor;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                negativeColor = [UIColor colorWithRed:208.0/255.0 green:2.0/255.0 blue:27.0/255.0 alpha:1.0];
            });
            self.yesterdayDifferenceLabel.textColor = negativeColor;
        }
        self.yesterdayDifferenceLabel.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:formatString, NSLocalizedString([self.viewModel currentToSymbolString], nil), [[self.percentNumberFormatter stringFromNumber:yesterdayPrice] integerValue]] attributes:[self yesterdayDifferenceLabelTextAttributes]];
    } error:^(NSError *error) {
        @strongify(self);
        self.updateDateLabel.text = NSLocalizedString(@"EROR_YESTERDAY_PRICE", @"Error while fetching yesterday price");
    }];
    
    [self.viewModel.showCurrencySelectionSignal subscribeNext:^(NSNumber* showSelection) {
        @strongify(self);
        [self setDateSelectionHidden:![showSelection boolValue] animated:self.verticalConstraints?YES:NO];
    }];
    
    [self.selectCurrencyButton addTarget:self.viewModel action:@selector(toggleShowCurrencySelection) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(NSNumberFormatter *)priceNumberFormatter {
    if (!_priceNumberFormatter) {
        _priceNumberFormatter = [[NSNumberFormatter alloc] init];
        _priceNumberFormatter.minimumFractionDigits = _priceNumberFormatter.maximumFractionDigits = 3;
        _priceNumberFormatter.minimumIntegerDigits = 1;
        _priceNumberFormatter.decimalSeparator = @",";
    }
    return _priceNumberFormatter;
}

-(NSNumberFormatter*)percentNumberFormatter {
    if (!_percentNumberFormatter) {
        _percentNumberFormatter = [[NSNumberFormatter alloc] init];
        _percentNumberFormatter.maximumFractionDigits = _percentNumberFormatter.minimumFractionDigits = 0;
        _percentNumberFormatter.roundingMode = NSNumberFormatterRoundHalfEven;
        _percentNumberFormatter.negativePrefix = @"";
    }
    return _percentNumberFormatter;
}

-(void)setDateSelectionHidden:(BOOL)hidden animated:(BOOL)animated {
    
    [self.view removeConstraints:self.verticalConstraints];
    NSMutableArray* newConstraints = [NSMutableArray new];
    
    NSLayoutConstraint* tableViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.currencySelectTableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:hidden?0:(self.viewModel.possibleConversionDirectionsSequence.array.count*kTableViewCellHeight)];
    [newConstraints addObject:tableViewHeightConstraint];
    
    if (!hidden) {
        NSLayoutConstraint* mainViewConstraint = [NSLayoutConstraint constraintWithItem:self.currencySelectTableView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self.yesterdayDifferenceLabel attribute:NSLayoutAttributeLastBaseline multiplier:1.0 constant:20.0];
        [newConstraints addObject:mainViewConstraint];
    }
    
    self.verticalConstraints = newConstraints;
    [self.view addConstraints:newConstraints];
    
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            [self.view layoutIfNeeded];
        }];
    } else {
        [self.view layoutIfNeeded];
    }
    if (hidden) {
        [self.view removeGestureRecognizer:self.tapRecognizer];
    } else {
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self.viewModel action:@selector(toggleShowCurrencySelection)];
        self.tapRecognizer.cancelsTouchesInView = NO;
        self.tapRecognizer.delegate = self;
        [self.view addGestureRecognizer:self.tapRecognizer];
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return !CGRectContainsPoint(self.currencySelectTableView.frame, [touch locationInView:self.view]);
}

#pragma mark - Label text attributes

-(NSDictionary*)priceLabelTextAttributes {
    return @{NSKernAttributeName:@(-4)};
}

-(NSDictionary *)currentConversionDirectionLabelTextAttributes {
    return @{NSKernAttributeName:@(1)};
}

-(NSDictionary *)yesterdayDifferenceLabelTextAttributes {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineHeightMultiple = 1.21;
    style.alignment = NSTextAlignmentCenter;
    return @{NSParagraphStyleAttributeName:style};
}

#pragma mark - UITableViewDataSource
#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.possibleConversionDirectionsSequence.array.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SCACurrencySelectTableViewCell";
    SCACurrencySelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kTableViewCellHeight;
}

#pragma mark - UITableViewDelegate
#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.viewModel.currentConversionDirectionIndex = indexPath.row;
    
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(SCACurrencySelectTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.currencyLabel.text = self.viewModel.possibleConversionDirectionsSequence.array[indexPath.row];
}

@end

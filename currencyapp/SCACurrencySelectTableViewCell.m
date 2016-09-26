//
//  SCACurrencySelectTableViewCell.m
//  currencyapp
//
//  Created by Виктор Стариков on 23.09.16.
//  Copyright © 2016 starikovvm. All rights reserved.
//

#import "SCACurrencySelectTableViewCell.h"

@implementation SCACurrencySelectTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    self.currencyLabel.font = [UIFont fontWithName:selected?@"Lato-Black":@"Lato-Regular" size:17.0];
}

@end

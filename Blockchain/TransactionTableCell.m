//
//  TransactionTableCell.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "TransactionTableCell.h"
#import "Transaction.h"
#import "AppDelegate.h"
#import "Output.h"
#import "Input.h"
#import "NSDate+Extensions.h"
#import "TransactionsViewController.h"

#define MAX_ADDRESS_ROWS_PER_CELL 5

@implementation TransactionTableCell

@synthesize transaction;

- (void)awakeFromNib
{
    labels = [[NSMutableArray alloc] initWithCapacity:5];
}

- (void)reload
{
    if (transaction == NULL)
        return;
    
    float y = 30;
    
    if (transaction.time > 0)  {
        [dateButton setHidden:FALSE];
        [dateButton setTitle:[[NSDate dateWithTimeIntervalSince1970:transaction.time] shortHandDateWithTime] forState:UIControlStateNormal];
    } else {
        [dateButton setHidden:TRUE];
    }
    
    [btcButton setTitle:[app formatMoney:transaction.result] forState:UIControlStateNormal];
    [btcButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [btcButton.titleLabel setMinimumScaleFactor:.5f];
    
    for (UILabel * label in labels) {
        [label removeFromSuperview];
    }
    
    // Payment Received
    if (transaction.result >= 0) {
        
        if (transaction.result == 0) {
            [transactionTypeLabel setText:BC_STRING_TRANSACTION_MOVED];
            [btcButton setBackgroundColor:COLOR_BUTTON_LIGHT_BLUE];
        } else {
            [transactionTypeLabel setText:@""];
            [btcButton setBackgroundColor:COLOR_BUTTON_GREEN];
        }
        
        NSArray * inputs = [transaction inputsNotFromAddresses:[[app transactionsViewController].data addresses]];
        
        if ([inputs count] == 0) {
            inputs = transaction.inputs;
        }
        
        // Show the inouts i.e. where the coins are from
        for (NSInteger i = 0; i < [inputs count] && i <= MAX_ADDRESS_ROWS_PER_CELL; i++)
        {
            UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 280, 20)];
            [label setFont:[UIFont systemFontOfSize:13]];
            [label setTextColor:[UIColor darkGrayColor]];
            label.adjustsFontSizeToFitWidth = YES;
            
            if (i == MAX_ADDRESS_ROWS_PER_CELL) {
                [label setText:[NSString stringWithFormat:BC_STRING_COUNT_MORE, [inputs count] - i]];
            }
            else {
                Input *input = [inputs objectAtIndex:i];
                NSString *addressString = [app.wallet labelForAddress:[[input prev_out] addr]];
                
                if ([addressString length] > 0)
                    [label setText:addressString];
                else
                    [label setText:[[input prev_out] addr]];
            }
            
            [labels addObject:label];
            [self addSubview:label];
            
            y += 22;
        }
    } else if (transaction.result < 0) {
        
        NSArray * outputs = [transaction outputsNotToAddresses:[app transactionsViewController].data.addresses];
        
        if ([outputs count] == 0) {
            [transactionTypeLabel setText:BC_STRING_TRANSACTION_MOVED];
            [btcButton setBackgroundColor:COLOR_BUTTON_LIGHT_BLUE];
        } else {
            [transactionTypeLabel setText:@""];
            [btcButton setBackgroundColor:COLOR_BUTTON_RED];
        }
        
        // Show the addresses involved anyway
        if ([outputs count] == 0) {
            outputs = transaction.outputs;
        }
        
        // limit to MAX_ADDRESS_ROWS_PER_CELL outputs
        for (NSInteger i = 0; i < [outputs count] && i < MAX_ADDRESS_ROWS_PER_CELL; i++)
        {
            UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 280, 20)];
            [label setFont:[UIFont systemFontOfSize:13]];
            [label setTextColor:[UIColor darkGrayColor]];
            label.adjustsFontSizeToFitWidth = YES;
            
            if (i == MAX_ADDRESS_ROWS_PER_CELL) {
                [label setText:[NSString stringWithFormat:BC_STRING_COUNT_MORE, [outputs count] - i]];
            } else {
                Output *output = [outputs objectAtIndex:i];
                NSString * addressString = [app.wallet labelForAddress:[output addr]];
                
                if ([addressString length] > 0)
                    [label setText:addressString];
                else
                    [label setText:[output addr]];
            }
            
            [labels addObject:label];
            [self addSubview:label];
            
            y += 22;
        }
    }
    
    y += 5;
    
    // Make the transaction lable minimal size to fit the text, then move it to it's position on the right and resize and move the date label to use up the rest of the space
    [transactionTypeLabel sizeToFit];
    float transactionTypeLabelX = self.frame.size.width - transactionTypeLabel.frame.size.width - 20;
    [transactionTypeLabel setFrame:CGRectMake(transactionTypeLabelX, transactionTypeLabel.frame.origin.y, transactionTypeLabel.frame.size.width, transactionTypeLabel.frame.size.height)];
    
    [dateButton setFrame:CGRectMake(20, dateButton.frame.origin.y, transactionTypeLabelX - 20 - 5, dateButton.frame.size.height)];
    
    // Move down the btc button and the confirmations label according to the number of inouts from above
    [btcButton setFrame:CGRectMake(btcButton.frame.origin.x, y, btcButton.frame.size.width, btcButton.frame.size.height)];
    
    [confirmationsLabel setFrame:CGRectMake(confirmationsLabel.frame.origin.x, y, confirmationsLabel.frame.size.width, confirmationsLabel.frame.size.height)];
}

- (void)seLatestBlock:(LatestBlock*)block
{
    // Hide confirmations if we're offline
    if (!block) {
        [confirmationsLabel setHidden:TRUE];
        return;
    }
    
    int confirmations = block.height - transaction.block_height + 1;
    
    if (confirmations <= 0 || transaction.block_height == 0) {
        [confirmationsLabel setHidden:FALSE];
        
        confirmationsLabel.textColor = [UIColor redColor];
        confirmationsLabel.text = BC_STRING_UNCONFIRMED;
    }
    else if (confirmations < 100) {
        [confirmationsLabel setHidden:FALSE];
        
        confirmationsLabel.textColor = [UIColor darkGrayColor];
        confirmationsLabel.text = [NSString stringWithFormat:BC_STRING_COUNT_CONFIRMATIONS, confirmations];
    }
    else {
        [confirmationsLabel setHidden:YES];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#pragma mark button interactions

- (IBAction)transactionClicked:(UIButton *)button
{
    [app pushWebViewController:[WebROOT stringByAppendingFormat:@"tx/%@", transaction.myHash]];
}

- (IBAction)btcbuttonclicked:(id)sender
{
    [app toggleSymbol];
}

@end

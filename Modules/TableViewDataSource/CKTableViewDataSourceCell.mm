//
//  CKTableViewDataSourceCell.mm
//  CKToolbox
//
//  Created by Jonathan Crooke on 17/01/2016.
//  Copyright (c) 2016 Jonathan Crooke. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import <CKToolbox/CKTableViewDataSourceCell.h>
#import <CKToolbox/CKTableViewTransactionalDataSourceCellConfiguration.h>
#import <ComponentKit/CKComponentRootView.h>

@implementation CKTableViewDataSourceCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
    // @see Note in CKCollectionViewDataSourceCell.m - no more elegant way to do this
    _rootView = [[CKComponentRootView alloc] initWithFrame:CGRectZero];
    [[self contentView] addSubview:_rootView];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  const CGSize size = [[self contentView] bounds].size;
  [_rootView setFrame:CGRectMake(0, 0, size.width, size.height)];
}

@end

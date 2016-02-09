//
//  CKToolboxCellConfiguration.h
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

#import <UIKit/UIKit.h>

/**
 *	A function that can be used to customize the cell's appearance.
 *  @param cell The UITableViewCell to be displayed
 *  @param indexPath The indexPath for the cell
 *  @param model The cell's model.
 *  @note This is be used very conservatively since this could quite easily
 *  cause unwanted side-effects with cell reuse, since no attempts are made
 *  to undo settings applied here.
 */
typedef void(*CKTableViewCellConfigurationFunction)(UITableViewCell *cell, NSIndexPath *indexPath, id<NSObject> model);

/**
 Configuration value object that wraps most that should be necessary to customize
 the cell's "out of the box" features.

 @note Properties are mutable for convenience when instantiating. However, 
 CKTableViewTransactionalDataSource always returns a copy from its -cellConfiguration 
 property. Mutate the copy and pass it in an update operation to override the default.
 */
@interface CKTableViewTransactionalDataSourceCellConfiguration : NSObject
@property (nonatomic, assign) UITableViewRowAnimation animationRowInsert;
@property (nonatomic, assign) UITableViewRowAnimation animationRowDelete;
@property (nonatomic, assign) UITableViewRowAnimation animationSectionInsert;
@property (nonatomic, assign) UITableViewRowAnimation animationSectionDelete;
/** If `YES`, will perform updates with `+[UIView performWithoutAnimation:]` */
@property (nonatomic, assign) BOOL animationsDisabled;
@property (nonatomic, assign) CKTableViewCellConfigurationFunction cellConfigurationFunction;
@end

/**
 The cell configuration object can be set as a constant value when the data source
 is created, or can also be updated when passed in a data source apply method
 using this userInfo dictionary key.
 */
extern NSString *const CKTableViewTransactionalDataSourceCellConfigurationKey;

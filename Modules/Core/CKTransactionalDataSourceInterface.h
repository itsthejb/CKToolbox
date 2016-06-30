//
//  CKTransactionalDataSourceInterface.h
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
#import "CKUpdateMode.h"

@class CKTransactionalComponentDataSourceChangeset;
@class CKTransactionalComponentDataSourceConfiguration;

/**
 Abstract interface for the essential parts of both CKCollectionViewTransactionalDataSource
 and CKTableViewTransactionalDataSource.
 If you should, for example, wish to create a controller which is agnostic of either a collection,
 table, or future other collection-based view (?), you could provide an output of type
 id <CKTransactionalDataSourceInterface>.
 */
@protocol CKTransactionalDataSourceInterface <NSObject>
/**
 Applies a changeset either synchronously or asynchronously to the view.
 If a synchronous changeset is applied while asynchronous changesets are still pending, then the pending changesets will be applied synchronously
 before the new changeset is applied.
 */
- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo;

/**
 @return The model associated with a certain index path in the view.

 As stated above components are generated asynchronously and on a background thread. This means that a changeset is enqueued
 and applied asynchronously when the corresponding component tree is generated. For this reason always use this method when you
 want to retrieve the model associated to a certain index path in the view (e.g in didSelectRowAtIndexPath: )
 */
- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath;

/**
 @return The layout size of the component tree at a certain indexPath.
 */
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

/** @see `CKTransactionalComponentDataSource` */
- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo;

/** @see `CKTransactionalComponentDataSource` */
- (void)updateConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo;

/**
 Simply returns a changeset that can be applied to remove
 all content for the current state of a data source.
 */
- (CKTransactionalComponentDataSourceChangeset*)removeAllChangeset;

/** Represents the underlying UIKit "collection" view, ie. a UICollectionView or UITableView */
@property (readonly, nonatomic, strong) UIView *view;

@end

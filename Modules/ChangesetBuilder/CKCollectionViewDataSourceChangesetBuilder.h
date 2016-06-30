//
//  CKCollectionViewDataSourceChangesetBuilder.h
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

@class CKTransactionalComponentDataSourceChangeset;

/**
 Block-based DSL changeset builder.
 */
@interface CKCollectionViewDataSourceChangesetBuilder : NSObject

/**
 Convenience method for one-off changeset creation.
 @see Instance method for more information.
 */
+ (CKTransactionalComponentDataSourceChangeset*)build:(void(^)(CKCollectionViewDataSourceChangesetBuilder *builder))block;

/**
 Instance method builder is intended to be used as a local variable.
 For example, it might be used within a loop to add various items.
 Expressions are natural language of the form(s):
 
 [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
   builder.insert.section.at.index(0);
   builder.insert.item(@"Foo").at.indexPath([NSIndexPath indexPathForItem:1 inSection:4]);
   builder.remove.section.at.index(1);
   builder.move.section.at.index(0).to.index(4);
 }];
 
 @note Prepositions are optional, but recommended.
 @see CKTransactionalComponentDataSourceChangesetBuilderTests for examples.
*/
- (instancetype)build:(void(^)(CKCollectionViewDataSourceChangesetBuilder *builder))block;

- (CKTransactionalComponentDataSourceChangeset *)build;

/** Verbs */
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *update;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *insert;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *remove;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *move;

/** Nouns */
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *section;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *sections;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *(^item)(id item);
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *(^items)(id itemsOrMap);
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *(^index)(NSUInteger index);
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *(^indexes)(NSIndexSet *indexSet);
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *(^indexPath)(NSIndexPath *indexPath);
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *(^indexPaths)(NSArray *indexPaths);

/** 
 Prepositions 
 @note Optional, but certainly aid natural language readibility
 */
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *at;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *to;
@property (nonatomic, strong, readonly) CKCollectionViewDataSourceChangesetBuilder *with;

@end

/**
 Additional syntactic sugar
 */
#define ck_indexPath(ITEM, SECTION)		indexPath([NSIndexPath indexPathForItem:ITEM inSection:SECTION])
#define ck_indexPaths(ITEM, SECTION)	indexPath([NSIndexPath indexPathForItem:ITEM inSection:SECTION])
#define ck_removeItem 								remove.item(nil)
#define ck_removeItems								remove.items(nil)
#define ck_moveItem 									move.item(nil)

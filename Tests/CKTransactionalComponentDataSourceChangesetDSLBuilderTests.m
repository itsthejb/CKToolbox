//
//  CKTransactionalComponentDataSourceChangesetDSLBuilderTests.m
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

#import <XCTest/XCTest.h>

#import <CKToolbox/CKCollectionViewDataSourceChangesetBuilder.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangeset.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangesetInternal.h>

static NSIndexPath *indexPath(NSInteger item, NSInteger section) {
  return [NSIndexPath indexPathForItem:item inSection:section];
}

@interface CKCollectionViewDataSourceChangesetBuilderTests : XCTestCase
@property (strong) CKTransactionalComponentDataSourceChangeset *changeset;
@end

@implementation CKCollectionViewDataSourceChangesetBuilderTests

- (void)testInsertions
{
  self.changeset =
  [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder)
   {
     builder.insert.section.at.index(0);
     builder.insert.item(@"Foo").at.ck_indexPath(0, 0);
     builder.insert.item(@"Bar").at.ck_indexPath(1, 0);
   }];

  XCTAssertEqualObjects(self.changeset.insertedSections, [NSIndexSet indexSetWithIndex:0]);
  XCTAssertEqualObjects(self.changeset.insertedItems, (@{ indexPath(0, 0) : @"Foo", indexPath(1, 0) : @"Bar" }));
}

- (void)testRemovalSingular
{
  self.changeset =
  [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder)
   {
     builder.ck_removeItem.at.ck_indexPath(10, 5);
     builder.remove.item(nil).at.ck_indexPath(1, 1);
     builder.remove.section.at.index(1);
     builder.remove.section.at.index(2);
   }];

  XCTAssertEqualObjects(self.changeset.removedSections, [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)]);
  XCTAssertEqualObjects(self.changeset.removedItems, ([NSSet setWithObjects:indexPath(10, 5), indexPath(1, 1), nil]));
}

- (void)testRemovePlurals
{
  NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 3)];
  self.changeset =
  [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder)
   {
     builder.remove.sections.at.indexes(indexSet);
     builder.remove.items(nil).at.indexPaths(@[indexPath(1, 3), indexPath(5, 6)]);
     builder.ck_removeItems.at.indexPaths(@[indexPath(2, 2), indexPath(9, 8)]);
   }];

  XCTAssertEqualObjects(self.changeset.removedSections, indexSet);
  XCTAssertEqualObjects(self.changeset.removedItems,
                        ([NSSet setWithObjects:
                          indexPath(1, 3), indexPath(5, 6), indexPath(2, 2), indexPath(9, 8), nil]));
}

- (void)testUpdates
{
  self.changeset =
  [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.update.item(@"Foo").at.ck_indexPath(5, 6);
    builder.update.at.ck_indexPath(1, 1).with.item(@"Bar");
  }];

  XCTAssertEqualObjects(self.changeset.updatedItems, (@{ indexPath(5, 6) : @"Foo", indexPath(1, 1) : @"Bar" }));
}

- (void)testUpdatePlurals
{
  self.changeset =
  [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.update.at.indexPaths(@[indexPath(1, 2), indexPath(9, 8)]).with.items(@[@4, @5]);
  }];
  XCTAssertEqualObjects(self.changeset.updatedItems, (@{ indexPath(1, 2) : @4, indexPath(9, 8) : @5 }));
}

- (void)testUpdatePluralsWithCountMismatch
{
  XCTAssertThrows([CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.update.at.indexPaths(@[indexPath(1, 2), indexPath(9, 8)]).with.items(@[@5]);
  }]);
}

- (void)testMoveItemSingular
{
  self.changeset =
  [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.ck_moveItem.at.ck_indexPath(0, 0).to.ck_indexPath(4, 4);
    builder.move.item(nil).at.ck_indexPath(3, 3).to.ck_indexPath(1, 0);
  }];

  XCTAssertEqualObjects(self.changeset.movedItems, (@{ indexPath(0, 0) : indexPath(4, 4), indexPath(3, 3) : indexPath(1, 0) }));
}

- (void)testMoveSectionNotSupported
{
  XCTAssertThrows([CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.move.section.at.index(0).to.index(4);
  }]);
}

- (void)testArrayItemsValid
{
  self.changeset =
  [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.insert.items(@[@1,@2,@3]).at.indexPaths(@[indexPath(1, 4), indexPath(2, 3), indexPath(9, 8)]);
  }];
  XCTAssertEqualObjects(self.changeset.insertedItems, (@{ indexPath(1, 4) : @1, indexPath(2, 3) : @2, indexPath(9, 8) : @3 }));
}

- (void)testArrayItemsMismatchedCounts
{
  XCTAssertThrows([CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.insert.items(@[@2,@3]).at.indexPaths(@[[NSIndexPath indexPathForItem:0 inSection:0]]);
  }]);
}

- (void)testInsertMap
{
  NSDictionary *map = @{ @1 : indexPath(4, 4), @2 : indexPath(1, 0), @3: indexPath(2, 2) };
  self.changeset =
  [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.insert.items(map);
  }];
  XCTAssertEqualObjects(self.changeset.insertedItems, map);
}

- (void)testInsertSectionIndexes
{
  NSIndexSet *sections = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(3, 2)];
	self.changeset =
  [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.insert.sections.at.indexes(sections);
  }];
  XCTAssertEqualObjects(self.changeset.insertedSections, sections);
}

- (void)testMovePlural
{
  self.changeset =
  [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.move.indexPaths(@[indexPath(3, 1), indexPath(6, 7)]).to.indexPaths(@[indexPath(2, 3), indexPath(11, 3)]);
  }];
  XCTAssertEqualObjects(self.changeset.movedItems, (@{ indexPath(3, 1) : indexPath(2, 3), indexPath(6, 7) : indexPath(11, 3) }));
}

- (void)testMovePluralSizeMismatch
{
  XCTAssertThrows([CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.move.indexPaths(@[indexPath(3, 1)]).to.indexPaths(@[indexPath(2, 3), indexPath(11, 3)]);
  }]);
}

@end

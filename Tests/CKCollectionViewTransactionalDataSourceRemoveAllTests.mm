//
//  CKCollectionViewTransactionalDataSourceRemoveAllTests.m
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
#import <OCMock/OCMock.h>

#import "CKTableViewTransactionalDataSourceTestComponent.h"

#import <ComponentKit/CKCollectionViewDataSourceCell.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangesetInternal.h>

#import <CKToolbox/CKCollectionViewTransactionalDataSource+AbstractInterface.h>
#import <CKToolbox/CKTableViewDataSourceCell.h>

@interface CKCollectionViewTransactionalDataSource () <UICollectionViewDataSource>
@end

@interface CKCollectionViewTransactionalDataSourceRemoveAllTests : XCTestCase <CKComponentProvider>
@property (strong) CKCollectionViewTransactionalDataSource *dataSource;
@property (strong) CKComponentController *componentController;
@property (strong) CKCollectionViewDataSourceCell *collectionViewCell;
@property (strong) CKTransactionalComponentDataSourceChangeset *changeset;
@property (strong) id mockCollectionView;
@end

@implementation CKCollectionViewTransactionalDataSourceRemoveAllTests

- (void)setUp {
  [super setUp];

  self.mockCollectionView = OCMClassMock([UICollectionView class]);
  self.collectionViewCell = [[CKCollectionViewDataSourceCell alloc] init];

  CKTransactionalComponentDataSourceConfiguration *config = [[CKTransactionalComponentDataSourceConfiguration alloc]
                                                             initWithComponentProvider:self.class
                                                             context:nil
                                                             sizeRange:CKSizeRange({50, 50}, {50, 50})];

  self.dataSource = [[CKCollectionViewTransactionalDataSource alloc]
                     initWithCollectionView:self.mockCollectionView
                     supplementaryViewDataSource:nil
                     configuration:config];

  [[[self.mockCollectionView stub] andDo:^(NSInvocation *invocation) {
    dispatch_block_t block;
    [invocation getArgument:&block atIndex:2];
    block();
  }] performBatchUpdates:[OCMArg any] completion:[OCMArg any]];

  self.changeset =
  [[CKTransactionalComponentDataSourceChangeset alloc]
   initWithUpdatedItems:nil
   removedItems:nil
   removedSections:nil
   movedItems:nil
   insertedSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]
   insertedItems:@{
                   [NSIndexPath indexPathForItem:0 inSection:0] : @"0-0",
                   [NSIndexPath indexPathForItem:0 inSection:1] : @"0-1",
                   [NSIndexPath indexPathForItem:1 inSection:1] : @"1-1",
                   [NSIndexPath indexPathForItem:0 inSection:2] : @"0-2",
                   [NSIndexPath indexPathForItem:1 inSection:2] : @"1-2",
                   [NSIndexPath indexPathForItem:2 inSection:2] : @"2-2"
                   }];

  [self.dataSource applyChangeset:self.changeset mode:CKUpdateModeSynchronous userInfo:nil];
}

+ (CKComponent *)componentForModel:(NSString*)model context:(id<NSObject>)context {
  return [CKTableViewTransactionalDataSourceTestComponent newWithIdentifier:@"TestComponent"];
}

- (void)testGeneratedChangesetShouldMatchSourceChangeset
{
  CKTransactionalComponentDataSourceChangeset *changeset = self.dataSource.removeAllChangeset;
  
  XCTAssertEqualObjects(changeset.removedItems, [NSSet setWithArray:self.changeset.insertedItems.allKeys]);
  XCTAssertEqualObjects(changeset.removedSections, self.changeset.insertedSections);

  XCTAssertEqual(changeset.updatedItems.count, 0);
  XCTAssertEqual(changeset.movedItems.count, 0);
  XCTAssertEqual(changeset.insertedSections.count, 0);
  XCTAssertEqual(changeset.insertedItems.count, 0);
  XCTAssertNil(changeset.userInfo);

}

@end

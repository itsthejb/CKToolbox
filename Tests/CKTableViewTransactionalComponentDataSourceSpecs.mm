//
//  CKTableViewTransactionalComponentDataSourceIntegrationTests.mm
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
#import <Specta/Specta.h>
#import <Specta/Specta.h>

#import "CKTableViewTransactionalDataSourceTestComponent.h"
#import "CKTableViewTransactionalDataSourceTestComponentController.h"
#import "CKTestCellConfiguration.h"

#import <ComponentKit/CKComponent.h>
#import <ComponentKit/CKComponentProvider.h>
#import <ComponentKit/CKComponentScope.h>
#import <ComponentKit/CKCompositeComponent.h>
#import <ComponentKit/CKComponentController.h>
#import <ComponentKit/CKTransactionalComponentDataSourceConfiguration.h>
#import <ComponentKit/CKTransactionalComponentDataSourceChangeset.h>

#import <CKToolbox/CKTableViewDataSourceCell.h>
#import <CKToolbox/CKTableViewTransactionalDataSource.h>
#import <CKToolbox/CKTableViewTransactionalDataSourceCellConfiguration.h>
#import <CKToolbox/CKCollectionViewDataSourceChangesetBuilder.h>

@interface CKTableViewTransactionalDataSource () <UITableViewDataSource>
@end

SpecBegin(CKTableViewTransactionalComponentDataSource)

__block CKTableViewTransactionalDataSource *dataSource;
__block CKComponentController *componentController;
__block CKTableViewDataSourceCell *tableViewCell;
__block id mockTableView;

__block NSIndexPath *ip00 = [NSIndexPath indexPathForItem:0 inSection:0];
__block NSIndexPath *ip01 = [NSIndexPath indexPathForItem:1 inSection:0];

void (^enqueueItem)(NSIndexPath *) = ^(NSIndexPath *indexPath) {
  [[[mockTableView stub] andDo:^(NSInvocation *invocation) {
    [invocation setReturnValue:&tableViewCell];
  }] dequeueReusableCellWithIdentifier:[OCMArg any] forIndexPath:indexPath];

  [[[mockTableView expect] andDo:^(NSInvocation *invocation) {
    [dataSource tableView:mockTableView cellForRowAtIndexPath:indexPath];
  }] insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

  [dataSource applyChangeset:
   [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
    builder.insert.section.at.index(0);
    builder.insert.item(@"").at.indexPath(indexPath);
  }] mode:CKUpdateModeSynchronous userInfo:nil];
};

before(^{
  mockTableView = OCMClassMock([UITableView class]);
  tableViewCell = [[CKTableViewDataSourceCell alloc] init];

  CKTransactionalComponentDataSourceConfiguration *config =
  [[CKTransactionalComponentDataSourceConfiguration alloc]
   initWithComponentProvider:[CKTableViewTransactionalDataSourceTestComponentController class]
   context:nil
   sizeRange:CKSizeRange({50, 50}, {50, 50})];

  dataSource = [[CKTableViewTransactionalDataSource alloc]
                initWithTableView:mockTableView
                supplementaryDataSource:nil
                configuration:config
                defaultCellConfiguration:nil];
});

afterEach(^{
  OCMVerify(mockTableView);
});

describe(@"cell configuration", ^{

  __block id mockCell = nil;

  before(^{
    mockCell = OCMClassMock([CKTableViewDataSourceCell class]);
  });

  after(^{
    OCMVerify(mockCell);
  });

  describe(@"default configuration", ^{
    describe(@"insert", ^{
      before(^{
        OCMExpect([mockTableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade]);
        OCMExpect([mockTableView insertRowsAtIndexPaths:@[ip00] withRowAnimation:UITableViewRowAnimationFade]);

        [dataSource applyChangeset:
         [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
          builder.insert.section.at.index(0);
          builder.insert.item(@"").at.indexPath([NSIndexPath indexPathForItem:0 inSection:0]);
        }] mode:CKUpdateModeSynchronous cellConfiguration:nil];
      });

      it(@"should use default animations", ^{});

      describe(@"update and insert", ^{
        before(^{
          OCMExpect([mockCell rootView]).andReturn([UIView new]);
          OCMExpect([mockTableView cellForRowAtIndexPath:ip00]).andReturn(mockCell);

          [dataSource applyChangeset:
           [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
            builder.update.item(@"").at.indexPath([NSIndexPath indexPathForItem:0 inSection:0]);
          }] mode:CKUpdateModeSynchronous cellConfiguration:nil];
        });

        it(@"should remount the view to the dequeued cell", ^{});

        describe(@"move", ^{
          before(^{
            [dataSource applyChangeset:
             [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
              builder.insert.item(@"").at.indexPath([NSIndexPath indexPathForItem:1 inSection:0]);
            }] mode:CKUpdateModeSynchronous cellConfiguration:nil];

            OCMExpect([mockTableView moveRowAtIndexPath:ip01 toIndexPath:ip00]);

            [dataSource applyChangeset:
             [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
              builder.ck_moveItem.at.indexPath([NSIndexPath indexPathForItem:1 inSection:0])
              .to.indexPath([NSIndexPath indexPathForItem:0 inSection:0]);
            }] mode:CKUpdateModeSynchronous cellConfiguration:nil];
          });

          it(@"should use default animations", ^{});

          describe(@"remove", ^{
            before(^{
              OCMExpect([mockTableView deleteRowsAtIndexPaths:[OCMArg checkWithBlock:^BOOL(NSArray *paths) {
                return [(@[ip00, ip01]) isEqual:[paths sortedArrayUsingSelector:@selector(compare:)]];
              }] withRowAnimation:UITableViewRowAnimationFade]);
              OCMExpect([mockTableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade]);

              [dataSource applyChangeset:
               [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
                builder.ck_removeItem.indexPath([NSIndexPath indexPathForItem:0 inSection:0]);
                builder.ck_removeItem.indexPath([NSIndexPath indexPathForItem:1 inSection:0]);
                builder.remove.section.at.index(0);
              }] mode:CKUpdateModeSynchronous cellConfiguration:nil];
            });

            it(@"should use default animations", ^{});
          });
        });
      });
    });
  });

  describe(@"custom configuration", ^{
    __block CKTestCellConfiguration *cellConfiguration = [CKTestCellConfiguration new];

    describe(@"insert", ^{
      before(^{
        OCMExpect([mockTableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationMiddle]);
        OCMExpect([mockTableView insertRowsAtIndexPaths:@[ip00] withRowAnimation:UITableViewRowAnimationTop]);

        [dataSource applyChangeset:
         [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
          builder.insert.section.at.index(0);
          builder.insert.item(@"").at.indexPath([NSIndexPath indexPathForItem:0 inSection:0]);
        }] mode:CKUpdateModeSynchronous cellConfiguration:cellConfiguration];
      });

      it(@"should use custom animations", ^{});

      describe(@"reload", ^{

        before(^{
          OCMExpect([mockCell rootView]).andReturn([UIView new]);
          OCMExpect([mockCell setBackgroundColor:[UIColor redColor]]);
          OCMExpect([mockTableView cellForRowAtIndexPath:ip00]).andReturn(mockCell);

          [dataSource applyChangeset:
           [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
            builder.update.item(@"").at.indexPath([NSIndexPath indexPathForItem:0 inSection:0]);
          }] mode:CKUpdateModeSynchronous cellConfiguration:cellConfiguration];
        });

        it(@"should use the cell configuration function", ^{});

        describe(@"remove", ^{
          before(^{
            [dataSource applyChangeset:
             [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
              builder.insert.item(@"").at.indexPath([NSIndexPath indexPathForItem:1 inSection:0]);
            }] mode:CKUpdateModeSynchronous cellConfiguration:cellConfiguration];
            [dataSource applyChangeset:
             [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
              builder.ck_moveItem.at.indexPath([NSIndexPath indexPathForItem:1 inSection:0])
              .to.indexPath([NSIndexPath indexPathForItem:0 inSection:0]);
            }] mode:CKUpdateModeSynchronous cellConfiguration:cellConfiguration];

            OCMExpect([mockTableView deleteRowsAtIndexPaths:[OCMArg checkWithBlock:^BOOL(NSArray *paths) {
              return [(@[ip00, ip01]) isEqual:[paths sortedArrayUsingSelector:@selector(compare:)]];
            }] withRowAnimation:UITableViewRowAnimationLeft]);
            OCMExpect([mockTableView deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic]);

            [dataSource applyChangeset:
             [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
              builder.ck_removeItem.indexPath([NSIndexPath indexPathForItem:0 inSection:0]);
              builder.ck_removeItem.indexPath([NSIndexPath indexPathForItem:1 inSection:0]);
              builder.remove.section.at.index(0);
            }] mode:CKUpdateModeSynchronous cellConfiguration:cellConfiguration];
          });

          it(@"should use custom animations", ^{});
        });
      });
    });
  });
});

describe(@"remount", ^{
  __block id observerMock;

  before(^{
    CKTableViewTransactionalDataSourceTestNotificationCenter = [[NSNotificationCenter alloc] init];
    observerMock = [OCMockObject observerMock];
    [CKTableViewTransactionalDataSourceTestNotificationCenter addMockObserver:observerMock name:nil object:nil];

    [[observerMock expect] notificationWithName:NSStringFromSelector(@selector(didUpdateComponent))
                                         object:[OCMArg checkWithBlock:^BOOL(CKComponentController *c)
                                                 {
                                                   componentController = c;
                                                   return YES;
                                                 }]];

    enqueueItem([NSIndexPath indexPathForItem:0 inSection:0]);
  });

  after(^{
    [observerMock verify];
    [CKTableViewTransactionalDataSourceTestNotificationCenter removeObserver:observerMock];
    CKTableViewTransactionalDataSourceTestNotificationCenter = nil;
  });

  it(@"should trigger remount in controller when reloading with matching identifier", ^{
    [[observerMock expect] notificationWithName:NSStringFromSelector(@selector(didUpdateComponent))
                                         object:componentController];
    [[observerMock expect] notificationWithName:NSStringFromSelector(@selector(willRemount))
                                         object:componentController];
    [[observerMock expect] notificationWithName:NSStringFromSelector(@selector(didRemount))
                                         object:componentController];

    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    [[[mockTableView stub] andReturn:tableViewCell] cellForRowAtIndexPath:indexPath];
    
    [dataSource applyChangeset:
     [CKCollectionViewDataSourceChangesetBuilder build:^(CKCollectionViewDataSourceChangesetBuilder *builder) {
      builder.update.item(@"").at.indexPath(indexPath);
    }] mode:CKUpdateModeSynchronous userInfo:nil];
  });
});

SpecEnd


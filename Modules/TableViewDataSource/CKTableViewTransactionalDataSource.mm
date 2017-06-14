//
//  CKTableViewTransactionalDataSource.mm
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

#import <CKToolbox/CKTableViewTransactionalDataSource.h>
#import <CKToolbox/CKTableViewDataSourceCell.h>
#import <CKToolbox/CKTableViewSupplementaryDataSource.h>
#import <CKToolbox/CKTableViewTransactionalDataSourceCellConfiguration.h>
#import <CKToolbox/CKTransactionalComponentDataSourceState+RemoveAll.h>
#import <ComponentKit/CKTransactionalComponentDataSource.h>
#import <ComponentKit/CKComponentDataSourceAttachController.h>
#import <ComponentKit/CKTransactionalComponentDataSourceState.h>
#import <ComponentKit/CKTransactionalComponentDataSourceAppliedChanges.h>
#import <ComponentKit/CKTransactionalComponentDataSourceItem.h>
#import <ComponentKit/CKTransactionalComponentDataSourceListener.h>
#import <ComponentKit/CKComponentRootView.h>

static const UITableViewRowAnimation kDefaultAnimation = UITableViewRowAnimationFade;

@interface CKTableViewTransactionalDataSource () <
UITableViewDataSource,
CKTransactionalComponentDataSourceListener
>
{
  CKTransactionalComponentDataSource *_componentDataSource;
  __weak NSObject <CKTableViewSupplementaryDataSource> *_supplementaryDataSource;
  CKTransactionalComponentDataSourceState *_currentState;
  CKComponentDataSourceAttachController *_attachController;
  CKTableViewTransactionalDataSourceCellConfiguration *_defaultCellConfiguration;
  CKTableViewTransactionalDataSourceCellConfiguration *_cellConfiguration;
  NSMapTable<UITableViewCell *, CKTransactionalComponentDataSourceItem *> *_cellToItemMap;
}
@end


@implementation CKTableViewTransactionalDataSource

- (instancetype)initWithTableView:(UITableView *)tableView
          supplementaryDataSource:(NSObject <CKTableViewSupplementaryDataSource> * _Nullable)supplementaryDataSource
                    configuration:(CKTransactionalComponentDataSourceConfiguration *)configuration
         defaultCellConfiguration:(CKTableViewTransactionalDataSourceCellConfiguration * _Nullable)cellConfiguration
{
  self = [super init];
  if (self) {
    _componentDataSource = [[CKTransactionalComponentDataSource alloc] initWithConfiguration:configuration];
    [_componentDataSource addListener:self];

    _tableView = tableView;
    _tableView.dataSource = self;
    [_tableView registerClass:[CKTableViewDataSourceCell class] forCellReuseIdentifier:kReuseIdentifier];

    _attachController = [[CKComponentDataSourceAttachController alloc] init];
    _supplementaryDataSource = supplementaryDataSource;
    _cellConfiguration = cellConfiguration;
    _cellToItemMap = [NSMapTable weakToStrongObjectsMapTable];

    // tableview have one section initially, while ck datasoure have no. This will led to crash
    // at some circumstances.
    [_tableView reloadData];
  }
  return self;
}

#pragma mark - Changeset application

- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource applyChangeset:changeset
                                  mode:mode
                              userInfo:userInfo];
}

static void applyChangesToTableView(CKTransactionalComponentDataSourceAppliedChanges *changes,
                                    UITableView *tableView,
                                    CKTableViewTransactionalDataSourceCellConfiguration *cellConfig,
                                    CKTransactionalComponentDataSourceState *currentState,
                                    CKComponentDataSourceAttachController *attachController,
                                    NSMapTable<UITableViewCell *, CKTransactionalComponentDataSourceItem *> *cellToItemMap)
{
  [changes.updatedIndexPaths enumerateObjectsUsingBlock:^(NSIndexPath *_Nonnull indexPath, BOOL * _Nonnull stop) {
    if (CKTableViewDataSourceCell *cell = [tableView cellForRowAtIndexPath:indexPath]) {
      _attachToCell(cell, indexPath, currentState, cellConfig, attachController, cellToItemMap);
    }
  }];
  [tableView deleteRowsAtIndexPaths:[changes.removedIndexPaths allObjects]
                   withRowAnimation:cellConfig ? cellConfig.animationRowDelete : kDefaultAnimation];
  [tableView deleteSections:changes.removedSections
           withRowAnimation:cellConfig ? cellConfig.animationSectionDelete : kDefaultAnimation];
  for (NSIndexPath *from in changes.movedIndexPaths) {
    NSIndexPath *to = changes.movedIndexPaths[from];
    [tableView moveRowAtIndexPath:from toIndexPath:to];
  }
  [tableView insertSections:changes.insertedSections
           withRowAnimation:cellConfig ? cellConfig.animationSectionInsert : kDefaultAnimation];
  [tableView insertRowsAtIndexPaths:[changes.insertedIndexPaths allObjects]
                   withRowAnimation:cellConfig ? cellConfig.animationRowInsert : kDefaultAnimation];
}

#pragma mark - CKTransactionalComponentDataSourceListener

- (void)transactionalComponentDataSource:(CKTransactionalComponentDataSource *)dataSource
                  didModifyPreviousState:(CKTransactionalComponentDataSourceState *)previousState
                       byApplyingChanges:(CKTransactionalComponentDataSourceAppliedChanges *)changes
{
  CKTableViewTransactionalDataSourceCellConfiguration *cellConfig =
  changes.userInfo[CKTableViewTransactionalDataSourceCellConfigurationKey] ?: _cellConfiguration;

  dispatch_block_t block = ^{
    [_tableView beginUpdates];
    applyChangesToTableView(changes, _tableView, cellConfig, _currentState, _attachController, _cellToItemMap);

    // Detach all the component layouts for items being deleted
    [self _detachComponentLayoutForRemovedItemsAtIndexPaths:[changes removedIndexPaths]
                                                    inState:previousState];
    _currentState = [_componentDataSource state];
    [_tableView endUpdates];
  };

  if (cellConfig.animationsDisabled) {
    [UIView performWithoutAnimation:block];
  } else {
    block();
  }
}

- (void)_detachComponentLayoutForRemovedItemsAtIndexPaths:(NSSet *)removedIndexPaths
                                                  inState:(CKTransactionalComponentDataSourceState *)state
{
  for (NSIndexPath *indexPath in removedIndexPaths) {
    CKComponentScopeRootIdentifier identifier = [[[state objectAtIndexPath:indexPath] scopeRoot] globalIdentifier];
    [_attachController detachComponentLayoutWithScopeIdentifier:identifier];
  }
}

#pragma mark - CKTransactionalDataSourceInterface

- (UIView *)view {
  return _tableView;
}

#pragma mark - State

- (id<NSObject>)modelForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_currentState objectAtIndexPath:indexPath].model;
}

- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_currentState objectAtIndexPath:indexPath].layout.size;
}

#pragma mark - Reload

- (void)reloadWithMode:(CKUpdateMode)mode
              userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource reloadWithMode:mode userInfo:userInfo];
}

- (void)updateConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
                   userInfo:(NSDictionary *)userInfo
{
  [_componentDataSource updateConfiguration:configuration mode:mode userInfo:userInfo];
}

#pragma mark - Cell configuration update convenience methods

- (void)applyChangeset:(CKTransactionalComponentDataSourceChangeset *)changeset
                  mode:(CKUpdateMode)mode
     cellConfiguration:(CKTableViewTransactionalDataSourceCellConfiguration *)cellConfiguration
{
  [self applyChangeset:changeset
                  mode:mode
              userInfo:(cellConfiguration
                        ? @{ CKTableViewTransactionalDataSourceCellConfigurationKey : cellConfiguration }
                        : nil)];
}

- (void)updateConfiguration:(CKTransactionalComponentDataSourceConfiguration *)configuration
                       mode:(CKUpdateMode)mode
          cellConfiguration:(CKTableViewTransactionalDataSourceCellConfiguration *)cellConfiguration
{
  [self updateConfiguration:configuration
                       mode:mode
                   userInfo:(cellConfiguration
                             ? @{ CKTableViewTransactionalDataSourceCellConfigurationKey : cellConfiguration }
                             : nil)];
}

- (CKTableViewTransactionalDataSourceCellConfiguration *)cellConfiguration {
  return _cellConfiguration.copy;
}

#pragma mark - Appearance announcements

- (void)announceWillDisplayCell:(UITableViewCell *)cell
{
  [[_cellToItemMap objectForKey:cell].scopeRoot announceEventToControllers:CKComponentAnnouncedEventTreeWillAppear];
}

- (void)announceDidEndDisplayingCell:(UITableViewCell *)cell
{
  [[_cellToItemMap objectForKey:cell].scopeRoot announceEventToControllers:CKComponentAnnouncedEventTreeDidDisappear];
}

#pragma mark - UITableViewDataSource

static NSString *const kReuseIdentifier = @"com.component_kit.table_view_data_source.cell";

static void _attachToCell(CKTableViewDataSourceCell *cell,
                          NSIndexPath *indexPath,
                          CKTransactionalComponentDataSourceState *currentState,
                          CKTableViewTransactionalDataSourceCellConfiguration *configuration,
                          CKComponentDataSourceAttachController *attachController,
                          NSMapTable<UITableViewCell *, CKTransactionalComponentDataSourceItem *> *cellToItemMap)
{
  CKTransactionalComponentDataSourceItem *item = [currentState objectAtIndexPath:indexPath];
  [attachController attachComponentLayout:item.layout withScopeIdentifier:item.scopeRoot.globalIdentifier withBoundsAnimation:item.boundsAnimation toView:cell.rootView];
  if (configuration.cellConfigurationFunction) {
    configuration.cellConfigurationFunction(cell, indexPath, item.model);
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  CKTableViewDataSourceCell *cell = [_tableView dequeueReusableCellWithIdentifier:kReuseIdentifier forIndexPath:indexPath];
  _attachToCell(cell, indexPath, _currentState, _cellConfiguration, _attachController, _cellToItemMap);
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return _currentState ? [_currentState numberOfSections] : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return _currentState ? [_currentState numberOfObjectsInSection:section] : 0;
}

#pragma mark - CKTableViewSupplementaryDataSource

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView titleForHeaderInSection:section];
  }
  return nil;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView titleForFooterInSection:section];
  }
  return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView canEditRowAtIndexPath:indexPath];
  }
  return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView canMoveRowAtIndexPath:indexPath];
  }
  return NO;
}

- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource sectionIndexTitlesForTableView:tableView];
  }
  return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
  }
  return NSNotFound;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
  }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
  if ([_supplementaryDataSource respondsToSelector:_cmd]) {
    return [_supplementaryDataSource tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
  }
}

#pragma mark - RemoveAll

- (CKTransactionalComponentDataSourceChangeset*)removeAllChangeset
{
    return [[self valueForKey:@"_currentState"] removeAllChangeset];
}

@end

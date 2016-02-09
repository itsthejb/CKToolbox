//
//  CKCollectionViewDataSourceChangesetBuilder.mm
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

#import "CKCollectionViewDataSourceChangesetBuilder.h"
#import "CKTransactionalComponentDataSourceChangesetInternal.h"

namespace CKChangesetBuilder {
  namespace Verb {
    enum Type { None, Update, Insert, Remove, Move };
  }
  namespace Element {
    enum Type { None, Section, Item };
  }
}

using namespace CKChangesetBuilder;

@interface CKCollectionViewDataSourceChangesetBuilder ()
@property (nonatomic, assign) Verb::Type verb;
@property (nonatomic, assign) Element::Type element;
@property (nonatomic, assign) BOOL plural;
@property (nonatomic, strong) id object;
@property (nonatomic, assign) NSNumber *sectionIndex;
@property (nonatomic, strong) NSIndexSet *sectionIndexes;
@property (nonatomic, strong) NSIndexPath *itemIndexPath;
@property (nonatomic, strong) NSArray *itemIndexPaths;
@property (nonatomic, strong) NSIndexPath *itemMoveIndexPath;
@property (nonatomic, strong) NSArray *itemMoveIndexPaths;
- (void)storeIfExpressionComplete;
- (void)reset;
@end

@implementation CKCollectionViewDataSourceChangesetBuilder
{
  NSMutableDictionary *_updatedItems;
  NSMutableSet *_removedItems;
  NSMutableIndexSet *_removedSections;
  NSMutableDictionary *_movedItems;
  NSMutableIndexSet *_insertedSections;
  NSMutableDictionary *_insertedItems;
}

- (instancetype)init
{
  if ((self = [super init])) {
    _updatedItems = [NSMutableDictionary dictionary];
    _movedItems = [NSMutableDictionary dictionary];
    _insertedItems = [NSMutableDictionary dictionary];
    _removedItems = [NSMutableSet set];
    _removedSections = [NSMutableIndexSet indexSet];
    _insertedSections = [NSMutableIndexSet indexSet];
  }
  return self;
}

+ (CKTransactionalComponentDataSourceChangeset*)build:(void(^)(CKCollectionViewDataSourceChangesetBuilder *builder))block
{
  CKCollectionViewDataSourceChangesetBuilder *builder = [[self alloc] init];
  [builder build:block];
  return builder.build;
}

- (instancetype)build:(void(^)(CKCollectionViewDataSourceChangesetBuilder *builder))block {
  block(self);
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)update {
  NSAssert(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Update;
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)insert {
  NSAssert(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Insert;
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)remove {
  NSAssert(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Remove;
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)move {
  NSAssert(self.verb == Verb::None, @"Expression contains >1 verb");
  self.verb = Verb::Move;
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)section {
  NSAssert(self.verb != Verb::None, @"Expression contains noun, but no verb");
  NSAssert(self.verb != Verb::Move, @"Section moving is not supported");
  NSAssert(self.element == Element::None, @"Expression contains >1 element");
  self.element = Element::Section;
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)sections {
  CKCollectionViewDataSourceChangesetBuilder *builder = [self section];
  self.plural = YES;
  return builder;
}

- (CKCollectionViewDataSourceChangesetBuilder *)at {
  NSAssert(self.verb != Verb::None, @"Expression contains no verb");
  NSAssert((self.element == Element::Section && !self.sectionIndex) ||
           (self.element == Element::Item && !self.itemIndexPath) ||
           (self.verb == Verb::Update),
           @"Expression already contains an index, or indexPath");
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)to {
  NSAssert(self.verb == Verb::Move, @"Preposition only valid for move operation");
  NSAssert((self.element == Element::Section && (self.sectionIndex || self.sectionIndexes)) ||
           (self.element == Element::Item && (self.itemIndexPath || self.itemIndexPaths)),
           @"Expression contains no source index or indexPath for move");
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *)with {
  NSAssert(self.verb == Verb::Update, @"Preposition only valid for update operation");
  NSAssert(self.itemIndexPath || self.itemIndexPaths, @"No indexPath(s) for update operation");
  return self;
}

- (CKCollectionViewDataSourceChangesetBuilder *(^)(id))_item {
  NSAssert(self.verb != Verb::None, @"Expression contains no verb");
  NSAssert(self.element == Element::None || self.verb == Verb::Update, @"Expression already contains a noun");
  return ^(id item) {
    NSAssert(self.verb != Verb::Insert || item, @"Object required for insert operation");
    self.object = item;
    [self storeIfExpressionComplete];
    return self;
  };
}

- (CKCollectionViewDataSourceChangesetBuilder *(^)(id))item {
  id block = [self _item];
  self.element = Element::Item;
  return block;
}

- (CKCollectionViewDataSourceChangesetBuilder *(^)(id))items {
  id block = [self _item];
  self.element = Element::Item;
  self.plural = YES;
  return block;
}

- (CKCollectionViewDataSourceChangesetBuilder *(^)(NSUInteger))index {
  NSAssert(self.element == Element::Section, @"Index only valid for section operations");
  return ^(NSUInteger index) {
    switch (self.verb) {
      case Verb::Insert:
      case Verb::Remove:
        self.sectionIndex = @(index);
        break;
      default:
        NSAssert(NO, @"Not valid for Update or Move");
        break;
    }
    [self storeIfExpressionComplete];
    return self;
  };
}

- (CKCollectionViewDataSourceChangesetBuilder *(^)(NSIndexSet *))indexes {
  NSAssert(self.plural, @"Only valid for plural sections");
  NSAssert(self.element == Element::Section, @"Index only valid for section operations");
  return ^(NSIndexSet *indexes) {
    switch (self.verb) {
      case Verb::Insert:
      case Verb::Remove:
        self.sectionIndexes = indexes;
        break;
      default:
        NSAssert(NO, @"Only valid for insert and remove");
        break;
    }
    [self storeIfExpressionComplete];
    return self;
  };
}

- (CKCollectionViewDataSourceChangesetBuilder *(^)(NSIndexPath *))indexPath {
  NSAssert(self.element == Element::Item || self.verb == Verb::Update, @"Expression contains no object");
  return ^(NSIndexPath *indexPath) {
    switch (self.verb) {
      case Verb::Insert:
      case Verb::Remove:
      case Verb::Update:
        self.itemIndexPath = indexPath;
        break;
      case Verb::Move:
        self.itemIndexPath ? self.itemMoveIndexPath = indexPath : self.itemIndexPath = indexPath;
        break;
      default:
        break;
    }
    [self storeIfExpressionComplete];
    return self;
  };
}

- (CKCollectionViewDataSourceChangesetBuilder *(^)(NSArray *))indexPaths {
  NSAssert(self.element == Element::Item || self.verb == Verb::Update || self.verb == Verb::Move, @"Expression contains no object");
  self.element = Element::Item;
  NSAssert(!self.itemMoveIndexPaths || self.plural, @"Only valid for plural object operations");
  return ^(NSArray *indexPaths) {
    switch (self.verb) {
      case Verb::Insert:
      case Verb::Remove:
      case Verb::Update:
        self.itemIndexPaths = indexPaths;
        break;
      case Verb::Move:
        self.itemIndexPaths ? self.itemMoveIndexPaths = indexPaths : self.itemIndexPaths = indexPaths;
        break;
      default:
        break;
    }
    [self storeIfExpressionComplete];
    return self;
  };
}

#pragma mark Parse expressions

- (void)_storeIfUpdate
{
  /** Singular */
  if (self.object && self.itemIndexPath) {
    NSAssert2(!_updatedItems[self.itemIndexPath],
              @"Already object %@ for indexPath %@",
              self.object, self.itemIndexPath);
    _updatedItems[self.itemIndexPath] = self.object;
    [self reset];
  }

  /** Plural */
  else if ([self.object isKindOfClass:[NSArray class]] && self.itemIndexPaths) {
    NSAssert2([self.object count] == self.itemIndexPaths.count,
              @"Update array count mismatch",
              self.object, self.itemIndexPaths);
    for (NSUInteger i = 0; i < [self.object count]; ++i) {
      _updatedItems[self.itemIndexPaths[i]] = [self.object objectAtIndex:i];
    }
    [self reset];
  }
}

- (void)_storeIfInsert
{
  switch (self.element) {
    case Element::Section:
      return [self _storeIfInsertSection];
    case Element::Item:
      return [self _storeIfInsertItem];
    default:
      break;
  }
}

- (void)_storeIfInsertSection
{
  /** singular */
  if (self.sectionIndex)
  {
    NSAssert1(![_insertedSections containsIndex:self.sectionIndex.unsignedIntegerValue],
              @"Inserted sections already contains index %@", self.sectionIndex);
    [_insertedSections addIndex:self.sectionIndex.unsignedIntegerValue];
    [self reset];
  }

  /** plural */
  else if (self.sectionIndexes) {
    [_insertedSections addIndexes:self.sectionIndexes];
    [self reset];
  }
}

- (void)_storeIfInsertItem
{
  /** Insert item */
  if (self.object) {

    /** Singular */
    if (self.itemIndexPath) {
      NSAssert2(!_insertedItems[self.itemIndexPath],
                @"Inserted items already contains object %@ for indexPath %@",
                self.object, self.itemIndexPath);
      _insertedItems[self.itemIndexPath] = self.object;
      [self reset];
    }

    /** Plural */
    else if (self.itemIndexPaths) {
      /** item array -> indexPath array */
      NSAssert1([self.object isKindOfClass:[NSArray class]],
                @"For plural insert at indexPaths, item object must be array of insert items: %@",
                self.object);
      NSAssert2([self.object count] == self.itemIndexPaths.count,
                @"Item and indexPath array count mismatch %@ %@",
                self.object, self.itemIndexPaths);
      for (NSUInteger i = 0; i < [self.object count]; ++i) {
        _insertedItems[self.itemIndexPaths[i]] = [self.object objectAtIndex:i];
      }

    } else if ([self.object isKindOfClass:[NSDictionary class]]) {
      /** Item map */
      [_insertedItems addEntriesFromDictionary:self.object];
      [self reset];
    }
  }
}

- (void)_storeIfMove
{
  /** Move section */
  switch (self.element) {
    case Element::Item:
      /** Singular */
      if (self.itemIndexPath && self.itemMoveIndexPath)
      {
        NSAssert2(!_movedItems[self.itemIndexPath],
                  @"Item move already exists from %@ to %@",
                  self.itemIndexPath, self.itemMoveIndexPath);
        _movedItems[self.itemIndexPath] = self.itemMoveIndexPath;
        [self reset];
      }

      else if (self.itemIndexPaths && self.itemMoveIndexPaths) {
        NSAssert2(self.itemIndexPaths.count == self.itemMoveIndexPaths.count,
                  @"Item move array count mismatch: %@ %@",
                  self.itemIndexPaths, self.itemMoveIndexPaths);
        for (NSUInteger i = 0; i < self.itemIndexPaths.count; ++i) {
          _movedItems[self.itemIndexPaths[i]] = self.itemMoveIndexPaths[i];
        }
        [self reset];
      }
      break;

    default:
      break;
  }
}

- (void)_storeIfRemove
{
  /** Remove section */
  switch (self.element) {
    case Element::Section:
      if (self.sectionIndex)
      {
        NSAssert1(![_removedSections containsIndex:self.sectionIndex.unsignedIntegerValue],
                  @"Section %@ already stored for removal", self.sectionIndex);
        [_removedSections addIndex:self.sectionIndex.unsignedIntegerValue];
        [self reset];
      }

      else if (self.sectionIndexes) {
        [_removedSections addIndexes:self.sectionIndexes];
        [self reset];
      }

      break;

    case Element::Item:
      if (self.itemIndexPath)
      {
        NSAssert1(![_removedItems member:self.itemIndexPath],
                  @"Item at indexPath %@ already stored for removal",
                  self.itemIndexPath);
        [_removedItems addObject:self.itemIndexPath];
        [self reset];
      }

      else if (self.itemIndexPaths)
      {
        [_removedItems addObjectsFromArray:self.itemIndexPaths];
        [self reset];
      }
      break;

    default:
      break;
  }
}

- (void)storeIfExpressionComplete
{
  NSAssert(self.verb != Verb::None, @"Expression contains no verb");
  NSAssert(self.element != Element::None || self.verb == Verb::Update, @"Expression contains no noun");

  switch (self.verb)
  {
    case Verb::Update:
      return [self _storeIfUpdate];
    case Verb::Insert:
      return [self _storeIfInsert];
    case Verb::Move:
      return [self _storeIfMove];
    case Verb::Remove:
      return [self _storeIfRemove];
    default:
      break;
  }
}

- (void)reset
{
  self.verb = Verb::None;
  self.element = Element::None;
  self.object = nil;
  self.plural = NO;
  self.sectionIndexes = nil;
  self.sectionIndex = nil;
  self.itemIndexPath = self.itemMoveIndexPath = nil;
  self.itemIndexPaths = self.itemMoveIndexPaths = nil;
}

- (CKTransactionalComponentDataSourceChangeset *)build
{
  return [[CKTransactionalComponentDataSourceChangeset alloc] initWithUpdatedItems:_updatedItems
                                                                      removedItems:_removedItems
                                                                   removedSections:_removedSections
                                                                        movedItems:_movedItems
                                                                  insertedSections:_insertedSections
                                                                     insertedItems:_insertedItems];
}

@end

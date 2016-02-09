//
//  CKTableViewTransactionalDataSource+RemoveAll.m
//  CKToolbox
//
//  Created by Jonathan Crooke on 21/01/2016.
//  Copyright © 2016 Jonathan Crooke. All rights reserved.
//

#import "CKTableViewTransactionalDataSource+RemoveAll.h"
#import "CKTransactionalComponentDataSourceState+RemoveAll.h"

@implementation CKTableViewTransactionalDataSource (RemoveAll)

- (CKTransactionalComponentDataSourceChangeset*)removeAllChangeset
{
  return [[self valueForKey:@"_currentState"] removeAllChangeset];
}

@end

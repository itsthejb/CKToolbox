//
//  AnimalComponentController.m
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

#import "AnimalComponentController.h"
#import "AnimalComponent.h"
#import "AnimalOverlayComponent.h"
#import "AnimalComponentResponder.h"
#import <ComponentKit/CKComponentSubclass.h>

@interface AnimalComponentController () <AnimalComponentResponder>
@property (nonatomic, weak, readonly) AnimalComponent *component;
@end

@implementation AnimalComponentController
@dynamic component;

- (void)didTap:(UITapGestureRecognizer*)sender
{
  if (self.component.overlay) {
    // this is a bit funky, but it works...
    [UIView animateWithDuration:0.3 animations:^{
      self.component.overlay.textComponent.viewContext.view.alpha = 0.0;
    } completion:^(BOOL finished) {
      [self.component updateState:^id(id) {
        return @(AnimalComponentOverlayShowNo);
      } mode:CKUpdateModeSynchronous];
    }];
  } else {
    [self.component updateState:^id(id) {
      return @(AnimalComponentOverlayShowYes);
    } mode:CKUpdateModeSynchronous];
  }
}

@end

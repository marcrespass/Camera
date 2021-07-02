//
//  CountdownViewControllerDelegate.h
//  Roaster
//
//  Created by Marc Respass on 06/06/2012.
//  Copyright (c) 2012 ILIOS Inc. All rights reserved.
//

@import Foundation;

@class CountdownViewController;

@protocol CountdownViewControllerDelegate <NSObject>

@required
- (void)countdownDidEnd:(CountdownViewController *)countdown;
- (void)countdownWasCanceled:(CountdownViewController *)countdown;

@end

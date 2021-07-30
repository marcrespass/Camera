//
//  NSAlert+ILIOSAdditions.h
//  ILIOSCocoaKit
//
//  Created by Marc Respass on 07/08/15.
//
//

@import Cocoa;

NS_ASSUME_NONNULL_BEGIN
@interface NSAlert (ILIOSAdditions)

- (NSAlert *)ilios_alertWithTitle:(NSString *)title
                          message:(NSString *)message;

- (NSAlert *)ilios_alertWithTitle:(NSString *)title
                          message:(NSString *)message
                    okButtonTitle:(NSString *)okTitle;

- (NSAlert *)ilios_alertWithTitle:(NSString *)title
                          message:(NSString *)message
                    okButtonTitle:(NSString *)okTitle
                cancelButtonTitle:(NSString *)cancelTitle;

- (void)ilios_displayAlertForWindow:(NSWindow * _Nullable)window;

@end
NS_ASSUME_NONNULL_END

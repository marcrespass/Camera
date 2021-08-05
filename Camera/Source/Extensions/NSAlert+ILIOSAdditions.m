//
//  NSAlert+ILIOSAdditions.m
//  ILIOSCocoaKit
//
//  Created by Marc Respass on 07/08/15.
//
//

#import "NSAlert+ILIOSAdditions.h"

@implementation NSAlert (ILIOSAdditions)

- (NSAlert *)ilios_alertWithTitle:(NSString *)title
                          message:(NSString *)message;
{
    NSAssert(title, @"title is required");
    NSAssert(message, @"message is required");

    [self setMessageText:title];

    [self setInformativeText:message];

    [self addButtonWithTitle:NSLocalizedString(@"OK", @"OK")];

    return self;
}

- (NSAlert *)ilios_alertWithTitle:(NSString *)title
                          message:(NSString *)message
                    okButtonTitle:(NSString *)okTitle;
{
    NSAssert(title, @"title is required");
    NSAssert(message, @"message is required");
    NSAssert(okTitle, @"okTitle is required");

    [self setMessageText:title];
    [self setInformativeText:message];
    [self addButtonWithTitle:okTitle];

    return self;
}

- (NSAlert *)ilios_alertWithTitle:(NSString *)title
                          message:(NSString *)message
                    okButtonTitle:(NSString *)okTitle
                cancelButtonTitle:(NSString *)cancelTitle;

{
    NSAssert(title, @"title is required");
    NSAssert(message, @"message is required");
    NSAssert(okTitle, @"okTitle is required");
    NSAssert(okTitle, @"okTitle is required");

    [self setMessageText:title];
    [self setInformativeText:message];
    [self addButtonWithTitle:okTitle];
    [self addButtonWithTitle:cancelTitle];

    return self;
}

- (void)ilios_displayAlertForWindow:(NSWindow *)window;
{
    if(window)
    {
        [self beginSheetModalForWindow:window completionHandler:nil];
    }
    else
    {
        [self runModal];
    }
}

@end

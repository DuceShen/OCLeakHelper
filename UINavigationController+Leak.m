//
//  UINavigationController+Leak.m
//
//

#import "UINavigationController+Leak.h"
#import "UIViewController+Leak.h"

@implementation UINavigationController (Leak)

#ifdef DEBUG

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSEL:@selector(popViewControllerAnimated:) withSEL:@selector(leak_popViewControllerAnimated:)];
        [self swizzleSEL:@selector(popToViewController:animated:) withSEL:@selector(leak_popToViewController:animated:)];
        [self swizzleSEL:@selector(popToRootViewControllerAnimated:) withSEL:@selector(leak_popToRootViewControllerAnimated:)];
    });
}

- (UIViewController *)leak_popViewControllerAnimated:(BOOL)animated {
    UIViewController *controller = [self leak_popViewControllerAnimated:animated];
    controller.poped = YES;
    return controller;
}

- (NSArray<UIViewController *> *)leak_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray<UIViewController *> *controllers = [self leak_popToViewController:viewController animated:animated];
    
    for (UIViewController *vc in controllers)
    {
        [vc willDealloc];
    }
    return controllers;
}

- (NSArray<UIViewController *> *)leak_popToRootViewControllerAnimated:(BOOL)animated {
    NSArray<UIViewController *> *controllers = [self leak_popToRootViewControllerAnimated:animated];
    
    for (UIViewController *vc in controllers)
    {
        [vc willDealloc];
    }
    
    return controllers;
}

#endif

@end

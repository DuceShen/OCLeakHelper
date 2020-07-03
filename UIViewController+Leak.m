//
//  UIViewController+Leak.m
//
//

#import "UIViewController+Leak.h"
#import <objc/runtime.h>

@implementation UIViewController (Leak)

#ifdef DEBUG

+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleSEL:@selector(viewDidDisappear:) withSEL:@selector(leak_viewDidDisappear:)];
        [self swizzleSEL:@selector(viewWillAppear:) withSEL:@selector(leak_viewWillAppear:)];
        [self swizzleSEL:@selector(dismissViewControllerAnimated:completion:) withSEL:@selector(leak_dismissViewControllerAnimated:completion:)];
    });
}

+ (void)swizzleSEL:(SEL)oriSEL withSEL:(SEL)curSEL
{
    Class selfClass = [self class];

    Method oriMethod = class_getInstanceMethod(selfClass, oriSEL);
    Method curMethod = class_getInstanceMethod(selfClass, curSEL);
    
    BOOL addSucc = class_addMethod(selfClass, oriSEL, method_getImplementation(curMethod), method_getTypeEncoding(curMethod));
    if (addSucc)
    {
        class_replaceMethod(selfClass, curSEL, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    }
    else
    {
        method_exchangeImplementations(oriMethod, curMethod);
    }
}

-(void) setPoped:(BOOL)poped
{
    objc_setAssociatedObject(self, @selector(poped), @(poped), OBJC_ASSOCIATION_RETAIN);
}

-(BOOL) poped
{
    NSNumber* val =  objc_getAssociatedObject(self, _cmd);
    if(val==nil)
    {
        return NO;
    }
    
    return val.boolValue;
}



- (void)leak_viewDidDisappear:(BOOL)animated
{
    [self leak_viewDidDisappear:animated];
    
    if (self.poped)
    {
        [self willDealloc];
    }
}
    
- (void)leak_viewWillAppear:(BOOL)animated
{
    [self leak_viewWillAppear:animated];
}

- (void)leak_dismissViewControllerAnimated:(BOOL)flag completion:(void (^ __nullable)(void))completion
{
    [self leak_dismissViewControllerAnimated:flag completion:completion];
    
    UIViewController *controller = self.presentedViewController;
    if (!controller && self.presentingViewController)
    {
        controller = self;
    }
    
    if (!controller) return;
    
    [controller willDealloc];
}


- (void)willDealloc
{
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf)
        {
            NSString *msg = [NSString stringWithFormat:@"%@ Leak", weakSelf.class];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:nil]];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        }
    });
}

#endif

@end

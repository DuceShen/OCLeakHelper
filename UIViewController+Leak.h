//
//  UIViewController+Leak.h
//
//

#import <UIKit/UIKit.h>

@interface UIViewController (Leak)
@property (nonatomic, assign) BOOL poped;

- (void)willDealloc;

+ (void)swizzleSEL:(SEL)oriSEL withSEL:(SEL)curSEL;
@end

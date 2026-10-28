#pragma once
#import <UIKit/UIKit.h>

@interface _0xDEADBEEE : UIViewController

@property (nonatomic, copy) void (^onCloseBlock)(void);
@property (nonatomic, copy) void (^onExitHUDRequested)(void);

- (BOOL)_0xF010:(CGPoint)point phase:(NSInteger)phase pointerId:(NSInteger)pointerId;

@end
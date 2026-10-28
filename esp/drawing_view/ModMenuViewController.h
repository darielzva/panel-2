#pragma once
#import <UIKit/UIKit.h>

@interface _0xDEADBEEE : UIViewController

@property (nonatomic, copy) void (^onCloseBlock)(void);
@property (nonatomic, copy) void (^onExitHUDRequested)(void);

@end
#ifdef MIZZE_INJECTED
#import "InjectedMenuController.h"
#import "UIView+SecureView.h"
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPPrefs.h"
#import "../esp/drawing_view/menu.h"

// Passthrough root view: never captures touches for itself.
// Subviews (_0xDAB2826 has userInteractionEnabled=NO; _0xB1872A2 has its
// own hitTest that returns nil for self) each handle their own hits.
// Without this, UIKit walks up and assigns unmatched touches to this view,
// blocking the game from receiving them simultaneously.
@interface _MizzeRootPassthroughView : UIView @end
@implementation _MizzeRootPassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return (hit == self) ? nil : hit;
}
@end

@interface InjectedMenuController ()
@property(nonatomic,strong) UIView   *espView;
@property(nonatomic,strong) _0xB1872A2 *menuControl;
@end

@implementation InjectedMenuController

- (void)loadView {
    self.view = [[_MizzeRootPassthroughView alloc] initWithFrame:UIScreen.mainScreen.bounds];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    ESPSyncFromPrefs();

    // ── 1. ESP draw overlay (boxes / bones / text — no interaction) ───────────
    self.espView = [[_0xDAB2826 alloc] initWithFrame:self.view.bounds];
    self.espView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.espView hideViewFromCapture:ESPPrefsBool(@"AnLive", NO)];
    [self.view addSubview:self.espView];

    // ── 2. Menu control layer (floating "I" button + 3-finger tap + panel
    //       _0xDEADBEEE + feature floating buttons Ghost/Fly/etc.) ─────────────
    self.menuControl = [[_0xB1872A2 alloc] initWithFrame:self.view.bounds];
    self.menuControl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.menuControl];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.gameWindow.rootViewController.supportedInterfaceOrientations ?: UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate {
    return self.gameWindow.rootViewController.shouldAutorotate;
}

@end
#endif

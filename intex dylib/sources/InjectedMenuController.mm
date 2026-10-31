#ifdef MIZZE_INJECTED
#import "InjectedMenuController.h"
#import "UIView+SecureView.h"
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPPrefs.h"
#import "../esp/drawing_view/menu.h"

@interface InjectedMenuController ()
@property(nonatomic,strong) UIView   *espView;
@property(nonatomic,strong) _0xB1872A2 *menuControl;
@end

@implementation InjectedMenuController

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

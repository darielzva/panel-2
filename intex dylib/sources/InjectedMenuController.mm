#ifdef MIZZE_INJECTED
#import "InjectedMenuController.h"
#import "UIView+SecureView.h"
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPPrefs.h"
#import "../menu/Menu.h"

// Registrado en MenuSetup.mm
void MenuSetupRegisterItems();

@interface InjectedMenuController ()
@property(nonatomic,strong) UIView *espView;
@end

@implementation InjectedMenuController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.clearColor;
    ESPSyncFromPrefs();

    // ESP draw overlay (CADisplayLink, renderiza boxes/bones sobre el juego)
    self.espView = [[_0xDAB2826 alloc] initWithFrame:self.view.bounds];
    self.espView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.espView hideViewFromCapture:ESPPrefsBool(@"AnLive", NO)];
    [self.view addSubview:self.espView];

    // Registrar items del nuevo panel y mostrarlo (MMFloat + MMPanel)
    MenuSetupRegisterItems();
    MyMenu::Show();
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return self.gameWindow.rootViewController.supportedInterfaceOrientations ?: UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate {
    return self.gameWindow.rootViewController.shouldAutorotate;
}

@end
#endif

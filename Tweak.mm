#import "Menu.h"
#import "ESP.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
#import "esp/drawing_view/esp.h"
#pragma clang diagnostic pop

#import "esp/drawing_view/ESPPrefs.h"

using MyMenu::Tab;

// The real drawing view lives in esp/drawing_view/_0xE298S9_.mm.
// It contains the entity loop, CADisplayLink, all CAShapeLayer paths,
// ESPSyncFromPrefs, and the _0x35572DA per-player draw calls.
// We instantiate it by class name so this file has no link-time dependency.

// ---------------------------------------------------------------------------
// Retain-cycle-free retry loop for attaching the ESP view to the game window.
// Uses a plain C function instead of a recursive block, so there is no capture.
// ---------------------------------------------------------------------------
static void AttachESPView(int attempt) {
    UIWindow *win = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (![s isKindOfClass:UIWindowScene.class]) continue;
        if (s.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *w in ((UIWindowScene *)s).windows)
            if (w.isKeyWindow) { win = w; break; }
        if (win) break;
    }

    if (!win) {
        if (attempt < 30)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC),
                           dispatch_get_main_queue(), ^{ AttachESPView(attempt + 1); });
        return;
    }

    // _0xDAB2826 manages its own CADisplayLink, entity iteration, and draw calls.
    // Adding it once is all that's needed — it self-updates via the display link.
    UIView *espView = [[NSClassFromString(@"_0xDAB2826") alloc] initWithFrame:win.bounds];
    espView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                               UIViewAutoresizingFlexibleHeight;
    espView.layer.zPosition  = 500; // above game, below menu
    [win addSubview:espView];
}

// ---------------------------------------------------------------------------

__attribute__((constructor))
static void MenuInit() {

    // Restore saved prefs into extern bools/floats before the menu renders.
    ESPSyncFromPrefs();

    // Mirror restored state into ESPConfig so menu toggle callbacks start correct.
    ESP::Config().enabled       = true;
    ESP::Config().box           = isBox;
    ESP::Config().line          = isLine;
    ESP::Config().skeleton      = isBone;
    ESP::Config().name          = isName;
    ESP::Config().health        = isHealth;
    ESP::Config().distance      = isDis;
    ESP::Config().weapon        = isWeapon;
    ESP::Config().aimbot        = isAimbot;
    ESP::Config().aimFov        = aimFov;
    ESP::Config().aimSpeed      = aimSpeed;
    ESP::Config().triggerMode   = triggerMode;
    ESP::Config().aimTargetMode = aimTargetMode;

    // ----------------------------------------------------------------
    // ESP TAB
    // ----------------------------------------------------------------
    MyMenu::AddToggle(Tab::Esp, "esp.master", [](bool on) {
        // Master gates all sub-features without clobbering their saved state.
        isBox    = on && ESP::Config().box;
        isBone   = on && ESP::Config().skeleton;
        isLine   = on && ESP::Config().line;
        isName   = on && ESP::Config().name;
        isDis    = on && ESP::Config().distance;
        isHealth = on && ESP::Config().health;
        isWeapon = on && ESP::Config().weapon;
        ESPPrefsSetBool(@"ESPEnabled", on);
        ESPPrefsSync();
    });

    MyMenu::AddSection(Tab::Esp, "sec.draw");

    MyMenu::AddToggle(Tab::Esp, "esp.box", [](bool on) {
        ESP::Config().box = on;
        isBox = on;
        ESPPrefsSetBool(@"Box", on);
        ESPPrefsSync();
    });

    MyMenu::AddToggle(Tab::Esp, "esp.line", [](bool on) {
        ESP::Config().line = on;
        isLine = on;
        ESPPrefsSetBool(@"Line", on);
        ESPPrefsSync();
    });

    MyMenu::AddToggle(Tab::Esp, "esp.skeleton", [](bool on) {
        ESP::Config().skeleton = on;
        isBone = on;
        ESPPrefsSetBool(@"Bone", on);
        ESPPrefsSync();
    });

    MyMenu::AddSection(Tab::Esp, "sec.info");

    MyMenu::AddToggle(Tab::Esp, "esp.name", [](bool on) {
        ESP::Config().name = on;
        isName = on;
        ESPPrefsSetBool(@"Name", on);
        ESPPrefsSync();
    });

    MyMenu::AddToggle(Tab::Esp, "esp.distance", [](bool on) {
        ESP::Config().distance = on;
        isDis = on;
        ESPPrefsSetBool(@"Dis", on);
        ESPPrefsSync();
    });

    MyMenu::AddToggle(Tab::Esp, "esp.health", [](bool on) {
        ESP::Config().health = on;
        isHealth = on;
        ESPPrefsSetBool(@"HP", on);
        ESPPrefsSync();
    });

    MyMenu::AddToggle(Tab::Esp, "esp.weapon", [](bool on) {
        ESP::Config().weapon = on;
        isWeapon = on;
        ESPPrefsSetBool(@"Weapon", on);
        ESPPrefsSync();
    });

    // ----------------------------------------------------------------
    // AIMBOT TAB
    // ----------------------------------------------------------------
    MyMenu::AddToggle(Tab::Aim, "aim.master", [](bool on) {
        ESP::Config().aimbot = on;
        isAimbot = on;
        ESPPrefsSetBool(@"Aimbot", on);
        ESPPrefsSync();
    });

    MyMenu::AddToggle(Tab::Aim, "aim.ignorewall", [](bool on) {
        ESP::Config().aimIgnoreWall = on;
        isAimIgnoreKnock = on;
        ESPPrefsSetBool(@"AimIgnoreKnock", on);
        ESPPrefsSync();
    });

    MyMenu::AddSlider(Tab::Aim, "aim.fov", 10.0f, 360.0f, aimFov, [](float v) {
        ESP::Config().aimFov = v;
        aimFov = v;
        ESPClearAimLock();
        ESPPrefsSetFloat(@"AimFov", v);
        ESPPrefsSync();
    });

    MyMenu::AddSlider(Tab::Aim, "aim.speed", 1.0f, 10.0f, aimSpeed, [](float v) {
        ESP::Config().aimSpeed = v;
        aimSpeed = v;
        ESPPrefsSetFloat(@"AimSpeed", v);
        ESPPrefsSync();
    });

    MyMenu::AddChoice(Tab::Aim, "aim.trigger",
        {"opt.always", "opt.firing", "opt.aiming"}, triggerMode,
        [](int i) {
            ESP::Config().triggerMode = i;
            triggerMode = i;
            ESPPrefsSetFloat(@"TriggerMode", (float)i);
            ESPPrefsSync();
        });

    MyMenu::AddChoice(Tab::Aim, "aim.target",
        {"opt.head", "opt.chest"}, aimTargetMode,
        [](int i) {
            ESP::Config().aimTargetMode = i;
            aimPosition = i;
            ESPPrefsSetFloat(@"AimPosition", (float)i);
            ESPPrefsSetFloat(@"AimType",     (float)i);
            ESPPrefsSync();
        });

    // ----------------------------------------------------------------
    // EXTRAS TAB
    // ----------------------------------------------------------------
    MyMenu::AddSection(Tab::Extras, "sec.general");
    MyMenu::AddToggle(Tab::Extras, "ext.fps",       [](bool on) { /* wire when ready */ });
    MyMenu::AddToggle(Tab::Extras, "ext.crosshair", [](bool on) { /* wire when ready */ });

    // ----------------------------------------------------------------
    // Attach the real ESP overlay (_0xDAB2826) to the game window.
    // Retries every second until the key window is available.
    // ----------------------------------------------------------------
    ESP::Start(); // keeps ESP.mm / MMOverlay in the build

    dispatch_async(dispatch_get_main_queue(), ^{ AttachESPView(0); });

    MyMenu::Show();
}

#ifdef MIZZE_INJECTED
#import "../menu/Menu.h"
#import "../menu/Loc.h"
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPPrefs.h"
#import "../sources/MizzeMenuPrefs.h"

// ── Global state vars NOT defined in _0xE298S9_.mm ──────────────────────────
// isBox, isBone, isHealth, isName, isDis, isLine, isHeadRedDot, isBox3D,
// isCleanESP are defined + owned by _0xE298S9_.mm (extern via esp.h).
// Everything below is unique to this translation unit.
bool isWeapon           = false;
bool isAimbot           = false;
bool isAimIgnoreKnock   = false;
bool isAimIgnoreBot     = false;
bool isAimCheckVisible  = false;
bool isAimRage          = false;
bool isLineAim          = false;
bool isEspBot           = false;
int  box                = 0;
int  triggerMode        = 0;
int  aimPosition        = 0;
int  aimTargetMode      = 0;
float aimFov            = 120.f;
float aimDistance       = 300.f;
float aimSpeed          = 5.f;
bool gGhostMode         = false;
bool gAutoFire          = false;
bool gAutoSwap          = false;
bool gRunSpeed          = false;
bool gFastFire          = false;
bool gNoReload          = false;
float gRunSpeedValue    = 6.f;
// ─────────────────────────────────────────────────────────────────────────────

using MyMenu::Tab;

// Registra todos los items del menú. Se llama desde InjectedMenuController
// justo antes de MyMenu::Show(), así los items ya existen cuando el panel abre.
void MenuSetupRegisterItems() {

    // ── ESP ──────────────────────────────────────────────────────────────────
    // "esp.master" → ESPEnabled key — master switch read by ESPSyncFromPrefs
    MyMenu::AddToggle(Tab::Esp, "esp.master", [](bool on) {
        ESPPrefsSetBool(@"ESPEnabled", on);
    });

    MyMenu::AddSection(Tab::Esp, "sec.draw");
    MyMenu::AddToggle(Tab::Esp, "esp.box", [](bool on) {
        ESPPrefsSetBool(@"Box", on);
    });
    MyMenu::AddToggle(Tab::Esp, "esp.box3d", [](bool on) {
        ESPPrefsSetBool(@"Box3D", on);
    });
    MyMenu::AddToggle(Tab::Esp, "esp.line", [](bool on) {
        ESPPrefsSetBool(@"Line", on);
    });
    MyMenu::AddToggle(Tab::Esp, "esp.skeleton", [](bool on) {
        ESPPrefsSetBool(@"Skeleton", on);
    });
    MyMenu::AddToggle(Tab::Esp, "esp.reddot", [](bool on) {
        ESPPrefsSetBool(@"HeadRedDot", on);
    });

    MyMenu::AddSection(Tab::Esp, "sec.info");
    MyMenu::AddToggle(Tab::Esp, "esp.name", [](bool on) {
        ESPPrefsSetBool(@"Name", on);
    });
    MyMenu::AddToggle(Tab::Esp, "esp.distance", [](bool on) {
        ESPPrefsSetBool(@"Dis", on);
    });
    MyMenu::AddToggle(Tab::Esp, "esp.health", [](bool on) {
        ESPPrefsSetBool(@"Health", on);
    });
    MyMenu::AddToggle(Tab::Esp, "esp.bots", [](bool on) {
        isEspBot = on; // no ESPPrefs key for this — direct var write
    });

    MyMenu::AddSection(Tab::Esp, "sec.fov");
    MyMenu::AddToggle(Tab::Esp, "esp.aimline", [](bool on) {
        isLineAim = on;
        ESPPrefsSetBool(@"AimTargetLine", on);
    });
    MyMenu::AddSlider(Tab::Esp, "aim.fov", 10.0f, 360.0f, 120.0f, [](float v) {
        aimFov = v;
        ESPPrefsSetFloat(@"FovSize", v);
    });

    // ── AIMBOT ───────────────────────────────────────────────────────────────
    // AimType: 0=Head, 1=Neck, 2=Silent — controlled by choice below
    MyMenu::AddToggle(Tab::Aim, "aim.master", [](bool on) {
        isAimbot = on;
        // AimActivation: 0=Off, 1=Always, 2=Firing, 3=Scoping
        ESPPrefsSetFloat(@"AimActivation", on ? 1.0f : 0.0f);
        ESPPrefsSetBool(@"ExplicitAimMenuV1", YES);
    });
    MyMenu::AddToggle(Tab::Aim, "aim.ignorewall", [](bool on) {
        isAimIgnoreKnock = on;
    });
    MyMenu::AddToggle(Tab::Aim, "aim.ignorebot", [](bool on) {
        isAimIgnoreBot = on;
    });
    MyMenu::AddToggle(Tab::Aim, "aim.checkvis", [](bool on) {
        isAimCheckVisible = on;
    });
    MyMenu::AddToggle(Tab::Aim, "aim.rage", [](bool on) {
        isAimRage = on;
        ESPPrefsSetFloat(@"AimType", on ? 2.0f : 0.0f); // 2=Silent(rage), 0=Head
        ESPPrefsSetBool(@"ExplicitAimMenuV1", YES);
    });
    MyMenu::AddSlider(Tab::Aim, "aim.fov", 10.0f, 360.0f, 120.0f, [](float v) {
        aimFov = v;
        ESPPrefsSetFloat(@"SilentFovSize", v);
        ESPPrefsSetFloat(@"FovSize", v);
    });
    MyMenu::AddSlider(Tab::Aim, "aim.speed", 1.0f, 10.0f, 5.0f, [](float v) {
        aimSpeed = v;
        // AimSpeed in ESPPrefs is degrees/sec (1-10 → scale to 20-360)
        ESPPrefsSetFloat(@"AimSpeed", v * 36.0f);
    });
    MyMenu::AddSlider(Tab::Aim, "aim.distance", 50.0f, 500.0f, 300.0f, [](float v) {
        aimDistance = v;
        ESPPrefsSetFloat(@"SilentMaxDistance", v / 3.0f); // SilentMaxDistance is 10-150
        ESPPrefsSetFloat(@"ESPMaxDistance", v);
    });
    MyMenu::AddChoice(Tab::Aim, "aim.trigger",
                      {"opt.always", "opt.firing", "opt.aiming"}, 0,
                      [](int i) {
        triggerMode = i;
        // AimActivation: 1=Always, 2=Firing, 3=Scoping
        ESPPrefsSetFloat(@"AimActivation", (float)(i + 1));
        ESPPrefsSetBool(@"ExplicitAimMenuV1", YES);
    });
    MyMenu::AddChoice(Tab::Aim, "aim.target",
                      {"opt.head", "opt.chest"}, 0,
                      [](int i) {
        aimPosition = i;
        // AimType: 0=Head, 1=Neck(chest approximation)
        ESPPrefsSetFloat(@"AimType", (float)i);
        ESPPrefsSetBool(@"ExplicitAimMenuV1", YES);
    });

    // ── EXTRAS ───────────────────────────────────────────────────────────────
    MyMenu::AddSection(Tab::Extras, "sec.general");
    MyMenu::AddToggle(Tab::Extras, "ext.ghostmode", [](bool on) {
        gGhostMode = on;
        ESPPrefsSetBool(@"GhostMode", on);
    });
    MyMenu::AddToggle(Tab::Extras, "ext.autofire", [](bool on) {
        gAutoFire = on;
        ESPPrefsSetBool(@"AutoFire", on);
    });
    MyMenu::AddToggle(Tab::Extras, "ext.autoswap", [](bool on) {
        gAutoSwap = on;
    });
    MyMenu::AddToggle(Tab::Extras, "ext.noreload", [](bool on) {
        gNoReload = on;
        ESPPrefsSetBool(@"ShootNoReload", on);
    });
    MyMenu::AddToggle(Tab::Extras, "ext.fastfire", [](bool on) {
        gFastFire = on;
        ESPPrefsSetBool(@"FastFire", on);
    });
    MyMenu::AddToggle(Tab::Extras, "ext.weapon", [](bool on) {
        isWeapon = on;
    });

    MyMenu::AddSection(Tab::Extras, "sec.movement");
    MyMenu::AddToggle(Tab::Extras, "ext.speed", [](bool on) {
        gRunSpeed = on;
        ESPPrefsSetBool(@"RunSpeed", on);
    });
    MyMenu::AddSlider(Tab::Extras, "ext.speedval", 1.0f, 20.0f, 6.0f, [](float v) {
        gRunSpeedValue = v;
        ESPPrefsSetFloat(@"RunSpeedValue", v);
    });

    // ── CUENTA ───────────────────────────────────────────────────────────────
    // MyMenu::SetAccount({ "TU-CLAVE", 30 });
}
#endif

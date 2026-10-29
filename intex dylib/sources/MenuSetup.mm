#ifdef MIZZE_INJECTED
#import "../menu/Menu.h"
#import "../menu/Loc.h"

// ── Definiciones de variables de estado (declaradas como extern en esp.h) ────
bool isBox          = false;
bool isBone         = false;
bool isHealth       = false;
bool isName         = false;
bool isDis          = false;
bool isLine         = false;
bool isHeadRedDot   = false;
bool isBox3D        = false;
bool isCleanESP     = false;
bool isWeapon       = false;
bool isAimbot       = false;
bool isAimIgnoreKnock   = false;
bool isAimIgnoreBot     = false;
bool isAimCheckVisible  = false;
bool isAimRage      = false;
bool isLineAim      = false;
bool isEspBot       = false;
int  box            = 0;
int  triggerMode    = 0;
int  aimPosition    = 0;
int  aimTargetMode  = 0;
float aimFov        = 120.f;
float aimDistance   = 300.f;
float aimSpeed      = 5.f;
bool gGhostMode     = false;
bool gAutoFire      = false;
bool gAutoSwap      = false;
bool gRunSpeed      = false;
bool gFastFire      = false;
bool gNoReload      = false;
float gRunSpeedValue = 6.f;
// ─────────────────────────────────────────────────────────────────────────────

using MyMenu::Tab;

// Registra todos los items del menú. Se llama desde InjectedMenuController
// justo antes de MyMenu::Show(), así los items ya existen cuando el panel abre.
void MenuSetupRegisterItems() {

    // ── ESP ──────────────────────────────────────────────────────────────────
    MyMenu::AddToggle(Tab::Esp, "esp.master",   [](bool on) { isCleanESP = on; });

    MyMenu::AddSection(Tab::Esp, "sec.draw");
    MyMenu::AddToggle(Tab::Esp, "esp.box",      [](bool on) { isBox = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.box3d",    [](bool on) { isBox3D = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.line",     [](bool on) { isLine = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.skeleton", [](bool on) { isBone = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.reddot",   [](bool on) { isHeadRedDot = on; });

    MyMenu::AddSection(Tab::Esp, "sec.info");
    MyMenu::AddToggle(Tab::Esp, "esp.name",     [](bool on) { isName = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.distance", [](bool on) { isDis = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.health",   [](bool on) { isHealth = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.bots",     [](bool on) { isEspBot = on; });

    MyMenu::AddSection(Tab::Esp, "sec.fov");
    MyMenu::AddToggle(Tab::Esp, "esp.aimline",  [](bool on) { isLineAim = on; });
    MyMenu::AddSlider(Tab::Esp, "aim.fov",      10.0f, 360.0f, 120.0f, [](float v) { aimFov = v; });

    // ── AIMBOT ───────────────────────────────────────────────────────────────
    MyMenu::AddToggle(Tab::Aim, "aim.master",     [](bool on) { isAimbot = on; });
    MyMenu::AddToggle(Tab::Aim, "aim.ignorewall", [](bool on) { isAimIgnoreKnock = on; });
    MyMenu::AddToggle(Tab::Aim, "aim.ignorebot",  [](bool on) { isAimIgnoreBot = on; });
    MyMenu::AddToggle(Tab::Aim, "aim.checkvis",   [](bool on) { isAimCheckVisible = on; });
    MyMenu::AddToggle(Tab::Aim, "aim.rage",       [](bool on) { isAimRage = on; });
    MyMenu::AddSlider(Tab::Aim, "aim.fov",        10.0f, 360.0f, 120.0f, [](float v) { aimFov = v; });
    MyMenu::AddSlider(Tab::Aim, "aim.speed",       1.0f,  10.0f,   5.0f, [](float v) { aimSpeed = v; });
    MyMenu::AddSlider(Tab::Aim, "aim.distance",   50.0f, 500.0f, 300.0f, [](float v) { aimDistance = v; });
    MyMenu::AddChoice(Tab::Aim, "aim.trigger",
                      {"opt.always", "opt.firing", "opt.aiming"}, 0,
                      [](int i) { triggerMode = i; });
    MyMenu::AddChoice(Tab::Aim, "aim.target",
                      {"opt.head", "opt.chest"}, 0,
                      [](int i) { aimPosition = i; });

    // ── EXTRAS ───────────────────────────────────────────────────────────────
    MyMenu::AddSection(Tab::Extras, "sec.general");
    MyMenu::AddToggle(Tab::Extras, "ext.ghostmode", [](bool on) { gGhostMode = on; });
    MyMenu::AddToggle(Tab::Extras, "ext.autofire",  [](bool on) { gAutoFire = on; });
    MyMenu::AddToggle(Tab::Extras, "ext.autoswap",  [](bool on) { gAutoSwap = on; });
    MyMenu::AddToggle(Tab::Extras, "ext.noreload",  [](bool on) { gNoReload = on; });
    MyMenu::AddToggle(Tab::Extras, "ext.fastfire",  [](bool on) { gFastFire = on; });
    MyMenu::AddToggle(Tab::Extras, "ext.weapon",    [](bool on) { isWeapon = on; });

    MyMenu::AddSection(Tab::Extras, "sec.movement");
    MyMenu::AddToggle(Tab::Extras, "ext.speed",     [](bool on) { gRunSpeed = on; });
    MyMenu::AddSlider(Tab::Extras, "ext.speedval",  1.0f, 20.0f, 6.0f,
                      [](float v) { gRunSpeedValue = v; });

    // ── CUENTA ───────────────────────────────────────────────────────────────
    // MyMenu::SetAccount({ "TU-CLAVE", 30 });
}
#endif

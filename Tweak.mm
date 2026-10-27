#import "Menu.h"
#import "ESP.h"

using MyMenu::Tab;

__attribute__((constructor))
static void MenuInit() {

    // ---------------- ESP ----------------
    MyMenu::AddToggle(Tab::Esp, "esp.master", [](bool on) { ESP::Config().enabled = on; });

    MyMenu::AddSection(Tab::Esp, "sec.draw");
    MyMenu::AddToggle(Tab::Esp, "esp.box",      [](bool on) { ESP::Config().box = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.line",     [](bool on) { ESP::Config().line = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.skeleton", [](bool on) { /* tu lógica */ });

    MyMenu::AddSection(Tab::Esp, "sec.info");
    MyMenu::AddToggle(Tab::Esp, "esp.name",     [](bool on) { ESP::Config().name = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.distance", [](bool on) { ESP::Config().distance = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.health",   [](bool on) { ESP::Config().health = on; });
    MyMenu::AddToggle(Tab::Esp, "esp.weapon",   [](bool on) { /* tu lógica */ });

    // ---------------- AIMBOT (solo visual por ahora) ----------------
    MyMenu::AddToggle(Tab::Aim, "aim.master",     [](bool on) { /* tu lógica */ });
    MyMenu::AddToggle(Tab::Aim, "aim.ignorewall", [](bool on) { /* tu lógica */ });
    MyMenu::AddSlider(Tab::Aim, "aim.fov",   10.0f, 360.0f, 120.0f, [](float v) { /* tu lógica */ });
    MyMenu::AddSlider(Tab::Aim, "aim.speed",  1.0f,  10.0f,   5.0f, [](float v) { /* tu lógica */ });
    MyMenu::AddChoice(Tab::Aim, "aim.trigger", {"opt.always", "opt.firing", "opt.aiming"}, 0,
                      [](int i) { /* tu lógica */ });
    MyMenu::AddChoice(Tab::Aim, "aim.target",  {"opt.head", "opt.chest"}, 0,
                      [](int i) { /* tu lógica */ });

    // ---------------- EXTRAS (solo visual por ahora) ----------------
    MyMenu::AddSection(Tab::Extras, "sec.general");
    MyMenu::AddToggle(Tab::Extras, "ext.fps",       [](bool on) { /* tu lógica */ });
    MyMenu::AddToggle(Tab::Extras, "ext.crosshair", [](bool on) { /* tu lógica */ });

    // ---------------- CUENTA ----------------
    // Rellénalo con los datos reales de tu propio sistema cuando lo tengas:
    // MyMenu::SetAccount({ "TU-CLAVE", 30 });

    // ---------------- Dibujo ESP (marca de prueba) ----------------
    ESP::SetDrawCallback([](CGContextRef ctx, CGSize screen) {
        NSString *test = @"ESP activo";
        [test drawAtPoint:CGPointMake(screen.width / 2 - 30, 20)
           withAttributes:@{ NSForegroundColorAttributeName: UIColor.greenColor,
                             NSFontAttributeName: [UIFont boldSystemFontOfSize:12] }];
    });

    ESP::Start();      // primero la capa de dibujo
    MyMenu::Show();    // después el menú, para que quede por encima
}

#import "Loc.h"
#include <string>
#include <unordered_map>

namespace {

struct Row { const char *en, *es, *vi; };

const std::unordered_map<std::string, Row> &Table() {
    static const std::unordered_map<std::string, Row> t = {
        // Pestañas
        {"tab.esp",        {"ESP",           "ESP",            "ESP"}},
        {"tab.aim",        {"AIMBOT",        "AIMBOT",         "AIMBOT"}},
        {"tab.extras",     {"EXTRAS",        "EXTRAS",         "TIỆN ÍCH"}},
        {"tab.config",     {"SETTINGS",      "CONFIGURACIÓN",  "CẤU HÌNH"}},
        {"tab.account",    {"ACCOUNT",       "CUENTA",         "TÀI KHOẢN"}},

        // Secciones
        {"sec.draw",       {"DRAW",          "DIBUJO",         "VẼ"}},
        {"sec.info",       {"INFO",          "INFO",           "THÔNG TIN"}},
        {"sec.general",    {"GENERAL",       "GENERAL",        "CHUNG"}},
        {"sec.license",    {"LICENSE",       "LICENCIA",       "GIẤY PHÉP"}},
        {"sec.about",      {"ABOUT",         "ACERCA DE",      "GIỚI THIỆU"}},
        {"sec.links",      {"LINKS",         "ENLACES",        "LIÊN KẾT"}},

        // ESP
        {"esp.master",     {"ESP master",    "ESP principal",  "ESP chính"}},
        {"esp.box",        {"Box",           "Caja",           "Hộp"}},
        {"esp.line",       {"Line",          "Línea",          "Đường kẻ"}},
        {"esp.skeleton",   {"Skeleton",      "Esqueleto",      "Xương"}},
        {"esp.name",       {"Name",          "Nombre",         "Tên"}},
        {"esp.distance",   {"Distance",      "Distancia",      "Khoảng cách"}},
        {"esp.health",     {"Health",        "Vida",           "Máu"}},
        {"esp.weapon",     {"Weapon",        "Arma",           "Vũ khí"}},

        // Aimbot
        {"aim.master",     {"Aimbot",        "Aimbot",         "Aimbot"}},
        {"aim.ignorewall", {"Ignore walls",  "Ignorar pared",  "Bỏ qua tường"}},
        {"aim.fov",        {"FOV radius",    "Radio FOV",      "Bán kính FOV"}},
        {"aim.speed",      {"Speed",         "Velocidad",      "Tốc độ"}},
        {"aim.trigger",    {"Activate",      "Activar",        "Kích hoạt"}},
        {"aim.target",     {"Target",        "Objetivo",       "Mục tiêu"}},
        {"opt.always",     {"Always",        "Siempre",        "Luôn luôn"}},
        {"opt.firing",     {"When firing",   "Al disparar",    "Khi bắn"}},
        {"opt.aiming",     {"When aiming",   "Al apuntar",     "Khi ngắm"}},
        {"opt.head",       {"Head",          "Cabeza",         "Đầu"}},
        {"opt.chest",      {"Chest",         "Pecho",          "Ngực"}},

        // Extras
        {"ext.fps",        {"Show FPS",      "Mostrar FPS",    "Hiện FPS"}},
        {"ext.crosshair",  {"Crosshair",     "Mira",           "Tâm ngắm"}},

        // Configuración
        {"cfg.custom",     {"CUSTOMIZE",     "PERSONALIZAR",   "TÙY CHỈNH"}},
        {"cfg.opacity",    {"Opacity",       "Opacidad",       "Độ trong suốt"}},
        {"cfg.accent",     {"Accent color",  "Color de acento","Màu nhấn"}},
        {"cfg.square",     {"Square corners","Puntas cuadradas","Góc vuông"}},
        {"cfg.language",   {"Language",      "Idioma",         "Ngôn ngữ"}},

        // Cuenta
        {"acc.key",        {"Key",           "Clave",          "Khóa"}},
        {"acc.days",       {"Days left",     "Días restantes", "Ngày còn lại"}},
        {"acc.product",    {"Product",       "Producto",       "Sản phẩm"}},
        {"acc.version",    {"Version",       "Versión",        "Phiên bản"}},
        {"acc.creator",    {"Creator",       "Creador",        "Người tạo"}},
        {"acc.contact",    {"Contact",       "Contacto",       "Liên hệ"}},
        {"acc.group",      {"Group",         "Grupo",          "Nhóm"}},

        // Aviso de Telegram
        {"tg.title",       {"Join our Telegram", "Únete a nuestro Telegram", "Tham gia Telegram của chúng tôi"}},
        {"tg.msg",         {"News and support in our group.",
                            "Novedades y soporte en nuestro grupo.",
                            "Cập nhật và hỗ trợ trong nhóm của chúng tôi."}},
        {"tg.open",        {"Open Telegram", "Abrir Telegram", "Mở Telegram"}},
        {"tg.later",       {"Later",         "Más tarde",      "Để sau"}},
    };
    return t;
}

Loc::Lang gLang = Loc::ES;
bool gLoaded = false;

void Load() {
    if (gLoaded) return;
    gLoaded = true;
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if ([ud objectForKey:@"MyMenu.lang"]) {
        NSInteger v = [ud integerForKey:@"MyMenu.lang"];
        if (v >= 0 && v <= 2) gLang = (Loc::Lang)v;
    }
}

} // namespace

namespace Loc {

Lang Get() { Load(); return gLang; }

void Set(Lang l) {
    Load();
    gLang = l;
    [NSUserDefaults.standardUserDefaults setInteger:l forKey:@"MyMenu.lang"];
}

NSString *T(const char *key) {
    Load();
    auto it = Table().find(key);
    if (it == Table().end()) return [NSString stringWithUTF8String:key];
    const char *s = (gLang == EN) ? it->second.en : (gLang == ES) ? it->second.es : it->second.vi;
    return [NSString stringWithUTF8String:s];
}

} // namespace Loc

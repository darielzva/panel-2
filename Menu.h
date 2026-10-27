#pragma once
#import <UIKit/UIKit.h>
#include <functional>
#include <string>
#include <vector>

// Las claves de texto ("esp.box", "aim.fov"...) se traducen con Loc.mm.
namespace MyMenu {

    // Pestañas que se llenan desde código. CONFIGURACIÓN y CUENTA ya vienen integradas.
    enum class Tab { Esp = 0, Aim = 1, Extras = 2 };

    void AddSection(Tab tab, const std::string &titleKey);

    void AddToggle(Tab tab, const std::string &titleKey,
                   std::function<void(bool)> onChange);

    void AddSlider(Tab tab, const std::string &titleKey,
                   float min, float max, float def,
                   std::function<void(float)> onChange);

    // Lista desplegable: optionKeys son claves de texto; el callback recibe el índice elegido.
    void AddChoice(Tab tab, const std::string &titleKey,
                   std::vector<std::string> optionKeys, int defIndex,
                   std::function<void(int)> onChange);

    void AddButton(Tab tab, const std::string &titleKey,
                   std::function<void()> onTap);

    // Datos que muestra la pestaña CUENTA. daysLeft < 0 muestra "—".
    struct AccountInfo {
        std::string key = "—";
        int daysLeft = -1;
    };
    void SetAccount(const AccountInfo &info);

    // Muestra el botón flotante y el panel (llamar una vez, después de registrar todo).
    void Show();
}

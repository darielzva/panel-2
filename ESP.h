#pragma once
#import <UIKit/UIKit.h>
#include <functional>

// Opciones que controla el menú. Tu código de dibujo las lee desde aquí.
struct ESPConfig {
    bool  enabled     = false;
    bool  box         = true;
    bool  line        = false;
    bool  name        = true;
    bool  health      = true;
    bool  distance    = false;
    float thickness   = 1.5f;
    float maxDistance = 300.0f;
};

namespace ESP {

    ESPConfig &Config();

    // Se llama en cada frame con el contexto de dibujo y el tamaño de la pantalla.
    // Aquí va tu lógica: leer entidades, convertir a pantalla y dibujar.
    using DrawCallback = std::function<void(CGContextRef ctx, CGSize screen)>;
    void SetDrawCallback(DrawCallback cb);

    // Crea la capa transparente encima del juego (llamar antes de MyMenu::Show()).
    void Start();
}

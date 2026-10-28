#pragma once
#import <UIKit/UIKit.h>
#include <functional>

// Runtime config — menu callbacks write here; the draw layer reads from here
// AND from the extern bools in esp/drawing_view/esp.h (filled by ESPSyncFromPrefs).
struct ESPConfig {
    bool  enabled       = false;
    bool  box           = false;
    bool  box3D         = false;
    bool  cleanESP      = false;
    bool  line          = false;
    bool  skeleton      = false;   // maps to isBone
    bool  name          = false;
    bool  health        = false;
    bool  distance      = false;
    bool  weapon        = false;
    bool  headRedDot    = false;

    // Aimbot
    bool  aimbot        = false;
    bool  aimIgnoreWall = false;
    bool  aimIgnoreBot  = false;
    float aimFov        = 120.0f;
    float aimSpeed      = 5.0f;
    float aimDistance   = 300.0f;
    int   triggerMode   = 0;   // 0=always 1=firing 2=aiming
    int   aimTargetMode = 0;   // 0=head   1=chest
};

namespace ESP {

    ESPConfig &Config();

    // Called every frame with the Core Graphics context and screen size.
    using DrawCallback = std::function<void(CGContextRef ctx, CGSize screen)>;
    void SetDrawCallback(DrawCallback cb);

    // Creates the transparent overlay above the game. Call before MyMenu::Show().
    void Start();

}

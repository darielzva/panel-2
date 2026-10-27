#pragma once
#import <Foundation/Foundation.h>

// Idiomas del menú: inglés, español y vietnamita.
namespace Loc {
    enum Lang { EN = 0, ES = 1, VI = 2 };

    Lang Get();
    void Set(Lang lang);                 // se guarda entre sesiones

    // Devuelve el texto de la clave en el idioma actual (si no existe, devuelve la clave).
    NSString *T(const char *key);
}

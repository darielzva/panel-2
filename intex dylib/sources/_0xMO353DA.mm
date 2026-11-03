#import "ModMenuViewController.h"
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPStyle.h"
#import <objc/runtime.h>
#import "UIView+SecureView.h"
#import "MizzeTheme.h"
#import "MizzeMenuPrefs.h"
#include <cmath>
#import "../esp/Core/PlayerModes.h"

// ─────────────────────────────────────────────────────────────────────────────
// SF SYMBOL HELPER
// ─────────────────────────────────────────────────────────────────────────────
static UIImage *SFSym(NSString *name, CGFloat pts, UIImageSymbolWeight w) {
    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:pts weight:w];
    return [UIImage systemImageNamed:name withConfiguration:cfg];
}

// ─────────────────────────────────────────────────────────────────────────────
// IDIOMA — 0=EN, 1=ES, 2=VI
// ─────────────────────────────────────────────────────────────────────────────
static NSInteger DAAELang(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.lang"]) return 0;
    NSInteger v = [ud integerForKey:@"DAAE.lang"];
    return (v >= 0 && v <= 2) ? v : 0;
}
static void DAAESetLang(NSInteger l) {
    [[NSUserDefaults standardUserDefaults] setInteger:l forKey:@"DAAE.lang"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
static NSString *DAAEStr(NSString *en, NSString *es, NSString *vi) {
    switch (DAAELang()) {
        case 1: return es;
        case 2: return vi;
        default: return en;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// TEMA — dark=NO por defecto (modo claro)
// ─────────────────────────────────────────────────────────────────────────────
static BOOL DAAEDark(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    // Si no se ha guardado nunca → modo claro (NO)
    if (![ud objectForKey:@"DAAE.darkMode"]) return NO;
    return [ud boolForKey:@"DAAE.darkMode"];
}
static void DAAESetDark(BOOL dark) {
    [[NSUserDefaults standardUserDefaults] setBool:dark forKey:@"DAAE.darkMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR DE ACENTO — 0=Celeste 1=Naranja 2=Rojo 3=Amarillo 4=Verde
//                   5=Negro(modo claro) / Blanco(modo oscuro) — automático según tema
// ─────────────────────────────────────────────────────────────────────────────
// TAMAÑO DEL PANEL — ancho en pt (default 380, min 300, max 480)
static CGFloat DAAEPanelSize(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.panelSize"]) return 380.0;
    float v = [ud floatForKey:@"DAAE.panelSize"];
    return (CGFloat)MAX(300.0f, MIN(480.0f, v));
}
static void DAAESetPanelSize(float s) {
    [[NSUserDefaults standardUserDefaults] setFloat:MAX(300.0f, MIN(480.0f, s))
                                            forKey:@"DAAE.panelSize"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
// ESQUINAS — 0=Redondeadas(default) 1=Cuadradas
static NSInteger DAAECornerStyle(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.cornerStyle"]) return 0;
    NSInteger v = [ud integerForKey:@"DAAE.cornerStyle"];
    return (v >= 0 && v <= 1) ? v : 0;
}
static void DAAESetCornerStyle(NSInteger s) {
    [[NSUserDefaults standardUserDefaults] setInteger:s forKey:@"DAAE.cornerStyle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
static CGFloat DAAECornerRadius(CGFloat full) {
    return (DAAECornerStyle() == 1) ? 4.0 : full;
}
static NSInteger DAAEAccentIdx(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.accentIdx"]) return 0;
    NSInteger v = [ud integerForKey:@"DAAE.accentIdx"];
    return (v >= 0 && v <= 5) ? v : 0;
}
static void DAAESetAccentIdx(NSInteger idx) {
    [[NSUserDefaults standardUserDefaults] setInteger:idx forKey:@"DAAE.accentIdx"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
// Color de acento real (para sliders, checkmarks, picker activo, sidebar, header)
static UIColor *DAAEAccentColor(void) {
    switch (DAAEAccentIdx()) {
        case 1: return [UIColor colorWithRed:1.00 green:0.60 blue:0.10 alpha:1];  // Naranja
        case 2: return [UIColor colorWithRed:0.95 green:0.22 blue:0.22 alpha:1];  // Rojo
        case 3: return [UIColor colorWithRed:0.95 green:0.82 blue:0.14 alpha:1];  // Amarillo
        case 4: return [UIColor colorWithRed:0.24 green:0.82 blue:0.50 alpha:1];  // Verde
        case 5: return DAAEDark() ? UIColor.whiteColor : UIColor.blackColor;      // Auto
        default: return [UIColor colorWithRed:0.26 green:0.78 blue:0.90 alpha:1]; // Celeste
    }
}
// Texto sobre DAAEAccentColor como fondo (íconos sidebar activo, pill activo)
static UIColor *DAAEAccentFG(void) {
    NSInteger idx = DAAEAccentIdx();
    if (idx == 5) return DAAEDark() ? UIColor.blackColor : UIColor.whiteColor;
    // Para amarillo el texto negro queda mejor
    if (idx == 3) return [UIColor colorWithWhite:0 alpha:0.85];
    return UIColor.whiteColor;
}

// Callback para actualizar swatch de color en tiempo real
static void (^sColorSwatchUpdater)(void) = nil;

// ─────────────────────────────────────────────────────────────────────────────
// PALETA — adaptativa claro/oscuro
// ─────────────────────────────────────────────────────────────────────────────
static UIColor *PanelBG(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:0.08 alpha:0.82]
        : [UIColor colorWithWhite:0.96 alpha:0.90];
}
static UIColor *RowBG(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1.0 alpha:0.07]
        : [UIColor colorWithWhite:0.0 alpha:0.05];
}
static UIColor *RowBGOn(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1.0 alpha:0.13]
        : [UIColor colorWithWhite:0.0 alpha:0.09];
}
static UIColor *SectionClr(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1.0 alpha:0.38]
        : [UIColor colorWithWhite:0.0 alpha:0.38];
}
static UIColor *LblMain(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:0.96 alpha:1.0]
        : [UIColor colorWithWhite:0.08 alpha:1.0];
}
static UIColor *LblDim(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1.0 alpha:0.45]
        : [UIColor colorWithWhite:0.0 alpha:0.40];
}
static UIColor *CheckRing(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1.0 alpha:0.18]
        : [UIColor colorWithWhite:0.0 alpha:0.12];
}
static UIColor *SidebarBG(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:0.0 alpha:0.12]
        : [UIColor colorWithWhite:0.0 alpha:0.05];
}
static UIColor *HeaderBG(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1.0 alpha:0.05]
        : [UIColor colorWithWhite:0.0 alpha:0.04];
}
static UIColor *DivClr(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1.0 alpha:0.07]
        : [UIColor colorWithWhite:0.0 alpha:0.07];
}
// Fondo del panel blur — adapta el estilo del UIBlurEffect
static UIBlurEffectStyle DAAEBlurStyle(void) {
    return DAAEDark()
        ? UIBlurEffectStyleSystemMaterialDark
        : UIBlurEffectStyleSystemMaterialLight;
}

// ─────────────────────────────────────────────────────────────────────────────
// AIM TYPE — raw float persistida; -1 = sin aim
// ─────────────────────────────────────────────────────────────────────────────
static float     AimRaw(void)   { return ESPPrefsFloat(@"AimType", -1); }
static BOOL      AimActive(void){ return AimRaw() >= 0; }
static NSInteger AimIdx(void)   { return AimActive() ? (NSInteger)AimRaw() : -1; }

// ─────────────────────────────────────────────────────────────────────────────
// CHECKMARK CIRCLE — igual a las imágenes
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAECheck : UIView
@property (nonatomic, assign) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
- (void)refreshTheme;
@end
@implementation DAAECheck { UIImageView *_iv; }
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.layer.cornerRadius = f.size.width / 2.0;
        self.layer.borderWidth  = 1.5;
        self.userInteractionEnabled = NO;
        _iv = [[UIImageView alloc] initWithImage:
            SFSym(@"checkmark", 13, UIImageSymbolWeightHeavy)];
        _iv.contentMode = UIViewContentModeScaleAspectFit;
        _iv.frame = CGRectInset(self.bounds, 7, 7);
        [self addSubview:_iv];
        [self setOn:NO animated:NO];
    }
    return self;
}
- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }
- (void)setOn:(BOOL)on animated:(BOOL)anim {
    _on = on;
    UIColor *accent = DAAEAccentColor();
    void (^upd)(void) = ^{
        if (on) {
            self.backgroundColor    = accent;
            self.layer.borderColor  = accent.CGColor;
            self->_iv.tintColor     = UIColor.whiteColor;
            self->_iv.hidden        = NO;
        } else {
            self.backgroundColor    = [UIColor clearColor];
            self.layer.borderColor  = CheckRing().CGColor;
            self->_iv.tintColor     = LblDim();
            self->_iv.hidden        = YES;
        }
    };
    if (anim) [UIView animateWithDuration:0.18 delay:0
        options:UIViewAnimationOptionCurveEaseInOut animations:upd completion:nil];
    else upd();
}
- (void)refreshTheme { [self setOn:_on animated:NO]; }
@end

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE ROW — label + checkmark circle derecha
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAERow : UIButton
@property (nonatomic, strong) DAAECheck *check;
@property (nonatomic, assign) BOOL toggleOn;
@property (nonatomic, copy)   void (^onChanged)(BOOL);
- (void)_applyStyle:(BOOL)on;
- (void)refreshTheme;
@end
@implementation DAAERow
- (instancetype)initWithLabel:(NSString *)txt on:(BOOL)on width:(CGFloat)w {
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, 60)])) {
        self.toggleOn = on;
        [self _applyStyle:on];

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, w - 74, 60)];
        lbl.text      = txt;
        lbl.textColor = LblMain();
        lbl.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        lbl.tag       = 888;
        lbl.userInteractionEnabled = NO;
        [self addSubview:lbl];

        self.check = [[DAAECheck alloc] initWithFrame:CGRectMake(w - 52, 14, 32, 32)];
        [self.check setOn:on animated:NO];
        [self addSubview:self.check];
        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)_applyStyle:(BOOL)on {
    self.backgroundColor    = on ? RowBGOn() : RowBG();
    self.layer.cornerRadius = DAAECornerRadius(14);
    self.layer.borderWidth  = on ? 0.7 : 0;
    self.layer.borderColor  = on
        ? [DAAEAccentColor() colorWithAlphaComponent:0.35].CGColor
        : [UIColor clearColor].CGColor;
    self.clipsToBounds = YES;
}
- (void)refreshTheme {
    [self _applyStyle:self.toggleOn];
    [self.check refreshTheme];
    UILabel *lbl = (UILabel *)[self viewWithTag:888];
    if (lbl) lbl.textColor = LblMain();
}
- (void)_tap {
    self.toggleOn = !self.toggleOn;
    [self.check setOn:self.toggleOn animated:YES];
    BOOL nowOn = self.toggleOn;
    [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{ [self _applyStyle:nowOn]; } completion:nil];
    if (self.onChanged) self.onChanged(self.toggleOn);
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// PILL PICKER ROW — tipo horizontal como en las imágenes
// Un botón por opción, el activo tiene fondo de acento
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAEPillPicker : UIView
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy)   void (^onSelected)(NSInteger idx);
- (instancetype)initWithOptions:(NSArray<NSString *> *)opts
                       selected:(NSInteger)sel
                          width:(CGFloat)w;
- (void)refreshTheme;
@end
@implementation DAAEPillPicker {
    NSArray<UIButton *> *_pills;
    NSArray<NSString *> *_opts;
}
- (instancetype)initWithOptions:(NSArray<NSString *> *)opts
                       selected:(NSInteger)sel
                          width:(CGFloat)w {
    NSInteger n = (NSInteger)opts.count;
    CGFloat h = 50;
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, h)])) {
        _opts = opts;
        _selectedIndex = sel;
        self.backgroundColor    = RowBG();
        self.layer.cornerRadius = DAAECornerRadius(14);
        self.clipsToBounds      = YES;

        CGFloat pad  = 8;
        CGFloat gap  = 6;
        CGFloat btnW = (w - pad * 2 - gap * (n - 1)) / (CGFloat)n;
        CGFloat btnY = (h - 34) / 2.0;

        NSMutableArray<UIButton *> *pills = [NSMutableArray array];
        for (NSInteger i = 0; i < n; i++) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.frame = CGRectMake(pad + i * (btnW + gap), btnY, btnW, 34);
            b.layer.cornerRadius = DAAECornerRadius(10);
            b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
            b.clipsToBounds = YES;
            [b setTitle:opts[(NSUInteger)i] forState:UIControlStateNormal];
            b.tag = 700 + i;
            [b addTarget:self action:@selector(_pillTap:)
                forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:b];
            [pills addObject:b];
        }
        _pills = pills;
        [self _refreshPills];
    }
    return self;
}
- (void)_refreshPills {
    UIColor *accent = DAAEAccentColor();
    for (NSInteger i = 0; i < (NSInteger)_pills.count; i++) {
        UIButton *b = _pills[(NSUInteger)i];
        BOOL sel = (i == _selectedIndex);
        b.backgroundColor = sel ? accent : [UIColor clearColor];
        [b setTitleColor:sel ? UIColor.whiteColor : LblDim() forState:UIControlStateNormal];
    }
}
- (void)_pillTap:(UIButton *)sender {
    NSInteger idx = sender.tag - 700;
    if (idx == _selectedIndex) return;
    _selectedIndex = idx;
    [UIView animateWithDuration:0.15 animations:^{ [self _refreshPills]; }];
    if (self.onSelected) self.onSelected(idx);
}
- (void)refreshTheme {
    self.backgroundColor = RowBG();
    [self _refreshPills];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// SLIDER ROW — label izq., valor en color acento derecha, slider debajo
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAESlider : UIView
- (void)refreshTheme;
@end
@implementation DAAESlider { UILabel *_lbl; UILabel *_val; UISlider *_sl; }
- (instancetype)initWithLabel:(NSString *)txt key:(NSString *)key
                          min:(float)mn max:(float)mx fallback:(float)fb width:(CGFloat)w {
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, 72)])) {
        self.backgroundColor    = RowBG();
        self.layer.cornerRadius = DAAECornerRadius(14);

        _lbl = [[UILabel alloc] initWithFrame:CGRectMake(18, 8, w - 90, 22)];
        _lbl.text      = txt;
        _lbl.textColor = LblMain();
        _lbl.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [self addSubview:_lbl];

        _val = [[UILabel alloc] initWithFrame:CGRectMake(w - 68, 8, 56, 22)];
        _val.textAlignment = NSTextAlignmentRight;
        _val.textColor = DAAEAccentColor();
        _val.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
        float cur = ESPPrefsFloat(key, fb);
        _val.text = [NSString stringWithFormat:@"%.0f", cur];
        [self addSubview:_val];

        _sl = [[UISlider alloc] initWithFrame:CGRectMake(14, 42, w - 28, 22)];
        _sl.minimumValue          = mn;
        _sl.maximumValue          = mx;
        _sl.value                 = cur;
        _sl.minimumTrackTintColor = DAAEAccentColor();
        _sl.maximumTrackTintColor = DAAEDark()
            ? [UIColor colorWithWhite:1 alpha:0.14]
            : [UIColor colorWithWhite:0 alpha:0.10];
        _sl.thumbTintColor = DAAEAccentColor();
        objc_setAssociatedObject(_sl, "valLbl", _val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(_sl, "espKey", key,  OBJC_ASSOCIATION_COPY_NONATOMIC);
        [_sl addTarget:self action:@selector(_slid:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_sl];
    }
    return self;
}
- (void)_slid:(UISlider *)sl {
    UILabel   *val = objc_getAssociatedObject(sl, "valLbl");
    NSString  *key = objc_getAssociatedObject(sl, "espKey");
    val.text = [NSString stringWithFormat:@"%.0f", sl.value];
    ESPPrefsSetFloat(key, sl.value);
    ESPSyncFromPrefs();
    // Actualización en tiempo real del swatch de color
    if (sColorSwatchUpdater && [key containsString:@"Color"]) {
        sColorSwatchUpdater();
    }
}
- (void)refreshTheme {
    UIColor *accent = DAAEAccentColor();
    self.backgroundColor = RowBG();
    _lbl.textColor = LblMain();
    _val.textColor = accent;
    _sl.minimumTrackTintColor = accent;
    _sl.thumbTintColor        = accent;
    _sl.maximumTrackTintColor = DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.14]
        : [UIColor colorWithWhite:0 alpha:0.10];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW helper
// ─────────────────────────────────────────────────────────────────────────────
static UIView *InfoRow(NSString *title, NSString *value, CGFloat w, BOOL dim) {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 52)];
    row.backgroundColor    = RowBG();
    row.layer.cornerRadius = DAAECornerRadius(14);

    UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, w * 0.45, 52)];
    tl.text      = title;
    tl.textColor = LblMain();
    tl.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [row addSubview:tl];

    UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(w * 0.44, 0, w * 0.52 - 8, 52)];
    vl.text          = value;
    vl.textColor     = dim ? LblDim() : DAAEAccentColor();
    vl.font          = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    vl.textAlignment = NSTextAlignmentRight;
    [row addSubview:vl];
    return row;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PANEL — _0xDEADBEEE
// ─────────────────────────────────────────────────────────────────────────────
@interface _0xDEADBEEE () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIVisualEffectView *blurBG;
@property (nonatomic, strong) UIView             *panel;
@property (nonatomic, strong) UIView             *sidebar;
@property (nonatomic, strong) UIView             *contentArea;
@property (nonatomic, strong) UIScrollView       *scroll;
@property (nonatomic, assign) NSInteger  page;
@property (nonatomic, assign) NSInteger  colorTarget;
@property (nonatomic, assign) CGFloat    builtWidth;
@property (nonatomic, strong) NSMutableArray<UIView *> *controls;
@property (nonatomic, strong) UILabel   *spinStatusLabel;
@property (nonatomic, strong) NSTimer   *spinStatusTimer;
@property (nonatomic, assign) NSInteger  pointer;
@property (nonatomic, assign) CGPoint    began;
@property (nonatomic, assign) CGPoint    panelOrigin;
@property (nonatomic, assign) CGFloat    scrollOrigin;
@property (nonatomic, assign) BOOL       dragging;
@property (nonatomic, assign) BOOL       scrolling;
@property (nonatomic, strong) UIControl *activeControl;
@end

@implementation _0xDEADBEEE

// ─────────────────────────────────────────────────────────────────────────────
// applyDefaults
// ─────────────────────────────────────────────────────────────────────────────
- (void)applyDefaults {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if ([ud objectForKey:@"_MizzeDefaultsApplied"]) return;

    for (NSString *k in @[@"ESPEnabled",@"Box",@"Box3D",@"CleanESP",@"Name",@"Health",
                           @"Line",@"Skeleton",@"HeadRedDot",@"Dis",@"AimLag",
                           @"AimTargetLine",@"SilentAim",@"AutoFire",@"AutoFireFloating",
                           @"FastFire",@"ShootNoReload",@"GhostModeFloating",@"FakeLagFloating",
                           @"FlyFloating",@"RunSpeedFloating",@"RunSpeed",@"VisualSpin",
                           @"AnLive",@"BalancedRender",@"HideFeatureButtons"])
        ESPPrefsSetBool(k, NO);
    ESPPrefsSetBool(@"ShowFov", YES);
    // Modo claro por defecto
    [ud setBool:NO forKey:@"DAAE.darkMode"];
    [ud synchronize];

    ESPPrefsSetFloat(@"AimType",        -1);
    ESPPrefsSetFloat(@"AimActivation",   1);
    ESPPrefsSetFloat(@"FovSize",        40);
    ESPPrefsSetFloat(@"SilentFovSize",  18);
    ESPPrefsSetFloat(@"RunSpeedValue",   6);
    ESPPrefsSetFloat(@"FlyHeight",       4);
    ESPPrefsSetFloat(@"VisualSpinSpeed", 0.5);

    ESPPrefsSetBool(@"ExplicitAimMenuV1", YES);
    [ud setBool:YES forKey:@"_MizzeDefaultsApplied"];
    [ud synchronize];
    ESPSyncFromPrefs();
}

// ─────────────────────────────────────────────────────────────────────────────
// viewDidLoad
// ─────────────────────────────────────────────────────────────────────────────
- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyDefaults];
    MizzePrepareMenuPrefs();
    // Abrir Telegram una vez por sesión al iniciar el menú
    static BOOL sTgOpened = NO;
    if (!sTgOpened) {
        sTgOpened = YES;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            NSURL *tgURL = [NSURL URLWithString:@"https://t.me/didierxit7"];
            [[UIApplication sharedApplication] openURL:tgURL
                                               options:@{}
                                     completionHandler:nil];
        });
    }
    self.pointer     = -1;
    self.colorTarget = 0;
    self.controls    = [NSMutableArray array];
    self.view.backgroundColor = UIColor.clearColor;

    __weak _0xDEADBEEE *ws = self;
    self.spinStatusTimer = [NSTimer scheduledTimerWithTimeInterval:.5 repeats:YES
        block:^(NSTimer *_){
            _0xDEADBEEE *s = ws;
            if (s.isViewLoaded && s.view.window && !s.view.hidden && s.spinStatusLabel)
                [s updateSpinStatus];
        }];

    CGFloat panelCR = DAAECornerRadius(22);
    self.blurBG = [[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:DAAEBlurStyle()]];
    self.blurBG.layer.cornerRadius = panelCR;
    self.blurBG.clipsToBounds      = YES;
    [self.view addSubview:self.blurBG];

    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.backgroundColor    = PanelBG();
    self.panel.layer.cornerRadius = panelCR;
    self.panel.layer.borderWidth  = 0.6;
    self.panel.layer.borderColor  = (DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.13]
        : [UIColor colorWithWhite:0 alpha:0.10]).CGColor;
    self.panel.clipsToBounds = YES;
    [self.view addSubview:self.panel];

    self.sidebar = [[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.backgroundColor = SidebarBG();
    [self.panel addSubview:self.sidebar];

    UIView *div = [[UIView alloc] initWithFrame:CGRectZero];
    div.tag = 99;
    div.backgroundColor = DivClr();
    [self.panel addSubview:div];

    self.contentArea = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentArea.backgroundColor = UIColor.clearColor;
    [self.panel addSubview:self.contentArea];

    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator = NO;
    self.scroll.bounces    = YES;
    self.scroll.clipsToBounds = YES;
    [self.contentArea addSubview:self.scroll];

    for (UIView *target in @[self.sidebar, self.contentArea]) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(dragPanel:)];
        pan.delegate = self;
        [target addGestureRecognizer:pan];
    }

    [self buildSidebar];
    [self buildPage];
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT
// ─────────────────────────────────────────────────────────────────────────────
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sw = self.view.bounds.size.width;
    CGFloat sh = self.view.bounds.size.height;
    if (sw <= 0) sw = 320; if (sh <= 0) sh = 480;

    // Tamaño del panel según slider del usuario (300-480pt ancho, alto proporcional)
    CGFloat baseW = DAAEPanelSize(); // 300..480, default 380
    CGFloat pw = MIN(sw - 40.0, baseW);
    pw = MAX(pw, 300.0);
    CGFloat ph = MIN(sh - 60.0, pw * 1.35);
    ph = MAX(ph, 380.0);

    CGRect f = self.panel.frame;
    if (f.size.width < 1) {
        f = CGRectMake((sw - pw) / 2.0, (sh - ph) / 2.0, pw, ph);
    } else {
        f.size = CGSizeMake(pw, ph);
        f.origin.x = MAX(8, MIN(f.origin.x, sw - pw - 8));
        f.origin.y = MAX(8, MIN(f.origin.y, sh - ph - 8));
    }
    self.panel.frame  = f;
    self.blurBG.frame = f;

    const CGFloat sbW = 70.0;
    self.sidebar.frame = CGRectMake(0, 0, sbW, ph);

    UIView *div = [self.panel viewWithTag:99];
    div.frame = CGRectMake(sbW, 0, 0.5, ph);

    CGFloat caX = sbW + 0.5;
    CGFloat caW = pw - caX;
    self.contentArea.frame = CGRectMake(caX, 0, caW, ph);

    const CGFloat headerH = 54.0;
    const CGFloat padH    = 10.0;
    const CGFloat padB    = 10.0;
    self.scroll.frame = CGRectMake(padH, headerH,
                                   caW - padH * 2,
                                   ph - headerH - padB);

    [self layoutSidebarButtons];
    if (fabs(self.builtWidth - self.scroll.bounds.size.width) > 0.5) [self buildPage];
    [self refreshSidebarSelection];
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR — 5 tabs
// ─────────────────────────────────────────────────────────────────────────────
static NSArray<NSString *> *TabIcons(void) {
    return @[@"eye.fill", @"scope", @"paintpalette.fill",
             @"shippingbox.fill", @"gearshape.fill"];
}
static NSArray<NSString *> *TabNamesEN(void) {
    return @[@"ESP", @"AIM", @"COLORS", @"MISC", @"SETTINGS"];
}
static NSString *TabName(NSInteger i) {
    NSArray *en = @[@"ESP",  @"AIM",  @"COLORS", @"MISC",  @"SETTINGS"];
    NSArray *es = @[@"ESP",  @"APUNT",@"COLORES",@"EXTRA", @"CONFIG"];
    NSArray *vi = @[@"ESP",  @"AIM",  @"MÀU",    @"KHÁC",  @"CÀI"];
    switch (DAAELang()) {
        case 1: return es[(NSUInteger)i];
        case 2: return vi[(NSUInteger)i];
        default: return en[(NSUInteger)i];
    }
}

- (void)buildSidebar {
    for (UIView *v in self.sidebar.subviews) [v removeFromSuperview];
    NSArray *icons = TabIcons();
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 300 + i;
        btn.layer.cornerRadius = 16;
        UIImage *img = SFSym(icons[(NSUInteger)i], 18, UIImageSymbolWeightSemibold);
        [btn setImage:img forState:UIControlStateNormal];

        // Label pequeño debajo del icono
        UILabel *lbl = [[UILabel alloc] init];
        lbl.tag  = 400 + i;
        lbl.text = TabName(i);
        lbl.font = [UIFont systemFontOfSize:9 weight:UIFontWeightSemibold];
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.adjustsFontSizeToFitWidth = YES;
        [btn addSubview:lbl];

        [btn addTarget:self action:@selector(sidebarTap:)
            forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
    }
    [self layoutSidebarButtons];
    [self refreshSidebarSelection];
}

- (void)layoutSidebarButtons {
    const CGFloat btnW = 54, btnH = 56, gap = 8;
    NSInteger n = 5;
    CGFloat total = n * btnH + (n - 1) * gap;
    CGFloat sbH = self.sidebar.bounds.size.height;
    if (sbH < 1) sbH = 400;
    CGFloat startY = (sbH - total) / 2.0;
    for (NSInteger i = 0; i < n; i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300 + i];
        if (!btn) continue;
        btn.frame = CGRectMake((70 - btnW) / 2.0,
                               startY + i * (btnH + gap),
                               btnW, btnH);
        // Reposiciona el label dentro del botón
        UILabel *lbl = (UILabel *)[btn viewWithTag:400 + i];
        if (lbl) lbl.frame = CGRectMake(0, btnH - 16, btnW, 13);
        // La imagen ocupa la zona superior
        btn.imageEdgeInsets = UIEdgeInsetsMake(-4, 0, 16, 0);
    }
}

- (void)refreshSidebarSelection {
    UIColor *accent   = DAAEAccentColor();
    UIColor *accentFG = DAAEAccentFG();
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300 + i];
        if (!btn) continue;
        BOOL sel = (i == self.page);
        btn.backgroundColor = sel ? accent
                                  : [UIColor colorWithWhite:DAAEDark()?1:0 alpha:0.06];
        btn.tintColor       = sel ? accentFG : LblDim();
        btn.layer.borderWidth = sel ? 0 : 0.5;
        btn.layer.borderColor = (DAAEDark()
            ? [UIColor colorWithWhite:1 alpha:0.14]
            : [UIColor colorWithWhite:0 alpha:0.10]).CGColor;

        UILabel *lbl = (UILabel *)[btn viewWithTag:400 + i];
        if (lbl) {
            lbl.textColor = sel ? accentFG : LblDim();
            lbl.text = TabName(i);
        }
    }
}

- (void)sidebarTap:(UIButton *)sender {
    NSInteger pg = sender.tag - 300;
    if (pg == self.page) return;
    self.page = pg;
    self.scroll.contentOffset = CGPointZero;
    [self refreshSidebarSelection];
    [self rebuildAnimated];
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildHeader {
    for (UIView *v in self.contentArea.subviews)
        if (v.tag >= 500 && v.tag < 600) [v removeFromSuperview];

    CGFloat cw = self.contentArea.bounds.size.width;
    if (cw < 10) cw = 280;

    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(10, 7, cw - 20, 40)];
    hdr.tag = 500;
    hdr.backgroundColor    = HeaderBG();
    hdr.layer.cornerRadius = DAAECornerRadius(13);
    [self.contentArea addSubview:hdr];

    UIImageView *iv = [[UIImageView alloc] initWithImage:
        SFSym(TabIcons()[(NSUInteger)self.page], 14, UIImageSymbolWeightSemibold)];
    iv.tag = 501;
    iv.tintColor   = DAAEAccentColor();
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.frame = CGRectMake(24, 18, 15, 15);
    [self.contentArea addSubview:iv];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(46, 10, cw - 110, 34)];
    title.tag       = 502;
    title.text      = TabName(self.page);
    title.textColor = DAAEAccentColor();
    title.font      = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [self.contentArea addSubview:title];

    // Botón modo oscuro (luna/sol) — a la izquierda de la X
    UIButton *darkBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    darkBtn.tag   = 504;
    darkBtn.frame = CGRectMake(cw - 76, 10, 30, 34);
    NSString *dmIcon = DAAEDark() ? @"sun.max.fill" : @"moon.fill";
    [darkBtn setImage:SFSym(dmIcon, 14, UIImageSymbolWeightSemibold)
             forState:UIControlStateNormal];
    darkBtn.tintColor = LblDim();
    [darkBtn addTarget:self action:@selector(darkModeToggle)
        forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:darkBtn];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.tag   = 503;
    close.frame = CGRectMake(cw - 42, 10, 30, 34);
    [close setImage:SFSym(@"xmark", 12, UIImageSymbolWeightBold) forState:UIControlStateNormal];
    close.tintColor = LblDim();
    [close addTarget:self action:@selector(closeMenu)
        forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:close];
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS de construcción
// ─────────────────────────────────────────────────────────────────────────────
- (CGFloat)contentWidth {
    CGFloat w = self.scroll.bounds.size.width;
    return (w > 10) ? w : 260;
}

- (CGFloat)addToggleEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key fallback:(BOOL)fb y:(CGFloat)y {
    CGFloat w = [self contentWidth];
    DAAERow *row = [[DAAERow alloc] initWithLabel:DAAEStr(en, es, vi)
                                               on:ESPPrefsBool(key, fb) width:w];
    row.frame = CGRectMake(0, y, w, 60);
    objc_setAssociatedObject(row, "espKey", key, OBJC_ASSOCIATION_COPY_NONATOMIC);
    __weak DAAERow *wrow = row;
    __weak _0xDEADBEEE *wself = self;
    row.onChanged = ^(BOOL on) {
        NSString *k = objc_getAssociatedObject(wrow, "espKey");
        ESPPrefsSetBool(k, on);
        ESPSyncFromPrefs();
        [wself toggleChanged:k value:on];
    };
    [self.controls addObject:row];
    [self.scroll addSubview:row];
    return y + 68;
}

- (CGFloat)addSection:(NSString *)title y:(CGFloat)y {
    UILabel *l = [[UILabel alloc] initWithFrame:
        CGRectMake(4, y + 4, [self contentWidth] - 8, 20)];
    l.text      = title;
    l.textColor = SectionClr();
    l.font      = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    [self.scroll addSubview:l];
    return y + 30;
}

- (CGFloat)addSliderEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key min:(float)mn max:(float)mx fallback:(float)fb y:(CGFloat)y {
    CGFloat w  = [self contentWidth];
    DAAESlider *sl = [[DAAESlider alloc] initWithLabel:DAAEStr(en, es, vi)
                                                   key:key min:mn max:mx fallback:fb width:w];
    sl.frame = CGRectMake(0, y, w, 72);
    [self.controls addObject:(UIControl *)sl];
    [self.scroll addSubview:sl];
    return y + 80;
}

// ─────────────────────────────────────────────────────────────────────────────
// rebuildAnimated
// ─────────────────────────────────────────────────────────────────────────────
- (void)rebuildAnimated {
    if (UIAccessibilityIsReduceMotionEnabled()) { [self buildPage]; return; }
    [UIView transitionWithView:self.scroll duration:0.15
        options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionAllowUserInteraction
        animations:^{ [self buildPage]; } completion:nil];
}

// Reaplica tema sin reconstruir todo (más barato)
- (void)refreshThemeInPlace {
    // Panel y blur — actualizar esquinas también
    CGFloat cr = DAAECornerRadius(22);
    self.panel.layer.cornerRadius = cr;
    self.blurBG.layer.cornerRadius = cr;
    self.panel.backgroundColor = PanelBG();
    self.panel.layer.borderColor = (DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.13]
        : [UIColor colorWithWhite:0 alpha:0.10]).CGColor;
    self.blurBG.effect = [UIBlurEffect effectWithStyle:DAAEBlurStyle()];
    self.sidebar.backgroundColor = SidebarBG();
    UIView *div = [self.panel viewWithTag:99];
    div.backgroundColor = DivClr();
    // Rebuild es la manera más segura dado que los colores estáticos
    // están capturados en closures de cada componente
    [self buildPage];
    [self refreshSidebarSelection];
}

// ─────────────────────────────────────────────────────────────────────────────
// buildPage
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildPage {
    sColorSwatchUpdater = nil; // limpiar callback anterior
    const CGFloat offset = self.scroll.contentOffset.y;
    for (UIView *v in self.scroll.subviews) [v removeFromSuperview];
    [self.controls removeAllObjects];
    self.spinStatusLabel = nil;
    self.builtWidth = [self contentWidth];
    [self buildHeader];
    CGFloat y = 6;

    // ── TAB 0: ESP ────────────────────────────────────────────────────────────
    if (self.page == 0) {
        y = [self addToggleEN:@"ESP Master"    ES:@"ESP Maestro"   VI:@"Bật ESP"      key:@"ESPEnabled" fallback:YES y:y];
        y = [self addSection:DAAEStr(@"— DRAW —",@"— DIBUJO —",@"— VẼ —") y:y];
        y = [self addToggleEN:@"Box ESP"       ES:@"Caja ESP"      VI:@"Khung ESP"    key:@"Box"        fallback:YES y:y];
        y = [self addToggleEN:@"Line ESP"      ES:@"Línea ESP"     VI:@"Đường Kẻ ESP" key:@"Line"       fallback:NO  y:y];
        y = [self addToggleEN:@"Skeleton"      ES:@"Esqueleto"     VI:@"Bộ Xương"     key:@"Skeleton"   fallback:NO  y:y];
        y = [self addToggleEN:@"Head Dot"      ES:@"Punto cabeza"  VI:@"Đầu Đỏ"       key:@"HeadRedDot" fallback:NO  y:y];
        y = [self addToggleEN:@"Health Bar"    ES:@"Barra de vida" VI:@"Thanh Máu"    key:@"Health"     fallback:YES y:y];
        y = [self addToggleEN:@"Name"          ES:@"Nombre"        VI:@"Tên"          key:@"Name"       fallback:YES y:y];
        y = [self addToggleEN:@"Distance"      ES:@"Distancia"     VI:@"Khoảng Cách"  key:@"Dis"        fallback:YES y:y];
        y = [self addToggleEN:@"Clean ESP"     ES:@"ESP limpio"    VI:@"ESP Sạch"     key:@"CleanESP"   fallback:YES y:y];
        y = [self addSection:DAAEStr(@"— FOV —",@"— FOV —",@"— FOV —") y:y];
        y = [self addToggleEN:@"Show FOV"      ES:@"Mostrar FOV"   VI:@"Hiện Vòng FOV" key:@"ShowFov"   fallback:YES y:y];
        y = [self addSliderEN:@"FOV Size"      ES:@"Tamaño FOV"    VI:@"Bán Kính FOV"
                          key:@"FovSize" min:5 max:48 fallback:40 y:y];

    // ── TAB 1: AIM ────────────────────────────────────────────────────────────
    } else if (self.page == 1) {
        y = [self addToggleEN:@"Enable Aimbot"  ES:@"Activar Aimbot"  VI:@"Bật Aimbot"      key:@"ESPEnabled" fallback:YES y:y];
        y = [self addToggleEN:@"Aim Line"       ES:@"Línea objetivo"  VI:@"Đường mục tiêu"  key:@"AimTargetLine" fallback:YES y:y];
        y = [self addToggleEN:@"Show FOV"       ES:@"Mostrar FOV"     VI:@"Hiện Vòng FOV"   key:@"ShowFov"    fallback:YES y:y];
        y = [self addToggleEN:@"Skip Bots"      ES:@"Ignorar bots"    VI:@"Bỏ qua bot"      key:@"CleanESP"   fallback:YES y:y];
        y = [self addToggleEN:@"Skip Downed"    ES:@"Ignorar caídos"  VI:@"Bỏ qua gục"      key:@"BalancedRender" fallback:NO y:y];

        y = [self addSection:DAAEStr(@"— ACTIVATION —",@"— ACTIVACIÓN —",@"— KÍCH HOẠT —") y:y];

        // Picker de activación — pill horizontal
        NSArray *actEN = @[@"Always",   @"On Fire",    @"On Aim"];
        NSArray *actES = @[@"Siempre",  @"Al Disparar",@"Al Apuntar"];
        NSArray *actVI = @[@"Luôn luôn",@"Khi bắn",   @"Khi ngắm"];
        NSArray<NSString *> *actOpts = @[
            DAAEStr(actEN[0], actES[0], actVI[0]),
            DAAEStr(actEN[1], actES[1], actVI[1]),
            DAAEStr(actEN[2], actES[2], actVI[2])
        ];
        const NSInteger curActRaw = static_cast<int>(
            AimModePolicy::ReadActivation(ESPPrefsFloat(@"AimActivation", 0)));
        // mapeo: raw 1→idx0(Siempre), raw 2→idx1(Bắn), raw 3→idx2(Ngắm)
        NSInteger actSel = (curActRaw >= 1 && curActRaw <= 3) ? curActRaw - 1 : 0;
        CGFloat w = [self contentWidth];
        DAAEPillPicker *actPicker = [[DAAEPillPicker alloc]
            initWithOptions:actOpts selected:actSel width:w];
        actPicker.frame = CGRectMake(0, y, w, 50);
        actPicker.onSelected = ^(NSInteger idx) {
            NSInteger choice = idx + 1;  // 1=Siempre, 2=Bắn, 3=Ngắm
            ESPPrefsSetFloat(@"AimActivation", (float)choice);
            ESPClearAimLock();
            ESPSyncFromPrefs();
        };
        [self.scroll addSubview:actPicker];
        y += 58;

        y = [self addSection:DAAEStr(@"— AIM POSITION —",@"— POSICIÓN AIM —",@"— VỊ TRÍ NGẮM —") y:y];

        // Picker de aim type — pill horizontal
        NSArray *aimOpts = @[
            DAAEStr(@"Head", @"Cabeza", @"Đầu"),
            DAAEStr(@"Neck", @"Cuello", @"Cổ"),
            DAAEStr(@"Body", @"Cuerpo", @"Thân")
        ];
        float aimRaw = AimRaw();
        NSInteger aimSel = (aimRaw >= 0 && aimRaw <= 2) ? (NSInteger)aimRaw : 0;
        DAAEPillPicker *aimPicker = [[DAAEPillPicker alloc]
            initWithOptions:aimOpts selected:aimSel width:w];
        aimPicker.frame = CGRectMake(0, y, w, 50);
        aimPicker.onSelected = ^(NSInteger idx) {
            ESPPrefsSetFloat(@"AimType", (float)idx);
            ESPPrefsSetFloat(@"AimActivation", static_cast<int>(
                AimModePolicy::AfterTypeSelection(
                    AimModePolicy::ReadType((float)idx))));
            ESPPrefsSetBool(@"SilentAim", NO);
            ESPClearAimLock();
            ESPSyncFromPrefs();
        };
        [self.scroll addSubview:aimPicker];
        y += 58;

        y = [self addSection:DAAEStr(@"— PRIORITY —",@"— PRIORIDAD —",@"— ƯU TIÊN —") y:y];
        y = [self addSliderEN:@"FOV Radius"   ES:@"Radio FOV"      VI:@"Bán Kính FOV"
                          key:@"FovSize" min:5 max:48 fallback:40 y:y];
        y = [self addSliderEN:@"FOV Thickness" ES:@"Grosor FOV"    VI:@"Độ Dày FOV"
                          key:@"SilentFovSize" min:0 max:10 fallback:0 y:y];
        y = [self addSection:DAAEStr(@"— WEAPON —",@"— ARMAS —",@"— VŨ KHÍ —") y:y];
        y = [self addToggleEN:@"Fast Fire"   ES:@"Disparo Rápido" VI:@"Bắn Nhanh"  key:@"FastFire"      fallback:NO y:y];
        y = [self addToggleEN:@"No Reload"   ES:@"Sin Recarga"    VI:@"Không Nạp"  key:@"ShootNoReload" fallback:NO y:y];

    // ── TAB 2: COLORS ─────────────────────────────────────────────────────────
    } else if (self.page == 2) {
        CGFloat w = [self contentWidth];
        UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Box", @"FOV"]];
        seg.frame = CGRectMake(0, y, w, 36);
        seg.selectedSegmentIndex    = self.colorTarget;
        seg.selectedSegmentTintColor = DAAEAccentColor();
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:LblMain(),
            NSFontAttributeName:[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]}
                            forState:UIControlStateNormal];
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor}
                            forState:UIControlStateSelected];
        [seg addTarget:self action:@selector(colorTargetChanged:)
             forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:seg];
        [self.controls addObject:(UIControl *)seg];
        y += 46;

        NSString *pfx = (self.colorTarget == 0) ? @"BoxColor" : @"FovColor";
        float r = ESPPrefsFloat([pfx stringByAppendingString:@"R"], 0.26);
        float g = ESPPrefsFloat([pfx stringByAppendingString:@"G"], 0.78);
        float b = ESPPrefsFloat([pfx stringByAppendingString:@"B"], 0.90);

        UILabel *swatch = [[UILabel alloc] initWithFrame:CGRectMake(0, y, w, 50)];
        swatch.tag = 789; // identificador para actualización en tiempo real
        swatch.text = [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)round(r*255),(int)round(g*255),(int)round(b*255)];
        swatch.textAlignment   = NSTextAlignmentCenter;
        swatch.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
        CGFloat lum = r*0.299 + g*0.587 + b*0.114;
        swatch.textColor    = lum > 0.6 ? UIColor.blackColor : UIColor.whiteColor;
        swatch.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        swatch.layer.cornerRadius = DAAECornerRadius(14);
        swatch.clipsToBounds = YES;
        objc_setAssociatedObject(swatch, "colorPfx", pfx, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [self.scroll addSubview:swatch];
        y += 58;

        // Callback de actualización en tiempo real para los sliders R/G/B
        __weak UIScrollView *wscroll = self.scroll;
        sColorSwatchUpdater = ^{
            UILabel *sw = (UILabel *)[wscroll viewWithTag:789];
            if (!sw) return;
            NSString *p = objc_getAssociatedObject(sw, "colorPfx");
            if (!p) return;
            float rr = ESPPrefsFloat([p stringByAppendingString:@"R"], 0.26);
            float gg = ESPPrefsFloat([p stringByAppendingString:@"G"], 0.78);
            float bb = ESPPrefsFloat([p stringByAppendingString:@"B"], 0.90);
            sw.backgroundColor = [UIColor colorWithRed:rr green:gg blue:bb alpha:1.0];
            sw.text = [NSString stringWithFormat:@"#%02X%02X%02X",
                (int)round(rr*255),(int)round(gg*255),(int)round(bb*255)];
            CGFloat l = rr*0.299 + gg*0.587 + bb*0.114;
            sw.textColor = l > 0.6 ? UIColor.blackColor : UIColor.whiteColor;
        };

        NSArray *rgbEN = @[@"Red",  @"Green",    @"Blue"];
        NSArray *rgbES = @[@"Rojo", @"Verde",    @"Azul"];
        NSArray *rgbVI = @[@"Đỏ",   @"Xanh lá", @"Xanh dương"];
        NSArray *suf   = @[@"R",    @"G",        @"B"];
        float def[3]   = {0.26f, 0.78f, 0.90f};
        for (int i = 0; i < 3; i++)
            y = [self addSliderEN:rgbEN[(NSUInteger)i]
                               ES:rgbES[(NSUInteger)i]
                               VI:rgbVI[(NSUInteger)i]
                              key:[pfx stringByAppendingString:suf[(NSUInteger)i]]
                              min:0 max:1 fallback:def[i] y:y];

    // ── TAB 3: MISC ───────────────────────────────────────────────────────────
    } else if (self.page == 3) {
        y = [self addSection:DAAEStr(@"— EXTRAS —",@"— EXTRAS —",@"— EXTRAS —") y:y];
        y = [self addToggleEN:@"Ghost"         ES:@"Fantasma"         VI:@"Bóng ma"            key:@"GhostModeFloating"  fallback:NO y:y];
        y = [self addToggleEN:@"FakeLag"       ES:@"Lag Falso"        VI:@"Lag giả"            key:@"FakeLagFloating"    fallback:NO y:y];
        y = [self addToggleEN:@"Fly"           ES:@"Volar"            VI:@"Bay"                key:@"FlyFloating"        fallback:NO y:y];
        y = [self addToggleEN:@"Speed"         ES:@"Velocidad"        VI:@"Tốc độ"             key:@"RunSpeedFloating"   fallback:NO y:y];
        y = [self addToggleEN:@"Hide Buttons"  ES:@"Ocultar botones"  VI:@"Ẩn nút"             key:@"HideFeatureButtons" fallback:NO y:y];
        y = [self addToggleEN:@"AimKill"       ES:@"Matar con aim"    VI:@"Aim giết"           key:@"AutoFireFloating"   fallback:NO y:y];

        y = [self addSection:DAAEStr(@"— MOVEMENT —",@"— MOVIMIENTO —",@"— DI CHUYỂN —") y:y];
        y = [self addToggleEN:@"Speed Toggle"  ES:@"Velocidad"        VI:@"Tốc độ"             key:@"RunSpeed"           fallback:NO y:y];
        y = [self addSliderEN:@"Speed Value"   ES:@"Velocidad (m/s)"  VI:@"Tốc độ (m/s)"
                          key:@"RunSpeedValue" min:1 max:15 fallback:6 y:y];
        if (ESPPrefsBool(@"FlyFloating", NO))
            y = [self addSliderEN:@"Fly Height" ES:@"Altura vuelo"    VI:@"Độ cao bay"
                              key:@"FlyHeight" min:1 max:6 fallback:4 y:y];

        y = [self addSection:DAAEStr(@"— EFFECTS —",@"— EFECTOS —",@"— HIỆU ỨNG —") y:y];
        y = [self addToggleEN:@"Visual Spin"     ES:@"Giro Visual"       VI:@"Xoay hiển thị"
                          key:@"VisualSpin" fallback:NO y:y];
        if (ESPPrefsBool(@"VisualSpin", NO)) {
            y = [self addSliderEN:@"Spin Speed"  ES:@"Vel. Giro"         VI:@"Tốc độ xoay"
                              key:@"VisualSpinSpeed" min:0.1 max:3 fallback:0.5 y:y];
            self.spinStatusLabel = [[UILabel alloc] initWithFrame:
                CGRectMake(4, y, [self contentWidth]-8, 34)];
            self.spinStatusLabel.textColor     = SectionClr();
            self.spinStatusLabel.font          = [UIFont systemFontOfSize:11];
            self.spinStatusLabel.numberOfLines = 2;
            [self.scroll addSubview:self.spinStatusLabel];
            [self updateSpinStatus];
            y += 40;
        }
        y = [self addToggleEN:@"Hide Capture"    ES:@"Ocultar capturas"   VI:@"Ẩn chụp màn hình"
                          key:@"AnLive" fallback:NO y:y];
        y = [self addToggleEN:@"Balanced Render" ES:@"Render equilibrado" VI:@"Render cân bằng"
                          key:@"BalancedRender" fallback:NO y:y];

    // ── TAB 4: SETTINGS ───────────────────────────────────────────────────────
    } else {
        CGFloat w = [self contentWidth];

        // ── IDIOMA ────────────────────────────────────────────────────────────
        y = [self addSection:DAAEStr(@"— LANGUAGE —",@"— IDIOMA —",@"— NGÔN NGỮ —") y:y];
        UIView *langRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 52)];
        langRow.backgroundColor    = RowBG();
        langRow.layer.cornerRadius = DAAECornerRadius(14);
        NSArray *codes    = @[@"EN", @"ES", @"VI"];
        NSArray *names    = @[@"English", @"Español", @"Tiếng Việt"];
        NSInteger curLang = DAAELang();
        CGFloat lbtnW = (w - 32 - 12) / 3.0;
        for (NSInteger k = 0; k < 3; k++) {
            UIButton *lb = [UIButton buttonWithType:UIButtonTypeCustom];
            lb.frame = CGRectMake(16 + k * (lbtnW + 6), 10, lbtnW, 32);
            BOOL sel = (k == curLang);
            lb.backgroundColor    = sel ? DAAEAccentColor()
                                        : [UIColor colorWithWhite:DAAEDark()?1:0 alpha:0.06];
            lb.layer.cornerRadius = DAAECornerRadius(10);
            [lb setTitle:codes[(NSUInteger)k] forState:UIControlStateNormal];
            lb.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
            [lb setTitleColor:sel ? UIColor.whiteColor : LblMain()
                     forState:UIControlStateNormal];
            objc_setAssociatedObject(lb, "langIdx", @(k), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [lb addTarget:self action:@selector(langTap:)
                forControlEvents:UIControlEventTouchUpInside];
            [langRow addSubview:lb];
        }
        [self.scroll addSubview:langRow];
        y += 60;

        UILabel *lhint = [[UILabel alloc] initWithFrame:CGRectMake(0, y, w, 18)];
        lhint.text          = names[(NSUInteger)curLang];
        lhint.textColor     = SectionClr();
        lhint.font          = [UIFont systemFontOfSize:11];
        lhint.textAlignment = NSTextAlignmentCenter;
        [self.scroll addSubview:lhint];
        y += 26;

        // ── MODO CLARO / OSCURO ───────────────────────────────────────────────
        y = [self addSection:DAAEStr(@"— APPEARANCE —",@"— APARIENCIA —",@"— GIAO DIỆN —") y:y];
        NSArray *modeEN = @[@"Light Mode", @"Dark Mode"];
        NSArray *modeES = @[@"Modo Claro", @"Modo Oscuro"];
        NSArray *modeVI = @[@"Sáng",       @"Tối"];
        NSArray<NSString *> *modeOpts = @[
            DAAEStr(modeEN[0], modeES[0], modeVI[0]),
            DAAEStr(modeEN[1], modeES[1], modeVI[1])
        ];
        BOOL isDark = DAAEDark();
        DAAEPillPicker *modePicker = [[DAAEPillPicker alloc]
            initWithOptions:modeOpts selected:(isDark ? 1 : 0) width:w];
        modePicker.frame = CGRectMake(0, y, w, 50);
        __weak _0xDEADBEEE *wself = self;
        modePicker.onSelected = ^(NSInteger idx) {
            DAAESetDark(idx == 1);
            [wself refreshThemeInPlace];
        };
        [self.scroll addSubview:modePicker];
        y += 58;

        // ── COLOR DE ACENTO ───────────────────────────────────────────────────
        y = [self addSection:DAAEStr(@"— ACCENT COLOR —",@"— COLOR ACENTO —",@"— MÀU NHẤN —") y:y];

        // Fila con 6 círculos de color (idx 5 = negro/blanco según modo)
        UIView *accentRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 60)];
        accentRow.backgroundColor    = RowBG();
        accentRow.layer.cornerRadius = DAAECornerRadius(14);

        UIColor *accentColors[6] = {
            [UIColor colorWithRed:0.26 green:0.78 blue:0.90 alpha:1],  // 0 Celeste
            [UIColor colorWithRed:1.00 green:0.60 blue:0.10 alpha:1],  // 1 Naranja
            [UIColor colorWithRed:0.95 green:0.22 blue:0.22 alpha:1],  // 2 Rojo
            [UIColor colorWithRed:0.95 green:0.82 blue:0.14 alpha:1],  // 3 Amarillo
            [UIColor colorWithRed:0.24 green:0.82 blue:0.50 alpha:1],  // 4 Verde
            DAAEDark() ? UIColor.whiteColor : UIColor.blackColor,      // 5 Auto B/W
        };
        NSInteger curAccent = DAAEAccentIdx();
        CGFloat circD = 30;
        CGFloat totalW = 6 * circD + 5 * 8;
        CGFloat startX = (w - totalW) / 2.0;
        for (NSInteger k = 0; k < 6; k++) {
            UIButton *cb = [UIButton buttonWithType:UIButtonTypeCustom];
            cb.frame = CGRectMake(startX + k * (circD + 8), (60 - circD) / 2.0, circD, circD);
            cb.backgroundColor    = accentColors[(NSUInteger)k];
            cb.layer.cornerRadius = circD / 2.0;
            cb.clipsToBounds      = NO;
            if (k == curAccent) {
                cb.layer.borderWidth = 3;
                cb.layer.borderColor = DAAEAccentColor().CGColor;
                cb.layer.shadowColor   = DAAEAccentColor().CGColor;
                cb.layer.shadowRadius  = 4;
                cb.layer.shadowOpacity = 0.5;
                cb.layer.shadowOffset  = CGSizeZero;
            }
            // Borde sutil para el círculo negro/blanco en modo opuesto
            if (k == 5) {
                if (!DAAEDark()) {
                    // negro sobre fondo claro: borde gris para visibilidad
                    if (k != curAccent) {
                        cb.layer.borderWidth = 1;
                        cb.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.25].CGColor;
                    }
                }
            }
            objc_setAssociatedObject(cb, "accentIdx", @(k), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [cb addTarget:self action:@selector(accentTap:)
                forControlEvents:UIControlEventTouchUpInside];
            [accentRow addSubview:cb];
        }
        [self.scroll addSubview:accentRow];
        y += 68;

        // Descripción del acento activo
        NSArray *accentNames = @[
            DAAEStr(@"Cyan",   @"Celeste",  @"Xanh ngọc"),
            DAAEStr(@"Orange", @"Naranja",  @"Cam"),
            DAAEStr(@"Red",    @"Rojo",     @"Đỏ"),
            DAAEStr(@"Yellow", @"Amarillo", @"Vàng"),
            DAAEStr(@"Green",  @"Verde",    @"Xanh lá"),
            DAAEStr(DAAEDark() ? @"White" : @"Black",
                    DAAEDark() ? @"Blanco" : @"Negro",
                    DAAEDark() ? @"Trắng" : @"Đen"),
        ];
        UILabel *accentHint = [[UILabel alloc] initWithFrame:CGRectMake(0, y, w, 18)];
        accentHint.text          = (curAccent >= 0 && curAccent < 6)
                                   ? accentNames[(NSUInteger)curAccent] : @"";
        accentHint.textColor     = DAAEAccentColor();
        accentHint.font          = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        accentHint.textAlignment = NSTextAlignmentCenter;
        [self.scroll addSubview:accentHint];
        y += 26;

        // ── ESQUINAS ──────────────────────────────────────────────────────────
        y = [self addSection:DAAEStr(@"— CORNERS —",@"— ESQUINAS —",@"— GÓC —") y:y];
        NSArray *cornerEN = @[@"Rounded",          @"Square"];
        NSArray *cornerES = @[@"Puntas Redondeadas",@"Puntas Cuadradas"];
        NSArray *cornerVI = @[@"Góc Tròn",          @"Góc Vuông"];
        NSArray<NSString *> *cornerOpts = @[
            DAAEStr(cornerEN[0], cornerES[0], cornerVI[0]),
            DAAEStr(cornerEN[1], cornerES[1], cornerVI[1])
        ];
        DAAEPillPicker *cornerPicker = [[DAAEPillPicker alloc]
            initWithOptions:cornerOpts selected:DAAECornerStyle() width:w];
        cornerPicker.frame = CGRectMake(0, y, w, 50);
        cornerPicker.onSelected = ^(NSInteger idx) {
            DAAESetCornerStyle(idx);
            [wself refreshThemeInPlace];
        };
        [self.scroll addSubview:cornerPicker];
        y += 58;

        // ── TAMAÑO DEL PANEL (slider) ─────────────────────────────────────────
        y = [self addSection:DAAEStr(@"— PANEL SIZE —",@"— TAMAÑO PANEL —",@"— CỠ PANEL —") y:y];
        {
            const CGFloat rowH = 72;
            UIView *psRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, rowH)];
            psRow.backgroundColor    = RowBG();
            psRow.layer.cornerRadius = DAAECornerRadius(14);

            UILabel *psLbl = [[UILabel alloc] initWithFrame:CGRectMake(18, 8, w - 120, 22)];
            psLbl.text      = DAAEStr(@"Width", @"Ancho", @"Chiều rộng");
            psLbl.textColor = LblMain();
            psLbl.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
            [psRow addSubview:psLbl];

            UILabel *psVal = [[UILabel alloc] initWithFrame:CGRectMake(w - 100, 8, 56, 22)];
            psVal.textAlignment = NSTextAlignmentRight;
            psVal.textColor = DAAEAccentColor();
            psVal.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
            psVal.text = [NSString stringWithFormat:@"%.0f", DAAEPanelSize()];
            [psRow addSubview:psVal];

            UIButton *psRst = [UIButton buttonWithType:UIButtonTypeSystem];
            psRst.frame = CGRectMake(w - 38, 8, 26, 22);
            [psRst setImage:SFSym(@"arrow.counterclockwise", 12, UIImageSymbolWeightSemibold)
                   forState:UIControlStateNormal];
            psRst.tintColor = LblDim();
            objc_setAssociatedObject(psRst, "psVal", psVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [psRst addTarget:wself action:@selector(panelSizeReset:)
                forControlEvents:UIControlEventTouchUpInside];
            [psRow addSubview:psRst];

            UISlider *psSl = [[UISlider alloc] initWithFrame:CGRectMake(14, 42, w - 28, 22)];
            psSl.minimumValue          = 300;
            psSl.maximumValue          = 480;
            psSl.value                 = (float)DAAEPanelSize();
            psSl.minimumTrackTintColor = DAAEAccentColor();
            psSl.maximumTrackTintColor = DAAEDark()
                ? [UIColor colorWithWhite:1 alpha:0.14]
                : [UIColor colorWithWhite:0 alpha:0.10];
            psSl.thumbTintColor = DAAEAccentColor();
            objc_setAssociatedObject(psSl, "psVal", psVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(psRst, "psSl", psSl, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [psSl addTarget:wself action:@selector(panelSizeSlid:)
                forControlEvents:UIControlEventValueChanged];
            [psRow addSubview:psSl];
            [self.scroll addSubview:psRow];
            y += rowH + 8;
        }

        // ── INFO ─────────────────────────────────────────────────────────────
        y = [self addSection:DAAEStr(@"— INFO —",@"— INFO —",@"— INFO —") y:y];
        typedef struct { NSString *t; NSString *v; BOOL dim; } InfoEntry;
        InfoEntry entries[4] = {
            {@"Product",  @"DAAE IOS",       NO},
            {@"Creator",  @"@didierxit7",    NO},
            {@"Telegram", @"t.me/didierxit7",NO},
            {@"Key",      @"TEST",           YES},
        };
        for (int i = 0; i < 4; i++) {
            UIView *row = InfoRow(entries[i].t, entries[i].v, w, entries[i].dim);
            row.frame = CGRectMake(0, y, w, 52);
            [self.scroll addSubview:row];
            y += 60;
        }
    }

    // Pie
    UILabel *credit = [[UILabel alloc] initWithFrame:
        CGRectMake(0, y + 8, [self contentWidth], 16)];
    credit.text          = @"DAAE IOS";
    credit.textColor     = [UIColor colorWithWhite:DAAEDark()?1:0 alpha:0.13];
    credit.font          = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    credit.textAlignment = NSTextAlignmentCenter;
    [self.scroll addSubview:credit];
    y += 30;

    self.scroll.contentSize = CGSizeMake([self contentWidth], y + 6);
    self.scroll.contentOffset = CGPointMake(0, MAX(0,
        MIN(offset, y + 6 - self.scroll.bounds.size.height)));
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCIONES
// ─────────────────────────────────────────────────────────────────────────────
- (void)closeMenu { if (self.onCloseBlock) self.onCloseBlock(); }

- (void)colorTargetChanged:(UISegmentedControl *)seg {
    self.colorTarget = seg.selectedSegmentIndex;
    [self buildPage];
}

- (void)langTap:(UIButton *)sender {
    NSNumber *n = objc_getAssociatedObject(sender, "langIdx");
    if (!n) return;
    DAAESetLang(n.integerValue);
    [self rebuildAnimated];
    [self buildSidebar];
}

- (void)accentTap:(UIButton *)sender {
    NSNumber *n = objc_getAssociatedObject(sender, "accentIdx");
    if (!n) return;
    DAAESetAccentIdx(n.integerValue);
    [self refreshThemeInPlace];
}

- (void)darkModeToggle {
    DAAESetDark(!DAAEDark());
    [self refreshThemeInPlace];
}

- (void)panelSizeSlid:(UISlider *)sl {
    UILabel *val = objc_getAssociatedObject(sl, "psVal");
    if (val) val.text = [NSString stringWithFormat:@"%.0f", sl.value];
    DAAESetPanelSize(sl.value);
    [self viewDidLayoutSubviews];
}

- (void)panelSizeReset:(UIButton *)btn {
    UISlider *sl  = objc_getAssociatedObject(btn, "psSl");
    UILabel  *val = objc_getAssociatedObject(btn, "psVal");
    DAAESetPanelSize(380.0f);
    if (sl)  { sl.value = 380.0f; }
    if (val) { val.text = @"380"; }
    [self viewDidLayoutSubviews];
}

- (void)applyMinimalESP {
    for (NSString *k in @[@"ESPEnabled",@"Box",@"Health",@"Name",@"Dis",@"CleanESP"])
        ESPPrefsSetBool(k, YES);
    for (NSString *k in @[@"Line",@"Skeleton",@"HeadRedDot",@"Box3D",@"BalancedRender"])
        ESPPrefsSetBool(k, NO);
    for (NSString *pfx in @[@"BoxColor",@"LineColor",@"FovColor"]) {
        ESPPrefsSetFloat([pfx stringByAppendingString:@"R"], 0.26);
        ESPPrefsSetFloat([pfx stringByAppendingString:@"G"], 0.78);
        ESPPrefsSetFloat([pfx stringByAppendingString:@"B"], 0.90);
    }
    ESPSyncFromPrefs(); [self buildPage];
}

- (void)toggleChanged:(NSString *)key value:(BOOL)on {
    if ([@[@"GhostModeFloating",@"FakeLagFloating",@"AutoFireFloating",@"FlyFloating"]
            containsObject:key]) {
        NSString *feat = [key stringByReplacingOccurrencesOfString:@"Floating" withString:@""];
        ESPPrefsSetBool(feat, on);
        if (on) ESPPrefsSetBool(@"HideFeatureButtons", NO);
    }
    if ([key isEqualToString:@"CleanESP"] && on) ESPPrefsSetBool(@"Box3D", NO);
    if ([key isEqualToString:@"RunSpeed"] && !AppSettingsObjectForKey(@"RunSpeedFloating"))
        ESPPrefsSetBool(@"RunSpeedFloating", YES);
    if ([key isEqualToString:@"AnLive"] &&
        ![UIView applyCaptureProtectionToRegisteredViews:on]) {
        ESPPrefsSetBool(@"AnLive", NO);
        [UIView applyCaptureProtectionToRegisteredViews:NO];
    }
    if ([@[@"SilentAutoConfig",@"AutoFireFloating",@"FlyFloating",@"VisualSpin"]
            containsObject:key]) [self rebuildAnimated];
}

- (void)updateSpinStatus {
    const auto state = PlayerModesRead();
    NSString *text = @"Spin: waiting for game tick";
    if (state.detail && state.detail[0])
        text = [NSString stringWithUTF8String:state.detail];
    else if (state.spinStatus==1) text = @"Spin: waiting for character";
    else if (state.spinStatus==2) text = @"Spin: no compatible model";
    else if (state.spinStatus==3) text = @"Spin: waiting for angle";
    else if (state.spinStatus==4)
        text = [NSString stringWithFormat:@"Spin: applied · %llu",
                (unsigned long long)state.spinApplies];
    self.spinStatusLabel.text = text;
}

- (void)dealloc { [self.spinStatusTimer invalidate]; }

// ─────────────────────────────────────────────────────────────────────────────
// DRAG
// ─────────────────────────────────────────────────────────────────────────────
- (void)dragPanel:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateBegan)
        self.panelOrigin = self.panel.frame.origin;
    CGPoint d = [pan translationInView:self.view];
    CGRect  f = self.panel.frame;
    f.origin  = CGPointMake(self.panelOrigin.x + d.x, self.panelOrigin.y + d.y);
    self.panel.frame  = f;
    self.blurBG.frame = f;
    [self viewDidLayoutSubviews];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)t {
    for (UIView *v = t.view; v && v != g.view; v = v.superview)
        if ([v isKindOfClass:UIControl.class]) return NO;
    return YES;
}

// ─────────────────────────────────────────────────────────────────────────────
// _0xF010 — touch routing
// ─────────────────────────────────────────────────────────────────────────────
- (BOOL)_0xF010:(CGPoint)point phase:(NSInteger)phase pointerId:(NSInteger)pointerId {
    if (phase == UITouchPhaseBegan) {
        if (!CGRectContainsPoint(self.panel.frame, point)) return NO;
        if (self.pointer != -1) return YES;
        self.pointer      = pointerId;
        self.began        = point;
        self.panelOrigin  = self.panel.frame.origin;
        self.scrollOrigin = self.scroll.contentOffset.y;
        self.scrolling    = NO;
        self.activeControl = nil;
        CGPoint local = [self.panel convertPoint:point fromView:self.view];
        self.dragging = (local.x < 72) ||
                        (local.y < 56 && local.x < self.panel.bounds.size.width - 44);
        if (self.dragging) return YES;
        CGPoint sc = [self.scroll convertPoint:point fromView:self.view];
        for (UIView *c in self.controls) {
            if (![c isKindOfClass:UIControl.class]) continue;
            UIControl *ctrl = (UIControl *)c;
            if (!ctrl.enabled) continue;
            if (CGRectContainsPoint([ctrl convertRect:ctrl.bounds toView:self.scroll], sc))
            { self.activeControl = ctrl; break; }
        }
        return YES;
    }
    if (self.pointer != pointerId) return NO;
    CGFloat dx = point.x - self.began.x, dy = point.y - self.began.y;
    if (phase == UITouchPhaseMoved) {
        if (self.dragging) {
            CGRect f = self.panel.frame;
            f.origin = CGPointMake(self.panelOrigin.x + dx, self.panelOrigin.y + dy);
            self.panel.frame = f; self.blurBG.frame = f;
            [self viewDidLayoutSubviews];
        } else if (fabs(dy) > 6 || self.scrolling) {
            self.scrolling = YES;
            CGFloat maxY = MAX(0, self.scroll.contentSize.height - self.scroll.bounds.size.height);
            self.scroll.contentOffset = CGPointMake(0, MAX(0, MIN(maxY, self.scrollOrigin - dy)));
        }
        return YES;
    }
    if (phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled) {
        BOOL activate = phase==UITouchPhaseEnded && !self.dragging && !self.scrolling
                        && fabs(dx)<24 && fabs(dy)<24;
        UIControl *ctrl = self.activeControl;
        self.pointer = -1; self.activeControl = nil;
        if (activate && ctrl && ctrl.enabled)
            [ctrl sendActionsForControlEvents:UIControlEventTouchUpInside];
        return YES;
    }
    return YES;
}

@end

// BUILD OK

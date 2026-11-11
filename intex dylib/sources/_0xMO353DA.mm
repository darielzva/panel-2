#import "ModMenuViewController.h"
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPStyle.h"
#import <objc/runtime.h>
#import "UIView+SecureView.h"
#import "MizzeTheme.h"
#import "MizzeMenuPrefs.h"
#include <cmath>
#import "../esp/Core/PlayerModes.h"

static UIImage *SFSym(NSString *name, CGFloat pts, UIImageSymbolWeight w) {
    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:pts weight:w];
    return [UIImage systemImageNamed:name withConfiguration:cfg];
}

// ─────────────────────────────────────────────────────────────────────────────
// IDIOMA — 0=EN (default), 1=ES, 2=VI
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
// TEMA — dark=NO por defecto (modo claro igual a las imágenes)
// ─────────────────────────────────────────────────────────────────────────────
static BOOL DAAEDark(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.darkMode"]) return NO;
    return [ud boolForKey:@"DAAE.darkMode"];
}
static void DAAESetDark(BOOL dark) {
    [[NSUserDefaults standardUserDefaults] setBool:dark forKey:@"DAAE.darkMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// ─────────────────────────────────────────────────────────────────────────────
// ESQUINAS — NO = redondeadas (default), YES = cuadradas (con radio pequeño)
// ─────────────────────────────────────────────────────────────────────────────
static BOOL DAAESquareCorners(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.squareCorners"]) return NO;
    return [ud boolForKey:@"DAAE.squareCorners"];
}
static void DAAESetSquareCorners(BOOL sq) {
    [[NSUserDefaults standardUserDefaults] setBool:sq forKey:@"DAAE.squareCorners"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
// Radios según modo
static CGFloat RadiusPanel(void) { return DAAESquareCorners() ? 6  : 22; }
static CGFloat RadiusRow(void)   { return DAAESquareCorners() ? 4  : 14; }
static CGFloat RadiusChip(void)  { return DAAESquareCorners() ? 5  : 10; }

// ─────────────────────────────────────────────────────────────────────────────
// TAMAÑO DEL PANEL — escala: 0.80–1.20 del tamaño por defecto
// guardada en DAAE.panelScale, default 1.0
// ─────────────────────────────────────────────────────────────────────────────
static CGFloat DAAEPanelScale(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.panelScale"]) return 1.0;
    double v = [ud doubleForKey:@"DAAE.panelScale"];
    if (v < 0.75 || v > 1.30) return 1.0;
    return (CGFloat)v;
}
static void DAAESetPanelScale(CGFloat s) {
    [[NSUserDefaults standardUserDefaults] setDouble:(double)s forKey:@"DAAE.panelScale"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// TRANSPARENCIA DEL PANEL — 0.40–1.00, default 1.0
static CGFloat DAAEPanelAlpha(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.panelAlpha"]) return 1.0;
    double v = [ud doubleForKey:@"DAAE.panelAlpha"];
    if (v < 0.40 || v > 1.0) return 1.0;
    return (CGFloat)v;
}
static void DAAESetPanelAlpha(CGFloat a) {
    [[NSUserDefaults standardUserDefaults] setDouble:(double)MAX(0.40, MIN(1.0, a))
                                            forKey:@"DAAE.panelAlpha"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// ─────────────────────────────────────────────────────────────────────────────
// COLOR DE ACENTO
// 0=Celeste(default)  1=Naranja  2=Rojo  3=Amarillo  4=Verde
// 5=Negro(solo en modo CLARO)  6=Blanco(solo en modo OSCURO)
// En modo claro: opción 5 (Negro) disponible, opción 6 oculta
// En modo oscuro: opción 6 (Blanco) disponible, opción 5 oculta
// Si se cambia de modo y el acento era 5 o 6, se ajusta automáticamente
// ─────────────────────────────────────────────────────────────────────────────
static NSInteger DAAEAccentIdx(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.accentIdx"]) return 0; // celeste default
    NSInteger v = [ud integerForKey:@"DAAE.accentIdx"];
    return (v >= 0 && v <= 6) ? v : 0;
}
static void DAAESetAccentIdx(NSInteger idx) {
    [[NSUserDefaults standardUserDefaults] setInteger:idx forKey:@"DAAE.accentIdx"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
// Cuando se cambia de modo, ajustar acento 5↔6 si aplica
static void DAAEAdjustAccentForMode(BOOL dark) {
    NSInteger cur = DAAEAccentIdx();
    if (dark && cur == 5) DAAESetAccentIdx(6);   // negro → blanco en oscuro
    else if (!dark && cur == 6) DAAESetAccentIdx(5); // blanco → negro en claro
}
static UIColor *DAAEAccentColor(void) {
    switch (DAAEAccentIdx()) {
        case 1:  return [UIColor colorWithRed:1.00 green:0.60 blue:0.10 alpha:1]; // Naranja
        case 2:  return [UIColor colorWithRed:0.95 green:0.22 blue:0.22 alpha:1]; // Rojo
        case 3:  return [UIColor colorWithRed:0.95 green:0.82 blue:0.14 alpha:1]; // Amarillo
        case 4:  return [UIColor colorWithRed:0.24 green:0.82 blue:0.50 alpha:1]; // Verde
        case 5:  return [UIColor colorWithWhite:0.05 alpha:1];                     // Negro (modo claro)
        case 6:  return [UIColor colorWithWhite:0.96 alpha:1];                     // Blanco (modo oscuro)
        default: return [UIColor colorWithRed:0.26 green:0.78 blue:0.90 alpha:1]; // Celeste
    }
}
// Foreground sobre el acento (icono sidebar activo, pill activo)
static UIColor *DAAEAccentFG(void) {
    NSInteger idx = DAAEAccentIdx();
    if (idx == 3) return [UIColor colorWithWhite:0.1 alpha:1]; // amarillo→texto oscuro
    if (idx == 4) return [UIColor colorWithWhite:0.1 alpha:1]; // verde claro→texto oscuro
    if (idx == 6) return [UIColor colorWithWhite:0.1 alpha:1]; // blanco→texto oscuro
    return UIColor.whiteColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// PALETA ADAPTATIVA
// ─────────────────────────────────────────────────────────────────────────────
static UIColor *PanelBG(void) {
    return DAAEDark() ? [UIColor colorWithWhite:0.08 alpha:0.86]
                      : [UIColor colorWithWhite:0.96 alpha:0.92];
}
static UIColor *RowBG(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.07]
                      : [UIColor colorWithWhite:0 alpha:0.05];
}
static UIColor *RowBGOn(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.13]
                      : [UIColor colorWithWhite:0 alpha:0.09];
}
static UIColor *SectionClr(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.38]
                      : [UIColor colorWithWhite:0 alpha:0.38];
}
static UIColor *LblMain(void) {
    return DAAEDark() ? [UIColor colorWithWhite:0.96 alpha:1]
                      : [UIColor colorWithWhite:0.08 alpha:1];
}
static UIColor *LblDim(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.45]
                      : [UIColor colorWithWhite:0 alpha:0.40];
}
static UIColor *CheckRing(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.18]
                      : [UIColor colorWithWhite:0 alpha:0.15];
}
static UIColor *SidebarBG(void) {
    return DAAEDark() ? [UIColor colorWithWhite:0 alpha:0.12]
                      : [UIColor colorWithWhite:0 alpha:0.05];
}
static UIColor *HeaderBG(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.05]
                      : [UIColor colorWithWhite:0 alpha:0.04];
}
static UIColor *DivClr(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.07]
                      : [UIColor colorWithWhite:0 alpha:0.07];
}
static UIBlurEffectStyle DAAEBlurStyle(void) {
    return DAAEDark() ? UIBlurEffectStyleSystemMaterialDark
                      : UIBlurEffectStyleSystemMaterialLight;
}

// ─────────────────────────────────────────────────────────────────────────────
// AIM TYPE — -1 = sin aim
// ─────────────────────────────────────────────────────────────────────────────
static float     AimRaw(void)    { return ESPPrefsFloat(@"AimType", -1); }
static BOOL      AimActive(void) { return AimRaw() >= 0; }
static NSInteger AimIdx(void)    { return AimActive() ? (NSInteger)AimRaw() : -1; }

// ─────────────────────────────────────────────────────────────────────────────
// CHECKMARK CIRCLE — idéntico a imágenes de referencia
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
            self.backgroundColor   = accent;
            self.layer.borderColor = accent.CGColor;
            self->_iv.tintColor    = UIColor.whiteColor;
            self->_iv.hidden       = NO;
        } else {
            self.backgroundColor   = UIColor.clearColor;
            self.layer.borderColor = CheckRing().CGColor;
            self->_iv.hidden       = YES;
        }
    };
    if (anim) [UIView animateWithDuration:0.18 delay:0
        options:UIViewAnimationOptionCurveEaseInOut animations:upd completion:nil];
    else upd();
}
- (void)refreshTheme { [self setOn:_on animated:NO]; }
@end

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE ROW
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
        lbl.text = txt;
        lbl.textColor = LblMain();
        lbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        lbl.tag  = 888;
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
    self.layer.cornerRadius = RadiusRow();
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
// PILL PICKER ROW — selector horizontal tipo capsule
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
}
- (instancetype)initWithOptions:(NSArray<NSString *> *)opts
                       selected:(NSInteger)sel
                          width:(CGFloat)w {
    NSInteger n = (NSInteger)opts.count;
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, 50)])) {
        _selectedIndex = sel;
        self.backgroundColor    = RowBG();
        self.layer.cornerRadius = RadiusRow();
        self.clipsToBounds      = YES;
        CGFloat pad = 8, gap = 6;
        CGFloat btnW = (w - pad*2 - gap*(n-1)) / (CGFloat)n;
        NSMutableArray<UIButton *> *pills = [NSMutableArray array];
        for (NSInteger i = 0; i < n; i++) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.frame = CGRectMake(pad + i*(btnW+gap), 8, btnW, 34);
            b.layer.cornerRadius = RadiusChip();
            b.clipsToBounds = YES;
            b.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
            b.titleLabel.adjustsFontSizeToFitWidth = YES;
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
        b.backgroundColor = sel ? accent : UIColor.clearColor;
        [b setTitleColor:sel ? DAAEAccentFG() : LblDim() forState:UIControlStateNormal];
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
    self.backgroundColor    = RowBG();
    self.layer.cornerRadius = RadiusRow();
    for (UIButton *b in _pills) b.layer.cornerRadius = RadiusChip();
    [self _refreshPills];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// SLIDER ROW — label + valor en acento, slider con track acento
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAESlider : UIView
- (void)refreshTheme;
@end
@implementation DAAESlider { UILabel *_lbl; UILabel *_val; UISlider *_sl; }
- (instancetype)initWithLabel:(NSString *)txt key:(NSString *)key
                          min:(float)mn max:(float)mx fallback:(float)fb width:(CGFloat)w {
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, 72)])) {
        self.backgroundColor    = RowBG();
        self.layer.cornerRadius = RadiusRow();
        _lbl = [[UILabel alloc] initWithFrame:CGRectMake(18, 8, w-90, 22)];
        _lbl.text = txt; _lbl.textColor = LblMain();
        _lbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [self addSubview:_lbl];
        _val = [[UILabel alloc] initWithFrame:CGRectMake(w-68, 8, 56, 22)];
        _val.textAlignment = NSTextAlignmentRight;
        _val.textColor = DAAEAccentColor();
        _val.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
        float cur = ESPPrefsFloat(key, fb);
        _val.text = [NSString stringWithFormat:@"%.0f", cur];
        [self addSubview:_val];
        _sl = [[UISlider alloc] initWithFrame:CGRectMake(14, 42, w-28, 22)];
        _sl.minimumValue = mn; _sl.maximumValue = mx; _sl.value = cur;
        _sl.minimumTrackTintColor = DAAEAccentColor();
        _sl.maximumTrackTintColor = DAAEDark()
            ? [UIColor colorWithWhite:1 alpha:0.14]
            : [UIColor colorWithWhite:0 alpha:0.10];
        _sl.thumbTintColor = DAAEAccentColor();
        objc_setAssociatedObject(_sl,"valLbl",_val,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(_sl,"espKey",key, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [_sl addTarget:self action:@selector(_slid:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_sl];
    }
    return self;
}
- (void)_slid:(UISlider *)sl {
    UILabel  *val = objc_getAssociatedObject(sl,"valLbl");
    NSString *key = objc_getAssociatedObject(sl,"espKey");
    val.text = [NSString stringWithFormat:@"%.0f", sl.value];
    ESPPrefsSetFloat(key, sl.value);
    ESPSyncFromPrefs();
}
- (void)refreshTheme {
    UIColor *accent = DAAEAccentColor();
    self.backgroundColor    = RowBG();
    self.layer.cornerRadius = RadiusRow();
    _lbl.textColor = LblMain(); _val.textColor = accent;
    _sl.minimumTrackTintColor = accent; _sl.thumbTintColor = accent;
    _sl.maximumTrackTintColor = DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.14]
        : [UIColor colorWithWhite:0 alpha:0.10];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW helper
// ─────────────────────────────────────────────────────────────────────────────
static UIView *InfoRow(NSString *title, NSString *value, CGFloat w, BOOL dim) {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0,0,w,52)];
    row.backgroundColor = RowBG();
    row.layer.cornerRadius = RadiusRow();
    UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(16,0,w*0.45,52)];
    tl.text = title; tl.textColor = LblMain();
    tl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [row addSubview:tl];
    UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(w*0.44,0,w*0.52-8,52)];
    vl.text = value;
    vl.textColor = dim ? LblDim() : DAAEAccentColor();
    vl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    vl.textAlignment = NSTextAlignmentRight;
    [row addSubview:vl];
    return row;
}

// ─────────────────────────────────────────────────────────────────────────────
// WARNING LABEL helper — texto de advertencia en rojo/naranja
// ─────────────────────────────────────────────────────────────────────────────
static CGFloat AddWarningLabel(NSString *text, UIScrollView *scroll, CGFloat w, CGFloat y) {
    UILabel *warn = [[UILabel alloc] initWithFrame:CGRectMake(0, y, w, 0)];
    warn.text = text;
    warn.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    warn.textColor = [UIColor colorWithRed:0.95 green:0.22 blue:0.22 alpha:1.0];
    warn.numberOfLines = 0;
    warn.lineBreakMode = NSLineBreakByWordWrapping;
    warn.alpha = 0.85;
    CGSize sz = [warn sizeThatFits:CGSizeMake(w, 999)];
    warn.frame = CGRectMake(0, y, w, sz.height);
    [scroll addSubview:warn];
    return y + sz.height + 10;
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
// Color swatch ref para live update
@property (nonatomic, strong) UILabel   *colorSwatchLabel;
@end

@implementation _0xDEADBEEE

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
    // Modo oscuro + acento rojo por defecto (igual a las imágenes)
    [ud setBool:YES forKey:@"DAAE.darkMode"];
    [ud setInteger:2 forKey:@"DAAE.accentIdx"]; // Rojo por defecto
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyDefaults];
    MizzePrepareMenuPrefs();
    self.pointer = -1; self.colorTarget = 0;
    self.controls = [NSMutableArray array];
    self.view.backgroundColor = UIColor.clearColor;

    __weak _0xDEADBEEE *ws = self;
    self.spinStatusTimer = [NSTimer scheduledTimerWithTimeInterval:.5 repeats:YES
        block:^(NSTimer *_){
            _0xDEADBEEE *s = ws;
            if (s.isViewLoaded && s.view.window && !s.view.hidden && s.spinStatusLabel)
                [s updateSpinStatus];
        }];

    self.blurBG = [[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:DAAEBlurStyle()]];
    self.blurBG.layer.cornerRadius = RadiusPanel();
    self.blurBG.clipsToBounds = YES;
    self.blurBG.alpha = DAAEPanelAlpha();
    [self.view addSubview:self.blurBG];

    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.backgroundColor    = PanelBG();
    self.panel.layer.cornerRadius = RadiusPanel();
    self.panel.layer.borderWidth  = 0.6;
    self.panel.layer.borderColor  = (DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.13]
        : [UIColor colorWithWhite:0 alpha:0.10]).CGColor;
    self.panel.clipsToBounds = YES;
    self.panel.alpha = DAAEPanelAlpha();
    [self.view addSubview:self.panel];

    self.sidebar = [[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.backgroundColor = SidebarBG();
    [self.panel addSubview:self.sidebar];

    UIView *div = [[UIView alloc] initWithFrame:CGRectZero];
    div.tag = 99; div.backgroundColor = DivClr();
    [self.panel addSubview:div];

    self.contentArea = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentArea.backgroundColor = UIColor.clearColor;
    [self.panel addSubview:self.contentArea];

    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator = NO;
    self.scroll.bounces = YES;
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud boolForKey:@"DAAE.tgOpened"]) {
        [ud setBool:YES forKey:@"DAAE.tgOpened"];
        [ud synchronize];
        NSURL *tgURL = [NSURL URLWithString:@"https://t.me/didierxit7"];
        if (tgURL) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication openURL:tgURL options:@{} completionHandler:nil];
            });
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT — respeta la escala del panel
// ─────────────────────────────────────────────────────────────────────────────
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sw = self.view.bounds.size.width;
    CGFloat sh = self.view.bounds.size.height;
    if (sw <= 0) sw = 320; if (sh <= 0) sh = 480;

    CGFloat scale = DAAEPanelScale();
    CGFloat basePW = MIN(sw - 120.0, 480.0);
    basePW = MAX(basePW, 280.0);
    CGFloat basePH = MIN(sh - 60.0, 560.0);
    basePH = MAX(basePH, 340.0);

    CGFloat pw = basePW * scale;
    CGFloat ph = basePH * scale;
    pw = MAX(pw, 240.0); ph = MAX(ph, 260.0);

    CGRect f = self.panel.frame;
    if (f.size.width < 1) {
        f = CGRectMake((sw-pw)/2.0, (sh-ph)/2.0, pw, ph);
    } else {
        f.size = CGSizeMake(pw, ph);
        f.origin.x = MAX(4, MIN(f.origin.x, sw-pw-4));
        f.origin.y = MAX(4, MIN(f.origin.y, sh-ph-4));
    }
    self.panel.frame  = f;
    self.blurBG.frame = f;

    const CGFloat sbW = 70.0;
    self.sidebar.frame = CGRectMake(0,0,sbW,ph);
    UIView *div = [self.panel viewWithTag:99];
    div.frame = CGRectMake(sbW,0,0.5,ph);
    CGFloat caW = pw - sbW - 0.5;
    self.contentArea.frame = CGRectMake(sbW+0.5, 0, caW, ph);
    const CGFloat headerH = 54.0, padH = 10.0, padB = 10.0;
    self.scroll.frame = CGRectMake(padH, headerH, caW-padH*2, ph-headerH-padB);

    [self layoutSidebarButtons];
    if (fabs(self.builtWidth - self.scroll.bounds.size.width) > 0.5) [self buildPage];
    [self refreshSidebarSelection];
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR — 5 tabs: ESP / AIM / COLORS / MISC / SETTINGS
// ─────────────────────────────────────────────────────────────────────────────
static NSArray<NSString *> *TabIcons(void) {
    return @[@"eye.fill",@"scope",@"paintpalette.fill",@"shippingbox.fill",@"gearshape.fill"];
}
static NSString *TabName(NSInteger i) {
    NSArray *en = @[@"ESP",@"AIM",@"COLORS",@"MISC",@"SETTINGS"];
    NSArray *es = @[@"ESP",@"APUNT",@"COLORES",@"EXTRA",@"CONFIG"];
    NSArray *vi = @[@"ESP",@"AIM",@"MÀU",@"KHÁC",@"CÀI"];
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
        btn.tag = 300+i;
        btn.layer.cornerRadius = DAAESquareCorners() ? 10 : 16;
        [btn setImage:SFSym(icons[(NSUInteger)i], 18, UIImageSymbolWeightSemibold)
             forState:UIControlStateNormal];
        UILabel *lbl = [[UILabel alloc] init];
        lbl.tag = 400+i; lbl.text = TabName(i);
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
    const CGFloat btnW=54, btnH=56, gap=8;
    CGFloat total = 5*btnH + 4*gap;
    CGFloat sbH = self.sidebar.bounds.size.height;
    if (sbH<1) sbH=400;
    CGFloat startY = (sbH-total)/2.0;
    for (NSInteger i=0;i<5;i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300+i];
        if (!btn) continue;
        btn.frame = CGRectMake((70-btnW)/2.0, startY+i*(btnH+gap), btnW, btnH);
        UILabel *lbl = (UILabel *)[btn viewWithTag:400+i];
        if (lbl) lbl.frame = CGRectMake(0, btnH-16, btnW, 13);
        btn.imageEdgeInsets = UIEdgeInsetsMake(-4,0,16,0);
    }
}
- (void)refreshSidebarSelection {
    UIColor *accent = DAAEAccentColor();
    UIColor *accentFG = DAAEAccentFG();
    for (NSInteger i=0;i<5;i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300+i];
        if (!btn) continue;
        BOOL sel = (i==self.page);
        btn.backgroundColor = sel ? accent
            : [UIColor colorWithWhite:DAAEDark()?1:0 alpha:0.06];
        btn.tintColor = sel ? accentFG : LblDim();
        btn.layer.borderWidth = sel ? 0 : 0.5;
        btn.layer.borderColor = (DAAEDark()
            ? [UIColor colorWithWhite:1 alpha:0.14]
            : [UIColor colorWithWhite:0 alpha:0.10]).CGColor;
        UILabel *lbl = (UILabel *)[btn viewWithTag:400+i];
        if (lbl) { lbl.textColor = sel ? accentFG : LblDim(); lbl.text = TabName(i); }
    }
}
- (void)sidebarTap:(UIButton *)sender {
    NSInteger pg = sender.tag-300;
    if (pg==self.page) return;
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
        if (v.tag>=500&&v.tag<600) [v removeFromSuperview];
    CGFloat cw = self.contentArea.bounds.size.width;
    if (cw<10) cw=280;

    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(10,7,cw-20,40)];
    hdr.tag = 500;
    hdr.backgroundColor    = HeaderBG();
    hdr.layer.cornerRadius = DAAESquareCorners() ? 4 : 13;
    [self.contentArea addSubview:hdr];

    UIImageView *iv = [[UIImageView alloc] initWithImage:
        SFSym(TabIcons()[(NSUInteger)self.page],14,UIImageSymbolWeightSemibold)];
    iv.tag=501; iv.tintColor=DAAEAccentColor(); iv.contentMode=UIViewContentModeScaleAspectFit;
    iv.frame=CGRectMake(24,18,15,15);
    [self.contentArea addSubview:iv];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(46,10,cw-110,34)];
    title.tag=502; title.text=TabName(self.page);
    title.textColor=DAAEAccentColor();
    title.font=[UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [self.contentArea addSubview:title];

    // Dark mode toggle — luna/sol a la izquierda de la X
    UIButton *darkBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    darkBtn.tag = 505;
    darkBtn.frame = CGRectMake(cw - 76, 10, 30, 34);
    NSString *darkIcon = DAAEDark() ? @"sun.max.fill" : @"moon.fill";
    [darkBtn setImage:SFSym(darkIcon, 13, UIImageSymbolWeightSemibold)
             forState:UIControlStateNormal];
    darkBtn.tintColor = DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.55]
                                   : [UIColor colorWithWhite:0 alpha:0.40];
    [darkBtn addTarget:self action:@selector(darkModeToggleTap)
           forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:darkBtn];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.tag=503; close.frame=CGRectMake(cw-42,10,30,34);
    [close setImage:SFSym(@"xmark",12,UIImageSymbolWeightBold) forState:UIControlStateNormal];
    close.tintColor=LblDim();
    [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:close];
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
- (CGFloat)contentWidth {
    CGFloat w = self.scroll.bounds.size.width;
    return (w>10)?w:260;
}

- (CGFloat)addToggleEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key fallback:(BOOL)fb y:(CGFloat)y {
    CGFloat w = [self contentWidth];
    DAAERow *row = [[DAAERow alloc] initWithLabel:DAAEStr(en,es,vi)
                                               on:ESPPrefsBool(key,fb) width:w];
    row.frame = CGRectMake(0,y,w,60);
    objc_setAssociatedObject(row,"espKey",key,OBJC_ASSOCIATION_COPY_NONATOMIC);
    __weak DAAERow *wrow=row; __weak _0xDEADBEEE *wself=self;
    row.onChanged = ^(BOOL on) {
        NSString *k = objc_getAssociatedObject(wrow,"espKey");
        ESPPrefsSetBool(k,on); ESPSyncFromPrefs();
        [wself toggleChanged:k value:on];
    };
    [self.controls addObject:row];
    [self.scroll addSubview:row];
    return y+68;
}

- (CGFloat)addSection:(NSString *)title y:(CGFloat)y {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(4,y+4,[self contentWidth]-8,20)];
    l.text=title; l.textColor=SectionClr();
    l.font=[UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    [self.scroll addSubview:l];
    return y+30;
}

- (CGFloat)addSliderEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key min:(float)mn max:(float)mx fallback:(float)fb y:(CGFloat)y {
    CGFloat w=[self contentWidth];
    DAAESlider *sl=[[DAAESlider alloc] initWithLabel:DAAEStr(en,es,vi)
                                                 key:key min:mn max:mx fallback:fb width:w];
    sl.frame=CGRectMake(0,y,w,72);
    [self.controls addObject:(UIControl *)sl];
    [self.scroll addSubview:sl];
    return y+80;
}

- (void)rebuildAnimated {
    if (UIAccessibilityIsReduceMotionEnabled()) { [self buildPage]; return; }
    [UIView transitionWithView:self.scroll duration:0.15
        options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionAllowUserInteraction
        animations:^{ [self buildPage]; } completion:nil];
}

- (void)refreshThemeInPlace {
    CGFloat alpha = DAAEPanelAlpha();
    self.panel.alpha  = alpha;
    self.blurBG.alpha = alpha;
    self.panel.backgroundColor = PanelBG();
    self.panel.layer.cornerRadius = RadiusPanel();
    self.panel.layer.borderColor = (DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.13]
        : [UIColor colorWithWhite:0 alpha:0.10]).CGColor;
    self.blurBG.effect = [UIBlurEffect effectWithStyle:DAAEBlurStyle()];
    self.blurBG.layer.cornerRadius = RadiusPanel();
    self.sidebar.backgroundColor = SidebarBG();
    UIView *div = [self.panel viewWithTag:99];
    div.backgroundColor = DivClr();
    // Rebuild sidebar buttons so cornerRadius updates to current mode
    [self buildSidebar];
    [self buildPage];
    [self refreshSidebarSelection];
}

// ─────────────────────────────────────────────────────────────────────────────
// buildPage
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildPage {
    const CGFloat offset = self.scroll.contentOffset.y;
    for (UIView *v in self.scroll.subviews) [v removeFromSuperview];
    [self.controls removeAllObjects];
    self.spinStatusLabel = nil;
    self.colorSwatchLabel = nil;
    self.builtWidth = [self contentWidth];
    [self buildHeader];
    CGFloat y = 6;

    // ── TAB 0: ESP ────────────────────────────────────────────────────────────
    if (self.page == 0) {
        y=[self addToggleEN:@"Enable ESP"   ES:@"Activar ESP"      VI:@"Bật ESP"
                        key:@"ESPEnabled" fallback:YES y:y];
        y=[self addSection:DAAEStr(@"— DRAW —",@"— DIBUJO —",@"— VẼ —") y:y];
        y=[self addToggleEN:@"Box ESP"      ES:@"Marco ESP"         VI:@"Khung ESP"
                        key:@"Box" fallback:YES y:y];
        y=[self addToggleEN:@"Line ESP"     ES:@"Línea ESP"         VI:@"Đường Kẻ ESP"
                        key:@"Line" fallback:NO y:y];
        y=[self addToggleEN:@"Skeleton"     ES:@"Esqueleto"         VI:@"Bộ Xương"
                        key:@"Skeleton" fallback:NO y:y];
        y=[self addToggleEN:@"Head Dot"     ES:@"Punto cabeza"      VI:@"Đầu Đỏ"
                        key:@"HeadRedDot" fallback:NO y:y];
        y=[self addToggleEN:@"Health Bar"   ES:@"Barra de vida"     VI:@"Thanh Máu"
                        key:@"Health" fallback:YES y:y];
        y=[self addToggleEN:@"Name"         ES:@"Nombre"            VI:@"Tên"
                        key:@"Name" fallback:YES y:y];
        y=[self addToggleEN:@"Distance"     ES:@"Distancia"         VI:@"Khoảng Cách"
                        key:@"Dis" fallback:YES y:y];
        y=[self addToggleEN:@"Clean ESP"    ES:@"ESP limpio"        VI:@"ESP Sạch"
                        key:@"CleanESP" fallback:YES y:y];
        y=[self addSection:DAAEStr(@"— FOV —",@"— FOV —",@"— FOV —") y:y];
        y=[self addToggleEN:@"Show FOV"     ES:@"Mostrar FOV"       VI:@"Hiện Vòng FOV"
                        key:@"ShowFov" fallback:YES y:y];
        y=[self addSliderEN:@"FOV Size"     ES:@"Tamaño FOV"        VI:@"Bán Kính FOV"
                        key:@"FovSize" min:5 max:48 fallback:40 y:y];

    // ── TAB 1: AIM ────────────────────────────────────────────────────────────
    } else if (self.page == 1) {
        // Advertencia aimbot — igual a la imagen de referencia
        NSString *aimWarn = DAAEStr(
            @"Use Aimbot with restraint. Avoid excessive headshots to reduce unexpected detections.",
            @"Usa el Aimbot con moderación. Evita muchos headshots para reducir detecciones inesperadas.",
            @"Sử dụng Aimbot có chừng mực. Tránh headshot quá nhiều để giảm nguy cơ bị phát hiện.");
        y = AddWarningLabel(aimWarn, self.scroll, [self contentWidth], y);
        y=[self addToggleEN:@"Enable Aimbot" ES:@"Activar Aimbot"   VI:@"Bật Aimbot"
                        key:@"AimTargetLine" fallback:NO y:y];
        y=[self addToggleEN:@"Aim Line"      ES:@"Línea objetivo"   VI:@"Aim Line"
                        key:@"AimTargetLine" fallback:YES y:y];
        y=[self addToggleEN:@"Show FOV"      ES:@"Mostrar FOV"      VI:@"Hiện Vòng FOV"
                        key:@"ShowFov" fallback:YES y:y];
        y=[self addToggleEN:@"Skip Bots"     ES:@"Ignorar bots"     VI:@"Bỏ Qua Bot"
                        key:@"AimLag" fallback:NO y:y];

        y=[self addSection:DAAEStr(@"— ACTIVATION —",@"— ACTIVACIÓN —",@"— KÍCH HOẠT —") y:y];
        NSArray *actOpts = @[
            DAAEStr(@"Always",   @"Siempre",    @"Luôn Luôn"),
            DAAEStr(@"On Shoot", @"Al Disparar",@"Khi Bắn"),
            DAAEStr(@"On Scope", @"Al Apuntar", @"Khi Ngắm"),
        ];
        const NSInteger curActRaw = static_cast<int>(
            AimModePolicy::ReadActivation(ESPPrefsFloat(@"AimActivation",0)));
        NSInteger actSel = (curActRaw>=1&&curActRaw<=3) ? curActRaw-1 : 0;
        CGFloat w=[self contentWidth];
        DAAEPillPicker *actPicker=[[DAAEPillPicker alloc]
            initWithOptions:actOpts selected:actSel width:w];
        actPicker.frame=CGRectMake(0,y,w,50);
        actPicker.onSelected=^(NSInteger idx){
            ESPPrefsSetFloat(@"AimActivation",(float)(idx+1));
            ESPClearAimLock(); ESPSyncFromPrefs();
        };
        [self.scroll addSubview:actPicker];
        y+=58;

        y=[self addSection:DAAEStr(@"— AIM POSITION —",@"— POSICIÓN AIM —",@"— VỊ TRÍ NGẮM —") y:y];
        NSArray *aimOpts=@[
            DAAEStr(@"Head",@"Cabeza",@"Đầu"),
            DAAEStr(@"Neck",@"Cuello",@"Cổ"),
            DAAEStr(@"Body",@"Cuerpo",@"Thân"),
        ];
        float aimRaw=AimRaw();
        NSInteger aimSel=(aimRaw>=0&&aimRaw<=2)?(NSInteger)aimRaw:0;
        DAAEPillPicker *aimPicker=[[DAAEPillPicker alloc]
            initWithOptions:aimOpts selected:aimSel width:w];
        aimPicker.frame=CGRectMake(0,y,w,50);
        aimPicker.onSelected=^(NSInteger idx){
            ESPPrefsSetFloat(@"AimType",(float)idx);
            ESPPrefsSetFloat(@"AimActivation",static_cast<int>(
                AimModePolicy::AfterTypeSelection(AimModePolicy::ReadType((float)idx))));
            ESPPrefsSetBool(@"SilentAim",NO);
            ESPClearAimLock(); ESPSyncFromPrefs();
        };
        [self.scroll addSubview:aimPicker];
        y+=58;

        y=[self addSliderEN:@"FOV Radius"    ES:@"Radio FOV"         VI:@"Bán Kính FOV"
                        key:@"FovSize" min:5 max:48 fallback:40 y:y];
        y=[self addSliderEN:@"FOV Thickness" ES:@"Grosor FOV"        VI:@"Độ Dày FOV"
                        key:@"SilentFovSize" min:0 max:10 fallback:0 y:y];
        y=[self addSection:DAAEStr(@"— WEAPONS —",@"— ARMAS —",@"— VŨ KHÍ —") y:y];
        y=[self addToggleEN:@"Fast Fire"    ES:@"Disparo rápido"    VI:@"Bắn Nhanh"
                        key:@"FastFire" fallback:NO y:y];
        y=[self addToggleEN:@"No Reload"    ES:@"Sin recarga"       VI:@"Không Nạp"
                        key:@"ShootNoReload" fallback:NO y:y];

    // ── TAB 2: COLORS ─────────────────────────────────────────────────────────
    } else if (self.page == 2) {
        CGFloat w=[self contentWidth];
        UISegmentedControl *seg=[[UISegmentedControl alloc] initWithItems:@[@"Box",@"FOV"]];
        seg.frame=CGRectMake(0,y,w,36);
        seg.selectedSegmentIndex=self.colorTarget;
        seg.selectedSegmentTintColor=DAAEAccentColor();
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:LblMain(),
            NSFontAttributeName:[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]}
                            forState:UIControlStateNormal];
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.whiteColor}
                            forState:UIControlStateSelected];
        [seg addTarget:self action:@selector(colorTargetChanged:)
             forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:seg];
        [self.controls addObject:(UIControl *)seg];
        y+=46;

        NSString *pfx=(self.colorTarget==0)?@"BoxColor":@"FovColor";
        float r=ESPPrefsFloat([pfx stringByAppendingString:@"R"],0.26);
        float g=ESPPrefsFloat([pfx stringByAppendingString:@"G"],0.78);
        float b=ESPPrefsFloat([pfx stringByAppendingString:@"B"],0.90);

        // Swatch — guardamos referencia para live update
        UILabel *swatch=[[UILabel alloc] initWithFrame:CGRectMake(0,y,w,50)];
        swatch.text=[NSString stringWithFormat:@"#%02X%02X%02X",
            (int)round(r*255),(int)round(g*255),(int)round(b*255)];
        swatch.textAlignment=NSTextAlignmentCenter;
        swatch.backgroundColor=[UIColor colorWithRed:r green:g blue:b alpha:1];
        CGFloat lum=r*0.299+g*0.587+b*0.114;
        swatch.textColor=lum>0.6?UIColor.blackColor:UIColor.whiteColor;
        swatch.font=[UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        swatch.layer.cornerRadius=RadiusRow();
        swatch.clipsToBounds=YES;
        swatch.tag=990; // live update tag
        [self.scroll addSubview:swatch];
        self.colorSwatchLabel = swatch;
        y+=58;

        NSArray *rgbEN=@[@"Red",@"Green",@"Blue"];
        NSArray *rgbES=@[@"Rojo",@"Verde",@"Azul"];
        NSArray *rgbVI=@[@"Đỏ",@"Xanh lá",@"Xanh dương"];
        NSArray *suf=@[@"R",@"G",@"B"];
        float def[3]={0.26f,0.78f,0.90f};
        __weak UILabel *wSwatch = swatch;
        __weak NSString *wPfx   = pfx;
        __weak _0xDEADBEEE *wself2 = self;
        for (int i=0;i<3;i++) {
            NSString *key=[pfx stringByAppendingString:suf[(NSUInteger)i]];
            CGFloat sw2=[self contentWidth];
            // Build row manually so we control the UISlider target directly
            UIView *rgbRow=[[UIView alloc] initWithFrame:CGRectMake(0,y,sw2,72)];
            rgbRow.backgroundColor=RowBG(); rgbRow.layer.cornerRadius=RadiusRow();

            UILabel *lbl=[[UILabel alloc] initWithFrame:CGRectMake(18,8,sw2-90,22)];
            lbl.text=DAAEStr(rgbEN[(NSUInteger)i],rgbES[(NSUInteger)i],rgbVI[(NSUInteger)i]);
            lbl.textColor=LblMain();
            lbl.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
            [rgbRow addSubview:lbl];

            UILabel *val=[[UILabel alloc] initWithFrame:CGRectMake(sw2-68,8,56,22)];
            val.textAlignment=NSTextAlignmentRight;
            val.textColor=DAAEAccentColor();
            val.font=[UIFont systemFontOfSize:15 weight:UIFontWeightBold];
            float cur2=ESPPrefsFloat(key,def[i]);
            val.text=[NSString stringWithFormat:@"%.0f",(double)cur2*100.0];
            [rgbRow addSubview:val];

            UISlider *rgbSl=[[UISlider alloc] initWithFrame:CGRectMake(14,42,sw2-28,22)];
            rgbSl.minimumValue=0; rgbSl.maximumValue=1; rgbSl.value=cur2;
            rgbSl.minimumTrackTintColor=DAAEAccentColor();
            rgbSl.maximumTrackTintColor=DAAEDark()
                ?[UIColor colorWithWhite:1 alpha:0.14]:[UIColor colorWithWhite:0 alpha:0.10];
            rgbSl.thumbTintColor=DAAEAccentColor();
            // Store refs for live update
            objc_setAssociatedObject(rgbSl,"espKey",  key,   OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(rgbSl,"valLbl",  val,   OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(rgbSl,"swatchRef",wSwatch, OBJC_ASSOCIATION_ASSIGN);
            objc_setAssociatedObject(rgbSl,"swatchPfx",wPfx,   OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(rgbSl,"menuRef",  wself2, OBJC_ASSOCIATION_ASSIGN);
            [rgbSl addTarget:self action:@selector(_colorSliderChanged:)
                forControlEvents:UIControlEventValueChanged];
            [rgbRow addSubview:rgbSl];
            [self.scroll addSubview:rgbRow];
            y+=80;
        }

    // ── TAB 3: MISC ───────────────────────────────────────────────────────────
    } else if (self.page == 3) {
        // Advertencia opciones peligrosas — igual a la imagen de referencia
        NSString *miscWarn = DAAEStr(
            @"Some options in this section may not be entirely safe. Use with caution and at your own risk.",
            @"Algunas opciones en esta sección pueden no ser completamente seguras. Úsalas con precaución y bajo tu propio riesgo.",
            @"Một số tùy chọn trong mục này có thể không hoàn toàn an toàn. Hãy cẩn thận và tự chịu trách nhiệm.");
        y = AddWarningLabel(miscWarn, self.scroll, [self contentWidth], y);
        y=[self addSection:DAAEStr(@"— EXTRAS —",@"— EXTRAS —",@"— EXTRAS —") y:y];
        y=[self addToggleEN:@"Ghost"         ES:@"Fantasma"         VI:@"Ghost"
                        key:@"GhostModeFloating" fallback:NO y:y];
        y=[self addToggleEN:@"FakeLag"       ES:@"Lag Falso"        VI:@"FakeLag"
                        key:@"FakeLagFloating" fallback:NO y:y];
        y=[self addToggleEN:@"Fly"           ES:@"Volar"            VI:@"Bay"
                        key:@"FlyFloating" fallback:NO y:y];
        y=[self addToggleEN:@"Speed"         ES:@"Velocidad"        VI:@"Tốc Độ"
                        key:@"RunSpeedFloating" fallback:NO y:y];
        y=[self addToggleEN:@"Hide Buttons"  ES:@"Ocultar botones"  VI:@"Ẩn Nút"
                        key:@"HideFeatureButtons" fallback:NO y:y];
        y=[self addToggleEN:@"AimKill"       ES:@"Matar con aim"    VI:@"AimKill"
                        key:@"AutoFireFloating" fallback:NO y:y];
        y=[self addSection:DAAEStr(@"— MOVEMENT —",@"— MOVIMIENTO —",@"— DI CHUYỂN —") y:y];
        y=[self addToggleEN:@"Speed Toggle"  ES:@"Velocidad"        VI:@"Tốc Độ"
                        key:@"RunSpeed" fallback:NO y:y];
        y=[self addSliderEN:@"Speed Value"   ES:@"Velocidad (m/s)"  VI:@"Tốc Độ (m/s)"
                        key:@"RunSpeedValue" min:1 max:15 fallback:6 y:y];
        if (ESPPrefsBool(@"FlyFloating",NO))
            y=[self addSliderEN:@"Fly Height" ES:@"Altura vuelo"    VI:@"Độ Cao Bay"
                            key:@"FlyHeight" min:1 max:6 fallback:4 y:y];
        y=[self addSection:DAAEStr(@"— EFFECTS —",@"— EFECTOS —",@"— HIỆU ỨNG —") y:y];
        y=[self addToggleEN:@"Visual Spin"   ES:@"Giro Visual"      VI:@"Xoay Hiển Thị"
                        key:@"VisualSpin" fallback:NO y:y];
        if (ESPPrefsBool(@"VisualSpin",NO)) {
            y=[self addSliderEN:@"Spin Speed" ES:@"Vel. Giro"       VI:@"Tốc Độ Xoay"
                            key:@"VisualSpinSpeed" min:0.1 max:3 fallback:0.5 y:y];
            self.spinStatusLabel=[[UILabel alloc] initWithFrame:
                CGRectMake(4,y,[self contentWidth]-8,34)];
            self.spinStatusLabel.textColor=SectionClr();
            self.spinStatusLabel.font=[UIFont systemFontOfSize:11];
            self.spinStatusLabel.numberOfLines=2;
            [self.scroll addSubview:self.spinStatusLabel];
            [self updateSpinStatus]; y+=40;
        }
        y=[self addToggleEN:@"Balanced Render"     ES:@"Render equilibrado" VI:@"Render Cân Bằng"
                        key:@"BalancedRender" fallback:NO y:y];

    // ── TAB 4: SETTINGS ───────────────────────────────────────────────────────
    } else {
        CGFloat w=[self contentWidth];

        // ── Stream Mode ───────────────────────────────────────────────────────
        y=[self addSection:DAAEStr(@"— DISPLAY —",@"— PANTALLA —",@"— HIỂN THỊ —") y:y];
        y=[self addToggleEN:@"Stream Mode" ES:@"Modo Streaming" VI:@"Chế Độ Stream"
                        key:@"AnLive" fallback:NO y:y];

        // ── Menu Transparency slider ──────────────────────────────────────────
        {
            UIView *tRow = [[UIView alloc] initWithFrame:CGRectMake(0,y,w,72)];
            tRow.backgroundColor    = RowBG();
            tRow.layer.cornerRadius = RadiusRow();

            UILabel *tLbl = [[UILabel alloc] initWithFrame:CGRectMake(18,8,w-90,22)];
            tLbl.text      = DAAEStr(@"Menu Transparency",@"Transparencia",@"Độ Trong Suốt");
            tLbl.textColor = LblMain();
            tLbl.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
            [tRow addSubview:tLbl];

            UILabel *tVal = [[UILabel alloc] initWithFrame:CGRectMake(w-68,8,56,22)];
            tVal.textAlignment = NSTextAlignmentRight;
            tVal.textColor = DAAEAccentColor();
            tVal.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
            tVal.text = [NSString stringWithFormat:@"%.2f", DAAEPanelAlpha()];
            [tRow addSubview:tVal];

            UISlider *tSl = [[UISlider alloc] initWithFrame:CGRectMake(14,42,w-28,22)];
            tSl.minimumValue = 0.40f; tSl.maximumValue = 1.0f;
            tSl.value = (float)DAAEPanelAlpha();
            tSl.minimumTrackTintColor = DAAEAccentColor();
            tSl.maximumTrackTintColor = DAAEDark()
                ? [UIColor colorWithWhite:1 alpha:0.14]
                : [UIColor colorWithWhite:0 alpha:0.10];
            tSl.thumbTintColor = DAAEAccentColor();
            objc_setAssociatedObject(tSl,"alphaValLbl",tVal,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [tSl addTarget:self action:@selector(_panelAlphaChanged:)
                forControlEvents:UIControlEventValueChanged];
            [tRow addSubview:tSl];
            [self.scroll addSubview:tRow];
            y += 80;
        }

        // ── Idioma ────────────────────────────────────────────────────────────
        y=[self addSection:DAAEStr(@"— LANGUAGE —",@"— IDIOMA —",@"— NGÔN NGỮ —") y:y];
        UIView *langRow=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,52)];
        langRow.backgroundColor=RowBG(); langRow.layer.cornerRadius=RadiusRow();
        NSArray *codes=@[@"EN",@"ES",@"VI"];
        NSArray *names=@[@"English",@"Español",@"Tiếng Việt"];
        NSInteger curLang=DAAELang();
        CGFloat lbtnW=(w-32-12)/3.0;
        for (NSInteger k=0;k<3;k++) {
            UIButton *lb=[UIButton buttonWithType:UIButtonTypeCustom];
            lb.frame=CGRectMake(16+k*(lbtnW+6),10,lbtnW,32);
            BOOL sel=(k==curLang);
            lb.backgroundColor=sel?DAAEAccentColor():[UIColor colorWithWhite:DAAEDark()?1:0 alpha:0.06];
            lb.layer.cornerRadius=RadiusChip();
            [lb setTitle:codes[(NSUInteger)k] forState:UIControlStateNormal];
            lb.titleLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightBold];
            [lb setTitleColor:sel?DAAEAccentFG():LblMain() forState:UIControlStateNormal];
            objc_setAssociatedObject(lb,"langIdx",@(k),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [lb addTarget:self action:@selector(langTap:) forControlEvents:UIControlEventTouchUpInside];
            [langRow addSubview:lb];
        }
        [self.scroll addSubview:langRow]; y+=60;
        UILabel *lhint=[[UILabel alloc] initWithFrame:CGRectMake(0,y,w,18)];
        lhint.text=names[(NSUInteger)curLang]; lhint.textColor=SectionClr();
        lhint.font=[UIFont systemFontOfSize:11]; lhint.textAlignment=NSTextAlignmentCenter;
        [self.scroll addSubview:lhint]; y+=26;

        // ── Modo claro / oscuro ───────────────────────────────────────────────
        y=[self addSection:DAAEStr(@"— APPEARANCE —",@"— APARIENCIA —",@"— GIAO DIỆN —") y:y];
        NSArray *modeOpts=@[
            DAAEStr(@"Light Mode",@"Modo Claro",@"Sáng"),
            DAAEStr(@"Dark Mode", @"Modo Oscuro",@"Tối"),
        ];
        DAAEPillPicker *modePicker=[[DAAEPillPicker alloc]
            initWithOptions:modeOpts selected:(DAAEDark()?1:0) width:w];
        modePicker.frame=CGRectMake(0,y,w,50);
        __weak _0xDEADBEEE *wself=self;
        modePicker.onSelected=^(NSInteger idx){
            BOOL newDark=(idx==1);
            DAAEAdjustAccentForMode(newDark); // ajusta acento 5↔6 si aplica
            DAAESetDark(newDark);
            [wself refreshThemeInPlace];
        };
        [self.scroll addSubview:modePicker]; y+=58;

        // ── Esquinas ─────────────────────────────────────────────────────────
        y=[self addSection:DAAEStr(@"— MENU SHAPE —",@"— FORMA MENÚ —",@"— HÌNH DẠNG —") y:y];
        NSArray *cornerOpts=@[
            DAAEStr(@"Rounded",@"Redondeadas",@"Tròn"),
            DAAEStr(@"Square", @"Cuadradas",  @"Vuông"),
        ];
        DAAEPillPicker *cornerPicker=[[DAAEPillPicker alloc]
            initWithOptions:cornerOpts selected:(DAAESquareCorners()?1:0) width:w];
        cornerPicker.frame=CGRectMake(0,y,w,50);
        cornerPicker.onSelected=^(NSInteger idx){
            DAAESetSquareCorners(idx==1);
            [wself refreshThemeInPlace];
        };
        [self.scroll addSubview:cornerPicker]; y+=58;

        // ── Tamaño del panel — slider + botón reset ──────────────────────────
        y=[self addSection:DAAEStr(@"— MENU SCALE —",@"— ESCALA MENÚ —",@"— CỠ MENU —") y:y];
        UIView *sizeRow=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,72)];
        sizeRow.backgroundColor=RowBG(); sizeRow.layer.cornerRadius=RadiusRow();

        UILabel *sizeLbl=[[UILabel alloc] initWithFrame:CGRectMake(18,8,w-100,22)];
        sizeLbl.text=DAAEStr(@"Menu Scale",@"Escala Menú",@"Tỷ Lệ Menu");
        sizeLbl.textColor=LblMain();
        sizeLbl.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [sizeRow addSubview:sizeLbl];

        CGFloat curScale=DAAEPanelScale();
        UILabel *sizeVal=[[UILabel alloc] initWithFrame:CGRectMake(w-100,8,46,22)];
        sizeVal.textAlignment=NSTextAlignmentRight;
        sizeVal.textColor=DAAEAccentColor();
        sizeVal.font=[UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        sizeVal.text=[NSString stringWithFormat:@"%d%%",(int)round(curScale*100)];
        [sizeRow addSubview:sizeVal];

        // Botón reset — ↩ vuelve a 100%
        UIButton *resetBtn=[UIButton buttonWithType:UIButtonTypeSystem];
        resetBtn.frame=CGRectMake(w-46,4,38,34);
        [resetBtn setImage:SFSym(@"arrow.counterclockwise",13,UIImageSymbolWeightSemibold)
                  forState:UIControlStateNormal];
        resetBtn.tintColor=LblDim();
        resetBtn.layer.cornerRadius=RadiusChip();

        UISlider *sizeSl=[[UISlider alloc] initWithFrame:CGRectMake(14,42,w-28,24)];
        sizeSl.minimumValue=0.75f; sizeSl.maximumValue=1.30f;
        sizeSl.value=(float)curScale;
        sizeSl.minimumTrackTintColor=DAAEAccentColor();
        sizeSl.maximumTrackTintColor=DAAEDark()
            ?[UIColor colorWithWhite:1 alpha:0.14]
            :[UIColor colorWithWhite:0 alpha:0.10];
        sizeSl.thumbTintColor=DAAEAccentColor();
        objc_setAssociatedObject(sizeSl,"valLbl",sizeVal,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [sizeSl addTarget:self action:@selector(_panelScaleChanged:)
              forControlEvents:UIControlEventValueChanged];
        // Wire reset button
        objc_setAssociatedObject(resetBtn,"sizeSlider",sizeSl,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(resetBtn,"sizeLabel",sizeVal,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [resetBtn addTarget:self action:@selector(_panelScaleReset:)
                forControlEvents:UIControlEventTouchUpInside];
        [sizeRow addSubview:sizeSl];
        [sizeRow addSubview:resetBtn];
        [self.scroll addSubview:sizeRow]; y+=80;

        // ── Color de acento ───────────────────────────────────────────────────
        y=[self addSection:DAAEStr(@"— ACCENT COLOR —",@"— COLOR ACENTO —",@"— MÀU NHẤN —") y:y];

        // Colores fijos + dinámico (negro en claro / blanco en oscuro)
        // 0=Celeste 1=Naranja 2=Rojo 3=Amarillo 4=Verde + condicional 5o6
        BOOL dark=DAAEDark();
        NSMutableArray *accentColors=[NSMutableArray arrayWithArray:@[
            [UIColor colorWithRed:0.26 green:0.78 blue:0.90 alpha:1], // 0 Celeste
            [UIColor colorWithRed:1.00 green:0.60 blue:0.10 alpha:1], // 1 Naranja
            [UIColor colorWithRed:0.95 green:0.22 blue:0.22 alpha:1], // 2 Rojo
            [UIColor colorWithRed:0.95 green:0.82 blue:0.14 alpha:1], // 3 Amarillo
            [UIColor colorWithRed:0.24 green:0.82 blue:0.50 alpha:1], // 4 Verde
        ]];
        // Índice real para cada chip: 0-4, luego 5(negro) o 6(blanco)
        NSMutableArray *chipIdxMap=[@[@0,@1,@2,@3,@4] mutableCopy];
        if (dark) {
            [accentColors addObject:[UIColor colorWithWhite:0.96 alpha:1]]; // Blanco
            [chipIdxMap addObject:@6];
        } else {
            [accentColors addObject:[UIColor colorWithWhite:0.08 alpha:1]]; // Negro
            [chipIdxMap addObject:@5];
        }

        NSInteger nChips=(NSInteger)accentColors.count; // 6
        NSInteger curAccent=DAAEAccentIdx();
        UIView *accentRow=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,66)];
        accentRow.backgroundColor=RowBG(); accentRow.layer.cornerRadius=RadiusRow();
        CGFloat circD=30;
        CGFloat totalCW=nChips*circD+(nChips-1)*8;
        CGFloat startX=(w-totalCW)/2.0;
        for (NSInteger k=0;k<nChips;k++) {
            NSInteger realIdx=[chipIdxMap[(NSUInteger)k] integerValue];
            UIButton *cb=[UIButton buttonWithType:UIButtonTypeCustom];
            cb.frame=CGRectMake(startX+k*(circD+8),(66-circD)/2.0,circD,circD);
            cb.backgroundColor=accentColors[(NSUInteger)k];
            cb.layer.cornerRadius=circD/2.0; cb.clipsToBounds=YES;
            if (realIdx==curAccent) {
                cb.layer.borderWidth=2.5;
                cb.layer.borderColor=(dark
                    ?[UIColor colorWithWhite:1 alpha:0.85]
                    :[UIColor colorWithWhite:0 alpha:0.5]).CGColor;
            }
            objc_setAssociatedObject(cb,"accentIdx",@(realIdx),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [cb addTarget:self action:@selector(accentTap:)
                forControlEvents:UIControlEventTouchUpInside];
            [accentRow addSubview:cb];
        }
        [self.scroll addSubview:accentRow]; y+=74;

        // ── Info ──────────────────────────────────────────────────────────────
        y=[self addSection:DAAEStr(@"— INFO —",@"— INFO —",@"— INFO —") y:y];
        NSArray *infoT=@[@"Product",@"Creator",@"Telegram",DAAEStr(@"Key",@"Clave",@"Khóa")];
        NSArray *infoV=@[@"DAAE IOS",@"@didierxit7",@"t.me/didierxit7",@"TEST"];
        for (int k=0;k<4;k++) {
            UIView *row=InfoRow(infoT[(NSUInteger)k],infoV[(NSUInteger)k],w,(k==3));
            row.frame=CGRectMake(0,y,w,52);
            [self.scroll addSubview:row]; y+=60;
        }
    }

    UILabel *credit=[[UILabel alloc] initWithFrame:CGRectMake(0,y+8,[self contentWidth],16)];
    credit.text=@"DAAE IOS";
    credit.textColor=[UIColor colorWithWhite:DAAEDark()?1:0 alpha:0.13];
    credit.font=[UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    credit.textAlignment=NSTextAlignmentCenter;
    [self.scroll addSubview:credit]; y+=30;

    self.scroll.contentSize=CGSizeMake([self contentWidth],y+6);
    self.scroll.contentOffset=CGPointMake(0,MAX(0,
        MIN(offset,y+6-self.scroll.bounds.size.height)));
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCIONES
// ─────────────────────────────────────────────────────────────────────────────
- (void)closeMenu { if (self.onCloseBlock) self.onCloseBlock(); }

- (void)darkModeToggleTap {
    BOOL newDark = !DAAEDark();
    DAAEAdjustAccentForMode(newDark);
    DAAESetDark(newDark);
    [self refreshThemeInPlace];
}

- (void)colorTargetChanged:(UISegmentedControl *)seg {
    self.colorTarget=seg.selectedSegmentIndex; [self buildPage];
}

// Live update del swatch de color — UISlider lleva todo via objc_setAssociatedObject
- (void)_colorSliderChanged:(UISlider *)sl {
    NSString *key     = objc_getAssociatedObject(sl, "espKey");
    UILabel  *valLbl  = objc_getAssociatedObject(sl, "valLbl");
    UILabel  *swatch  = objc_getAssociatedObject(sl, "swatchRef");
    NSString *pfx     = objc_getAssociatedObject(sl, "swatchPfx");

    // Fallback: swatch by tag if weak ref was zeroed
    if (!swatch) swatch = (UILabel *)[self.scroll viewWithTag:990];
    if (!pfx)    pfx    = (self.colorTarget == 0) ? @"BoxColor" : @"FovColor";

    // Persist the new value
    if (key) ESPPrefsSetFloat(key, sl.value);
    if (valLbl) valLbl.text = [NSString stringWithFormat:@"%.0f", (double)sl.value * 100.0];

    if (!swatch || !pfx) return;

    // Read all 3 channels and redraw swatch
    float r = ESPPrefsFloat([pfx stringByAppendingString:@"R"], 0.26f);
    float g = ESPPrefsFloat([pfx stringByAppendingString:@"G"], 0.78f);
    float b = ESPPrefsFloat([pfx stringByAppendingString:@"B"], 0.90f);

    [UIView performWithoutAnimation:^{
        swatch.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1];
        swatch.text = [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)round(r*255), (int)round(g*255), (int)round(b*255)];
        CGFloat lum = r*0.299f + g*0.587f + b*0.114f;
        swatch.textColor = lum > 0.6f ? UIColor.blackColor : UIColor.whiteColor;
    }];

    ESPSyncFromPrefs();
}

- (void)_panelScaleChanged:(UISlider *)sl {
    UILabel *val = objc_getAssociatedObject(sl, "valLbl");
    DAAESetPanelScale(sl.value);
    val.text = [NSString stringWithFormat:@"%d%%", (int)round(sl.value * 100)];
    // Force full recalc from center by zeroing the frame
    self.panel.frame  = CGRectZero;
    self.blurBG.frame = CGRectZero;
    [self viewDidLayoutSubviews];
}
- (void)_panelScaleReset:(UIButton *)btn {
    DAAESetPanelScale(1.0);
    // Update the slider value visually
    UISlider *sl = objc_getAssociatedObject(btn, "sizeSlider");
    UILabel  *val = objc_getAssociatedObject(btn, "sizeLabel");
    if (sl) sl.value = 1.0f;
    if (val) val.text = @"100%";
    self.panel.frame  = CGRectZero;
    self.blurBG.frame = CGRectZero;
    [self viewDidLayoutSubviews];
}

- (void)_panelAlphaChanged:(UISlider *)sl {
    UILabel *val = objc_getAssociatedObject(sl, "alphaValLbl");
    DAAESetPanelAlpha(sl.value);
    if (val) val.text = [NSString stringWithFormat:@"%.2f", sl.value];
    self.panel.alpha  = sl.value;
    self.blurBG.alpha = sl.value;
}

- (void)langTap:(UIButton *)sender {
    NSNumber *n=objc_getAssociatedObject(sender,"langIdx");
    if (!n) return;
    DAAESetLang(n.integerValue);
    [self rebuildAnimated];
    [self buildSidebar];
}

- (void)accentTap:(UIButton *)sender {
    NSNumber *n=objc_getAssociatedObject(sender,"accentIdx");
    if (!n) return;
    DAAESetAccentIdx(n.integerValue);
    [self refreshThemeInPlace];
}

- (void)applyMinimalESP {
    for (NSString *k in @[@"ESPEnabled",@"Box",@"Health",@"Name",@"Dis",@"CleanESP"])
        ESPPrefsSetBool(k,YES);
    for (NSString *k in @[@"Line",@"Skeleton",@"HeadRedDot",@"Box3D",@"BalancedRender"])
        ESPPrefsSetBool(k,NO);
    for (NSString *pfx in @[@"BoxColor",@"LineColor",@"FovColor"]) {
        ESPPrefsSetFloat([pfx stringByAppendingString:@"R"],0.26);
        ESPPrefsSetFloat([pfx stringByAppendingString:@"G"],0.78);
        ESPPrefsSetFloat([pfx stringByAppendingString:@"B"],0.90);
    }
    ESPSyncFromPrefs(); [self buildPage];
}

- (void)toggleChanged:(NSString *)key value:(BOOL)on {
    if ([@[@"GhostModeFloating",@"FakeLagFloating",@"AutoFireFloating",@"FlyFloating"]
            containsObject:key]) {
        NSString *feat=[key stringByReplacingOccurrencesOfString:@"Floating" withString:@""];
        ESPPrefsSetBool(feat,on);
        if (on) ESPPrefsSetBool(@"HideFeatureButtons",NO);
    }
    if ([key isEqualToString:@"CleanESP"]&&on) ESPPrefsSetBool(@"Box3D",NO);
    if ([key isEqualToString:@"RunSpeed"]&&!AppSettingsObjectForKey(@"RunSpeedFloating"))
        ESPPrefsSetBool(@"RunSpeedFloating",YES);
    if ([key isEqualToString:@"AnLive"]&&![UIView applyCaptureProtectionToRegisteredViews:on]) {
        ESPPrefsSetBool(@"AnLive",NO);
        [UIView applyCaptureProtectionToRegisteredViews:NO];
    }
    if ([@[@"SilentAutoConfig",@"AutoFireFloating",@"FlyFloating",@"VisualSpin"]
            containsObject:key]) [self rebuildAnimated];
}

- (void)updateSpinStatus {
    const auto state=PlayerModesRead();
    NSString *text=@"Spin: waiting for game tick";
    if (state.detail&&state.detail[0]) text=[NSString stringWithUTF8String:state.detail];
    else if (state.spinStatus==1) text=@"Spin: waiting for character";
    else if (state.spinStatus==2) text=@"Spin: no compatible model";
    else if (state.spinStatus==3) text=@"Spin: waiting for angle";
    else if (state.spinStatus==4)
        text=[NSString stringWithFormat:@"Spin: applied · %llu",
              (unsigned long long)state.spinApplies];
    self.spinStatusLabel.text=text;
}

- (void)dealloc { [self.spinStatusTimer invalidate]; }

// ─────────────────────────────────────────────────────────────────────────────
// DRAG
// ─────────────────────────────────────────────────────────────────────────────
- (void)dragPanel:(UIPanGestureRecognizer *)pan {
    if (pan.state==UIGestureRecognizerStateBegan) self.panelOrigin=self.panel.frame.origin;
    CGPoint d=[pan translationInView:self.view];
    CGRect f=self.panel.frame;
    f.origin=CGPointMake(self.panelOrigin.x+d.x,self.panelOrigin.y+d.y);
    self.panel.frame=f; self.blurBG.frame=f;
    [self viewDidLayoutSubviews];
}
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)t {
    for (UIView *v=t.view;v&&v!=g.view;v=v.superview)
        if ([v isKindOfClass:UIControl.class]) return NO;
    return YES;
}

// ─────────────────────────────────────────────────────────────────────────────
// _0xF010 — touch routing
// ─────────────────────────────────────────────────────────────────────────────
- (BOOL)_0xF010:(CGPoint)point phase:(NSInteger)phase pointerId:(NSInteger)pointerId {
    if (phase==UITouchPhaseBegan) {
        if (!CGRectContainsPoint(self.panel.frame,point)) return NO;
        if (self.pointer!=-1) return YES;
        self.pointer=pointerId; self.began=point;
        self.panelOrigin=self.panel.frame.origin;
        self.scrollOrigin=self.scroll.contentOffset.y;
        self.scrolling=NO; self.activeControl=nil;
        CGPoint local=[self.panel convertPoint:point fromView:self.view];
        self.dragging=(local.x<72)||(local.y<56&&local.x<self.panel.bounds.size.width-44);
        if (self.dragging) return YES;
        CGPoint sc=[self.scroll convertPoint:point fromView:self.view];
        for (UIView *c in self.controls) {
            if (![c isKindOfClass:UIControl.class]) continue;
            UIControl *ctrl=(UIControl *)c;
            if (!ctrl.enabled) continue;
            if (CGRectContainsPoint([ctrl convertRect:ctrl.bounds toView:self.scroll],sc))
            { self.activeControl=ctrl; break; }
        }
        return YES;
    }
    if (self.pointer!=pointerId) return NO;
    CGFloat dx=point.x-self.began.x, dy=point.y-self.began.y;
    if (phase==UITouchPhaseMoved) {
        if (self.dragging) {
            CGRect f=self.panel.frame;
            f.origin=CGPointMake(self.panelOrigin.x+dx,self.panelOrigin.y+dy);
            self.panel.frame=f; self.blurBG.frame=f;
            [self viewDidLayoutSubviews];
        } else if (fabs(dy)>6||self.scrolling) {
            self.scrolling=YES;
            CGFloat maxY=MAX(0,self.scroll.contentSize.height-self.scroll.bounds.size.height);
            self.scroll.contentOffset=CGPointMake(0,MAX(0,MIN(maxY,self.scrollOrigin-dy)));
        }
        return YES;
    }
    if (phase==UITouchPhaseEnded||phase==UITouchPhaseCancelled) {
        BOOL activate=phase==UITouchPhaseEnded&&!self.dragging&&!self.scrolling
                      &&fabs(dx)<24&&fabs(dy)<24;
        UIControl *ctrl=self.activeControl;
        self.pointer=-1; self.activeControl=nil;
        if (activate&&ctrl&&ctrl.enabled)
            [ctrl sendActionsForControlEvents:UIControlEventTouchUpInside];
        return YES;
    }
    return YES;
}
@end

// BUILD OK

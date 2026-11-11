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
    return [[UIImage systemImageNamed:name withConfiguration:cfg]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

// ─────────────────────────────────────────────────────────────────────────────
// MEDIDAS (igual a las imágenes de referencia)
// ─────────────────────────────────────────────────────────────────────────────
static const CGFloat kSidebarW = 64.0;
static const CGFloat kHeaderH  = 62.0;
static const CGFloat kRowH     = 56.0;
static const CGFloat kRowStep  = 62.0;   // fila + gap compacto
static const CGFloat kSliderH  = 72.0;
static const CGFloat kSliderStep = 78.0;

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
// TEMA
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

// ESQUINAS — NO = redondeadas (default), YES = cuadradas
static BOOL DAAESquareCorners(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.squareCorners"]) return NO;
    return [ud boolForKey:@"DAAE.squareCorners"];
}
static void DAAESetSquareCorners(BOOL sq) {
    [[NSUserDefaults standardUserDefaults] setBool:sq forKey:@"DAAE.squareCorners"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
static CGFloat RadiusPanel(void) { return DAAESquareCorners() ? 6  : 26; }
static CGFloat RadiusRow(void)   { return DAAESquareCorners() ? 5  : 20; }
static CGFloat RadiusChip(void)  { return DAAESquareCorners() ? 5  : 16; }
static CGFloat RadiusPill(void)  { return DAAESquareCorners() ? 8  : 22; }

// TAMAÑO DEL PANEL — 0.75–1.30
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

// TRANSPARENCIA DEL PANEL — 0.40–1.00
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

// COLOR DE ACENTO
// 0=Celeste 1=Naranja 2=Rojo 3=Amarillo 4=Verde 5=Negro(claro) 6=Blanco(oscuro)
static NSInteger DAAEAccentIdx(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.accentIdx"]) return 0;
    NSInteger v = [ud integerForKey:@"DAAE.accentIdx"];
    return (v >= 0 && v <= 6) ? v : 0;
}
static void DAAESetAccentIdx(NSInteger idx) {
    [[NSUserDefaults standardUserDefaults] setInteger:idx forKey:@"DAAE.accentIdx"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
static void DAAEAdjustAccentForMode(BOOL dark) {
    NSInteger cur = DAAEAccentIdx();
    if (dark && cur == 5) DAAESetAccentIdx(6);
    else if (!dark && cur == 6) DAAESetAccentIdx(5);
}
static UIColor *DAAEAccentColor(void) {
    switch (DAAEAccentIdx()) {
        case 1:  return [UIColor colorWithRed:1.00 green:0.60 blue:0.10 alpha:1];
        case 2:  return [UIColor colorWithRed:0.97 green:0.20 blue:0.22 alpha:1];
        case 3:  return [UIColor colorWithRed:0.95 green:0.82 blue:0.14 alpha:1];
        case 4:  return [UIColor colorWithRed:0.24 green:0.82 blue:0.50 alpha:1];
        case 5:  return [UIColor colorWithWhite:0.05 alpha:1];
        case 6:  return [UIColor colorWithWhite:0.96 alpha:1];
        default: return [UIColor colorWithRed:0.26 green:0.78 blue:0.90 alpha:1];
    }
}
static UIColor *DAAEAccentFG(void) {
    NSInteger idx = DAAEAccentIdx();
    if (idx == 3 || idx == 4 || idx == 6) return [UIColor colorWithWhite:0.1 alpha:1];
    return UIColor.whiteColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// PALETA ADAPTATIVA — GLASS
// ─────────────────────────────────────────────────────────────────────────────
static UIColor *PanelBG(void) {
    return DAAEDark() ? [UIColor colorWithWhite:0.10 alpha:0.40]
                      : [UIColor colorWithWhite:0.97 alpha:0.55];
}
static UIColor *RowBG(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.10]
                      : [UIColor colorWithWhite:0 alpha:0.06];
}
static UIColor *RowBGOn(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.15]
                      : [UIColor colorWithWhite:0 alpha:0.10];
}
static UIColor *SectionClr(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.45]
                      : [UIColor colorWithWhite:0 alpha:0.45];
}
static UIColor *LblMain(void) {
    return DAAEDark() ? [UIColor colorWithWhite:0.97 alpha:1]
                      : [UIColor colorWithWhite:0.08 alpha:1];
}
static UIColor *LblDim(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.50]
                      : [UIColor colorWithWhite:0 alpha:0.45];
}
static UIColor *CheckOff(void) {
    return DAAEDark() ? [UIColor colorWithWhite:0 alpha:0.30]
                      : [UIColor colorWithWhite:0 alpha:0.10];
}
static UIColor *SidebarBG(void) {
    return DAAEDark() ? [UIColor colorWithWhite:0 alpha:0.04]
                      : [UIColor colorWithWhite:0 alpha:0.02];
}
static UIColor *HeaderBG(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.10]
                      : [UIColor colorWithWhite:0 alpha:0.07];
}
static UIColor *CircleBG(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.10]
                      : [UIColor colorWithWhite:0 alpha:0.07];
}
static UIColor *DivClr(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.10]
                      : [UIColor colorWithWhite:0 alpha:0.10];
}
static UIColor *TrackOff(void) {
    return DAAEDark() ? [UIColor colorWithWhite:1 alpha:0.16]
                      : [UIColor colorWithWhite:0 alpha:0.12];
}
static UIBlurEffectStyle DAAEBlurStyle(void) {
    return DAAEDark() ? UIBlurEffectStyleSystemUltraThinMaterialDark
                      : UIBlurEffectStyleSystemUltraThinMaterialLight;
}
static void StyleSlider(UISlider *s) {
    s.minimumTrackTintColor = DAAEAccentColor();
    s.maximumTrackTintColor = TrackOff();
    s.thumbTintColor = UIColor.whiteColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// AIM TYPE — -1 = sin aim
// ─────────────────────────────────────────────────────────────────────────────
static float     AimRaw(void)    { return ESPPrefsFloat(@"AimType", -1); }
static BOOL      AimActive(void) { return AimRaw() >= 0; }

// ─────────────────────────────────────────────────────────────────────────────
// CHECK CIRCLE
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
        self.userInteractionEnabled = NO;
        _iv = [[UIImageView alloc] initWithImage:
            SFSym(@"checkmark", 13, UIImageSymbolWeightHeavy)];
        _iv.contentMode = UIViewContentModeScaleAspectFit;
        _iv.frame = CGRectInset(self.bounds, 8, 8);
        [self addSubview:_iv];
        [self setOn:NO animated:NO];
    }
    return self;
}
- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }
- (void)setOn:(BOOL)on animated:(BOOL)anim {
    _on = on;
    UIColor *accent = DAAEAccentColor();
    UIColor *fg = DAAEAccentFG();
    void (^upd)(void) = ^{
        if (on) {
            self.backgroundColor = accent;
            self->_iv.tintColor  = fg;
            self->_iv.hidden     = NO;
        } else {
            self.backgroundColor = CheckOff();
            self->_iv.hidden     = YES;
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
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, kRowH)])) {
        self.toggleOn = on;
        [self _applyStyle:on];
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, w - 78, kRowH)];
        lbl.text = txt;
        lbl.textColor = LblMain();
        lbl.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        lbl.adjustsFontSizeToFitWidth = YES;
        lbl.minimumScaleFactor = 0.7;
        lbl.tag  = 888;
        lbl.userInteractionEnabled = NO;
        [self addSubview:lbl];
        self.check = [[DAAECheck alloc] initWithFrame:CGRectMake(w - 52, (kRowH - 32) / 2.0, 32, 32)];
        [self.check setOn:on animated:NO];
        [self addSubview:self.check];
        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)_applyStyle:(BOOL)on {
    self.backgroundColor    = on ? RowBGOn() : RowBG();
    self.layer.cornerRadius = RadiusRow();
    self.layer.borderWidth  = 0;
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
// PILL PICKER
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
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, 54)])) {
        _selectedIndex = sel;
        self.backgroundColor    = RowBG();
        self.layer.cornerRadius = RadiusRow();
        self.clipsToBounds      = YES;
        CGFloat pad = 8, gap = 6;
        CGFloat btnW = (w - pad*2 - gap*(n-1)) / (CGFloat)n;
        NSMutableArray<UIButton *> *pills = [NSMutableArray array];
        for (NSInteger i = 0; i < n; i++) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.frame = CGRectMake(pad + i*(btnW+gap), 8, btnW, 38);
            b.layer.cornerRadius = RadiusChip();
            b.clipsToBounds = YES;
            b.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
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
// SLIDER ROW
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAESlider : UIView
- (void)refreshTheme;
@end
@implementation DAAESlider { UILabel *_lbl; UILabel *_val; UISlider *_sl; }
- (instancetype)initWithLabel:(NSString *)txt key:(NSString *)key
                          min:(float)mn max:(float)mx fallback:(float)fb width:(CGFloat)w {
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, kSliderH)])) {
        self.backgroundColor    = RowBG();
        self.layer.cornerRadius = RadiusRow();
        _lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 9, w-96, 22)];
        _lbl.text = txt; _lbl.textColor = LblMain();
        _lbl.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        [self addSubview:_lbl];
        _val = [[UILabel alloc] initWithFrame:CGRectMake(w-76, 9, 58, 22)];
        _val.textAlignment = NSTextAlignmentRight;
        _val.textColor = DAAEAccentColor();
        _val.font = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
        float cur = ESPPrefsFloat(key, fb);
        _val.text = (mx <= 3.0f) ? [NSString stringWithFormat:@"%.2f", cur]
                                 : [NSString stringWithFormat:@"%.0f", cur];
        [self addSubview:_val];
        _sl = [[UISlider alloc] initWithFrame:CGRectMake(16, 40, w-32, 24)];
        _sl.minimumValue = mn; _sl.maximumValue = mx; _sl.value = cur;
        StyleSlider(_sl);
        objc_setAssociatedObject(_sl,"valLbl",_val,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(_sl,"espKey",key, OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(_sl,"fmtDec",@(mx <= 3.0f),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [_sl addTarget:self action:@selector(_slid:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_sl];
    }
    return self;
}
- (void)_slid:(UISlider *)sl {
    UILabel  *val = objc_getAssociatedObject(sl,"valLbl");
    NSString *key = objc_getAssociatedObject(sl,"espKey");
    BOOL dec = [objc_getAssociatedObject(sl,"fmtDec") boolValue];
    val.text = dec ? [NSString stringWithFormat:@"%.2f", sl.value]
                   : [NSString stringWithFormat:@"%.0f", sl.value];
    ESPPrefsSetFloat(key, sl.value);
    ESPSyncFromPrefs();
}
- (void)refreshTheme {
    self.backgroundColor    = RowBG();
    self.layer.cornerRadius = RadiusRow();
    _lbl.textColor = LblMain(); _val.textColor = DAAEAccentColor();
    StyleSlider(_sl);
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW helper
// ─────────────────────────────────────────────────────────────────────────────
static UIView *InfoRow(NSString *title, NSString *value, CGFloat w, BOOL dim) {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0,0,w,kRowH)];
    row.backgroundColor = RowBG();
    row.layer.cornerRadius = RadiusRow();
    UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(20,0,w*0.42,kRowH)];
    tl.text = title; tl.textColor = LblMain();
    tl.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [row addSubview:tl];
    UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(w*0.42,0,w*0.58-18,kRowH)];
    vl.text = value;
    vl.textColor = dim ? LblDim() : DAAEAccentColor();
    vl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    vl.textAlignment = NSTextAlignmentRight;
    vl.adjustsFontSizeToFitWidth = YES;
    [row addSubview:vl];
    return row;
}

// ─────────────────────────────────────────────────────────────────────────────
// WARNING LABEL — texto normal con palabras clave resaltadas en acento
// ─────────────────────────────────────────────────────────────────────────────
static CGFloat AddWarningLabel(NSString *text, NSArray<NSString *> *highlights,
                               UIScrollView *scroll, CGFloat w, CGFloat y) {
    UIFont *font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc]
        initWithString:text
            attributes:@{NSFontAttributeName:font,
                         NSForegroundColorAttributeName:LblMain()}];
    for (NSString *h in highlights) {
        NSRange r = [text rangeOfString:h];
        if (r.location != NSNotFound)
            [as addAttribute:NSForegroundColorAttributeName value:DAAEAccentColor() range:r];
    }
    UILabel *warn = [[UILabel alloc] initWithFrame:CGRectMake(4, y, w - 8, 0)];
    warn.attributedText = as;
    warn.numberOfLines = 0;
    warn.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize sz = [warn sizeThatFits:CGSizeMake(w - 8, 999)];
    warn.frame = CGRectMake(4, y, w - 8, sz.height);
    [scroll addSubview:warn];
    return y + sz.height + 12;
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
@property (nonatomic, strong) UILabel   *colorSwatchLabel;
@end

@implementation _0xDEADBEEE

- (void)applyDefaults {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;

    // Tema (guard propio): fuerza modo oscuro + acento rojo una sola vez,
    // sin tocar las opciones que el usuario ya tenga guardadas.
    if (![ud boolForKey:@"_DAAEThemeV2"]) {
        [ud setBool:YES forKey:@"DAAE.darkMode"];
        [ud setInteger:2 forKey:@"DAAE.accentIdx"];
        [ud setBool:YES forKey:@"_DAAEThemeV2"];
        [ud synchronize];
    }

    if ([ud objectForKey:@"_MizzeDefaultsApplied"]) return;
    for (NSString *k in @[@"ESPEnabled",@"Box",@"Box3D",@"CleanESP",@"Name",@"Health",
                           @"Line",@"Skeleton",@"HeadRedDot",@"Dis",@"AimLag",
                           @"AimTargetLine",@"SilentAim",@"AutoFire",@"AutoFireFloating",
                           @"FastFire",@"ShootNoReload",@"GhostModeFloating",@"FakeLagFloating",
                           @"FlyFloating",@"RunSpeedFloating",@"RunSpeed",@"VisualSpin",
                           @"AnLive",@"BalancedRender",@"HideFeatureButtons"])
        ESPPrefsSetBool(k, NO);
    ESPPrefsSetBool(@"ShowFov", YES);
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

// Aplica fondo + transparencia (solo al cristal, el contenido queda nítido)
- (void)applyPanelAlpha {
    CGFloat a = DAAEPanelAlpha();
    UIColor *bg = PanelBG();
    CGFloat baseA = CGColorGetAlpha(bg.CGColor);
    self.panel.backgroundColor = [bg colorWithAlphaComponent:baseA * a];
    self.blurBG.alpha = a;
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
    [self.view addSubview:self.blurBG];

    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.layer.cornerRadius = RadiusPanel();
    self.panel.layer.borderWidth  = 0.6;
    self.panel.layer.borderColor  = (DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.16]
        : [UIColor colorWithWhite:0 alpha:0.10]).CGColor;
    self.panel.clipsToBounds = YES;
    [self.view addSubview:self.panel];
    [self applyPanelAlpha];

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
// LAYOUT — panel grande (~90% del alto en landscape)
// ─────────────────────────────────────────────────────────────────────────────
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sw = self.view.bounds.size.width;
    CGFloat sh = self.view.bounds.size.height;
    if (sw <= 0) { sw = 320; }
    if (sh <= 0) { sh = 480; }

    CGFloat scale = DAAEPanelScale();
    CGFloat basePW = MIN(sw - 80.0, 520.0);
    basePW = MAX(basePW, 300.0);
    CGFloat basePH = MIN(sh - 24.0, 600.0);
    basePH = MAX(basePH, 340.0);

    CGFloat pw = MAX(basePW * scale, 260.0);
    CGFloat ph = MAX(basePH * scale, 280.0);
    pw = MIN(pw, sw - 8.0);
    ph = MIN(ph, sh - 8.0);

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

    self.sidebar.frame = CGRectMake(0,0,kSidebarW,ph);
    UIView *div = [self.panel viewWithTag:99];
    div.frame = CGRectMake(kSidebarW,14,0.5,ph-28);
    CGFloat caW = pw - kSidebarW - 0.5;
    self.contentArea.frame = CGRectMake(kSidebarW+0.5, 0, caW, ph);
    const CGFloat padH = 10.0, padB = 10.0;
    self.scroll.frame = CGRectMake(padH, kHeaderH, caW-padH*2, ph-kHeaderH-padB);

    [self layoutSidebarButtons];
    if (fabs(self.builtWidth - self.scroll.bounds.size.width) > 0.5) [self buildPage];
    [self refreshSidebarSelection];
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR — solo íconos en círculos
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
        btn.layer.cornerRadius = DAAESquareCorners() ? 12 : 22;
        [btn setImage:SFSym(icons[(NSUInteger)i], 19, UIImageSymbolWeightSemibold)
             forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(sidebarTap:)
            forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
    }
    [self layoutSidebarButtons];
    [self refreshSidebarSelection];
}
- (void)layoutSidebarButtons {
    const CGFloat d = 44, gap = 10;
    CGFloat total = 5*d + 4*gap;
    CGFloat sbH = self.sidebar.bounds.size.height;
    if (sbH < 1) sbH = 400;
    CGFloat startY = MAX(8, (sbH-total)/2.0);
    for (NSInteger i=0;i<5;i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300+i];
        if (!btn) continue;
        btn.frame = CGRectMake((kSidebarW-d)/2.0, startY+i*(d+gap), d, d);
    }
}
- (void)refreshSidebarSelection {
    UIColor *accent = DAAEAccentColor();
    for (NSInteger i=0;i<5;i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300+i];
        if (!btn) continue;
        BOOL sel = (i==self.page);
        btn.backgroundColor = sel ? [accent colorWithAlphaComponent:0.16] : CircleBG();
        btn.tintColor = sel ? accent : LblDim();
        btn.layer.borderWidth = sel ? 1.6 : 0;
        btn.layer.borderColor = accent.CGColor;
        btn.layer.cornerRadius = DAAESquareCorners() ? 12 : 22;
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
// HEADER — píldora con título grande + luna y X en círculos
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildHeader {
    for (UIView *v in self.contentArea.subviews)
        if (v.tag>=500&&v.tag<600) [v removeFromSuperview];
    CGFloat cw = self.contentArea.bounds.size.width;
    if (cw<10) cw=280;

    const CGFloat d = 44, top = 9, pad = 10, gap = 8;
    CGFloat pillW = cw - pad*2 - (d + gap)*2;

    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(pad,top,pillW,d)];
    hdr.tag = 500;
    hdr.backgroundColor    = HeaderBG();
    hdr.layer.cornerRadius = RadiusPill();
    [self.contentArea addSubview:hdr];

    UIImageView *iv = [[UIImageView alloc] initWithImage:
        SFSym(TabIcons()[(NSUInteger)self.page],17,UIImageSymbolWeightSemibold)];
    iv.tag=501; iv.tintColor=DAAEAccentColor(); iv.contentMode=UIViewContentModeScaleAspectFit;
    iv.frame=CGRectMake(pad+16, top+(d-20)/2.0, 20, 20);
    [self.contentArea addSubview:iv];

    UILabel *title = [[UILabel alloc] initWithFrame:
        CGRectMake(pad+44, top, pillW-54, d)];
    title.tag=502; title.text=TabName(self.page);
    title.textColor=DAAEAccentColor();
    title.font=[UIFont systemFontOfSize:19 weight:UIFontWeightHeavy];
    title.adjustsFontSizeToFitWidth = YES;
    title.minimumScaleFactor = 0.7;
    [self.contentArea addSubview:title];

    UIButton *darkBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    darkBtn.tag = 505;
    darkBtn.frame = CGRectMake(cw - pad - d*2 - gap, top, d, d);
    darkBtn.backgroundColor = HeaderBG();
    darkBtn.layer.cornerRadius = RadiusPill();
    NSString *darkIcon = DAAEDark() ? @"sun.max.fill" : @"moon.fill";
    [darkBtn setImage:SFSym(darkIcon, 17, UIImageSymbolWeightSemibold)
             forState:UIControlStateNormal];
    darkBtn.tintColor = DAAEAccentColor();
    [darkBtn addTarget:self action:@selector(darkModeToggleTap)
           forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:darkBtn];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.tag=503; close.frame=CGRectMake(cw - pad - d, top, d, d);
    close.backgroundColor = HeaderBG();
    close.layer.cornerRadius = RadiusPill();
    [close setImage:SFSym(@"xmark",16,UIImageSymbolWeightBold) forState:UIControlStateNormal];
    close.tintColor=DAAEAccentColor();
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
    row.frame = CGRectMake(0,y,w,kRowH);
    objc_setAssociatedObject(row,"espKey",key,OBJC_ASSOCIATION_COPY_NONATOMIC);
    __weak DAAERow *wrow=row; __weak _0xDEADBEEE *wself=self;
    row.onChanged = ^(BOOL on) {
        NSString *k = objc_getAssociatedObject(wrow,"espKey");
        ESPPrefsSetBool(k,on); ESPSyncFromPrefs();
        [wself toggleChanged:k value:on];
    };
    [self.controls addObject:row];
    [self.scroll addSubview:row];
    return y+kRowStep;
}

// Toggle con lógica propia (no ligado a una sola clave de prefs)
- (CGFloat)addCustomToggleEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                          on:(BOOL)on y:(CGFloat)y handler:(void (^)(BOOL))handler {
    CGFloat w = [self contentWidth];
    DAAERow *row = [[DAAERow alloc] initWithLabel:DAAEStr(en,es,vi) on:on width:w];
    row.frame = CGRectMake(0,y,w,kRowH);
    row.onChanged = handler;
    [self.controls addObject:row];
    [self.scroll addSubview:row];
    return y+kRowStep;
}

- (CGFloat)addSection:(NSString *)title y:(CGFloat)y {
    NSString *t = [[title stringByReplacingOccurrencesOfString:@"—" withString:@""]
        stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    t = t.capitalizedString;
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(8,y+6,[self contentWidth]-16,20)];
    l.text=t; l.textColor=SectionClr();
    l.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    [self.scroll addSubview:l];
    return y+32;
}

- (CGFloat)addSliderEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key min:(float)mn max:(float)mx fallback:(float)fb y:(CGFloat)y {
    CGFloat w=[self contentWidth];
    DAAESlider *sl=[[DAAESlider alloc] initWithLabel:DAAEStr(en,es,vi)
                                                 key:key min:mn max:mx fallback:fb width:w];
    sl.frame=CGRectMake(0,y,w,kSliderH);
    [self.controls addObject:(UIControl *)sl];
    [self.scroll addSubview:sl];
    return y+kSliderStep;
}

- (void)rebuildAnimated {
    if (UIAccessibilityIsReduceMotionEnabled()) { [self buildPage]; return; }
    [UIView transitionWithView:self.scroll duration:0.15
        options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionAllowUserInteraction
        animations:^{ [self buildPage]; } completion:nil];
}

- (void)refreshThemeInPlace {
    self.panel.layer.cornerRadius = RadiusPanel();
    self.panel.layer.borderColor = (DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.16]
        : [UIColor colorWithWhite:0 alpha:0.10]).CGColor;
    self.blurBG.effect = [UIBlurEffect effectWithStyle:DAAEBlurStyle()];
    self.blurBG.layer.cornerRadius = RadiusPanel();
    [self applyPanelAlpha];
    self.sidebar.backgroundColor = SidebarBG();
    UIView *div = [self.panel viewWithTag:99];
    div.backgroundColor = DivClr();
    [self buildSidebar];
    [self buildPage];
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
    CGFloat y = 4;
    CGFloat w = [self contentWidth];

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
        y=[self addSection:@"— FOV —" y:y];
        y=[self addToggleEN:@"Show FOV"     ES:@"Mostrar FOV"       VI:@"Hiện Vòng FOV"
                        key:@"ShowFov" fallback:YES y:y];
        y=[self addSliderEN:@"FOV Size"     ES:@"Tamaño FOV"        VI:@"Bán Kính FOV"
                        key:@"FovSize" min:5 max:48 fallback:40 y:y];

    // ── TAB 1: AIM ────────────────────────────────────────────────────────────
    } else if (self.page == 1) {
        NSString *aimWarn = DAAEStr(
            @"Use Aimbot with restraint. Avoid excessive headshots to reduce unexpected detections.",
            @"Usa el Aimbot con moderación. Evita muchos headshots para reducir detecciones inesperadas.",
            @"Sử dụng Aimbot có chừng mực. Tránh headshot quá nhiều để giảm nguy cơ bị phát hiện.");
        NSArray *aimHL = @[
            DAAEStr(@"restraint", @"moderación", @"có chừng mực"),
            DAAEStr(@"headshots", @"headshots",  @"headshot"),
            DAAEStr(@"unexpected detections", @"detecciones inesperadas", @"bị phát hiện")];
        y = AddWarningLabel(aimWarn, aimHL, self.scroll, w, y);

        __weak _0xDEADBEEE *wa = self;
        y=[self addCustomToggleEN:@"Aimbot" ES:@"Aimbot" VI:@"Aimbot"
                               on:AimActive() y:y handler:^(BOOL on){
            if (on) {
                ESPPrefsSetFloat(@"AimType", 0);
                ESPPrefsSetFloat(@"AimActivation", (float)static_cast<int>(
                    AimModePolicy::AfterTypeSelection(AimModePolicy::ReadType(0.0f))));
                ESPPrefsSetBool(@"SilentAim", NO);
            } else {
                ESPPrefsSetFloat(@"AimType", -1);
            }
            ESPClearAimLock(); ESPSyncFromPrefs();
            [wa rebuildAnimated];
        }];
        y=[self addToggleEN:@"Aim Line"      ES:@"Línea objetivo"   VI:@"Aim Line"
                        key:@"AimTargetLine" fallback:NO y:y];
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
        DAAEPillPicker *actPicker=[[DAAEPillPicker alloc]
            initWithOptions:actOpts selected:actSel width:w];
        actPicker.frame=CGRectMake(0,y,w,54);
        actPicker.onSelected=^(NSInteger idx){
            ESPPrefsSetFloat(@"AimActivation",(float)(idx+1));
            ESPClearAimLock(); ESPSyncFromPrefs();
        };
        [self.scroll addSubview:actPicker];
        y+=62;

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
        aimPicker.frame=CGRectMake(0,y,w,54);
        aimPicker.onSelected=^(NSInteger idx){
            ESPPrefsSetFloat(@"AimType",(float)idx);
            ESPPrefsSetFloat(@"AimActivation",static_cast<int>(
                AimModePolicy::AfterTypeSelection(AimModePolicy::ReadType((float)idx))));
            ESPPrefsSetBool(@"SilentAim",NO);
            ESPClearAimLock(); ESPSyncFromPrefs();
        };
        [self.scroll addSubview:aimPicker];
        y+=62;

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
        UISegmentedControl *seg=[[UISegmentedControl alloc] initWithItems:@[@"Box",@"FOV"]];
        seg.frame=CGRectMake(0,y,w,40);
        seg.selectedSegmentIndex=self.colorTarget;
        seg.selectedSegmentTintColor=DAAEAccentColor();
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:LblMain(),
            NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]}
                            forState:UIControlStateNormal];
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:DAAEAccentFG()}
                            forState:UIControlStateSelected];
        [seg addTarget:self action:@selector(colorTargetChanged:)
             forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:seg];
        [self.controls addObject:(UIControl *)seg];
        y+=50;

        NSString *pfx=(self.colorTarget==0)?@"BoxColor":@"FovColor";
        float r=ESPPrefsFloat([pfx stringByAppendingString:@"R"],0.26);
        float g=ESPPrefsFloat([pfx stringByAppendingString:@"G"],0.78);
        float b=ESPPrefsFloat([pfx stringByAppendingString:@"B"],0.90);

        UILabel *swatch=[[UILabel alloc] initWithFrame:CGRectMake(0,y,w,52)];
        swatch.text=[NSString stringWithFormat:@"#%02X%02X%02X",
            (int)round(r*255),(int)round(g*255),(int)round(b*255)];
        swatch.textAlignment=NSTextAlignmentCenter;
        swatch.backgroundColor=[UIColor colorWithRed:r green:g blue:b alpha:1];
        CGFloat lum=r*0.299+g*0.587+b*0.114;
        swatch.textColor=lum>0.6?UIColor.blackColor:UIColor.whiteColor;
        swatch.font=[UIFont systemFontOfSize:15 weight:UIFontWeightBold];
        swatch.layer.cornerRadius=RadiusRow();
        swatch.clipsToBounds=YES;
        swatch.tag=990;
        [self.scroll addSubview:swatch];
        self.colorSwatchLabel = swatch;
        y+=60;

        NSArray *rgbEN=@[@"Red",@"Green",@"Blue"];
        NSArray *rgbES=@[@"Rojo",@"Verde",@"Azul"];
        NSArray *rgbVI=@[@"Đỏ",@"Xanh lá",@"Xanh dương"];
        NSArray *suf=@[@"R",@"G",@"B"];
        float def[3]={0.26f,0.78f,0.90f};
        __weak UILabel *wSwatch = swatch;
        __weak _0xDEADBEEE *wself2 = self;
        for (int i=0;i<3;i++) {
            NSString *key=[pfx stringByAppendingString:suf[(NSUInteger)i]];
            UIView *rgbRow=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,kSliderH)];
            rgbRow.backgroundColor=RowBG(); rgbRow.layer.cornerRadius=RadiusRow();

            UILabel *lbl=[[UILabel alloc] initWithFrame:CGRectMake(20,9,w-96,22)];
            lbl.text=DAAEStr(rgbEN[(NSUInteger)i],rgbES[(NSUInteger)i],rgbVI[(NSUInteger)i]);
            lbl.textColor=LblMain();
            lbl.font=[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
            [rgbRow addSubview:lbl];

            UILabel *val=[[UILabel alloc] initWithFrame:CGRectMake(w-76,9,58,22)];
            val.textAlignment=NSTextAlignmentRight;
            val.textColor=DAAEAccentColor();
            val.font=[UIFont systemFontOfSize:15 weight:UIFontWeightBold];
            float cur2=ESPPrefsFloat(key,def[i]);
            val.text=[NSString stringWithFormat:@"%.0f",(double)cur2*100.0];
            [rgbRow addSubview:val];

            UISlider *rgbSl=[[UISlider alloc] initWithFrame:CGRectMake(16,40,w-32,24)];
            rgbSl.minimumValue=0; rgbSl.maximumValue=1; rgbSl.value=cur2;
            StyleSlider(rgbSl);
            objc_setAssociatedObject(rgbSl,"espKey",  key,   OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(rgbSl,"valLbl",  val,   OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(rgbSl,"swatchRef",wSwatch, OBJC_ASSOCIATION_ASSIGN);
            objc_setAssociatedObject(rgbSl,"swatchPfx",pfx,  OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(rgbSl,"menuRef",  wself2, OBJC_ASSOCIATION_ASSIGN);
            [rgbSl addTarget:self action:@selector(_colorSliderChanged:)
                forControlEvents:UIControlEventValueChanged];
            [rgbRow addSubview:rgbSl];
            [self.scroll addSubview:rgbRow];
            y+=kSliderStep;
        }

    // ── TAB 3: MISC ───────────────────────────────────────────────────────────
    } else if (self.page == 3) {
        NSString *miscWarn = DAAEStr(
            @"Some options in this section may not be entirely safe. Use with caution and at your own risk.",
            @"Algunas opciones en esta sección pueden no ser completamente seguras. Úsalas con precaución y bajo tu propio riesgo.",
            @"Một số tùy chọn trong mục này có thể không hoàn toàn an toàn. Hãy cẩn thận và tự chịu trách nhiệm.");
        NSArray *miscHL = @[
            DAAEStr(@"not be entirely safe", @"no ser completamente seguras", @"không hoàn toàn an toàn"),
            DAAEStr(@"caution", @"precaución", @"cẩn thận"),
            DAAEStr(@"at your own risk", @"bajo tu propio riesgo", @"tự chịu trách nhiệm")];
        y = AddWarningLabel(miscWarn, miscHL, self.scroll, w, y);
        y=[self addSection:@"— EXTRAS —" y:y];
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
                CGRectMake(4,y,w-8,34)];
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
        y=[self addToggleEN:@"Stream Mode" ES:@"Modo Streaming" VI:@"Chế Độ Stream"
                        key:@"AnLive" fallback:NO y:y];

        // Menu Transparency
        {
            UIView *tRow = [[UIView alloc] initWithFrame:CGRectMake(0,y,w,kSliderH)];
            tRow.backgroundColor    = RowBG();
            tRow.layer.cornerRadius = RadiusRow();

            UILabel *tLbl = [[UILabel alloc] initWithFrame:CGRectMake(20,9,w-96,22)];
            tLbl.text      = DAAEStr(@"Menu Transparency",@"Transparencia",@"Độ Trong Suốt");
            tLbl.textColor = LblMain();
            tLbl.font      = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
            [tRow addSubview:tLbl];

            UILabel *tVal = [[UILabel alloc] initWithFrame:CGRectMake(w-76,9,58,22)];
            tVal.textAlignment = NSTextAlignmentRight;
            tVal.textColor = DAAEAccentColor();
            tVal.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
            tVal.text = [NSString stringWithFormat:@"%.2f", DAAEPanelAlpha()];
            [tRow addSubview:tVal];

            UISlider *tSl = [[UISlider alloc] initWithFrame:CGRectMake(16,40,w-32,24)];
            tSl.minimumValue = 0.40f; tSl.maximumValue = 1.0f;
            tSl.value = (float)DAAEPanelAlpha();
            StyleSlider(tSl);
            objc_setAssociatedObject(tSl,"alphaValLbl",tVal,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [tSl addTarget:self action:@selector(_panelAlphaChanged:)
                forControlEvents:UIControlEventValueChanged];
            [tRow addSubview:tSl];
            [self.scroll addSubview:tRow];
            y += kSliderStep;
        }

        // Menu Scale
        {
            UIView *sizeRow=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,kSliderH)];
            sizeRow.backgroundColor=RowBG(); sizeRow.layer.cornerRadius=RadiusRow();

            UILabel *sizeLbl=[[UILabel alloc] initWithFrame:CGRectMake(20,9,w-130,22)];
            sizeLbl.text=DAAEStr(@"Menu Scale",@"Escala Menú",@"Tỷ Lệ Menu");
            sizeLbl.textColor=LblMain();
            sizeLbl.font=[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
            [sizeRow addSubview:sizeLbl];

            CGFloat curScale=DAAEPanelScale();
            UILabel *sizeVal=[[UILabel alloc] initWithFrame:CGRectMake(w-112,9,56,22)];
            sizeVal.textAlignment=NSTextAlignmentRight;
            sizeVal.textColor=DAAEAccentColor();
            sizeVal.font=[UIFont systemFontOfSize:15 weight:UIFontWeightBold];
            sizeVal.text=[NSString stringWithFormat:@"%d%%",(int)round(curScale*100)];
            [sizeRow addSubview:sizeVal];

            UIButton *resetBtn=[UIButton buttonWithType:UIButtonTypeSystem];
            resetBtn.frame=CGRectMake(w-50,4,40,34);
            [resetBtn setImage:SFSym(@"arrow.counterclockwise",14,UIImageSymbolWeightSemibold)
                      forState:UIControlStateNormal];
            resetBtn.tintColor=DAAEAccentColor();

            UISlider *sizeSl=[[UISlider alloc] initWithFrame:CGRectMake(16,40,w-32,24)];
            sizeSl.minimumValue=0.75f; sizeSl.maximumValue=1.30f;
            sizeSl.value=(float)curScale;
            StyleSlider(sizeSl);
            objc_setAssociatedObject(sizeSl,"valLbl",sizeVal,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [sizeSl addTarget:self action:@selector(_panelScaleChanged:)
                  forControlEvents:UIControlEventValueChanged];
            objc_setAssociatedObject(resetBtn,"sizeSlider",sizeSl,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(resetBtn,"sizeLabel",sizeVal,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [resetBtn addTarget:self action:@selector(_panelScaleReset:)
                    forControlEvents:UIControlEventTouchUpInside];
            [sizeRow addSubview:sizeSl];
            [sizeRow addSubview:resetBtn];
            [self.scroll addSubview:sizeRow]; y+=kSliderStep;
        }

        // Menu Shape
        __weak _0xDEADBEEE *wself=self;
        y=[self addSection:DAAEStr(@"— MENU SHAPE —",@"— FORMA MENÚ —",@"— HÌNH DẠNG —") y:y];
        NSArray *cornerOpts=@[
            DAAEStr(@"Rounded",@"Redondeadas",@"Tròn"),
            DAAEStr(@"Square", @"Cuadradas",  @"Vuông"),
        ];
        DAAEPillPicker *cornerPicker=[[DAAEPillPicker alloc]
            initWithOptions:cornerOpts selected:(DAAESquareCorners()?1:0) width:w];
        cornerPicker.frame=CGRectMake(0,y,w,54);
        cornerPicker.onSelected=^(NSInteger idx){
            DAAESetSquareCorners(idx==1);
            [wself refreshThemeInPlace];
        };
        [self.scroll addSubview:cornerPicker]; y+=62;

        // Idioma
        y=[self addSection:DAAEStr(@"— LANGUAGE —",@"— IDIOMA —",@"— NGÔN NGỮ —") y:y];
        UIView *langRow=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,54)];
        langRow.backgroundColor=RowBG(); langRow.layer.cornerRadius=RadiusRow();
        NSArray *codes=@[@"EN",@"ES",@"VI"];
        NSArray *names=@[@"English",@"Español",@"Tiếng Việt"];
        NSInteger curLang=DAAELang();
        CGFloat lbtnW=(w-16-12)/3.0;
        for (NSInteger k=0;k<3;k++) {
            UIButton *lb=[UIButton buttonWithType:UIButtonTypeCustom];
            lb.frame=CGRectMake(8+k*(lbtnW+6),8,lbtnW,38);
            BOOL sel=(k==curLang);
            lb.backgroundColor=sel?DAAEAccentColor():UIColor.clearColor;
            lb.layer.cornerRadius=RadiusChip();
            [lb setTitle:codes[(NSUInteger)k] forState:UIControlStateNormal];
            lb.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightBold];
            [lb setTitleColor:sel?DAAEAccentFG():LblDim() forState:UIControlStateNormal];
            objc_setAssociatedObject(lb,"langIdx",@(k),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [lb addTarget:self action:@selector(langTap:) forControlEvents:UIControlEventTouchUpInside];
            [langRow addSubview:lb];
        }
        [self.scroll addSubview:langRow]; y+=62;
        UILabel *lhint=[[UILabel alloc] initWithFrame:CGRectMake(0,y,w,18)];
        lhint.text=names[(NSUInteger)curLang]; lhint.textColor=SectionClr();
        lhint.font=[UIFont systemFontOfSize:11]; lhint.textAlignment=NSTextAlignmentCenter;
        [self.scroll addSubview:lhint]; y+=26;

        // Apariencia
        y=[self addSection:DAAEStr(@"— APPEARANCE —",@"— APARIENCIA —",@"— GIAO DIỆN —") y:y];
        NSArray *modeOpts=@[
            DAAEStr(@"Light Mode",@"Modo Claro",@"Sáng"),
            DAAEStr(@"Dark Mode", @"Modo Oscuro",@"Tối"),
        ];
        DAAEPillPicker *modePicker=[[DAAEPillPicker alloc]
            initWithOptions:modeOpts selected:(DAAEDark()?1:0) width:w];
        modePicker.frame=CGRectMake(0,y,w,54);
        modePicker.onSelected=^(NSInteger idx){
            BOOL newDark=(idx==1);
            DAAEAdjustAccentForMode(newDark);
            DAAESetDark(newDark);
            [wself refreshThemeInPlace];
        };
        [self.scroll addSubview:modePicker]; y+=62;

        // Color de acento
        y=[self addSection:DAAEStr(@"— ACCENT COLOR —",@"— COLOR ACENTO —",@"— MÀU NHẤN —") y:y];
        BOOL dark=DAAEDark();
        NSMutableArray *accentColors=[NSMutableArray arrayWithArray:@[
            [UIColor colorWithRed:0.26 green:0.78 blue:0.90 alpha:1],
            [UIColor colorWithRed:1.00 green:0.60 blue:0.10 alpha:1],
            [UIColor colorWithRed:0.97 green:0.20 blue:0.22 alpha:1],
            [UIColor colorWithRed:0.95 green:0.82 blue:0.14 alpha:1],
            [UIColor colorWithRed:0.24 green:0.82 blue:0.50 alpha:1],
        ]];
        NSMutableArray *chipIdxMap=[@[@0,@1,@2,@3,@4] mutableCopy];
        if (dark) {
            [accentColors addObject:[UIColor colorWithWhite:0.96 alpha:1]];
            [chipIdxMap addObject:@6];
        } else {
            [accentColors addObject:[UIColor colorWithWhite:0.08 alpha:1]];
            [chipIdxMap addObject:@5];
        }
        NSInteger nChips=(NSInteger)accentColors.count;
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

        // Info
        y=[self addSection:@"— INFO —" y:y];
        NSArray *infoT=@[@"Product",@"Creator",@"Telegram",DAAEStr(@"Key",@"Clave",@"Khóa")];
        NSArray *infoV=@[@"DAAE IOS",@"@didierxit7",@"t.me/didierxit7",@"TEST"];
        for (int k=0;k<4;k++) {
            UIView *row=InfoRow(infoT[(NSUInteger)k],infoV[(NSUInteger)k],w,(k==3));
            row.frame=CGRectMake(0,y,w,kRowH);
            [self.scroll addSubview:row]; y+=kRowStep;
        }
    }

    UILabel *credit=[[UILabel alloc] initWithFrame:CGRectMake(0,y+8,w,16)];
    credit.text=@"DAAE IOS";
    credit.textColor=[UIColor colorWithWhite:DAAEDark()?1:0 alpha:0.18];
    credit.font=[UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    credit.textAlignment=NSTextAlignmentCenter;
    [self.scroll addSubview:credit]; y+=30;

    self.scroll.contentSize=CGSizeMake(w,y+6);
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

- (void)_colorSliderChanged:(UISlider *)sl {
    NSString *key     = objc_getAssociatedObject(sl, "espKey");
    UILabel  *valLbl  = objc_getAssociatedObject(sl, "valLbl");
    UILabel  *swatch  = objc_getAssociatedObject(sl, "swatchRef");
    NSString *pfx     = objc_getAssociatedObject(sl, "swatchPfx");

    if (!swatch) swatch = (UILabel *)[self.scroll viewWithTag:990];
    if (!pfx)    pfx    = (self.colorTarget == 0) ? @"BoxColor" : @"FovColor";

    if (key) ESPPrefsSetFloat(key, sl.value);
    if (valLbl) valLbl.text = [NSString stringWithFormat:@"%.0f", (double)sl.value * 100.0];

    if (!swatch || !pfx) return;

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
    self.panel.frame  = CGRectZero;
    self.blurBG.frame = CGRectZero;
    [self viewDidLayoutSubviews];
}
- (void)_panelScaleReset:(UIButton *)btn {
    DAAESetPanelScale(1.0);
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
    [self applyPanelAlpha];
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
        // Arrastrable: sidebar y la franja del header (sin tocar los 2 botones circulares)
        self.dragging=(local.x<kSidebarW+2)||
                      (local.y<kHeaderH&&local.x<self.panel.bounds.size.width-108);
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

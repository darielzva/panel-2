#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPStyle.h"
#import "../esp/Core/PlayerModes.h"
#import "UIView+SecureView.h"

// ─────────────────────────────────────────────────────────────────────────────
// FORWARD DECLARATIONS
// ─────────────────────────────────────────────────────────────────────────────
@interface _0xMO353DA : UIViewController
@property (nonatomic, copy) void (^onCloseBlock)(void);
- (BOOL)_0xF010:(CGPoint)point phase:(NSInteger)phase pointerId:(NSInteger)pointerId;
@end

// ─────────────────────────────────────────────────────────────────────────────
// SF SYMBOL HELPER
// ─────────────────────────────────────────────────────────────────────────────
static UIImage *SFSym(NSString *name, CGFloat pts, UIImageSymbolWeight w) {
    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:pts weight:w];
    return [[UIImage systemImageNamed:name withConfiguration:cfg]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT CONSTANTS  — compact, matches reference
// ─────────────────────────────────────────────────────────────────────────────
static const CGFloat kSidebarW   = 52.0;
static const CGFloat kHeaderH    = 48.0;
static const CGFloat kRowH       = 46.0;
static const CGFloat kRowStep    = 52.0;
static const CGFloat kSliderH    = 64.0;
static const CGFloat kSliderStep = 70.0;

// Default panel size — small and square-ish like references
static const CGFloat kDefaultPanelW = 310.0;
static const CGFloat kDefaultPanelH = 420.0;

// ─────────────────────────────────────────────────────────────────────────────
// LANGUAGE
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
// THEME PREFS
// ─────────────────────────────────────────────────────────────────────────────
static BOOL DAAEDark(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.darkMode"]) return YES;
    return [ud boolForKey:@"DAAE.darkMode"];
}
static void DAAESetDark(BOOL dark) {
    [[NSUserDefaults standardUserDefaults] setBool:dark forKey:@"DAAE.darkMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static BOOL DAAESquareCorners(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.squareCorners"]) return YES; // default: square (matches ref)
    return [ud boolForKey:@"DAAE.squareCorners"];
}
static void DAAESetSquareCorners(BOOL sq) {
    [[NSUserDefaults standardUserDefaults] setBool:sq forKey:@"DAAE.squareCorners"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static CGFloat RadiusPanel(void) { return DAAESquareCorners() ? 14.0 : 26.0; }
static CGFloat RadiusRow(void)   { return DAAESquareCorners() ?  8.0 : 18.0; }
static CGFloat RadiusChip(void)  { return DAAESquareCorners() ?  6.0 : 14.0; }
static CGFloat RadiusPill(void)  { return DAAESquareCorners() ? 10.0 : 22.0; }
static CGFloat RadiusSidebar(void) { return DAAESquareCorners() ? 10.0 : 20.0; }

// Panel scale — only changes size, not layout ratios
static CGFloat DAAEPanelScale(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.panelScale"]) return 1.0;
    double v = [ud doubleForKey:@"DAAE.panelScale"];
    if (v < 0.8 || v > 1.6) return 1.0;
    return (CGFloat)v;
}
static void DAAESetPanelScale(CGFloat s) {
    [[NSUserDefaults standardUserDefaults] setDouble:(double)s forKey:@"DAAE.panelScale"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

static CGFloat DAAEPanelAlpha(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.panelAlpha"]) return 1.0;
    double v = [ud doubleForKey:@"DAAE.panelAlpha"];
    if (v < 0.35 || v > 1.0) return 1.0;
    return (CGFloat)v;
}
static void DAAESetPanelAlpha(CGFloat a) {
    [[NSUserDefaults standardUserDefaults] setDouble:(double)MAX(0.35, MIN(1.0, a))
                                              forKey:@"DAAE.panelAlpha"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// ─────────────────────────────────────────────────────────────────────────────
// BACKGROUND STYLE
// 0=Glass(blur)  1=Solid  2=Dark Glass
// ─────────────────────────────────────────────────────────────────────────────
static NSInteger DAAEBgStyle(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.bgStyle"]) return 0;
    NSInteger v = [ud integerForKey:@"DAAE.bgStyle"];
    return (v >= 0 && v <= 2) ? v : 0;
}
static void DAAESetBgStyle(NSInteger s) {
    [[NSUserDefaults standardUserDefaults] setInteger:s forKey:@"DAAE.bgStyle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENT PRESET
// 0=None  1=Blue  2=Purple  3=Gold  4=Green  5=Red  6=Pure Dark
// ─────────────────────────────────────────────────────────────────────────────
static NSInteger DAAEGradientPreset(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.gradientPreset"]) return 0;
    NSInteger v = [ud integerForKey:@"DAAE.gradientPreset"];
    return (v >= 0 && v <= 6) ? v : 0;
}
static void DAAESetGradientPreset(NSInteger p) {
    [[NSUserDefaults standardUserDefaults] setInteger:p forKey:@"DAAE.gradientPreset"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
static void DAAEGradientColors(NSInteger preset, UIColor **c1, UIColor **c2) {
    switch (preset) {
        case 1:
            *c1 = [UIColor colorWithRed:0.78 green:0.90 blue:1.00 alpha:0.70];
            *c2 = [UIColor colorWithRed:0.55 green:0.75 blue:0.98 alpha:0.60];
            break;
        case 2:
            *c1 = [UIColor colorWithRed:0.72 green:0.60 blue:0.95 alpha:0.70];
            *c2 = [UIColor colorWithRed:0.50 green:0.35 blue:0.88 alpha:0.60];
            break;
        case 3:
            *c1 = [UIColor colorWithRed:1.00 green:0.88 blue:0.55 alpha:0.70];
            *c2 = [UIColor colorWithRed:0.98 green:0.70 blue:0.20 alpha:0.60];
            break;
        case 4:
            *c1 = [UIColor colorWithRed:0.60 green:0.95 blue:0.72 alpha:0.70];
            *c2 = [UIColor colorWithRed:0.24 green:0.82 blue:0.50 alpha:0.60];
            break;
        case 5:
            *c1 = [UIColor colorWithRed:1.00 green:0.65 blue:0.65 alpha:0.70];
            *c2 = [UIColor colorWithRed:0.97 green:0.20 blue:0.22 alpha:0.60];
            break;
        case 6:
            *c1 = [UIColor colorWithWhite:0.08 alpha:0.95];
            *c2 = [UIColor colorWithWhite:0.14 alpha:0.90];
            break;
        default:
            *c1 = nil; *c2 = nil;
            break;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACCENT COLOR
// ─────────────────────────────────────────────────────────────────────────────
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
// ADAPTIVE PALETTE — matches reference glass style
// ─────────────────────────────────────────────────────────────────────────────
static UIColor *PanelBG(void) {
    NSInteger bg = DAAEBgStyle();
    NSInteger gr = DAAEGradientPreset();
    if (bg == 1) { // Solid
        return DAAEDark()
            ? [UIColor colorWithWhite:0.12 alpha:0.98]
            : [UIColor colorWithWhite:0.95 alpha:0.98];
    }
    if (bg == 2) { // Dark Glass
        return [UIColor colorWithWhite:0.08 alpha:0.75];
    }
    // Glass (default)
    if (gr > 0 && gr < 6) {
        return DAAEDark()
            ? [UIColor colorWithWhite:0.10 alpha:0.15]
            : [UIColor colorWithWhite:1.00 alpha:0.20];
    }
    if (gr == 6) return [UIColor colorWithWhite:0.08 alpha:0.90];
    return DAAEDark()
        ? [UIColor colorWithWhite:0.14 alpha:0.55]
        : [UIColor colorWithWhite:0.98 alpha:0.65];
}

static UIBlurEffectStyle DAAEBlurStyle(void) {
    NSInteger bg = DAAEBgStyle();
    if (bg == 1) return DAAEDark()
        ? UIBlurEffectStyleDark : UIBlurEffectStyleExtraLight;
    if (bg == 2) return UIBlurEffectStyleDark;
    NSInteger gr = DAAEGradientPreset();
    if (gr >= 1 && gr <= 5)
        return UIBlurEffectStyleSystemUltraThinMaterialLight;
    return DAAEDark()
        ? UIBlurEffectStyleSystemUltraThinMaterialDark
        : UIBlurEffectStyleSystemUltraThinMaterialLight;
}

static UIColor *RowBG(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.08]
        : [UIColor colorWithWhite:0 alpha:0.05];
}
static UIColor *RowBGOn(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.13]
        : [UIColor colorWithWhite:0 alpha:0.09];
}
static UIColor *SectionClr(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.38]
        : [UIColor colorWithWhite:0 alpha:0.38];
}
static UIColor *LblMain(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:0.97 alpha:1]
        : [UIColor colorWithWhite:0.08 alpha:1];
}
static UIColor *LblDim(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.45]
        : [UIColor colorWithWhite:0 alpha:0.40];
}
static UIColor *SidebarBG(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:0 alpha:0.08]
        : [UIColor colorWithWhite:0 alpha:0.04];
}
static UIColor *HeaderBG(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.08]
        : [UIColor colorWithWhite:0 alpha:0.06];
}
static UIColor *DivClr(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.09]
        : [UIColor colorWithWhite:0 alpha:0.09];
}
static UIColor *TrackOff(void) {
    return DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.14]
        : [UIColor colorWithWhite:0 alpha:0.11];
}
static void StyleSlider(UISlider *s) {
    s.minimumTrackTintColor = DAAEAccentColor();
    s.maximumTrackTintColor = TrackOff();
    s.thumbTintColor = UIColor.whiteColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// AIM HELPERS
// ─────────────────────────────────────────────────────────────────────────────
static float AimRaw(void)    { return ESPPrefsFloat(@"AimType", -1); }
static BOOL  AimActive(void) { return AimRaw() >= 0; }

// ─────────────────────────────────────────────────────────────────────────────
// CHECK VIEW — accent circle with checkmark (active) / empty row (inactive)
// Matches reference: inactive toggle has NO visible circle
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
        self.clipsToBounds = YES;
        self.userInteractionEnabled = NO;
        _iv = [[UIImageView alloc] initWithImage:
            SFSym(@"checkmark", 11, UIImageSymbolWeightHeavy)];
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
    void (^upd)(void) = ^{
        if (on) {
            self.backgroundColor = DAAEAccentColor();
            self->_iv.tintColor  = DAAEAccentFG();
            self->_iv.alpha      = 1.0;
        } else {
            // Reference: inactive = no visible circle, just transparent
            self.backgroundColor = [UIColor colorWithWhite:DAAEDark()?1:0 alpha:0.08];
            self->_iv.alpha      = 0.0;
        }
    };
    if (anim) [UIView animateWithDuration:0.16 delay:0
        options:UIViewAnimationOptionCurveEaseOut animations:upd completion:nil];
    else upd();
}
- (void)refreshTheme { [self setOn:_on animated:NO]; }
@end

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE ROW — slim, matches reference height
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
        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, w - 60, kRowH)];
        lbl.text = txt;
        lbl.textColor = LblMain();
        lbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        lbl.adjustsFontSizeToFitWidth = YES;
        lbl.minimumScaleFactor = 0.75;
        lbl.tag = 888;
        lbl.userInteractionEnabled = NO;
        [self addSubview:lbl];
        self.check = [[DAAECheck alloc] initWithFrame:
            CGRectMake(w - 44, (kRowH - 28) / 2.0, 28, 28)];
        [self.check setOn:on animated:NO];
        [self addSubview:self.check];
        [self addTarget:self action:@selector(_tap)
              forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)_applyStyle:(BOOL)on {
    self.backgroundColor    = on ? RowBGOn() : RowBG();
    self.layer.cornerRadius = RadiusRow();
    self.clipsToBounds      = YES;
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
    [UIView animateWithDuration:0.16 delay:0
        options:UIViewAnimationOptionCurveEaseOut
        animations:^{ [self _applyStyle:nowOn]; }
        completion:nil];
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
@implementation DAAEPillPicker { NSArray<UIButton *> *_pills; }
- (instancetype)initWithOptions:(NSArray<NSString *> *)opts
                       selected:(NSInteger)sel
                          width:(CGFloat)w {
    NSInteger n = (NSInteger)opts.count;
    CGFloat h = 44;
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, h)])) {
        _selectedIndex = sel;
        self.backgroundColor    = RowBG();
        self.layer.cornerRadius = RadiusRow();
        self.clipsToBounds      = YES;
        CGFloat pad = 6, gap = 5;
        CGFloat btnW = (w - pad * 2 - gap * (n - 1)) / (CGFloat)n;
        NSMutableArray<UIButton *> *pills = [NSMutableArray array];
        for (NSInteger i = 0; i < n; i++) {
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.frame = CGRectMake(pad + i * (btnW + gap), 5, btnW, h - 10);
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
    [UIView animateWithDuration:0.14 animations:^{ [self _refreshPills]; }];
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
// SLIDER ROW — slim version
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
        _lbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 7, w - 90, 20)];
        _lbl.text = txt; _lbl.textColor = LblMain();
        _lbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        [self addSubview:_lbl];
        _val = [[UILabel alloc] initWithFrame:CGRectMake(w - 72, 7, 60, 20)];
        _val.textAlignment = NSTextAlignmentRight;
        _val.textColor = DAAEAccentColor();
        _val.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        float cur = ESPPrefsFloat(key, fb);
        _val.text = (mx <= 3.0f)
            ? [NSString stringWithFormat:@"%.2f", cur]
            : [NSString stringWithFormat:@"%.0f", cur];
        [self addSubview:_val];
        _sl = [[UISlider alloc] initWithFrame:CGRectMake(12, 36, w - 24, 22)];
        _sl.minimumValue = mn; _sl.maximumValue = mx; _sl.value = cur;
        StyleSlider(_sl);
        objc_setAssociatedObject(_sl, "valLbl", _val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(_sl, "espKey",  key,  OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(_sl, "fmtDec",  @(mx <= 3.0f), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [_sl addTarget:self action:@selector(_slid:)
              forControlEvents:UIControlEventValueChanged];
        [self addSubview:_sl];
    }
    return self;
}
- (void)_slid:(UISlider *)sl {
    UILabel  *val = objc_getAssociatedObject(sl, "valLbl");
    NSString *key = objc_getAssociatedObject(sl, "espKey");
    BOOL dec = [objc_getAssociatedObject(sl, "fmtDec") boolValue];
    val.text = dec
        ? [NSString stringWithFormat:@"%.2f", sl.value]
        : [NSString stringWithFormat:@"%.0f", sl.value];
    ESPPrefsSetFloat(key, sl.value);
    ESPSyncFromPrefs();
}
- (void)refreshTheme {
    self.backgroundColor    = RowBG();
    self.layer.cornerRadius = RadiusRow();
    _lbl.textColor = LblMain();
    _val.textColor = DAAEAccentColor();
    StyleSlider(_sl);
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW
// ─────────────────────────────────────────────────────────────────────────────
static UIView *InfoRow(NSString *title, NSString *value, CGFloat w, BOOL dim) {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, kRowH)];
    row.backgroundColor    = RowBG();
    row.layer.cornerRadius = RadiusRow();
    UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(14, 0, w * 0.42, kRowH)];
    tl.text = title; tl.textColor = LblMain();
    tl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [row addSubview:tl];
    UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(w * 0.42, 0, w * 0.55, kRowH)];
    vl.text = value;
    vl.textColor = dim ? LblDim() : DAAEAccentColor();
    vl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    vl.textAlignment = NSTextAlignmentRight;
    vl.adjustsFontSizeToFitWidth = YES;
    [row addSubview:vl];
    return row;
}

// ─────────────────────────────────────────────────────────────────────────────
// WARNING LABEL
// ─────────────────────────────────────────────────────────────────────────────
static CGFloat AddWarningLabel(NSString *text, NSArray<NSString *> *highlights,
                                UIScrollView *scroll, CGFloat w, CGFloat y) {
    UIFont *font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    NSMutableAttributedString *as = [[NSMutableAttributedString alloc]
        initWithString:text
            attributes:@{NSFontAttributeName: font,
                         NSForegroundColorAttributeName: LblDim()}];
    for (NSString *h in highlights) {
        NSRange r = [text rangeOfString:h];
        if (r.location != NSNotFound)
            [as addAttribute:NSForegroundColorAttributeName
                       value:DAAEAccentColor() range:r];
    }
    UILabel *warn = [[UILabel alloc] initWithFrame:CGRectMake(4, y, w - 8, 0)];
    warn.attributedText = as;
    warn.numberOfLines  = 0;
    warn.lineBreakMode  = NSLineBreakByWordWrapping;
    CGSize sz = [warn sizeThatFits:CGSizeMake(w - 8, 999)];
    warn.frame = CGRectMake(4, y, w - 8, sz.height);
    [scroll addSubview:warn];
    return y + sz.height + 10;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PANEL
// ─────────────────────────────────────────────────────────────────────────────
@interface _0xMO353DA () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) UIVisualEffectView *blurBG;
@property (nonatomic, strong) CAGradientLayer    *gradientLayer;
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

@implementation _0xMO353DA

// ─────────────────────────────────────────────────────────────────────────────
// DEFAULTS
// ─────────────────────────────────────────────────────────────────────────────
- (void)applyDefaults {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if (![ud boolForKey:@"_DAAEThemeV3"]) {
        [ud setBool:YES  forKey:@"DAAE.darkMode"];
        [ud setInteger:0 forKey:@"DAAE.accentIdx"];
        [ud setBool:YES  forKey:@"DAAE.squareCorners"];
        [ud setBool:YES  forKey:@"_DAAEThemeV3"];
        [ud synchronize];
    }
    if ([ud objectForKey:@"_MizzeDefaultsApplied"]) return;
    for (NSString *k in @[
        @"ESPEnabled",@"Box",@"Box3D",@"CleanESP",@"Name",@"Health",
        @"Line",@"Skeleton",@"HeadRedDot",@"Dis",@"AimLag",
        @"AimTargetLine",@"SilentAim",@"AutoFire",@"AutoFireFloating",
        @"FastFire",@"ShootNoReload",@"GhostModeFloating",@"FakeLagFloating",
        @"FlyFloating",@"RunSpeedFloating",@"RunSpeed",@"VisualSpin",
        @"AnLive",@"BalancedRender",@"HideFeatureButtons"
    ]) ESPPrefsSetBool(k, NO);
    ESPPrefsSetBool(@"ShowFov",    YES);
    ESPPrefsSetFloat(@"AimType",         -1);
    ESPPrefsSetFloat(@"AimActivation",    1);
    ESPPrefsSetFloat(@"FovSize",         40);
    ESPPrefsSetFloat(@"SilentFovSize",   18);
    ESPPrefsSetFloat(@"RunSpeedValue",    6);
    ESPPrefsSetFloat(@"FlyHeight",        4);
    ESPPrefsSetFloat(@"VisualSpinSpeed",  0.5);
    ESPPrefsSetBool(@"ExplicitAimMenuV1", YES);
    [ud setBool:YES forKey:@"_MizzeDefaultsApplied"];
    [ud synchronize];
    ESPSyncFromPrefs();
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW DID LOAD
// ─────────────────────────────────────────────────────────────────────────────
- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyDefaults];
    self.pointer = -1; self.colorTarget = 0; self.page = 0;
    self.controls = [NSMutableArray array];
    self.view.backgroundColor = UIColor.clearColor;

    __weak _0xMO353DA *ws = self;
    self.spinStatusTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES
        block:^(NSTimer *_){ [ws updateSpinStatus]; }];

    // Blur background
    self.blurBG = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:DAAEBlurStyle()]];
    self.blurBG.layer.cornerRadius = RadiusPanel();
    self.blurBG.clipsToBounds      = YES;
    [self.view addSubview:self.blurBG];

    // Panel container
    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.layer.cornerRadius = RadiusPanel();
    self.panel.layer.borderWidth  = 0.5;
    self.panel.layer.borderColor  = (DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.14]
        : [UIColor colorWithWhite:0 alpha:0.09]).CGColor;
    self.panel.clipsToBounds = YES;
    [self.view addSubview:self.panel];
    [self applyPanelAlpha];

    // Sidebar
    self.sidebar = [[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.backgroundColor = SidebarBG();
    [self.panel addSubview:self.sidebar];

    // Divider
    UIView *div = [[UIView alloc] initWithFrame:CGRectZero];
    div.tag = 99; div.backgroundColor = DivClr();
    [self.panel addSubview:div];

    // Content area
    self.contentArea = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentArea.backgroundColor = UIColor.clearColor;
    [self.panel addSubview:self.contentArea];

    // Scroll
    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator = NO;
    self.scroll.bounces = YES;
    self.scroll.clipsToBounds = YES;
    [self.contentArea addSubview:self.scroll];

    // Drag gestures
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
        NSURL *url = [NSURL URLWithString:@"https://t.me/didierxit7"];
        if (url) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)),
                dispatch_get_main_queue(), ^{
                [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
            });
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// LAYOUT — panel size driven only by scale, not screen size
// ─────────────────────────────────────────────────────────────────────────────
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sw = self.view.bounds.size.width;
    CGFloat sh = self.view.bounds.size.height;
    if (sw <= 0) sw = 375; if (sh <= 0) sh = 667;

    CGFloat scale = DAAEPanelScale();
    CGFloat pw = MIN(kDefaultPanelW * scale, sw - 16.0);
    CGFloat ph = MIN(kDefaultPanelH * scale, sh - 16.0);
    pw = MAX(pw, 240.0);
    ph = MAX(ph, 280.0);

    CGRect f = self.panel.frame;
    if (f.size.width < 1) {
        // First layout: center the panel
        f = CGRectMake(floorf((sw - pw) / 2.0), floorf((sh - ph) / 2.0), pw, ph);
    } else {
        // Keep position, update size, clamp to screen
        f.size = CGSizeMake(pw, ph);
        f.origin.x = MAX(4.0, MIN(f.origin.x, sw - pw - 4.0));
        f.origin.y = MAX(4.0, MIN(f.origin.y, sh - ph - 4.0));
    }
    self.panel.frame  = f;
    self.blurBG.frame = f;

    // Gradient layer follows panel bounds
    if (self.gradientLayer) {
        self.gradientLayer.frame        = self.panel.bounds;
        self.gradientLayer.cornerRadius = RadiusPanel();
    }

    // Sidebar: full height, left strip
    self.sidebar.frame = CGRectMake(0, 0, kSidebarW, ph);

    // Divider
    UIView *div = [self.panel viewWithTag:99];
    div.frame = CGRectMake(kSidebarW, 10, 0.5, ph - 20);

    // Content area
    CGFloat caX = kSidebarW + 0.5;
    CGFloat caW = pw - caX;
    self.contentArea.frame = CGRectMake(caX, 0, caW, ph);

    // Scroll — below header
    CGFloat scrollPadH = 8.0, scrollPadB = 8.0;
    self.scroll.frame = CGRectMake(scrollPadH, kHeaderH,
                                   caW - scrollPadH * 2,
                                   ph - kHeaderH - scrollPadB);

    [self layoutSidebarButtons];

    // Rebuild content only if width changed significantly
    if (fabs(self.builtWidth - self.scroll.bounds.size.width) > 1.0) {
        [self buildPage];
    }
    [self refreshSidebarSelection];
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
static NSArray<NSString *> *TabIcons(void) {
    return @[@"eye.fill", @"scope", @"paintpalette.fill", @"shippingbox.fill", @"gearshape.fill"];
}
static NSString *TabName(NSInteger i) {
    NSArray *en = @[@"ESP",    @"AIM",   @"CUSTOM", @"MISC",   @"SETTINGS"];
    NSArray *es = @[@"ESP",    @"APUNT", @"ESTILO", @"EXTRA",  @"CONFIG"];
    NSArray *vi = @[@"ESP",    @"AIM",   @"GIAO",   @"KHÁC",   @"CÀI"];
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
        btn.layer.cornerRadius = RadiusSidebar();
        btn.clipsToBounds = YES;
        [btn setImage:SFSym(icons[(NSUInteger)i], 17, UIImageSymbolWeightMedium)
             forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(sidebarTap:)
              forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
    }
    [self layoutSidebarButtons];
    [self refreshSidebarSelection];
}

- (void)layoutSidebarButtons {
    const CGFloat d = 38, gap = 10;
    CGFloat total = 5 * d + 4 * gap;
    CGFloat sbH   = MAX(self.sidebar.bounds.size.height, 300);
    CGFloat startY = MAX(8, (sbH - total) / 2.0);
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300 + i];
        if (!btn) continue;
        btn.frame = CGRectMake((kSidebarW - d) / 2.0, startY + i * (d + gap), d, d);
    }
}

- (void)refreshSidebarSelection {
    UIColor *accent = DAAEAccentColor();
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300 + i];
        if (!btn) continue;
        BOOL sel = (i == self.page);
        btn.backgroundColor  = sel ? [accent colorWithAlphaComponent:0.18] : UIColor.clearColor;
        btn.tintColor        = sel ? accent : LblDim();
        btn.layer.borderWidth = sel ? 1.4 : 0;
        btn.layer.borderColor = accent.CGColor;
        btn.layer.cornerRadius = RadiusSidebar();
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
// HEADER — slim, matches reference
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildHeader {
    for (UIView *v in self.contentArea.subviews)
        if (v.tag >= 500 && v.tag < 600) [v removeFromSuperview];

    CGFloat cw  = MAX(self.contentArea.bounds.size.width, 200);
    const CGFloat btnD = 32, top = 8, pad = 8, gap = 6;

    // Tab title label — directly in header, no pill container
    UILabel *title = [[UILabel alloc] initWithFrame:
        CGRectMake(pad + 24, top, cw - pad - 24 - (btnD + gap) * 2 - pad, btnD)];
    title.tag       = 502;
    title.text      = TabName(self.page);
    title.textColor = DAAEAccentColor();
    title.font      = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    title.adjustsFontSizeToFitWidth = YES;
    title.minimumScaleFactor = 0.75;
    [self.contentArea addSubview:title];

    // Tab icon left of title
    UIImageView *iv = [[UIImageView alloc]
        initWithImage:SFSym(TabIcons()[(NSUInteger)self.page], 14, UIImageSymbolWeightSemibold)];
    iv.tag           = 501;
    iv.tintColor     = DAAEAccentColor();
    iv.contentMode   = UIViewContentModeScaleAspectFit;
    iv.frame         = CGRectMake(pad, top + (btnD - 16) / 2.0, 16, 16);
    [self.contentArea addSubview:iv];

    // Dark/light toggle button
    UIButton *darkBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    darkBtn.tag   = 505;
    darkBtn.frame = CGRectMake(cw - pad - (btnD + gap) * 2, top, btnD, btnD);
    darkBtn.backgroundColor   = HeaderBG();
    darkBtn.layer.cornerRadius = RadiusChip();
    darkBtn.clipsToBounds      = YES;
    NSString *darkIcon = DAAEDark() ? @"sun.max.fill" : @"moon.fill";
    [darkBtn setImage:SFSym(darkIcon, 14, UIImageSymbolWeightSemibold)
             forState:UIControlStateNormal];
    darkBtn.tintColor = DAAEAccentColor();
    [darkBtn addTarget:self action:@selector(darkModeToggleTap)
           forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:darkBtn];

    // Close button
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.tag   = 503;
    close.frame = CGRectMake(cw - pad - btnD, top, btnD, btnD);
    close.backgroundColor   = HeaderBG();
    close.layer.cornerRadius = RadiusChip();
    close.clipsToBounds      = YES;
    [close setImage:SFSym(@"xmark", 13, UIImageSymbolWeightBold)
           forState:UIControlStateNormal];
    close.tintColor = DAAEAccentColor();
    [close addTarget:self action:@selector(closeMenu)
           forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:close];

    // Bottom separator line
    UIView *sep = [[UIView alloc] initWithFrame:
        CGRectMake(0, kHeaderH - 0.5, cw, 0.5)];
    sep.tag             = 510;
    sep.backgroundColor = DivClr();
    [self.contentArea addSubview:sep];
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
- (CGFloat)contentWidth {
    CGFloat w = self.scroll.bounds.size.width;
    return (w > 10) ? w : 230;
}

- (CGFloat)addToggleEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key fallback:(BOOL)fb y:(CGFloat)y {
    CGFloat w = [self contentWidth];
    DAAERow *row = [[DAAERow alloc] initWithLabel:DAAEStr(en, es, vi)
                                               on:ESPPrefsBool(key, fb)
                                            width:w];
    row.frame = CGRectMake(0, y, w, kRowH);
    objc_setAssociatedObject(row, "espKey", key, OBJC_ASSOCIATION_COPY_NONATOMIC);
    __weak DAAERow *wrow = row; __weak _0xMO353DA *ws = self;
    row.onChanged = ^(BOOL on) {
        NSString *k = objc_getAssociatedObject(wrow, "espKey");
        ESPPrefsSetBool(k, on);
        ESPSyncFromPrefs();
        [ws toggleChanged:k value:on];
    };
    [self.controls addObject:row];
    [self.scroll addSubview:row];
    return y + kRowStep;
}

- (CGFloat)addCustomToggleEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                          on:(BOOL)on y:(CGFloat)y handler:(void (^)(BOOL))handler {
    CGFloat w = [self contentWidth];
    DAAERow *row = [[DAAERow alloc] initWithLabel:DAAEStr(en, es, vi) on:on width:w];
    row.frame    = CGRectMake(0, y, w, kRowH);
    row.onChanged = handler;
    [self.controls addObject:row];
    [self.scroll addSubview:row];
    return y + kRowStep;
}

- (CGFloat)addSection:(NSString *)title y:(CGFloat)y {
    NSString *t = [[title stringByReplacingOccurrencesOfString:@"—" withString:@""]
        stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    t = t.uppercaseString;
    UILabel *l = [[UILabel alloc] initWithFrame:
        CGRectMake(6, y + 4, [self contentWidth] - 12, 18)];
    l.text      = t;
    l.textColor = SectionClr();
    l.font      = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    [self.scroll addSubview:l];
    return y + 26;
}

- (CGFloat)addSliderEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key min:(float)mn max:(float)mx fallback:(float)fb y:(CGFloat)y {
    CGFloat w = [self contentWidth];
    DAAESlider *sl = [[DAAESlider alloc]
        initWithLabel:DAAEStr(en, es, vi) key:key min:mn max:mx fallback:fb width:w];
    sl.frame = CGRectMake(0, y, w, kSliderH);
    [self.controls addObject:(UIControl *)sl];
    [self.scroll addSubview:sl];
    return y + kSliderStep;
}

- (void)rebuildAnimated {
    if (UIAccessibilityIsReduceMotionEnabled()) { [self buildPage]; return; }
    [UIView transitionWithView:self.scroll duration:0.14
        options:UIViewAnimationOptionTransitionCrossDissolve |
                UIViewAnimationOptionAllowUserInteraction
        animations:^{ [self buildPage]; }
        completion:nil];
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME HELPERS
// ─────────────────────────────────────────────────────────────────────────────
- (void)applyPanelAlpha {
    CGFloat a  = DAAEPanelAlpha();
    UIColor *bg = PanelBG();
    CGFloat baseA = CGColorGetAlpha(bg.CGColor);
    self.panel.backgroundColor = [bg colorWithAlphaComponent:baseA * a];
    self.blurBG.alpha = a;
}

- (void)applyGradient {
    NSInteger preset = DAAEGradientPreset();
    UIColor *c1 = nil, *c2 = nil;
    DAAEGradientColors(preset, &c1, &c2);
    if (!c1 || !c2) {
        [self.gradientLayer removeFromSuperlayer];
        self.gradientLayer = nil;
        return;
    }
    if (!self.gradientLayer) {
        self.gradientLayer = [CAGradientLayer layer];
        self.gradientLayer.startPoint = CGPointMake(0, 0);
        self.gradientLayer.endPoint   = CGPointMake(1, 1);
        [self.panel.layer insertSublayer:self.gradientLayer atIndex:0];
    }
    self.gradientLayer.frame        = self.panel.bounds;
    self.gradientLayer.cornerRadius = RadiusPanel();
    self.gradientLayer.colors       = @[(id)c1.CGColor, (id)c2.CGColor];
}

- (void)refreshThemeInPlace {
    self.panel.layer.cornerRadius = RadiusPanel();
    self.panel.layer.borderColor  = (DAAEDark()
        ? [UIColor colorWithWhite:1 alpha:0.14]
        : [UIColor colorWithWhite:0 alpha:0.09]).CGColor;
    self.blurBG.effect = [UIBlurEffect effectWithStyle:DAAEBlurStyle()];
    self.blurBG.layer.cornerRadius = RadiusPanel();
    [self applyPanelAlpha];
    [self applyGradient];
    self.sidebar.backgroundColor = SidebarBG();
    UIView *div = [self.panel viewWithTag:99];
    div.backgroundColor = DivClr();
    [self buildSidebar];
    [self buildPage];
}

// ─────────────────────────────────────────────────────────────────────────────
// BUILD PAGE
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildPage {
    const CGFloat savedOffset = self.scroll.contentOffset.y;
    for (UIView *v in self.scroll.subviews) [v removeFromSuperview];
    [self.controls removeAllObjects];
    self.spinStatusLabel = nil;
    self.builtWidth      = [self contentWidth];
    [self buildHeader];

    CGFloat y = 4;
    CGFloat w = [self contentWidth];

    // ── TAB 0: ESP ────────────────────────────────────────────────────────────
    if (self.page == 0) {
        y = [self addToggleEN:@"ESP Master"  ES:@"ESP Master"   VI:@"ESP Master"
                          key:@"ESPEnabled" fallback:YES y:y];
        y = [self addSection:DAAEStr(@"DRAW", @"DIBUJO", @"VẼ") y:y];
        y = [self addToggleEN:@"Box ESP"     ES:@"Marco ESP"    VI:@"Khung ESP"
                          key:@"Box"       fallback:YES y:y];
        y = [self addToggleEN:@"Line ESP"    ES:@"Línea ESP"    VI:@"Đường ESP"
                          key:@"Line"      fallback:NO  y:y];
        y = [self addToggleEN:@"Skeleton"    ES:@"Esqueleto"    VI:@"Xương"
                          key:@"Skeleton"  fallback:NO  y:y];
        y = [self addToggleEN:@"Head Dot"    ES:@"Punto cabeza" VI:@"Đầu Đỏ"
                          key:@"HeadRedDot" fallback:NO y:y];
        y = [self addToggleEN:@"Health Bar"  ES:@"Vida"         VI:@"Thanh Máu"
                          key:@"Health"    fallback:YES y:y];
        y = [self addToggleEN:@"Name"        ES:@"Nombre"       VI:@"Tên"
                          key:@"Name"      fallback:YES y:y];
        y = [self addToggleEN:@"Distance"    ES:@"Distancia"    VI:@"Khoảng Cách"
                          key:@"Dis"       fallback:YES y:y];
        y = [self addToggleEN:@"Clean ESP"   ES:@"ESP Limpio"   VI:@"ESP Sạch"
                          key:@"CleanESP"  fallback:YES y:y];
        y = [self addSection:@"FOV" y:y];
        y = [self addToggleEN:@"Show FOV"    ES:@"Mostrar FOV"  VI:@"Hiện FOV"
                          key:@"ShowFov"   fallback:YES y:y];
        y = [self addSliderEN:@"FOV Size"    ES:@"Tamaño FOV"   VI:@"Bán Kính"
                          key:@"FovSize" min:5 max:48 fallback:40 y:y];

    // ── TAB 1: AIM ────────────────────────────────────────────────────────────
    } else if (self.page == 1) {
        NSString *warn = DAAEStr(
            @"Use Aimbot with restraint. Excessive headshots may trigger detections.",
            @"Usa el Aimbot con moderación. Muchos headshots pueden activar detecciones.",
            @"Dùng Aimbot có chừng mực. Headshot quá nhiều có thể bị phát hiện.");
        y = AddWarningLabel(warn, @[
            DAAEStr(@"restraint",@"moderación",@"có chừng mực"),
            DAAEStr(@"detections",@"detecciones",@"phát hiện")
        ], self.scroll, w, y);

        __weak _0xMO353DA *wa = self;
        y = [self addCustomToggleEN:@"Aimbot" ES:@"Aimbot" VI:@"Aimbot"
                                 on:AimActive() y:y handler:^(BOOL on) {
            if (on) {
                ESPPrefsSetFloat(@"AimType", 0);
                ESPPrefsSetFloat(@"AimActivation", (float)static_cast<int>(
                    AimModePolicy::AfterTypeSelection(AimModePolicy::ReadType(0.0f))));
                ESPPrefsSetBool(@"SilentAim", NO);
            } else {
                ESPPrefsSetFloat(@"AimType", -1);
            }
            ESPClearAimLock();
            ESPSyncFromPrefs();
            [wa rebuildAnimated];
        }];
        y = [self addToggleEN:@"Aim Line"   ES:@"Línea objetivo" VI:@"Aim Line"
                          key:@"AimTargetLine" fallback:NO y:y];
        y = [self addToggleEN:@"Show FOV"   ES:@"Mostrar FOV"    VI:@"Hiện FOV"
                          key:@"ShowFov"    fallback:YES y:y];
        y = [self addToggleEN:@"Skip Bots"  ES:@"Ignorar bots"   VI:@"Bỏ Qua Bot"
                          key:@"AimLag"     fallback:NO  y:y];

        // Activation picker
        y = [self addSection:DAAEStr(@"ACTIVATION",@"ACTIVACIÓN",@"KÍCH HOẠT") y:y];
        NSArray *actOpts = @[
            DAAEStr(@"Always",    @"Siempre",     @"Luôn Luôn"),
            DAAEStr(@"On Shoot",  @"Al Disparar", @"Khi Bắn"),
            DAAEStr(@"On Scope",  @"Al Apuntar",  @"Khi Ngắm"),
        ];
        const NSInteger curActRaw = static_cast<int>(
            AimModePolicy::ReadActivation(ESPPrefsFloat(@"AimActivation", 0)));
        NSInteger actSel = (curActRaw >= 1 && curActRaw <= 3) ? curActRaw - 1 : 0;
        DAAEPillPicker *actPicker = [[DAAEPillPicker alloc]
            initWithOptions:actOpts selected:actSel width:w];
        actPicker.frame = CGRectMake(0, y, w, 44);
        actPicker.onSelected = ^(NSInteger idx) {
            ESPPrefsSetFloat(@"AimActivation", (float)(idx + 1));
            ESPClearAimLock();
            ESPSyncFromPrefs();
        };
        [self.scroll addSubview:actPicker];
        y += 50;

        // Aim position picker
        y = [self addSection:DAAEStr(@"AIM POSITION",@"POSICIÓN AIM",@"VỊ TRÍ NGẮM") y:y];
        NSArray *aimOpts = @[
            DAAEStr(@"Head",@"Cabeza",@"Đầu"),
            DAAEStr(@"Neck",@"Cuello",@"Cổ"),
            DAAEStr(@"Body",@"Cuerpo",@"Thân"),
        ];
        float aimRaw = AimRaw();
        NSInteger aimSel = (aimRaw >= 0 && aimRaw <= 2) ? (NSInteger)aimRaw : 0;
        DAAEPillPicker *aimPicker = [[DAAEPillPicker alloc]
            initWithOptions:aimOpts selected:aimSel width:w];
        aimPicker.frame = CGRectMake(0, y, w, 44);
        aimPicker.onSelected = ^(NSInteger idx) {
            ESPPrefsSetFloat(@"AimType", (float)idx);
            ESPPrefsSetFloat(@"AimActivation", static_cast<int>(
                AimModePolicy::AfterTypeSelection(AimModePolicy::ReadType((float)idx))));
            ESPPrefsSetBool(@"SilentAim", NO);
            ESPClearAimLock();
            ESPSyncFromPrefs();
        };
        [self.scroll addSubview:aimPicker];
        y += 50;

        y = [self addSliderEN:@"FOV Radius"    ES:@"Radio FOV"    VI:@"Bán Kính FOV"
                          key:@"FovSize"    min:5 max:48 fallback:40 y:y];
        y = [self addSliderEN:@"FOV Thickness" ES:@"Grosor FOV"   VI:@"Độ Dày FOV"
                          key:@"SilentFovSize" min:0 max:10 fallback:0 y:y];
        y = [self addSection:DAAEStr(@"WEAPONS",@"ARMAS",@"VŨ KHÍ") y:y];
        y = [self addToggleEN:@"Fast Fire"  ES:@"Disparo rápido" VI:@"Bắn Nhanh"
                          key:@"FastFire"      fallback:NO y:y];
        y = [self addToggleEN:@"No Reload"  ES:@"Sin recarga"    VI:@"Không Nạp"
                          key:@"ShootNoReload" fallback:NO y:y];

    // ── TAB 2: CUSTOMIZE ──────────────────────────────────────────────────────
    } else if (self.page == 2) {

        // ESP Colors section
        y = [self addSection:DAAEStr(@"ESP COLORS",@"COLORES ESP",@"MÀU ESP") y:y];
        UISegmentedControl *seg = [[UISegmentedControl alloc]
            initWithItems:@[@"Box", @"FOV"]];
        seg.frame                   = CGRectMake(0, y, w, 36);
        seg.selectedSegmentIndex    = self.colorTarget;
        seg.selectedSegmentTintColor = DAAEAccentColor();
        [seg setTitleTextAttributes:@{
            NSForegroundColorAttributeName: LblMain(),
            NSFontAttributeName: [UIFont systemFontOfSize:13 weight:UIFontWeightMedium]
        } forState:UIControlStateNormal];
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName: DAAEAccentFG()}
                           forState:UIControlStateSelected];
        [seg addTarget:self action:@selector(colorTargetChanged:)
              forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:seg];
        [self.controls addObject:(UIControl *)seg];
        y += 42;

        // Color swatch
        NSString *pfx = (self.colorTarget == 0) ? @"BoxColor" : @"FovColor";
        float r  = ESPPrefsFloat([pfx stringByAppendingString:@"R"], 0.26f);
        float g2 = ESPPrefsFloat([pfx stringByAppendingString:@"G"], 0.78f);
        float b  = ESPPrefsFloat([pfx stringByAppendingString:@"B"], 0.90f);

        UILabel *swatch = [[UILabel alloc] initWithFrame:CGRectMake(0, y, w, 44)];
        swatch.text = [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)round(r * 255), (int)round(g2 * 255), (int)round(b * 255)];
        swatch.textAlignment    = NSTextAlignmentCenter;
        swatch.backgroundColor  = [UIColor colorWithRed:r green:g2 blue:b alpha:1];
        CGFloat lum = r * 0.299f + g2 * 0.587f + b * 0.114f;
        swatch.textColor        = lum > 0.6f ? UIColor.blackColor : UIColor.whiteColor;
        swatch.font             = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        swatch.layer.cornerRadius = RadiusRow();
        swatch.clipsToBounds    = YES;
        swatch.tag              = 990;
        [self.scroll addSubview:swatch];
        y += 50;

        // RGB sliders
        NSArray *rgbEN = @[@"Red",   @"Green",    @"Blue"];
        NSArray *rgbES = @[@"Rojo",  @"Verde",    @"Azul"];
        NSArray *rgbVI = @[@"Đỏ",    @"Xanh lá",  @"Xanh"];
        NSArray *suf   = @[@"R",     @"G",        @"B"];
        float def[3] = {0.26f, 0.78f, 0.90f};

        __weak UILabel *wSwatch = swatch;
        __weak _0xMO353DA *wself2 = self;

        for (int i = 0; i < 3; i++) {
            NSString *key = [pfx stringByAppendingString:suf[(NSUInteger)i]];
            UIView *rgbRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, kSliderH)];
            rgbRow.backgroundColor    = RowBG();
            rgbRow.layer.cornerRadius = RadiusRow();
            UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 7, w - 90, 20)];
            lbl.text = DAAEStr(rgbEN[(NSUInteger)i], rgbES[(NSUInteger)i], rgbVI[(NSUInteger)i]);
            lbl.textColor = LblMain();
            lbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
            [rgbRow addSubview:lbl];
            UILabel *val = [[UILabel alloc] initWithFrame:CGRectMake(w - 72, 7, 60, 20)];
            val.textAlignment = NSTextAlignmentRight;
            val.textColor = DAAEAccentColor();
            val.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
            float cur2 = ESPPrefsFloat(key, def[i]);
            val.text = [NSString stringWithFormat:@"%.0f", (double)cur2 * 100.0];
            [rgbRow addSubview:val];
            UISlider *rgbSl = [[UISlider alloc] initWithFrame:CGRectMake(12, 36, w - 24, 22)];
            rgbSl.minimumValue = 0; rgbSl.maximumValue = 1; rgbSl.value = cur2;
            StyleSlider(rgbSl);
            objc_setAssociatedObject(rgbSl, "espKey",    key,     OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(rgbSl, "valLbl",    val,     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(rgbSl, "swatchRef", wSwatch, OBJC_ASSOCIATION_ASSIGN);
            objc_setAssociatedObject(rgbSl, "swatchPfx", pfx,     OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(rgbSl, "menuRef",   wself2,  OBJC_ASSOCIATION_ASSIGN);
            [rgbSl addTarget:self action:@selector(_colorSliderChanged:)
                   forControlEvents:UIControlEventValueChanged];
            [rgbRow addSubview:rgbSl];
            [self.scroll addSubview:rgbRow];
            y += kSliderStep;
        }

        // Panel background style
        y = [self addSection:DAAEStr(@"BACKGROUND STYLE",@"ESTILO FONDO",@"KIỂU NỀN") y:y];
        NSArray *bgOpts = @[
            DAAEStr(@"Glass",  @"Cristal", @"Kính"),
            DAAEStr(@"Solid",  @"Sólido",  @"Đặc"),
            DAAEStr(@"D.Glass",@"C.Oscuro",@"Kính Tối"),
        ];
        DAAEPillPicker *bgPicker = [[DAAEPillPicker alloc]
            initWithOptions:bgOpts selected:DAAEBgStyle() width:w];
        bgPicker.frame = CGRectMake(0, y, w, 44);
        __weak _0xMO353DA *wbg = self;
        bgPicker.onSelected = ^(NSInteger idx) {
            DAAESetBgStyle(idx);
            [wbg refreshThemeInPlace];
        };
        [self.scroll addSubview:bgPicker];
        y += 50;

        // Gradient preset grid
        y = [self addSection:DAAEStr(@"GRADIENT",@"GRADIENTE",@"MÀU NỀN") y:y];
        {
            NSArray *presetNames = @[
                DAAEStr(@"None",   @"Ninguno", @"Không"),
                DAAEStr(@"Blue",   @"Azul",    @"Xanh"),
                DAAEStr(@"Purple", @"Morado",  @"Tím"),
                DAAEStr(@"Gold",   @"Dorado",  @"Vàng"),
                DAAEStr(@"Green",  @"Verde",   @"Xanh lá"),
                DAAEStr(@"Red",    @"Rojo",    @"Đỏ"),
                DAAEStr(@"Dark",   @"Oscuro",  @"Tối"),
            ];
            NSInteger nP = (NSInteger)presetNames.count;
            NSInteger cols = 4;
            NSInteger rows = (nP + cols - 1) / cols;
            CGFloat cellW = (w - (cols - 1) * 6) / (CGFloat)cols;
            CGFloat cellH = 44.0;
            NSInteger cur = DAAEGradientPreset();

            for (NSInteger pi = 0; pi < nP; pi++) {
                NSInteger col = pi % cols;
                NSInteger row = pi / cols;
                CGFloat cx = col * (cellW + 6);
                CGFloat cy = y + row * (cellH + 6);

                UIButton *cell = [UIButton buttonWithType:UIButtonTypeCustom];
                cell.frame = CGRectMake(cx, cy, cellW, cellH);
                cell.layer.cornerRadius = RadiusChip();
                cell.layer.borderWidth  = (pi == cur) ? 2.0 : 0.5;
                cell.layer.borderColor  = (pi == cur)
                    ? DAAEAccentColor().CGColor
                    : [UIColor colorWithWhite:DAAEDark() ? 1 : 0 alpha:0.15].CGColor;
                cell.clipsToBounds = YES;
                cell.tag = 800 + pi;

                if (pi == 0) {
                    cell.backgroundColor = RowBG();
                    [cell setImage:SFSym(@"xmark", 12, UIImageSymbolWeightRegular)
                          forState:UIControlStateNormal];
                    cell.tintColor = LblDim();
                } else {
                    UIColor *gc1 = nil, *gc2 = nil;
                    DAAEGradientColors(pi, &gc1, &gc2);
                    if (gc1 && gc2) {
                        CAGradientLayer *gl = [CAGradientLayer layer];
                        gl.frame  = cell.bounds;
                        gl.colors = @[(id)gc1.CGColor, (id)gc2.CGColor];
                        gl.startPoint = CGPointMake(0, 0);
                        gl.endPoint   = CGPointMake(1, 1);
                        [cell.layer insertSublayer:gl atIndex:0];
                    }
                }

                UILabel *cellLbl = [[UILabel alloc]
                    initWithFrame:CGRectMake(0, cellH - 18, cellW, 18)];
                cellLbl.text = presetNames[(NSUInteger)pi];
                cellLbl.textAlignment = NSTextAlignmentCenter;
                cellLbl.font = [UIFont systemFontOfSize:10 weight:UIFontWeightSemibold];
                cellLbl.backgroundColor = pi == 0
                    ? UIColor.clearColor
                    : [UIColor colorWithWhite:0 alpha:0.30];
                cellLbl.textColor = pi == 0 ? LblMain() : UIColor.whiteColor;
                [cell addSubview:cellLbl];

                objc_setAssociatedObject(cell, "gradientPresetIdx", @(pi),
                    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [cell addTarget:self action:@selector(gradientPresetTap:)
                      forControlEvents:UIControlEventTouchUpInside];
                [self.scroll addSubview:cell];
            }
            y += rows * (cellH + 6) + 4;
        }

    // ── TAB 3: MISC ───────────────────────────────────────────────────────────
    } else if (self.page == 3) {
        NSString *miscWarn = DAAEStr(
            @"Some options may not be entirely safe. Use with caution.",
            @"Algunas opciones pueden no ser completamente seguras. Úsalas con precaución.",
            @"Một số tùy chọn có thể không an toàn. Hãy cẩn thận.");
        y = AddWarningLabel(miscWarn, @[
            DAAEStr(@"not be entirely safe",@"no ser completamente seguras",@"không an toàn"),
            DAAEStr(@"caution",@"precaución",@"cẩn thận")
        ], self.scroll, w, y);

        y = [self addSection:@"EXTRAS" y:y];
        y = [self addToggleEN:@"Ghost"        ES:@"Fantasma"      VI:@"Ghost"
                          key:@"GhostModeFloating"  fallback:NO y:y];
        y = [self addToggleEN:@"FakeLag"      ES:@"Lag Falso"     VI:@"FakeLag"
                          key:@"FakeLagFloating"    fallback:NO y:y];
        y = [self addToggleEN:@"Fly"          ES:@"Volar"         VI:@"Bay"
                          key:@"FlyFloating"        fallback:NO y:y];
        y = [self addToggleEN:@"Speed"        ES:@"Velocidad"     VI:@"Tốc Độ"
                          key:@"RunSpeedFloating"   fallback:NO y:y];
        y = [self addToggleEN:@"Hide Buttons" ES:@"Ocultar"       VI:@"Ẩn Nút"
                          key:@"HideFeatureButtons" fallback:NO y:y];
        y = [self addToggleEN:@"AimKill"      ES:@"Matar aim"     VI:@"AimKill"
                          key:@"AutoFireFloating"   fallback:NO y:y];

        y = [self addSection:DAAEStr(@"MOVEMENT",@"MOVIMIENTO",@"DI CHUYỂN") y:y];
        y = [self addToggleEN:@"Speed Toggle" ES:@"Velocidad"     VI:@"Tốc Độ"
                          key:@"RunSpeed"            fallback:NO y:y];
        y = [self addSliderEN:@"Speed Value"  ES:@"Velocidad m/s" VI:@"Tốc Độ m/s"
                          key:@"RunSpeedValue" min:1 max:15 fallback:6 y:y];
        if (ESPPrefsBool(@"FlyFloating", NO))
            y = [self addSliderEN:@"Fly Height" ES:@"Altura"      VI:@"Độ Cao"
                              key:@"FlyHeight" min:1 max:6 fallback:4 y:y];

        y = [self addSection:DAAEStr(@"EFFECTS",@"EFECTOS",@"HIỆU ỨNG") y:y];
        y = [self addToggleEN:@"Visual Spin" ES:@"Giro Visual"    VI:@"Xoay"
                          key:@"VisualSpin" fallback:NO y:y];
        if (ESPPrefsBool(@"VisualSpin", NO)) {
            y = [self addSliderEN:@"Spin Speed" ES:@"Vel. Giro"   VI:@"Tốc Độ Xoay"
                              key:@"VisualSpinSpeed" min:0.1 max:3 fallback:0.5 y:y];
            self.spinStatusLabel = [[UILabel alloc]
                initWithFrame:CGRectMake(4, y, w - 8, 30)];
            self.spinStatusLabel.textColor  = SectionClr();
            self.spinStatusLabel.font       = [UIFont systemFontOfSize:11];
            self.spinStatusLabel.numberOfLines = 2;
            [self.scroll addSubview:self.spinStatusLabel];
            [self updateSpinStatus];
            y += 36;
        }
        y = [self addToggleEN:@"Balanced Render" ES:@"Render eq." VI:@"Render"
                          key:@"BalancedRender" fallback:NO y:y];

    // ── TAB 4: SETTINGS ───────────────────────────────────────────────────────
    } else {
        y = [self addToggleEN:@"Stream Mode" ES:@"Modo Stream" VI:@"Stream"
                          key:@"AnLive" fallback:NO y:y];

        // Transparency slider
        {
            UIView *tRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, kSliderH)];
            tRow.backgroundColor    = RowBG();
            tRow.layer.cornerRadius = RadiusRow();
            UILabel *tLbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 7, w - 90, 20)];
            tLbl.text      = DAAEStr(@"Transparency", @"Transparencia", @"Độ Mờ");
            tLbl.textColor = LblMain();
            tLbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
            [tRow addSubview:tLbl];
            UILabel *tVal = [[UILabel alloc] initWithFrame:CGRectMake(w - 72, 7, 60, 20)];
            tVal.textAlignment = NSTextAlignmentRight;
            tVal.textColor = DAAEAccentColor();
            tVal.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
            tVal.text = [NSString stringWithFormat:@"%.2f", DAAEPanelAlpha()];
            [tRow addSubview:tVal];
            UISlider *tSl = [[UISlider alloc] initWithFrame:CGRectMake(12, 36, w - 24, 22)];
            tSl.minimumValue = 0.35f; tSl.maximumValue = 1.0f;
            tSl.value = (float)DAAEPanelAlpha();
            StyleSlider(tSl);
            objc_setAssociatedObject(tSl, "alphaValLbl", tVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [tSl addTarget:self action:@selector(_panelAlphaChanged:)
                  forControlEvents:UIControlEventValueChanged];
            [tRow addSubview:tSl];
            [self.scroll addSubview:tRow];
            y += kSliderStep;
        }

        // Panel scale slider
        {
            UIView *sRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, kSliderH)];
            sRow.backgroundColor    = RowBG();
            sRow.layer.cornerRadius = RadiusRow();
            UILabel *sLbl = [[UILabel alloc] initWithFrame:CGRectMake(14, 7, w - 110, 20)];
            sLbl.text = DAAEStr(@"Panel Scale", @"Escala Panel", @"Tỷ Lệ");
            sLbl.textColor = LblMain();
            sLbl.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
            [sRow addSubview:sLbl];
            UILabel *sVal = [[UILabel alloc] initWithFrame:CGRectMake(w - 108, 7, 54, 20)];
            sVal.textAlignment = NSTextAlignmentRight;
            sVal.textColor = DAAEAccentColor();
            sVal.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
            sVal.text = [NSString stringWithFormat:@"%d%%", (int)round(DAAEPanelScale() * 100)];
            [sRow addSubview:sVal];
            UIButton *resetBtn = [UIButton buttonWithType:UIButtonTypeSystem];
            resetBtn.frame = CGRectMake(w - 48, 2, 36, 30);
            [resetBtn setImage:SFSym(@"arrow.counterclockwise", 12, UIImageSymbolWeightSemibold)
                      forState:UIControlStateNormal];
            resetBtn.tintColor = DAAEAccentColor();
            UISlider *sSl = [[UISlider alloc] initWithFrame:CGRectMake(12, 36, w - 24, 22)];
            sSl.minimumValue = 0.8f; sSl.maximumValue = 1.6f;
            sSl.value = (float)DAAEPanelScale();
            StyleSlider(sSl);
            objc_setAssociatedObject(sSl, "valLbl", sVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [sSl addTarget:self action:@selector(_panelScaleChanged:)
                  forControlEvents:UIControlEventValueChanged];
            objc_setAssociatedObject(resetBtn, "sizeSlider", sSl,  OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(resetBtn, "sizeLabel",  sVal, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [resetBtn addTarget:self action:@selector(_panelScaleReset:)
                      forControlEvents:UIControlEventTouchUpInside];
            [sRow addSubview:sSl];
            [sRow addSubview:resetBtn];
            [self.scroll addSubview:sRow];
            y += kSliderStep;
        }

        // Shape picker
        y = [self addSection:DAAEStr(@"SHAPE",@"FORMA",@"HÌNH DẠNG") y:y];
        NSArray *cornerOpts = @[
            DAAEStr(@"Rounded", @"Redondeado", @"Tròn"),
            DAAEStr(@"Square",  @"Cuadrado",   @"Vuông"),
        ];
        __weak _0xMO353DA *wself = self;
        DAAEPillPicker *cornerPicker = [[DAAEPillPicker alloc]
            initWithOptions:cornerOpts selected:(DAAESquareCorners() ? 1 : 0) width:w];
        cornerPicker.frame = CGRectMake(0, y, w, 44);
        cornerPicker.onSelected = ^(NSInteger idx) {
            DAAESetSquareCorners(idx == 1);
            [wself refreshThemeInPlace];
        };
        [self.scroll addSubview:cornerPicker];
        y += 50;

        // Language picker
        y = [self addSection:DAAEStr(@"LANGUAGE",@"IDIOMA",@"NGÔN NGỮ") y:y];
        {
            UIView *langRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 44)];
            langRow.backgroundColor    = RowBG();
            langRow.layer.cornerRadius = RadiusRow();
            NSArray *codes = @[@"EN", @"ES", @"VI"];
            NSArray *names = @[@"English", @"Español", @"Tiếng Việt"];
            NSInteger curLang = DAAELang();
            CGFloat btnW = (w - 16 - 10) / 3.0;
            for (NSInteger k = 0; k < 3; k++) {
                UIButton *lb = [UIButton buttonWithType:UIButtonTypeCustom];
                lb.frame = CGRectMake(8 + k * (btnW + 5), 5, btnW, 34);
                BOOL sel = (k == curLang);
                lb.backgroundColor    = sel ? DAAEAccentColor() : UIColor.clearColor;
                lb.layer.cornerRadius = RadiusChip();
                [lb setTitle:codes[(NSUInteger)k] forState:UIControlStateNormal];
                lb.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
                [lb setTitleColor:sel ? DAAEAccentFG() : LblDim()
                         forState:UIControlStateNormal];
                objc_setAssociatedObject(lb, "langIdx", @(k), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [lb addTarget:self action:@selector(langTap:)
                    forControlEvents:UIControlEventTouchUpInside];
                [langRow addSubview:lb];
            }
            [self.scroll addSubview:langRow];
            y += 50;
            UILabel *lhint = [[UILabel alloc] initWithFrame:CGRectMake(0, y, w, 16)];
            lhint.text          = names[(NSUInteger)curLang];
            lhint.textColor     = SectionClr();
            lhint.font          = [UIFont systemFontOfSize:11];
            lhint.textAlignment = NSTextAlignmentCenter;
            [self.scroll addSubview:lhint];
            y += 22;
        }

        // Appearance (dark/light)
        y = [self addSection:DAAEStr(@"APPEARANCE",@"APARIENCIA",@"GIAO DIỆN") y:y];
        NSArray *modeOpts = @[
            DAAEStr(@"Light", @"Claro", @"Sáng"),
            DAAEStr(@"Dark",  @"Oscuro", @"Tối"),
        ];
        DAAEPillPicker *modePicker = [[DAAEPillPicker alloc]
            initWithOptions:modeOpts selected:(DAAEDark() ? 1 : 0) width:w];
        modePicker.frame = CGRectMake(0, y, w, 44);
        modePicker.onSelected = ^(NSInteger idx) {
            BOOL newDark = (idx == 1);
            DAAEAdjustAccentForMode(newDark);
            DAAESetDark(newDark);
            [wself refreshThemeInPlace];
        };
        [self.scroll addSubview:modePicker];
        y += 50;

        // Accent color picker
        y = [self addSection:DAAEStr(@"ACCENT COLOR",@"COLOR ACENTO",@"MÀU NHẤN") y:y];
        {
            BOOL dark = DAAEDark();
            NSMutableArray *accentColors = [NSMutableArray arrayWithArray:@[
                [UIColor colorWithRed:0.26 green:0.78 blue:0.90 alpha:1],
                [UIColor colorWithRed:1.00 green:0.60 blue:0.10 alpha:1],
                [UIColor colorWithRed:0.97 green:0.20 blue:0.22 alpha:1],
                [UIColor colorWithRed:0.95 green:0.82 blue:0.14 alpha:1],
                [UIColor colorWithRed:0.24 green:0.82 blue:0.50 alpha:1],
            ]];
            NSMutableArray *chipIdxMap = [@[@0, @1, @2, @3, @4] mutableCopy];
            if (dark) {
                [accentColors addObject:[UIColor colorWithWhite:0.96 alpha:1]];
                [chipIdxMap addObject:@6];
            } else {
                [accentColors addObject:[UIColor colorWithWhite:0.08 alpha:1]];
                [chipIdxMap addObject:@5];
            }
            NSInteger n = (NSInteger)accentColors.count;
            NSInteger curAccent = DAAEAccentIdx();
            UIView *accentRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 56)];
            accentRow.backgroundColor    = RowBG();
            accentRow.layer.cornerRadius = RadiusRow();
            CGFloat circD = 28;
            CGFloat totalW = n * circD + (n - 1) * 8;
            CGFloat startX = (w - totalW) / 2.0;
            for (NSInteger k = 0; k < n; k++) {
                NSInteger realIdx = [chipIdxMap[(NSUInteger)k] integerValue];
                UIButton *cb = [UIButton buttonWithType:UIButtonTypeCustom];
                cb.frame = CGRectMake(startX + k * (circD + 8), (56 - circD) / 2.0, circD, circD);
                cb.backgroundColor    = accentColors[(NSUInteger)k];
                cb.layer.cornerRadius = circD / 2.0;
                cb.clipsToBounds      = YES;
                if (realIdx == curAccent) {
                    cb.layer.borderWidth = 2.5;
                    cb.layer.borderColor = (dark
                        ? [UIColor colorWithWhite:1 alpha:0.80]
                        : [UIColor colorWithWhite:0 alpha:0.45]).CGColor;
                }
                objc_setAssociatedObject(cb, "accentIdx", @(realIdx),
                    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [cb addTarget:self action:@selector(accentTap:)
                    forControlEvents:UIControlEventTouchUpInside];
                [accentRow addSubview:cb];
            }
            [self.scroll addSubview:accentRow];
            y += 62;
        }

        // Info section
        y = [self addSection:@"INFO" y:y];
        NSArray *infoT = @[@"Product", @"Creator", @"Telegram",
                           DAAEStr(@"Key", @"Clave", @"Khóa")];
        NSArray *infoV = @[@"DAAE IOS", @"@didierxit7", @"t.me/didierxit7", @"TEST"];
        for (int k = 0; k < 4; k++) {
            UIView *row = InfoRow(infoT[(NSUInteger)k], infoV[(NSUInteger)k], w, (k == 3));
            row.frame = CGRectMake(0, y, w, kRowH);
            [self.scroll addSubview:row];
            y += kRowStep;
        }
    }

    // Credit footer
    UILabel *credit = [[UILabel alloc] initWithFrame:CGRectMake(0, y + 6, w, 14)];
    credit.text          = @"DAAE IOS";
    credit.textColor     = [UIColor colorWithWhite:DAAEDark() ? 1 : 0 alpha:0.15];
    credit.font          = [UIFont systemFontOfSize:9 weight:UIFontWeightMedium];
    credit.textAlignment = NSTextAlignmentCenter;
    [self.scroll addSubview:credit];
    y += 26;

    self.scroll.contentSize    = CGSizeMake(w, y + 6);
    self.scroll.contentOffset  = CGPointMake(0, MAX(0,
        MIN(savedOffset, y + 6 - self.scroll.bounds.size.height)));
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTIONS
// ─────────────────────────────────────────────────────────────────────────────
- (void)closeMenu { if (self.onCloseBlock) self.onCloseBlock(); }

- (void)darkModeToggleTap {
    BOOL newDark = !DAAEDark();
    DAAEAdjustAccentForMode(newDark);
    DAAESetDark(newDark);
    [self refreshThemeInPlace];
}

- (void)colorTargetChanged:(UISegmentedControl *)seg {
    self.colorTarget = seg.selectedSegmentIndex;
    [self buildPage];
}

- (void)gradientPresetTap:(UIButton *)sender {
    NSNumber *n = objc_getAssociatedObject(sender, "gradientPresetIdx");
    if (!n) return;
    NSInteger newPreset = n.integerValue;
    DAAESetGradientPreset(newPreset);
    for (NSInteger pi = 0; pi < 7; pi++) {
        UIButton *chip = (UIButton *)[self.scroll viewWithTag:800 + pi];
        if (!chip) continue;
        BOOL sel = (pi == newPreset);
        chip.layer.borderWidth = sel ? 2.0 : 0.5;
        chip.layer.borderColor = sel
            ? DAAEAccentColor().CGColor
            : [UIColor colorWithWhite:DAAEDark() ? 1 : 0 alpha:0.15].CGColor;
    }
    [self refreshThemeInPlace];
}

- (void)_colorSliderChanged:(UISlider *)sl {
    NSString *key    = objc_getAssociatedObject(sl, "espKey");
    UILabel  *valLbl = objc_getAssociatedObject(sl, "valLbl");
    UILabel  *swatch = objc_getAssociatedObject(sl, "swatchRef");
    NSString *pfx    = objc_getAssociatedObject(sl, "swatchPfx");
    if (!swatch) swatch = (UILabel *)[self.scroll viewWithTag:990];
    if (!pfx)    pfx    = (self.colorTarget == 0) ? @"BoxColor" : @"FovColor";
    if (key)    ESPPrefsSetFloat(key, sl.value);
    if (valLbl) valLbl.text = [NSString stringWithFormat:@"%.0f", (double)sl.value * 100.0];
    if (!swatch || !pfx) return;
    float r = ESPPrefsFloat([pfx stringByAppendingString:@"R"], 0.26f);
    float g = ESPPrefsFloat([pfx stringByAppendingString:@"G"], 0.78f);
    float b = ESPPrefsFloat([pfx stringByAppendingString:@"B"], 0.90f);
    [UIView performWithoutAnimation:^{
        swatch.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1];
        swatch.text = [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)round(r * 255), (int)round(g * 255), (int)round(b * 255)];
        CGFloat lum = r * 0.299f + g * 0.587f + b * 0.114f;
        swatch.textColor = lum > 0.6f ? UIColor.blackColor : UIColor.whiteColor;
    }];
    ESPSyncFromPrefs();
}

- (void)_panelScaleChanged:(UISlider *)sl {
    UILabel *val = objc_getAssociatedObject(sl, "valLbl");
    DAAESetPanelScale(sl.value);
    if (val) val.text = [NSString stringWithFormat:@"%d%%", (int)round(sl.value * 100)];
    // Reset panel frame to trigger re-centering at new size
    self.panel.frame  = CGRectZero;
    self.blurBG.frame = CGRectZero;
    [self viewDidLayoutSubviews];
}

- (void)_panelScaleReset:(UIButton *)btn {
    DAAESetPanelScale(1.0);
    UISlider *sl  = objc_getAssociatedObject(btn, "sizeSlider");
    UILabel  *val = objc_getAssociatedObject(btn, "sizeLabel");
    if (sl)  sl.value = 1.0f;
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

- (void)toggleChanged:(NSString *)key value:(BOOL)on {
    if ([@[@"GhostModeFloating", @"FakeLagFloating",
           @"AutoFireFloating",  @"FlyFloating"] containsObject:key]) {
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
    if ([@[@"SilentAutoConfig", @"AutoFireFloating",
           @"FlyFloating", @"VisualSpin"] containsObject:key])
        [self rebuildAnimated];
}

- (void)updateSpinStatus {
    if (!self.isViewLoaded || !self.view.window || self.view.hidden) return;
    if (!self.spinStatusLabel) return;
    const auto state = PlayerModesRead();
    NSString *text = @"Spin: waiting for game tick";
    if (state.detail && state.detail[0])
        text = [NSString stringWithUTF8String:state.detail];
    else if (state.spinStatus == 1) text = @"Spin: waiting for character";
    else if (state.spinStatus == 2) text = @"Spin: no compatible model";
    else if (state.spinStatus == 3) text = @"Spin: waiting for angle";
    else if (state.spinStatus == 4)
        text = [NSString stringWithFormat:@"Spin: applied · %llu",
                (unsigned long long)state.spinApplies];
    self.spinStatusLabel.text = text;
}

- (void)dealloc { [self.spinStatusTimer invalidate]; }

// ─────────────────────────────────────────────────────────────────────────────
// DRAG GESTURE
// ─────────────────────────────────────────────────────────────────────────────
- (void)dragPanel:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateBegan)
        self.panelOrigin = self.panel.frame.origin;
    CGPoint d = [pan translationInView:self.view];
    CGRect f  = self.panel.frame;
    f.origin  = CGPointMake(self.panelOrigin.x + d.x, self.panelOrigin.y + d.y);
    self.panel.frame  = f;
    self.blurBG.frame = f;
    if (self.gradientLayer) self.gradientLayer.frame = self.panel.bounds;
    [self viewDidLayoutSubviews];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)t {
    for (UIView *v = t.view; v && v != g.view; v = v.superview)
        if ([v isKindOfClass:UIControl.class]) return NO;
    return YES;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOUCH ROUTING — _0xF010
// ─────────────────────────────────────────────────────────────────────────────
- (BOOL)_0xF010:(CGPoint)point phase:(NSInteger)phase pointerId:(NSInteger)pointerId {
    if (phase == UITouchPhaseBegan) {
        if (!CGRectContainsPoint(self.panel.frame, point)) return NO;
        if (self.pointer != -1) return YES;
        self.pointer     = pointerId;
        self.began       = point;
        self.panelOrigin = self.panel.frame.origin;
        self.scrollOrigin= self.scroll.contentOffset.y;
        self.scrolling   = NO;
        self.activeControl = nil;

        CGPoint local = [self.panel convertPoint:point fromView:self.view];
        self.dragging = (local.x < kSidebarW + 2) ||
                        (local.y < kHeaderH && local.x < self.panel.bounds.size.width - 80);
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
    CGFloat dx = point.x - self.began.x;
    CGFloat dy = point.y - self.began.y;

    if (phase == UITouchPhaseMoved) {
        if (self.dragging) {
            CGRect f  = self.panel.frame;
            f.origin  = CGPointMake(self.panelOrigin.x + dx, self.panelOrigin.y + dy);
            self.panel.frame  = f;
            self.blurBG.frame = f;
            if (self.gradientLayer) self.gradientLayer.frame = self.panel.bounds;
            [self viewDidLayoutSubviews];
        } else if (fabs(dy) > 5 || self.scrolling) {
            self.scrolling = YES;
            CGFloat maxY   = MAX(0, self.scroll.contentSize.height - self.scroll.bounds.size.height);
            self.scroll.contentOffset = CGPointMake(0, MAX(0, MIN(maxY, self.scrollOrigin - dy)));
        }
        return YES;
    }
    if (phase == UITouchPhaseEnded || phase == UITouchPhaseCancelled) {
        BOOL activate = phase == UITouchPhaseEnded &&
                        !self.dragging && !self.scrolling &&
                        fabs(dx) < 20 && fabs(dy) < 20;
        UIControl *ctrl = self.activeControl;
        self.pointer       = -1;
        self.activeControl = nil;
        if (activate && ctrl && ctrl.enabled)
            [ctrl sendActionsForControlEvents:UIControlEventTouchUpInside];
        return YES;
    }
    return YES;
}

@end
// BUILD OK

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

// Devuelve el string en el idioma activo
static NSString *DAAEStr(NSString *en, NSString *es, NSString *vi) {
    switch (DAAELang()) {
        case 1: return es;
        case 2: return vi;
        default: return en;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// AIM TYPE — raw float persistida; -1 = sin aim
// ─────────────────────────────────────────────────────────────────────────────
static float  AimRaw(void)     { return ESPPrefsFloat(@"AimType", -1); }
static BOOL   AimActive(void)  { return AimRaw() >= 0; }
static NSInteger AimIdx(void)  { return AimActive() ? (NSInteger)AimRaw() : -1; }

// ─────────────────────────────────────────────────────────────────────────────
// PALETA — glass: panel casi transparente, el blur hace el tono
// ─────────────────────────────────────────────────────────────────────────────
static UIColor *PanelBG(void)     { return [UIColor colorWithWhite:0.08 alpha:0.82]; }
static UIColor *RowOFF(void)      { return [UIColor colorWithWhite:1 alpha:0.07]; }
static UIColor *RowON(void)       { return [UIColor colorWithWhite:1 alpha:0.14]; }
static UIColor *SectionClr(void)  { return [UIColor colorWithWhite:1 alpha:0.38]; }
static UIColor *LblMain(void)     { return UIColor.whiteColor; }
static UIColor *LblDim(void)      { return [UIColor colorWithWhite:1 alpha:0.55]; }
static UIColor *CheckON(void)     { return [UIColor colorWithWhite:1 alpha:0.22]; }
static UIColor *CheckOFF(void)    { return [UIColor colorWithWhite:1 alpha:0.11]; }
static UIColor *SidebarBG(void)   { return [UIColor colorWithWhite:0 alpha:0.12]; }
static UIColor *HeaderBG(void)    { return [UIColor colorWithWhite:1 alpha:0.05]; }

// ─────────────────────────────────────────────────────────────────────────────
// CHECKMARK CIRCLE — igual a las imágenes: círculo siempre visible,
// checkmark SF Symbol visible solo cuando ON
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAECheck : UIView
@property (nonatomic, assign) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end
@implementation DAAECheck { UIImageView *_iv; }
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.layer.cornerRadius = f.size.width / 2.0;
        self.userInteractionEnabled = NO;
        _iv = [[UIImageView alloc] initWithImage:
            SFSym(@"checkmark", 13, UIImageSymbolWeightHeavy)];
        _iv.tintColor   = [UIColor colorWithWhite:0.9 alpha:1.0];
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
        self.backgroundColor = on ? CheckON() : CheckOFF();
        self->_iv.hidden = !on;
    };
    if (anim) [UIView animateWithDuration:0.18 delay:0
        options:UIViewAnimationOptionCurveEaseInOut animations:upd completion:nil];
    else upd();
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE ROW — label monolingüe, checkmark circle derecha
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAERow : UIButton
@property (nonatomic, strong) DAAECheck *check;
@property (nonatomic, assign) BOOL toggleOn;
@property (nonatomic, copy)   void (^onChanged)(BOOL);
- (void)_applyStyle:(BOOL)on;
@end
@implementation DAAERow
- (instancetype)initWithLabel:(NSString *)txt on:(BOOL)on width:(CGFloat)w {
    // Alto fijo 60pt — coincide con la referencia
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, 60)])) {
        self.toggleOn = on;
        [self _applyStyle:on];

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, w - 74, 60)];
        lbl.text                = txt;
        lbl.textColor           = LblMain();
        lbl.font                = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
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
    self.backgroundColor    = on ? RowON() : RowOFF();
    self.layer.cornerRadius = 14;
    self.layer.borderWidth  = on ? 0.7 : 0;
    self.layer.borderColor  = on ? [UIColor colorWithWhite:1 alpha:0.20].CGColor
                                 : [UIColor clearColor].CGColor;
    self.clipsToBounds = YES;
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
// SLIDER ROW — fondo RowOFF, label monolingüe, slider UIKit
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAESlider : UIView
@end
@implementation DAAESlider
- (instancetype)initWithLabel:(NSString *)txt key:(NSString *)key
                          min:(float)mn max:(float)mx fallback:(float)fb width:(CGFloat)w {
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, 72)])) {
        self.backgroundColor    = RowOFF();
        self.layer.cornerRadius = 14;

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(18, 8, w - 90, 22)];
        lbl.text      = txt;
        lbl.textColor = LblMain();
        lbl.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [self addSubview:lbl];

        UILabel *val = [[UILabel alloc] initWithFrame:CGRectMake(w - 64, 8, 52, 22)];
        val.textAlignment = NSTextAlignmentRight;
        val.textColor = LblMain();
        val.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        float cur = ESPPrefsFloat(key, fb);
        val.text = [NSString stringWithFormat:@"%.0f", cur];
        [self addSubview:val];

        UISlider *sl = [[UISlider alloc] initWithFrame:CGRectMake(14, 40, w - 28, 22)];
        sl.minimumValue          = mn;
        sl.maximumValue          = mx;
        sl.value                 = cur;
        sl.minimumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.85];
        sl.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.18];
        sl.thumbTintColor        = UIColor.whiteColor;
        objc_setAssociatedObject(sl, "valLbl", val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(sl, "espKey", key, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [sl addTarget:self action:@selector(_slid:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:sl];
    }
    return self;
}
- (void)_slid:(UISlider *)sl {
    UILabel *val  = objc_getAssociatedObject(sl, "valLbl");
    NSString *key = objc_getAssociatedObject(sl, "espKey");
    val.text = [NSString stringWithFormat:@"%.0f", sl.value];
    ESPPrefsSetFloat(key, sl.value);
    ESPSyncFromPrefs();
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW — settings
// ─────────────────────────────────────────────────────────────────────────────
static UIView *InfoRow(NSString *title, NSString *value, CGFloat w, BOOL dim) {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 52)];
    row.backgroundColor    = RowOFF();
    row.layer.cornerRadius = 14;

    UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, w * 0.45, 52)];
    tl.text      = title;
    tl.textColor = LblMain();
    tl.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [row addSubview:tl];

    UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(w * 0.44, 0, w * 0.52 - 8, 52)];
    vl.text          = value;
    vl.textColor     = dim ? LblDim() : LblMain();
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
@property (nonatomic, assign) NSInteger  page;         // 0=ESP 1=Aim 2=Colors 3=Misc 4=Settings
@property (nonatomic, assign) NSInteger  colorTarget;  // 0=Box 1=FOV
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
// applyDefaults — AimType default -1 (sin aim)
// ─────────────────────────────────────────────────────────────────────────────
- (void)applyDefaults {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if ([ud objectForKey:@"_MizzeDefaultsApplied"]) return;

    // Booleanos — todos OFF por defecto excepto ShowFov
    for (NSString *k in @[@"ESPEnabled",@"Box",@"Box3D",@"CleanESP",@"Name",@"Health",
                           @"Line",@"Skeleton",@"HeadRedDot",@"Dis",@"AimLag",
                           @"AimTargetLine",@"SilentAim",@"AutoFire",@"AutoFireFloating",
                           @"FastFire",@"ShootNoReload",@"GhostModeFloating",@"FakeLagFloating",
                           @"FlyFloating",@"RunSpeedFloating",@"RunSpeed",@"VisualSpin",
                           @"AnLive",@"BalancedRender",@"HideFeatureButtons"])
        ESPPrefsSetBool(k, NO);
    ESPPrefsSetBool(@"ShowFov",    YES);
    ESPPrefsSetBool(@"DarkTheme",  YES);

    // Floats
    ESPPrefsSetFloat(@"AimType",        -1);   // SIN aim por defecto
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

    // ── Blur glassmorphism — hace el efecto translúcido
    self.blurBG = [[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    self.blurBG.layer.cornerRadius  = 22;
    self.blurBG.clipsToBounds       = YES;
    [self.view addSubview:self.blurBG];

    // ── Panel sobre el blur — casi transparente para dejar pasar el glass
    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.backgroundColor    = PanelBG();
    self.panel.layer.cornerRadius = 22;
    self.panel.layer.borderWidth  = 0.6;
    self.panel.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.13].CGColor;
    self.panel.clipsToBounds      = YES;
    [self.view addSubview:self.panel];

    // ── Sidebar
    self.sidebar = [[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.backgroundColor = SidebarBG();
    [self.panel addSubview:self.sidebar];

    // ── Divisor sidebar/content
    UIView *div = [[UIView alloc] initWithFrame:CGRectZero];
    div.tag = 99;
    div.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
    [self.panel addSubview:div];

    // ── Content area
    self.contentArea = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentArea.backgroundColor = UIColor.clearColor;
    [self.panel addSubview:self.contentArea];

    // ── Scroll con padding lateral — filas no se cortan
    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator = NO;
    self.scroll.bounces = YES;
    self.scroll.clipsToBounds = YES;
    [self.contentArea addSubview:self.scroll];

    // ── Pan gestures para arrastrar el panel
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

    // Panel ocupa bien la pantalla — se ve como en la referencia
    CGFloat pw = MIN(sw - 120.0, 480.0);
    pw = MAX(pw, 280.0);
    CGFloat ph = MIN(sh - 60.0, 560.0);
    ph = MAX(ph, 340.0);

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

    const CGFloat headerH  = 54.0;
    const CGFloat padH     = 10.0;  // padding horizontal filas
    const CGFloat padB     = 10.0;  // padding bottom
    self.scroll.frame = CGRectMake(padH, headerH,
                                   caW - padH * 2,
                                   ph - headerH - padB);

    [self layoutSidebarButtons];
    if (fabs(self.builtWidth - self.scroll.bounds.size.width) > 0.5) [self buildPage];
    [self refreshSidebarSelection];
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR — 5 tabs
// 0: ESP          eye.fill
// 1: Aim          scope
// 2: Colors       paintpalette.fill
// 3: Misc         shippingbox.fill
// 4: Settings     gearshape.fill
// ─────────────────────────────────────────────────────────────────────────────
static NSArray<NSString *> *TabIcons(void) {
    return @[@"eye.fill", @"scope", @"paintpalette.fill",
             @"shippingbox.fill", @"gearshape.fill"];
}
static NSArray<NSString *> *TabNames(void) {
    return @[@"ESP", @"Aim", @"Colors", @"Misc", @"Settings"];
}

- (void)buildSidebar {
    for (UIView *v in self.sidebar.subviews) [v removeFromSuperview];
    NSArray *icons = TabIcons();
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 300 + i;
        btn.layer.cornerRadius = 26;  // 52×52 → r26
        [btn setImage:SFSym(icons[i], 21, UIImageSymbolWeightSemibold)
             forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(sidebarTap:)
            forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
    }
    [self layoutSidebarButtons];
    [self refreshSidebarSelection];
}

- (void)layoutSidebarButtons {
    const CGFloat btnSz = 52, gap = 12;
    CGFloat total = 5 * btnSz + 4 * gap;
    CGFloat sbH = self.sidebar.bounds.size.height;
    if (sbH < 1) sbH = 400;
    CGFloat startY = (sbH - total) / 2.0;
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300 + i];
        if (!btn) continue;
        btn.frame = CGRectMake((70 - btnSz) / 2.0,
                               startY + i * (btnSz + gap),
                               btnSz, btnSz);
    }
}

- (void)refreshSidebarSelection {
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300 + i];
        if (!btn) continue;
        BOOL sel = (i == self.page);
        btn.backgroundColor   = sel ? UIColor.whiteColor
                                    : [UIColor colorWithWhite:1 alpha:0.10];
        btn.tintColor         = sel ? UIColor.blackColor
                                    : [UIColor colorWithWhite:1 alpha:0.55];
        btn.layer.borderWidth = sel ? 0 : 0.5;
        btn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.16].CGColor;
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

    // Fondo del header — coincide con la referencia
    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(10, 7, cw - 20, 40)];
    hdr.tag = 500;
    hdr.backgroundColor    = HeaderBG();
    hdr.layer.cornerRadius = 13;
    [self.contentArea addSubview:hdr];

    UIImageView *iv = [[UIImageView alloc] initWithImage:
        SFSym(TabIcons()[self.page], 14, UIImageSymbolWeightSemibold)];
    iv.tag = 501;
    iv.tintColor   = LblMain();
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.frame = CGRectMake(24, 18, 15, 15);
    [self.contentArea addSubview:iv];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(46, 10, cw - 110, 34)];
    title.tag       = 502;
    title.text      = TabNames()[self.page];
    title.textColor = LblMain();
    title.font      = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [self.contentArea addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.tag   = 503;
    close.frame = CGRectMake(cw - 42, 10, 30, 34);
    [close setImage:SFSym(@"xmark", 12, UIImageSymbolWeightBold) forState:UIControlStateNormal];
    close.tintColor = [UIColor colorWithWhite:1 alpha:0.38];
    [close addTarget:self action:@selector(closeMenu)
        forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:close];
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
- (CGFloat)contentWidth {
    CGFloat w = self.scroll.bounds.size.width;
    return (w > 10) ? w : 260;
}

// Toggle — label monolingüe (idioma activo)
- (CGFloat)addToggleEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key fallback:(BOOL)fb y:(CGFloat)y {
    CGFloat w = [self contentWidth];
    NSString *txt = DAAEStr(en, es, vi);
    DAAERow *row = [[DAAERow alloc] initWithLabel:txt on:ESPPrefsBool(key, fb) width:w];
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

// Sección
- (CGFloat)addSection:(NSString *)title y:(CGFloat)y {
    UILabel *l = [[UILabel alloc] initWithFrame:
        CGRectMake(4, y + 4, [self contentWidth] - 8, 20)];
    l.text      = title;
    l.textColor = SectionClr();
    l.font      = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    [self.scroll addSubview:l];
    return y + 30;
}

// Slider monolingüe
- (CGFloat)addSliderEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key min:(float)mn max:(float)mx fallback:(float)fb y:(CGFloat)y {
    CGFloat w   = [self contentWidth];
    NSString *t = DAAEStr(en, es, vi);
    DAAESlider *sl = [[DAAESlider alloc] initWithLabel:t key:key min:mn max:mx fallback:fb width:w];
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

// ─────────────────────────────────────────────────────────────────────────────
// buildPage
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildPage {
    const CGFloat offset = self.scroll.contentOffset.y;
    for (UIView *v in self.scroll.subviews) [v removeFromSuperview];
    [self.controls removeAllObjects];
    self.spinStatusLabel = nil;
    self.builtWidth = [self contentWidth];
    [self buildHeader];
    CGFloat y = 6;

    // ── TAB 0: ESP ────────────────────────────────────────────────────────────
    if (self.page == 0) {
        y = [self addToggleEN:@"ESP Master"  ES:@"Maestro ESP"   VI:@"Chế độ ESP"   key:@"ESPEnabled" fallback:YES y:y];
        y = [self addSection:@"— DRAW —" y:y];
        y = [self addToggleEN:@"Box ESP"     ES:@"Caja ESP"      VI:@"Hộp ESP"      key:@"Box"        fallback:YES y:y];
        y = [self addToggleEN:@"Line ESP"    ES:@"Ejes XYZ"      VI:@"Đường thẳng" key:@"Line"       fallback:NO  y:y];
        y = [self addToggleEN:@"Skeleton"    ES:@"Esqueleto"     VI:@"Xương"        key:@"Skeleton"   fallback:NO  y:y];
        y = [self addToggleEN:@"Head Dot"    ES:@"Punto cabeza"  VI:@"Chấm đầu"     key:@"HeadRedDot" fallback:NO  y:y];
        y = [self addToggleEN:@"Health Bar"  ES:@"Barra de vida" VI:@"Thanh máu"   key:@"Health"     fallback:YES y:y];
        y = [self addToggleEN:@"Name"        ES:@"Nombre"        VI:@"Tên"          key:@"Name"       fallback:YES y:y];
        y = [self addToggleEN:@"Distance"    ES:@"Distancia"     VI:@"Khoảng cách" key:@"Dis"        fallback:YES y:y];
        y = [self addToggleEN:@"Clean ESP"   ES:@"ESP limpio"    VI:@"ESP sạch"     key:@"CleanESP"   fallback:YES y:y];
        y = [self addSection:@"— FOV —" y:y];
        y = [self addToggleEN:@"Show FOV"    ES:@"Mostrar FOV"   VI:@"Hiện FOV"     key:@"ShowFov"    fallback:YES y:y];
        y = [self addSliderEN:@"FOV Size"    ES:@"Tamaño FOV"    VI:@"Cỡ FOV"
                          key:@"FovSize" min:5 max:48 fallback:40 y:y];

    // ── TAB 1: AIM ────────────────────────────────────────────────────────────
    } else if (self.page == 1) {
        y = [self addSection:@"— AIM TYPE —" y:y];

        // Lee el raw float — no usa AimModePolicy::ReadType para evitar que
        // valores como -1 sean normalizados a 0 por la política interna
        float aimRaw = AimRaw();   // -1 = sin aim, 0/1/2 = tipo
        NSInteger aimIdx = AimIdx();

        NSArray *aimEN = @[@"Aim Head",   @"Aim Neck",          @"Silent Aim"];
        NSArray *aimES = @[@"Apuntar cabeza",@"Apuntar cuello", @"Apuntado silencioso"];
        NSArray *aimVI = @[@"Bắn đầu",   @"Bắn cổ",           @"Bắn im lặng"];

        NSMutableArray<DAAERow *> *aimRows = [NSMutableArray array];
        for (NSInteger i = 0; i < 3; i++) {
            CGFloat w = [self contentWidth];
            NSString *txt = DAAEStr(aimEN[i], aimES[i], aimVI[i]);
            DAAERow *row = [[DAAERow alloc] initWithLabel:txt
                                                       on:(aimIdx == i) width:w];
            row.frame = CGRectMake(0, y, w, 60);
            [aimRows addObject:row];
            [self.scroll addSubview:row];
            y += 68;
        }
        for (NSInteger i = 0; i < 3; i++) {
            NSInteger idx = i;
            __weak NSMutableArray<DAAERow *> *wRows = aimRows;
            aimRows[i].onChanged = ^(BOOL on) {
                NSMutableArray<DAAERow *> *rows = wRows;
                if (on) {
                    // Activa este, desactiva los demás
                    for (NSInteger j = 0; j < (NSInteger)rows.count; j++) {
                        if (j != idx) {
                            rows[j].toggleOn = NO;
                            [rows[j].check setOn:NO animated:YES];
                            [UIView animateWithDuration:0.15
                                animations:^{ [rows[j] _applyStyle:NO]; }];
                        }
                    }
                    ESPPrefsSetFloat(@"AimType", (float)idx);
                    ESPPrefsSetFloat(@"AimActivation", static_cast<int>(
                        AimModePolicy::AfterTypeSelection(
                            AimModePolicy::ReadType((float)idx))));
                    ESPPrefsSetBool(@"SilentAim", NO);
                } else {
                    // Desactiva — todos quedan OFF, guarda -1 explícitamente
                    ESPPrefsSetFloat(@"AimType", -1);
                }
                ESPClearAimLock();
                ESPSyncFromPrefs();
            };
        }

        // Activation — solo visible si hay aim activo y no es Silent
        BOOL isSilent = (aimRaw >= 0 &&
                         AimModePolicy::ReadType(aimRaw) == AimModePolicy::Type::Silent);
        if (AimActive() && !isSilent) {
            y = [self addSection:@"— ACTIVATION —" y:y];
            NSArray *actEN = @[@"On Shoot",    @"On Scope",   @"Always",      @"Fire+Scope"];
            NSArray *actES = @[@"Al disparar", @"Al apuntar", @"Siempre",     @"Disparar+Scope"];
            NSArray *actVI = @[@"Khi bắn",     @"Khi ngắm",  @"Luôn luôn",  @"Bắn+Ngắm"];
            const NSInteger curAct = static_cast<int>(
                AimModePolicy::ReadActivation(ESPPrefsFloat(@"AimActivation", 0)));

            NSMutableArray<DAAERow *> *actRows = [NSMutableArray array];
            for (NSInteger i = 0; i < 4; i++) {
                CGFloat w = [self contentWidth];
                NSString *txt = DAAEStr(actEN[i], actES[i], actVI[i]);
                DAAERow *row = [[DAAERow alloc] initWithLabel:txt
                                                           on:(curAct == i + 1) width:w];
                row.frame = CGRectMake(0, y, w, 60);
                [actRows addObject:row];
                [self.scroll addSubview:row];
                y += 68;
            }
            for (NSInteger i = 0; i < 4; i++) {
                NSInteger choice = i + 1;
                __weak NSMutableArray<DAAERow *> *wAct = actRows;
                actRows[i].onChanged = ^(BOOL on) {
                    NSMutableArray<DAAERow *> *rows = wAct;
                    if (on) {
                        for (NSInteger j = 0; j < (NSInteger)rows.count; j++) {
                            if (j != (choice - 1)) {
                                rows[j].toggleOn = NO;
                                [rows[j].check setOn:NO animated:YES];
                                [UIView animateWithDuration:0.15
                                    animations:^{ [rows[j] _applyStyle:NO]; }];
                            }
                        }
                        ESPPrefsSetFloat(@"AimActivation", (float)choice);
                    } else {
                        ESPPrefsSetFloat(@"AimActivation", 0);
                    }
                    ESPClearAimLock();
                    ESPSyncFromPrefs();
                };
            }
        }

        y = [self addToggleEN:@"Aim Lag"     ES:@"Retraso de aim" VI:@"Trễ aim"          key:@"AimLag"           fallback:NO  y:y];
        y = [self addToggleEN:@"Target Line" ES:@"Línea objetivo"  VI:@"Đường mục tiêu"  key:@"AimTargetLine"    fallback:YES y:y];
        y = [self addToggleEN:@"AimKill"     ES:@"Matar con aim"   VI:@"Aim giết"         key:@"AutoFireFloating" fallback:NO  y:y];
        y = [self addSliderEN:@"FOV"         ES:@"FOV"             VI:@"FOV"
                          key:@"FovSize" min:5 max:48 fallback:40 y:y];
        y = [self addSection:@"— WEAPONS —" y:y];
        y = [self addToggleEN:@"Fast Fire"   ES:@"Disparo rápido"  VI:@"Bắn nhanh"        key:@"FastFire"         fallback:NO  y:y];
        y = [self addToggleEN:@"No Reload"   ES:@"Sin recarga"     VI:@"Không nạp đạn"   key:@"ShootNoReload"    fallback:NO  y:y];

    // ── TAB 2: COLORS ─────────────────────────────────────────────────────────
    } else if (self.page == 2) {
        CGFloat w = [self contentWidth];
        UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"Box", @"FOV"]];
        seg.frame = CGRectMake(0, y, w, 36);
        seg.selectedSegmentIndex = self.colorTarget;
        seg.selectedSegmentTintColor = [UIColor colorWithWhite:1 alpha:0.22];
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:LblMain(),
            NSFontAttributeName:[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]}
                            forState:UIControlStateNormal];
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:LblMain()}
                            forState:UIControlStateSelected];
        [seg addTarget:self action:@selector(colorTargetChanged:)
             forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:seg];
        [self.controls addObject:(UIControl *)seg];
        y += 46;

        NSString *pfx = (self.colorTarget == 0) ? @"BoxColor" : @"FovColor";
        float r = ESPPrefsFloat([pfx stringByAppendingString:@"R"], 0.46);
        float g = ESPPrefsFloat([pfx stringByAppendingString:@"G"], 0.86);
        float b = ESPPrefsFloat([pfx stringByAppendingString:@"B"], 0.73);

        UILabel *swatch = [[UILabel alloc] initWithFrame:CGRectMake(0, y, w, 50)];
        swatch.text = [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)round(r*255),(int)round(g*255),(int)round(b*255)];
        swatch.textAlignment   = NSTextAlignmentCenter;
        swatch.backgroundColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
        CGFloat lum = r*0.299 + g*0.587 + b*0.114;
        swatch.textColor   = lum > 0.6 ? UIColor.blackColor : UIColor.whiteColor;
        swatch.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        swatch.layer.cornerRadius = 14;
        swatch.clipsToBounds = YES;
        [self.scroll addSubview:swatch];
        y += 58;

        NSArray *rgbEN  = @[@"Red",  @"Green",   @"Blue"];
        NSArray *rgbES  = @[@"Rojo", @"Verde",   @"Azul"];
        NSArray *rgbVI  = @[@"Đỏ",   @"Xanh lá", @"Xanh dương"];
        NSArray *suf    = @[@"R",    @"G",       @"B"];
        float    def[3] = {0.46f,   0.86f,       0.73f};
        for (int i = 0; i < 3; i++)
            y = [self addSliderEN:rgbEN[i] ES:rgbES[i] VI:rgbVI[i]
                              key:[pfx stringByAppendingString:suf[i]]
                              min:0 max:1 fallback:def[i] y:y];

    // ── TAB 3: MISC ───────────────────────────────────────────────────────────
    } else if (self.page == 3) {
        y = [self addSection:@"— EXTRAS —" y:y];
        y = [self addToggleEN:@"Ghost"        ES:@"Fantasma"         VI:@"Bóng ma"            key:@"GhostModeFloating"  fallback:NO y:y];
        y = [self addToggleEN:@"FakeLag"      ES:@"Lag falso"        VI:@"Lag giả"            key:@"FakeLagFloating"    fallback:NO y:y];
        y = [self addToggleEN:@"Fly"          ES:@"Volar"            VI:@"Bay"                key:@"FlyFloating"        fallback:NO y:y];
        y = [self addToggleEN:@"Speed"        ES:@"Velocidad"        VI:@"Tốc độ"             key:@"RunSpeedFloating"   fallback:NO y:y];
        y = [self addToggleEN:@"Hide Buttons" ES:@"Ocultar botones"  VI:@"Ẩn nút"             key:@"HideFeatureButtons" fallback:NO y:y];
        y = [self addToggleEN:@"AimKill"      ES:@"Matar con aim"    VI:@"Aim giết"           key:@"AutoFireFloating"   fallback:NO y:y];

        y = [self addSection:@"— MOVEMENT —" y:y];
        y = [self addToggleEN:@"Speed Toggle" ES:@"Velocidad"        VI:@"Tốc độ"             key:@"RunSpeed"           fallback:NO y:y];
        y = [self addSliderEN:@"Speed Value"  ES:@"Velocidad (m/s)"  VI:@"Tốc độ (m/s)"
                          key:@"RunSpeedValue" min:1 max:15 fallback:6 y:y];
        if (ESPPrefsBool(@"FlyFloating", NO))
            y = [self addSliderEN:@"Fly Height" ES:@"Altura vuelo"   VI:@"Độ cao bay"
                              key:@"FlyHeight" min:1 max:6 fallback:4 y:y];

        y = [self addSection:@"— EFFECTS —" y:y];
        y = [self addToggleEN:@"Visual Spin"     ES:@"Giro visual"       VI:@"Xoay hiển thị"
                          key:@"VisualSpin" fallback:NO y:y];
        if (ESPPrefsBool(@"VisualSpin", NO)) {
            y = [self addSliderEN:@"Spin Speed"  ES:@"Vel. giro"         VI:@"Tốc độ xoay"
                              key:@"VisualSpinSpeed" min:0.1 max:3 fallback:0.5 y:y];
            self.spinStatusLabel = [[UILabel alloc] initWithFrame:
                CGRectMake(4, y, [self contentWidth]-8, 34)];
            self.spinStatusLabel.textColor    = SectionClr();
            self.spinStatusLabel.font         = [UIFont systemFontOfSize:11];
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

        // Selector de idioma — 3 botones, solo el activo resaltado
        y = [self addSection:@"— LANGUAGE —" y:y];
        UIView *langRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 52)];
        langRow.backgroundColor    = RowOFF();
        langRow.layer.cornerRadius = 14;
        NSArray *codes     = @[@"EN", @"ES", @"VI"];
        NSArray *fullNames = @[@"English", @"Español", @"Tiếng Việt"];
        NSInteger curLang  = DAAELang();
        CGFloat lbtnW = (w - 32 - 12) / 3.0;
        for (NSInteger k = 0; k < 3; k++) {
            UIButton *lb = [UIButton buttonWithType:UIButtonTypeCustom];
            lb.frame = CGRectMake(16 + k * (lbtnW + 6), 10, lbtnW, 32);
            lb.backgroundColor    = (k == curLang) ? UIColor.whiteColor
                                                    : [UIColor colorWithWhite:1 alpha:0.08];
            lb.layer.cornerRadius = 10;
            [lb setTitle:codes[k] forState:UIControlStateNormal];
            lb.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
            [lb setTitleColor:(k == curLang) ? UIColor.blackColor : LblMain()
                     forState:UIControlStateNormal];
            objc_setAssociatedObject(lb, "langIdx", @(k), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [lb addTarget:self action:@selector(langTap:)
                forControlEvents:UIControlEventTouchUpInside];
            [langRow addSubview:lb];
        }
        [self.scroll addSubview:langRow];
        y += 60;

        // Nombre del idioma activo debajo
        UILabel *lhint = [[UILabel alloc] initWithFrame:CGRectMake(0, y, w, 18)];
        lhint.text          = fullNames[curLang];
        lhint.textColor     = SectionClr();
        lhint.font          = [UIFont systemFontOfSize:11];
        lhint.textAlignment = NSTextAlignmentCenter;
        [self.scroll addSubview:lhint];
        y += 26;

        // Info
        y = [self addSection:@"— INFO —" y:y];
        typedef struct { NSString *t; NSString *v; BOOL dim; } InfoEntry;
        InfoEntry entries[4] = {
            {@"Product",   @"DAAE IOS",         NO},
            {@"Creator",   @"@didierxit7",       NO},
            {@"Telegram",  @"t.me/didierxit7",   NO},
            {@"Key",       @"TEST",              YES},
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
    credit.textColor     = [UIColor colorWithWhite:1 alpha:0.13];
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
}

- (void)applyMinimalESP {
    for (NSString *k in @[@"ESPEnabled",@"Box",@"Health",@"Name",@"Dis",@"CleanESP"])
        ESPPrefsSetBool(k, YES);
    for (NSString *k in @[@"Line",@"Skeleton",@"HeadRedDot",@"Box3D",@"BalancedRender"])
        ESPPrefsSetBool(k, NO);
    for (NSString *pfx in @[@"BoxColor",@"LineColor",@"FovColor"]) {
        ESPPrefsSetFloat([pfx stringByAppendingString:@"R"], 0.46);
        ESPPrefsSetFloat([pfx stringByAppendingString:@"G"], 0.86);
        ESPPrefsSetFloat([pfx stringByAppendingString:@"B"], 0.73);
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

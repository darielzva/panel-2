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
// HELPERS SF SYMBOLS
// ─────────────────────────────────────────────────────────────────────────────
static UIImage *SFSym(NSString *name, CGFloat pts, UIImageSymbolWeight w) {
    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:pts weight:w];
    return [UIImage systemImageNamed:name withConfiguration:cfg];
}

// ─────────────────────────────────────────────────────────────────────────────
// ACENTO — blanco por defecto, cambiable
// Key guardada en NSUserDefaults: "DAAE.accentIdx"
// 0 Blanco 1 Celeste 2 Amarillo 3 Rojo 4 Rosa 5 Verde
// ─────────────────────────────────────────────────────────────────────────────
static NSArray<UIColor *> *DAAEAccents(void) {
    static NSArray *a;
    static dispatch_once_t t;
    dispatch_once(&t, ^{
        a = @[
            [UIColor colorWithWhite:1.0 alpha:1.0],                              // 0 blanco
            [UIColor colorWithRed:0.28 green:0.72 blue:1.00 alpha:1.0],          // 1 celeste
            [UIColor colorWithRed:1.00 green:0.85 blue:0.20 alpha:1.0],          // 2 amarillo
            [UIColor colorWithRed:1.00 green:0.27 blue:0.27 alpha:1.0],          // 3 rojo
            [UIColor colorWithRed:1.00 green:0.45 blue:0.75 alpha:1.0],          // 4 rosa
            [UIColor colorWithRed:0.25 green:0.88 blue:0.62 alpha:1.0],          // 5 verde
        ];
    });
    return a;
}

static NSInteger DAAEAccentIdx(void) {
    NSInteger idx = [[NSUserDefaults standardUserDefaults] integerForKey:@"DAAE.accentIdx"];
    if (idx < 0 || idx >= (NSInteger)DAAEAccents().count) idx = 0;
    return idx;
}
static UIColor *DAAEAccent(void) { return DAAEAccents()[DAAEAccentIdx()]; }

// ─────────────────────────────────────────────────────────────────────────────
// IDIOMA — ES por defecto, EN / VI
// Key: "DAAE.lang"  0=ES 1=EN 2=VI
// ─────────────────────────────────────────────────────────────────────────────
static NSInteger DAAELang(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.lang"]) [ud setInteger:0 forKey:@"DAAE.lang"];
    NSInteger v = [ud integerForKey:@"DAAE.lang"];
    return (v >= 0 && v <= 2) ? v : 0;
}
static void DAAESetLang(NSInteger l) {
    [[NSUserDefaults standardUserDefaults] setInteger:l forKey:@"DAAE.lang"];
}

// Devuelve string según idioma actual  (idx 0=ES 1=EN 2=VI)
static NSString *TR(NSString *es, NSString *en, NSString *vi) {
    switch (DAAELang()) {
        case 1:  return en;
        case 2:  return vi;
        default: return es;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHECKMARK PILL — igual a las imágenes
// Círculo con ✓ cuando ON, círculo vacío con borde cuando OFF
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAECheck : UIView
@property (nonatomic, assign) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end
@implementation DAAECheck {
    UIImageView *_checkIV;
}
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.layer.cornerRadius  = f.size.width / 2.0;
        self.layer.borderWidth   = 1.2;
        self.userInteractionEnabled = NO;
        UIImage *img = SFSym(@"checkmark", 12, UIImageSymbolWeightHeavy);
        _checkIV = [[UIImageView alloc] initWithImage:img];
        _checkIV.tintColor       = UIColor.blackColor;
        _checkIV.frame           = CGRectInset(self.bounds, 4, 4);
        _checkIV.contentMode     = UIViewContentModeScaleAspectFit;
        [self addSubview:_checkIV];
        [self setOn:NO animated:NO];
    }
    return self;
}
- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }
- (void)setOn:(BOOL)on animated:(BOOL)anim {
    _on = on;
    void (^upd)(void) = ^{
        self.backgroundColor       = on ? DAAEAccent() : [UIColor clearColor];
        self.layer.borderColor     = on ? [UIColor clearColor].CGColor
                                       : [UIColor colorWithWhite:1 alpha:0.35].CGColor;
        self->_checkIV.hidden      = !on;
        self->_checkIV.tintColor   = [UIColor colorWithWhite:0.1 alpha:1.0];
    };
    if (anim)
        [UIView animateWithDuration:0.18 delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:upd completion:nil];
    else upd();
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE ROW — borde pill + label + checkmark (layout de las imágenes)
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAEToggleRow : UIButton
@property (nonatomic, strong) DAAECheck *check;
@property (nonatomic, assign) BOOL toggleOn;
@property (nonatomic, copy)   void (^onChanged)(BOOL);
@property (nonatomic, strong) UIView *glowView;
@end
@implementation DAAEToggleRow
- (instancetype)initWithTitle:(NSString *)title on:(BOOL)on width:(CGFloat)w {
    BOOL dark = ESPPrefsBool(@"DarkTheme", YES);
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, 50)])) {
        self.backgroundColor       = dark ? [UIColor colorWithWhite:1 alpha:0.07]
                                          : [UIColor colorWithWhite:0 alpha:0.05];
        self.layer.cornerRadius    = 14;
        self.layer.borderWidth     = 0.6;
        self.layer.borderColor     = dark ? [UIColor colorWithWhite:1 alpha:0.12].CGColor
                                          : [UIColor colorWithWhite:0 alpha:0.10].CGColor;
        self.clipsToBounds         = YES;
        self.toggleOn = on;

        // Glow background — detrás de todo
        self.glowView = [[UIView alloc] initWithFrame:self.bounds];
        self.glowView.layer.cornerRadius = 14;
        self.glowView.userInteractionEnabled = NO;
        self.glowView.backgroundColor = on ? [DAAEAccent() colorWithAlphaComponent:0.13]
                                           : [UIColor clearColor];
        [self insertSubview:self.glowView atIndex:0];

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(18, 0, w - 70, 50)];
        lbl.text      = title;
        lbl.textColor = dark ? [UIColor colorWithWhite:0.95 alpha:1.0]
                             : [UIColor colorWithWhite:0.08 alpha:1.0];
        lbl.font      = [UIFont systemFontOfSize:15.5 weight:UIFontWeightMedium];
        lbl.adjustsFontSizeToFitWidth = YES;
        lbl.minimumScaleFactor = 0.75;
        [self addSubview:lbl];

        self.check = [[DAAECheck alloc] initWithFrame:CGRectMake(w - 46, 12, 26, 26)];
        [self.check setOn:on animated:NO];
        [self addSubview:self.check];

        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)_tap {
    self.toggleOn = !self.toggleOn;
    [self.check setOn:self.toggleOn animated:YES];
    UIView *glow = self.glowView;
    BOOL nowOn = self.toggleOn;
    [UIView animateWithDuration:0.18 delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        glow.backgroundColor = nowOn ? [DAAEAccent() colorWithAlphaComponent:0.13]
                                     : [UIColor clearColor];
    } completion:nil];
    if (self.onChanged) self.onChanged(self.toggleOn);
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL — texto en mayúscula con color muted
// ─────────────────────────────────────────────────────────────────────────────
static UILabel *DAAESectionLabel(NSString *title, CGFloat w) {
    BOOL dark = ESPPrefsBool(@"DarkTheme", YES);
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(6, 0, w - 12, 22)];
    l.text      = [title uppercaseString];
    l.textColor = dark ? [UIColor colorWithWhite:1 alpha:0.40]
                       : [UIColor colorWithWhite:0.08 alpha:0.55];
    l.font      = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    return l;
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDER ROW
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAESliderRow : UIView
@end
@implementation DAAESliderRow
- (instancetype)initWithTitle:(NSString *)title key:(NSString *)key
                          min:(float)mn max:(float)mx fallback:(float)fb
                        width:(CGFloat)w onChanged:(void(^)(float))cb {
    BOOL dark = ESPPrefsBool(@"DarkTheme", YES);
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, 68)])) {
        self.backgroundColor    = dark ? [UIColor colorWithWhite:1 alpha:0.07]
                                       : [UIColor colorWithWhite:0 alpha:0.05];
        self.layer.cornerRadius = 14;
        self.layer.borderWidth  = 0.6;
        self.layer.borderColor  = dark ? [UIColor colorWithWhite:1 alpha:0.12].CGColor
                                       : [UIColor colorWithWhite:0 alpha:0.10].CGColor;

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(18, 8, w - 100, 20)];
        lbl.text      = title;
        lbl.textColor = dark ? [UIColor colorWithWhite:0.95 alpha:1.0]
                             : [UIColor colorWithWhite:0.08 alpha:1.0];
        lbl.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [self addSubview:lbl];

        UILabel *val = [[UILabel alloc] initWithFrame:CGRectMake(w - 70, 6, 54, 22)];
        val.textAlignment = NSTextAlignmentCenter;
        val.textColor     = UIColor.blackColor;
        val.font          = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
        val.backgroundColor   = DAAEAccent();
        val.layer.cornerRadius = 10;
        val.clipsToBounds     = YES;
        float cur = ESPPrefsFloat(key, fb);
        val.text = [NSString stringWithFormat:@"%.0f", cur];
        [self addSubview:val];

        UISlider *sl = [[UISlider alloc] initWithFrame:CGRectMake(14, 36, w - 28, 24)];
        sl.minimumValue          = mn;
        sl.maximumValue          = mx;
        sl.value                 = cur;
        sl.minimumTrackTintColor = DAAEAccent();
        sl.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.18];
        sl.thumbTintColor        = UIColor.whiteColor;
        objc_setAssociatedObject(sl, "valLbl", val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(sl, "espKey", key, OBJC_ASSOCIATION_COPY_NONATOMIC);
        void (^cbCopy)(float) = [cb copy];
        objc_setAssociatedObject(sl, "cb", cbCopy, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [sl addTarget:self action:@selector(_slid:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:sl];
    }
    return self;
}
- (void)_slid:(UISlider *)sl {
    UILabel *val = objc_getAssociatedObject(sl, "valLbl");
    NSString *key = objc_getAssociatedObject(sl, "espKey");
    void (^cb)(float) = objc_getAssociatedObject(sl, "cb");
    val.text = [NSString stringWithFormat:@"%.0f", sl.value];
    ESPPrefsSetFloat(key, sl.value);
    ESPSyncFromPrefs();
    if (cb) cb(sl.value);
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MAIN PANEL  _0xDEADBEEE
// ─────────────────────────────────────────────────────────────────────────────
@interface _0xDEADBEEE () <UIGestureRecognizerDelegate>
// Layout principal
@property (nonatomic, strong) UIVisualEffectView *blurBG;
@property (nonatomic, strong) UIView             *panel;
@property (nonatomic, strong) UIView             *sidebar;
@property (nonatomic, strong) UIView             *contentArea;
@property (nonatomic, strong) UIScrollView       *scroll;
// Estado
@property (nonatomic, assign) NSInteger  page;       // 0=Aims 1=ESP 2=Misc 3=Colors 4=Settings
@property (nonatomic, assign) BOOL       darkMode;
@property (nonatomic, assign) BOOL       aimExpanded;
@property (nonatomic, assign) BOOL       advancedExpanded;
@property (nonatomic, assign) CGFloat    builtWidth;
@property (nonatomic, strong) NSMutableArray<UIControl *> *controls;
// Spin
@property (nonatomic, strong) UILabel  *spinStatusLabel;
@property (nonatomic, strong) NSTimer  *spinStatusTimer;
// Drag
@property (nonatomic, assign) NSInteger pointer;
@property (nonatomic, assign) CGPoint   began;
@property (nonatomic, assign) CGPoint   panelOrigin;
@property (nonatomic, assign) CGFloat   scrollOrigin;
@property (nonatomic, assign) BOOL      dragging;
@property (nonatomic, assign) BOOL      scrolling;
@property (nonatomic, strong) UIControl *activeControl;
@end

@implementation _0xDEADBEEE

// ── defaults primera vez ──────────────────────────────────────────────────────
- (void)applyDefaults {
    NSDictionary *defaults = @{
        @"ESPEnabled":@NO, @"Box":@NO, @"Box3D":@NO, @"CleanESP":@NO,
        @"Name":@NO, @"Health":@NO, @"Line":@NO, @"Skeleton":@NO,
        @"HeadRedDot":@NO, @"Dis":@NO, @"ShowFov":@YES,
        @"AimLag":@NO, @"AimTargetLine":@NO, @"SilentAim":@NO,
        @"AutoFire":@NO, @"AutoFireFloating":@NO, @"FastFire":@NO,
        @"ShootNoReload":@NO, @"GhostModeFloating":@NO, @"FakeLagFloating":@NO,
        @"FlyFloating":@NO, @"RunSpeedFloating":@NO, @"RunSpeed":@NO,
        @"VisualSpin":@NO, @"AnLive":@NO, @"DarkTheme":@YES,
        @"BalancedRender":@NO,
        @"AimType":@(0.0f), @"AimActivation":@(1.0f),
        @"FovSize":@(40.0f), @"SilentFovSize":@(18.0f),
    };
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if ([ud objectForKey:@"_MizzeDefaultsApplied"]) return;
    for (NSString *key in defaults) {
        id val = defaults[key];
        if ([val isKindOfClass:NSNumber.class]) {
            const char *t = ((NSNumber *)val).objCType;
            if (strcmp(t,@encode(BOOL))==0||strcmp(t,@encode(bool))==0||strcmp(t,@encode(char))==0)
                ESPPrefsSetBool(key, ((NSNumber *)val).boolValue);
            else
                ESPPrefsSetFloat(key, ((NSNumber *)val).floatValue);
        }
    }
    ESPPrefsSetBool(@"ExplicitAimMenuV1", YES);
    [ud setBool:YES forKey:@"_MizzeDefaultsApplied"];
    [ud synchronize];
    ESPSyncFromPrefs();
}

// ── viewDidLoad ───────────────────────────────────────────────────────────────
- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyDefaults];
    MizzePrepareMenuPrefs();
    self.darkMode = ESPPrefsBool(@"DarkTheme", YES);
    self.pointer  = -1;
    self.controls = [NSMutableArray array];
    self.view.backgroundColor = UIColor.clearColor;

    // Spin timer
    __weak _0xDEADBEEE *ws = self;
    self.spinStatusTimer = [NSTimer scheduledTimerWithTimeInterval:.5 repeats:YES
        block:^(NSTimer *_){ _0xDEADBEEE *s=ws;
            if(s.isViewLoaded&&s.view.window&&!s.view.hidden&&s.spinStatusLabel)
                [s updateSpinStatus]; }];

    // Panel + blur  — tamaño igual al de las imágenes
    self.blurBG = [[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    self.blurBG.layer.cornerRadius = 22;
    self.blurBG.clipsToBounds = YES;
    [self.view addSubview:self.blurBG];

    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.32];
    self.panel.layer.cornerRadius = 22;
    self.panel.layer.borderWidth  = 0.7;
    self.panel.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
    self.panel.clipsToBounds = YES;
    [self.view addSubview:self.panel];

    // Sidebar izquierda — ancho 70 igual a las imágenes
    self.sidebar = [[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.06];
    [self.panel addSubview:self.sidebar];

    // Línea divisoria sidebar / contenido
    UIView *div = [[UIView alloc] initWithFrame:CGRectZero];
    div.tag = 99;
    div.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    [self.panel addSubview:div];

    // Área de contenido (header + scroll)
    self.contentArea = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentArea.backgroundColor = UIColor.clearColor;
    [self.panel addSubview:self.contentArea];

    // Scroll
    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator = NO;
    self.scroll.bounces = YES;
    [self.contentArea addSubview:self.scroll];

    // Pan drag en sidebar y contentArea
    UIPanGestureRecognizer *panA = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(dragPanel:)];
    panA.delegate = self;
    [self.sidebar addGestureRecognizer:panA];

    UIPanGestureRecognizer *panB = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(dragPanel:)];
    panB.delegate = self;
    [self.contentArea addGestureRecognizer:panB];

    [self buildSidebar];
    [self buildPage];
}

// ── layout ────────────────────────────────────────────────────────────────────
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sw = self.view.bounds.size.width;
    CGFloat sh = self.view.bounds.size.height;
    if (sw <= 0) sw = 320; if (sh <= 0) sh = 480;

    // Tamaño del panel: ~360 wide × ~300 tall — igual al de las imágenes
    CGFloat pw = MIN(380.0, MAX(220.0, sw - 32.0));
    CGFloat ph = MIN(320.0, MAX(200.0, sh - 48.0));

    CGRect f = self.panel.frame;
    if (f.size.width == 0) {
        f = CGRectMake((sw - pw) / 2, (sh - ph) / 2, pw, ph);
    } else {
        f.size = CGSizeMake(pw, ph);
        f.origin.x = MAX(8, MIN(f.origin.x, sw - pw - 8));
        f.origin.y = MAX(8, MIN(f.origin.y, sh - ph - 8));
    }
    self.panel.frame  = f;
    self.blurBG.frame = f;

    // Sidebar: 70 px ancho, altura completa
    // No mask — el panel tiene clipsToBounds=YES y cornerRadius=22, hereda el clip
    CGFloat sbW = 70.0;
    self.sidebar.frame = CGRectMake(0, 0, sbW, ph);
    self.sidebar.layer.mask = nil;

    UIView *div = [self.panel viewWithTag:99];
    div.frame = CGRectMake(sbW, 0, 0.6, ph);

    // Content area: resto ancho
    CGFloat caX = sbW + 0.6;
    self.contentArea.frame = CGRectMake(caX, 0, pw - caX, ph);

    // Scroll debajo del header (44px)
    CGFloat headerH = 44.0;
    self.scroll.frame = CGRectMake(0, headerH, pw - caX, ph - headerH);

    if (fabs(self.builtWidth - self.scroll.bounds.size.width) > 0.5) [self buildPage];

    [self refreshSidebarSelection];
}

// ── sidebar ───────────────────────────────────────────────────────────────────
- (void)buildSidebar {
    // 5 tabs: Aims(mira) ESP(ojo) Misc(caja) Colors(paleta) Settings(engranaje)
    // tag 300-304
    NSArray *icons = @[@"scope", @"eye.fill", @"cube.box.fill",
                       @"paintpalette.fill", @"gearshape.fill"];
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 300 + i;
        CGFloat btnW = 46, btnH = 46;
        btn.frame = CGRectMake((70 - btnW) / 2, 18 + i * 52, btnW, btnH);
        btn.layer.cornerRadius = 23;
        btn.layer.borderWidth  = 0.7;
        UIImage *img = SFSym(icons[i], 19, UIImageSymbolWeightSemibold);
        [btn setImage:img forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(sidebarTap:)
            forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
    }
    [self refreshSidebarSelection];
}

- (void)refreshSidebarSelection {
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300 + i];
        if (!btn) continue;
        BOOL sel = (i == self.page);
        btn.backgroundColor   = sel ? UIColor.whiteColor
                                    : [UIColor colorWithWhite:1 alpha:0.10];
        btn.tintColor         = sel ? UIColor.blackColor
                                    : [UIColor colorWithWhite:0.85 alpha:1.0];
        btn.layer.borderColor = sel ? [UIColor clearColor].CGColor
                                    : [UIColor colorWithWhite:1 alpha:0.20].CGColor;
    }
}

- (void)sidebarTap:(UIButton *)sender {
    NSInteger newPage = sender.tag - 300;
    if (newPage == self.page) return;
    self.page = newPage;
    self.scroll.contentOffset = CGPointZero;
    [self refreshSidebarSelection];
    [self rebuildAnimated];
}

// ── header dinámico ───────────────────────────────────────────────────────────
- (void)buildHeader {
    // Limpia vistas con tag 500-510
    for (UIView *v in self.contentArea.subviews)
        if (v.tag >= 500 && v.tag < 600) [v removeFromSuperview];

    CGFloat cw = self.contentArea.bounds.size.width;
    NSArray *tabIcons = @[@"scope", @"eye.fill", @"cube.box.fill",
                          @"paintpalette.fill", @"gearshape.fill"];
    NSArray *tabNamesES = @[@"Aims", @"ESP", @"Misc", @"Colores", @"Ajustes"];
    NSArray *tabNamesEN = @[@"Aims", @"ESP", @"Misc", @"Colors", @"Settings"];
    NSArray *tabNamesVI = @[@"Aims", @"ESP", @"Khác", @"Màu sắc", @"Cài đặt"];

    NSArray *tabNames = (DAAELang()==1) ? tabNamesEN : (DAAELang()==2) ? tabNamesVI : tabNamesES;

    // Fondo header
    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(0, 0, cw, 44)];
    hdr.tag = 500;
    hdr.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
    hdr.layer.borderWidth = 0;
    [self.contentArea addSubview:hdr];

    // Línea separadora bajo header
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(0, 43.5, cw, 0.5)];
    sep.tag = 501;
    sep.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
    [self.contentArea addSubview:sep];

    // Icono de la tab activa
    UIImageView *iv = [[UIImageView alloc] initWithImage:
        SFSym(tabIcons[self.page], 14, UIImageSymbolWeightSemibold)];
    iv.tag = 502;
    iv.tintColor = DAAEAccent();
    iv.frame = CGRectMake(14, 14, 16, 16);
    iv.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentArea addSubview:iv];

    // Título de la tab
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(36, 0, cw - 82, 44)];
    title.tag = 503;
    title.text = tabNames[self.page];
    title.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    title.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [self.contentArea addSubview:title];

    // Botón luna/sol — esquina derecha
    UIButton *moonBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    moonBtn.tag = 504;
    moonBtn.frame = CGRectMake(cw - 70, 8, 28, 28);
    UIImage *moonImg = SFSym(self.darkMode ? @"moon.fill" : @"sun.max.fill",
                              15, UIImageSymbolWeightSemibold);
    [moonBtn setImage:moonImg forState:UIControlStateNormal];
    moonBtn.tintColor = [UIColor colorWithWhite:0.75 alpha:1.0];
    [moonBtn addTarget:self action:@selector(toggleTheme)
        forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:moonBtn];

    // Botón cerrar
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.tag = 505;
    closeBtn.frame = CGRectMake(cw - 38, 8, 28, 28);
    UIImage *xImg = SFSym(@"xmark", 12, UIImageSymbolWeightBold);
    [closeBtn setImage:xImg forState:UIControlStateNormal];
    closeBtn.tintColor = [UIColor colorWithWhite:0.55 alpha:1.0];
    [closeBtn addTarget:self action:@selector(closeMenu)
        forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:closeBtn];
}

// ── helpers de construcción ───────────────────────────────────────────────────
- (CGFloat)contentWidth {
    return self.scroll.bounds.size.width > 10 ? self.scroll.bounds.size.width : 280;
}

- (CGFloat)addToggle:(NSString *)title key:(NSString *)key fallback:(BOOL)fb y:(CGFloat)y {
    CGFloat w = [self contentWidth];
    DAAEToggleRow *row = [[DAAEToggleRow alloc] initWithTitle:title on:ESPPrefsBool(key, fb) width:w];
    row.frame = CGRectMake(0, y, w, 50);
    objc_setAssociatedObject(row, "espKey", key, OBJC_ASSOCIATION_COPY_NONATOMIC);
    __weak DAAEToggleRow *wrow = row;
    __weak _0xDEADBEEE  *ws   = self;
    row.onChanged = ^(BOOL on) {
        NSString *k = objc_getAssociatedObject(wrow, "espKey");
        ESPPrefsSetBool(k, on);
        ESPSyncFromPrefs();
        [ws toggleChanged:k value:on];
    };
    [self.controls addObject:row];
    [self.scroll addSubview:row];
    return y + 56;
}

- (CGFloat)addSection:(NSString *)title y:(CGFloat)y {
    UILabel *l = DAAESectionLabel(title, [self contentWidth]);
    l.frame = CGRectMake(4, y + 6, [self contentWidth] - 8, 22);
    [self.scroll addSubview:l];
    return y + 32;
}

- (CGFloat)addSlider:(NSString *)title key:(NSString *)key
                 min:(float)mn max:(float)mx fallback:(float)fb y:(CGFloat)y {
    CGFloat w = [self contentWidth];
    DAAESliderRow *row = [[DAAESliderRow alloc]
        initWithTitle:title key:key min:mn max:mx fallback:fb width:w onChanged:nil];
    row.frame = CGRectMake(0, y, w, 68);
    [self.controls addObject:(UIControl *)row];
    [self.scroll addSubview:row];
    return y + 74;
}

// ── rebuildAnimated ───────────────────────────────────────────────────────────
- (void)rebuildAnimated {
    if (UIAccessibilityIsReduceMotionEnabled()) { [self buildPage]; return; }
    [UIView transitionWithView:self.scroll duration:0.18
        options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionAllowUserInteraction
        animations:^{ [self buildPage]; } completion:nil];
}

// ── buildPage — toda la lógica original preservada ────────────────────────────
- (void)buildPage {
    const CGFloat offset = self.scroll.contentOffset.y;
    for (UIView *v in self.scroll.subviews) [v removeFromSuperview];
    [self.controls removeAllObjects];
    self.spinStatusLabel = nil;
    self.builtWidth = [self contentWidth];

    // Actualiza fondo según modo oscuro/claro
    self.panel.backgroundColor =
        self.darkMode ? [UIColor colorWithWhite:0 alpha:0.32]
                      : [UIColor colorWithWhite:1 alpha:0.18];
    self.blurBG.effect = [UIBlurEffect effectWithStyle:
        self.darkMode ? UIBlurEffectStyleSystemUltraThinMaterialDark
                      : UIBlurEffectStyleSystemUltraThinMaterial];

    [self buildHeader];

    CGFloat y = 6;

    // ── PAGE 0: AIMS ──────────────────────────────────────────────────────────
    if (self.page == 0) {
        // Chooser tipo aim
        NSArray *aimNames = @[
            TR(@"Aim Cabeza", @"Head Aim",   @"Aim Đầu"),
            TR(@"Aim Cuello", @"Neck Aim",   @"Aim Cổ"),
            @"Silent Aim"
        ];
        const NSInteger type = static_cast<int>(
            AimModePolicy::ReadType(ESPPrefsFloat(@"AimType",0)));
        UIButton *chooser = [UIButton buttonWithType:UIButtonTypeSystem];
        chooser.frame = CGRectMake(0, y, [self contentWidth], 48);
        chooser.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
        chooser.layer.cornerRadius = 14;
        chooser.layer.borderWidth  = 0.6;
        chooser.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
        chooser.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        chooser.contentEdgeInsets = UIEdgeInsetsMake(0,16,0,16);
        [chooser setTitle:[NSString stringWithFormat:@"%@  %@",
            TR(@"Tipo de aim", @"Aim type", @"Loại aim"),
            self.aimExpanded ? @"▴" : @"▾"] forState:UIControlStateNormal];
        [chooser setTitleColor:DAAEAccent() forState:UIControlStateNormal];
        chooser.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [chooser addTarget:self action:@selector(chooseAim) forControlEvents:UIControlEventTouchUpInside];
        [self.scroll addSubview:chooser];
        y += 54;

        if (self.aimExpanded) {
            NSMutableArray<DAAEToggleRow *> *aimRows = [NSMutableArray array];
            for (NSUInteger i = 0; i < aimNames.count; i++) {
                DAAEToggleRow *row = [[DAAEToggleRow alloc]
                    initWithTitle:aimNames[i] on:(type == (NSInteger)i) width:[self contentWidth]];
                row.frame = CGRectMake(0, y, [self contentWidth], 50);
                [aimRows addObject:row];
                [self.scroll addSubview:row];
                y += 56;
            }
            // Asignar onChanged después de tener todas las filas — exclusividad
            for (NSUInteger i = 0; i < aimRows.count; i++) {
                NSUInteger idx = i;
                __weak NSMutableArray<DAAEToggleRow *> *wRows = aimRows;
                aimRows[i].onChanged = ^(BOOL on) {
                    if (!on) return;
                    // Desactivar todas las demás visualmente
                    NSMutableArray<DAAEToggleRow *> *rows = wRows;
                    for (NSUInteger j = 0; j < rows.count; j++) {
                        if (j != idx) [rows[j].check setOn:NO animated:YES];
                        if (j != idx) rows[j].toggleOn = NO;
                    }
                    ESPPrefsSetFloat(@"AimType", (float)idx);
                    ESPPrefsSetFloat(@"AimActivation", static_cast<int>(
                        AimModePolicy::AfterTypeSelection(AimModePolicy::ReadType((float)idx))));
                    ESPPrefsSetBool(@"SilentAim", NO);
                    ESPClearAimLock(); ESPSyncFromPrefs();
                };
            }
        }

        const BOOL silent = AimModePolicy::ReadType(ESPPrefsFloat(@"AimType",0)) == AimModePolicy::Type::Silent;
        if (silent) {
            y = [self addToggle:TR(@"Activar Silent Aim",@"Enable Silent Aim",@"Bật Silent Aim")
                            key:@"SilentAim" fallback:NO y:y];
        } else {
            y = [self addSection:TR(@"Activación",@"Activation",@"Kích hoạt") y:y];
            // Activation picker — 2 columnas
            NSArray *actNames = @[
                TR(@"Al disparar",@"When firing",@"Khi bắn"),
                TR(@"Al apuntar",@"When aiming",@"Khi ngắm"),
                TR(@"Siempre",@"Always",@"Luôn luôn"),
                TR(@"Fire+Scope",@"Fire+Scope",@"Bắn+Ngắm")
            ];
            const NSInteger mode = static_cast<int>(
                AimModePolicy::ReadActivation(ESPPrefsFloat(@"AimActivation",0)));
            CGFloat hw = ([self contentWidth] - 6) / 2.0;
            NSMutableArray<DAAEToggleRow *> *actRows = [NSMutableArray array];
            for (NSUInteger i = 0; i < actNames.count; i++) {
                DAAEToggleRow *row = [[DAAEToggleRow alloc]
                    initWithTitle:actNames[i] on:(mode == (NSInteger)(i+1)) width:hw];
                row.frame = CGRectMake((i%2) * (hw + 6), y + (i/2) * 56, hw, 50);
                [actRows addObject:row];
                [self.scroll addSubview:row];
            }
            // Exclusividad: solo una opción activa a la vez
            for (NSUInteger i = 0; i < actRows.count; i++) {
                NSUInteger choice = i + 1;
                __weak NSMutableArray<DAAEToggleRow *> *wActRows = actRows;
                actRows[i].onChanged = ^(BOOL on) {
                    if (!on) return;
                    NSMutableArray<DAAEToggleRow *> *rows = wActRows;
                    for (NSUInteger j = 0; j < rows.count; j++) {
                        if (j != (choice - 1)) [rows[j].check setOn:NO animated:YES];
                        if (j != (choice - 1)) rows[j].toggleOn = NO;
                    }
                    ESPPrefsSetFloat(@"AimActivation", (float)choice);
                    ESPClearAimLock(); ESPSyncFromPrefs();
                };
            }
            y += 118;
        }

        y = [self addToggle:TR(@"Aimlag al apuntar",@"Aimlag",@"Aimlag khi ngắm")
                        key:@"AimLag" fallback:NO y:y];
        y = [self addToggle:TR(@"Línea al objetivo",@"Target line",@"Dây tới mục tiêu")
                        key:@"AimTargetLine" fallback:YES y:y];
        y = [self addSlider:@"FOV"
                        key:(silent || ESPPrefsBool(@"AutoFire",NO)) ? @"SilentFovSize" : @"FovSize"
                        min:5 max:48
                   fallback:(silent || ESPPrefsBool(@"AutoFire",NO)) ? 18 : 40 y:y];
        y = [self addToggle:TR(@"Mostrar FOV",@"Show FOV",@"Hiện vòng FOV")
                        key:@"ShowFov" fallback:YES y:y];
        y = [self addToggle:@"AimKill"
                        key:@"AutoFireFloating" fallback:NO y:y];
        if (silent || ESPPrefsBool(@"AutoFireFloating",NO))
            y = [self addSlider:TR(@"% Headshot",@"% Headshot",@"Tỷ lệ headshot")
                            key:@"SilentHeadPercent" min:0 max:100 fallback:75 y:y];

        y = [self addSection:TR(@"Armas",@"Weapons",@"Súng") y:y];
        y = [self addToggle:TR(@"Disparo rápido (2×)",@"Fast fire (2×)",@"Bắn nhanh (2×)")
                        key:@"FastFire" fallback:NO y:y];
        y = [self addToggle:TR(@"Sin recarga",@"No reload",@"Không nạp đạn")
                        key:@"ShootNoReload" fallback:NO y:y];

        // Advanced disclosure
        UIButton *adv = [UIButton buttonWithType:UIButtonTypeSystem];
        adv.frame = CGRectMake(0, y, [self contentWidth], 44);
        adv.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
        adv.layer.cornerRadius = 14;
        [adv setTitle:[NSString stringWithFormat:@"%@  %@",
            TR(@"Avanzado",@"Advanced",@"Nâng cao"),
            self.advancedExpanded ? @"▴" : @"▾"] forState:UIControlStateNormal];
        [adv setTitleColor:[UIColor colorWithWhite:0.85 alpha:1.0] forState:UIControlStateNormal];
        adv.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [adv addTarget:self action:@selector(toggleAdvanced) forControlEvents:UIControlEventTouchUpInside];
        [self.scroll addSubview:adv];
        y += 50;
        if (self.advancedExpanded) {
            if (silent) {
                y = [self addToggle:TR(@"Rango auto",@"Auto range",@"Tự chọn tầm")
                                key:@"SilentAutoConfig" fallback:YES y:y];
                if (!ESPPrefsBool(@"SilentAutoConfig",YES))
                    y = [self addSlider:TR(@"Rango Silent",@"Silent range",@"Tầm Silent")
                                    key:@"SilentMaxDistance" min:10 max:150 fallback:100 y:y];
            }
        }

    // ── PAGE 1: ESP ───────────────────────────────────────────────────────────
    } else if (self.page == 1) {
        y = [self addToggle:TR(@"Activar ESP",@"Enable ESP",@"Bật ESP")
                        key:@"ESPEnabled" fallback:YES y:y];

        UIButton *preset = [UIButton buttonWithType:UIButtonTypeSystem];
        preset.frame = CGRectMake(0, y, [self contentWidth], 44);
        preset.layer.cornerRadius = 14;
        preset.backgroundColor = [DAAEAccent() colorWithAlphaComponent:0.18];
        [preset setTitle:TR(@"⚡ ESP mínimo",@"⚡ Minimal ESP",@"⚡ ESP tối giản")
               forState:UIControlStateNormal];
        [preset setTitleColor:DAAEAccent() forState:UIControlStateNormal];
        preset.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [preset addTarget:self action:@selector(applyMinimalESP) forControlEvents:UIControlEventTouchUpInside];
        [self.scroll addSubview:preset];
        y += 50;

        y = [self addSection:TR(@"Dibujo",@"Draw",@"Vẽ") y:y];
        y = [self addToggle:TR(@"Marco limpio",@"Clean box",@"Khung góc mảnh")
                        key:@"CleanESP" fallback:YES y:y];
        y = [self addToggle:TR(@"Nombre",@"Name",@"Tên người chơi")
                        key:@"Name" fallback:YES y:y];
        y = [self addToggle:TR(@"Barra de vida",@"Health bar",@"Thanh máu")
                        key:@"Health" fallback:YES y:y];
        y = [self addToggle:TR(@"Ejes XYZ",@"XYZ axes",@"Trục XYZ")
                        key:@"Line" fallback:NO y:y];
        y = [self addToggle:TR(@"Caja del jugador",@"Player box",@"Khung người chơi")
                        key:@"Box" fallback:YES y:y];
        y = [self addToggle:TR(@"Esqueleto",@"Skeleton",@"Xương người chơi")
                        key:@"Skeleton" fallback:NO y:y];
        y = [self addToggle:TR(@"Punto cabeza",@"Head dot",@"Điểm đầu")
                        key:@"HeadRedDot" fallback:NO y:y];
        y = [self addToggle:TR(@"Distancia",@"Distance",@"Khoảng cách")
                        key:@"Dis" fallback:YES y:y];

        y = [self addSection:TR(@"Estilo caja",@"Box style",@"Kiểu khung") y:y];
        UISegmentedControl *boxStyle = [[UISegmentedControl alloc] initWithItems:@[@"2D",@"3D"]];
        boxStyle.frame = CGRectMake(0, y, [self contentWidth], 38);
        boxStyle.selectedSegmentIndex = ESPPrefsBool(@"Box3D",NO) ? 1 : 0;
        boxStyle.selectedSegmentTintColor = DAAEAccent();
        [boxStyle addTarget:self action:@selector(boxStyleChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:boxStyle];
        [self.controls addObject:boxStyle];
        y += 46;

        y = [self addSlider:TR(@"Distancia ESP",@"ESP Distance",@"Tầm ESP")
                        key:@"ESPMaxDistance" min:50 max:500 fallback:150 y:y];
        y = [self addSlider:TR(@"Amarillo si vida ≤",@"Yellow if HP ≤",@"Vàng khi máu ≤")
                        key:@"HealthYellowPercent" min:10 max:90 fallback:50 y:y];
        y = [self addSlider:TR(@"Rojo si vida ≤",@"Red if HP ≤",@"Đỏ khi máu ≤")
                        key:@"HealthRedPercent" min:5 max:80 fallback:25 y:y];

    // ── PAGE 2: MISC ──────────────────────────────────────────────────────────
    } else if (self.page == 2) {
        y = [self addSection:TR(@"Botones flotantes",@"Float buttons",@"Nút nổi") y:y];
        y = [self addToggle:@"Ghost" key:@"GhostModeFloating" fallback:NO y:y];
        y = [self addToggle:@"FakeLag" key:@"FakeLagFloating" fallback:NO y:y];
        y = [self addToggle:TR(@"Volar",@"Fly",@"Fly") key:@"FlyFloating" fallback:NO y:y];
        y = [self addToggle:TR(@"Ocultar botones",@"Hide buttons",@"Ẩn nút")
                        key:@"HideFeatureButtons" fallback:NO y:y];
        y = [self addToggle:TR(@"Botón Speed",@"Speed button",@"Nút Speed")
                        key:@"RunSpeedFloating" fallback:ESPPrefsBool(@"RunSpeed",NO) y:y];

        y = [self addSection:TR(@"Movimiento",@"Movement",@"Di chuyển") y:y];
        if (ESPPrefsBool(@"FlyFloating",NO))
            y = [self addSlider:TR(@"Altura Fly",@"Fly height",@"Độ cao Fly")
                            key:@"FlyHeight" min:1 max:6 fallback:4 y:y];
        y = [self addToggle:TR(@"Velocidad",@"Speed",@"Speed") key:@"RunSpeed" fallback:NO y:y];

        y = [self addSection:TR(@"Efectos",@"Effects",@"Hiệu ứng") y:y];
        y = [self addToggle:TR(@"Spin (solo tú)",@"Spin (only you)",@"Spin · chỉ mình thấy")
                        key:@"VisualSpin" fallback:NO y:y];
        if (ESPPrefsBool(@"VisualSpin",NO)) {
            y = [self addSlider:TR(@"Vueltas/seg",@"Turns/sec",@"Vòng/giây")
                            key:@"VisualSpinSpeed" min:0.1 max:3 fallback:0.5 y:y];
            self.spinStatusLabel = [[UILabel alloc] initWithFrame:
                CGRectMake(6, y, [self contentWidth]-12, 36)];
            self.spinStatusLabel.textColor   = [UIColor colorWithWhite:1 alpha:0.40];
            self.spinStatusLabel.font        = [UIFont systemFontOfSize:11];
            self.spinStatusLabel.numberOfLines = 2;
            [self.scroll addSubview:self.spinStatusLabel];
            [self updateSpinStatus];
            y += 42;
        }
        y = [self addToggle:TR(@"Ocultar en capturas",@"Hide in screen",@"Ẩn khi chụp")
                        key:@"AnLive" fallback:NO y:y];
        y = [self addToggle:TR(@"Ahorro batería (30 FPS)",@"Save battery (30 FPS)",@"Tiết kiệm pin")
                        key:@"BalancedRender" fallback:NO y:y];

    // ── PAGE 3: COLORS ────────────────────────────────────────────────────────
    } else if (self.page == 3) {
        y = [self addSection:TR(@"Color de acento",@"Accent color",@"Màu nhấn") y:y];

        // Paleta de colores — chips cuadrados/redondos
        NSArray *accentNames = @[
            TR(@"Blanco",@"White",@"Trắng"),
            TR(@"Celeste",@"Blue",@"Xanh lam"),
            TR(@"Amarillo",@"Yellow",@"Vàng"),
            TR(@"Rojo",@"Red",@"Đỏ"),
            TR(@"Rosa",@"Pink",@"Hồng"),
            TR(@"Verde",@"Green",@"Xanh lá"),
        ];
        NSInteger curAccent = DAAEAccentIdx();
        CGFloat chipW = 42, chipH = 42, chipGap = 10;
        CGFloat totalChipsW = accentNames.count * chipW + (accentNames.count-1) * chipGap;
        CGFloat chipStartX = ([self contentWidth] - totalChipsW) / 2.0;

        UIView *chipRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, [self contentWidth], chipH + 20)];
        chipRow.backgroundColor = [UIColor colorWithWhite:1 alpha:0.05];
        chipRow.layer.cornerRadius = 14;
        chipRow.layer.borderWidth  = 0.6;
        chipRow.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
        for (NSInteger k = 0; k < (NSInteger)accentNames.count; k++) {
            UIButton *chip = [UIButton buttonWithType:UIButtonTypeCustom];
            chip.frame = CGRectMake(chipStartX + k*(chipW+chipGap), 10, chipW, chipH);
            chip.backgroundColor = DAAEAccents()[k];
            chip.layer.cornerRadius = chipW / 2.0;
            chip.layer.borderWidth  = (k == curAccent) ? 2.5 : 0;
            chip.layer.borderColor  = UIColor.whiteColor.CGColor;
            chip.tag = 400 + k;
            [chip addTarget:self action:@selector(accentTap:) forControlEvents:UIControlEventTouchUpInside];
            [chipRow addSubview:chip];
        }
        [self.scroll addSubview:chipRow];
        y += chipH + 30;

        // Preview label
        UILabel *preview = [[UILabel alloc] initWithFrame:CGRectMake(0, y, [self contentWidth], 40)];
        preview.text = TR(@"Vista previa del acento activo",@"Active accent preview",@"Xem trước màu nhấn");
        preview.textAlignment = NSTextAlignmentCenter;
        preview.textColor = DAAEAccent();
        preview.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
        preview.backgroundColor = [DAAEAccent() colorWithAlphaComponent:0.12];
        preview.layer.cornerRadius = 10;
        preview.clipsToBounds = YES;
        [self.scroll addSubview:preview];
        y += 48;

        // Colores ESP (Box / FOV)
        y = [self addSection:TR(@"Colores ESP",@"ESP Colors",@"Màu ESP") y:y];
        UISegmentedControl *target = [[UISegmentedControl alloc]
            initWithItems:@[TR(@"Marco",@"Box",@"Hộp"), @"FOV"]];
        target.frame = CGRectMake(0, y, [self contentWidth], 36);
        target.selectedSegmentIndex = 0;
        target.selectedSegmentTintColor = DAAEAccent();
        [target addTarget:self action:@selector(colorTargetChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:target];
        [self.controls addObject:target];
        y += 44;

        NSArray *rgbNames = @[TR(@"Rojo",@"Red",@"Đỏ"),
                              TR(@"Verde",@"Green",@"Xanh lá"),
                              TR(@"Azul",@"Blue",@"Xanh lam")];
        NSArray *rgbSuf   = @[@"R", @"G", @"B"];
        float rgbDef[3]   = {0.46f, 0.86f, 0.73f};
        for (int i = 0; i < 3; i++) {
            NSString *pfx = ESPPrefsBool(@"Box3D",NO) ? @"BoxColor" : @"BoxColor";
            NSString *key = [pfx stringByAppendingString:rgbSuf[i]];
            y = [self addSlider:rgbNames[i] key:key min:0 max:1 fallback:rgbDef[i] y:y];
        }

    // ── PAGE 4: SETTINGS ──────────────────────────────────────────────────────
    } else {
        y = [self addSection:TR(@"Apariencia",@"Appearance",@"Giao diện") y:y];
        y = [self addToggle:TR(@"Modo oscuro",@"Dark mode",@"Giao diện tối")
                        key:@"DarkTheme" fallback:YES y:y];

        // Idioma — 3 botones
        y = [self addSection:TR(@"Idioma",@"Language",@"Ngôn ngữ") y:y];
        UIView *langRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, [self contentWidth], 46)];
        langRow.backgroundColor = [UIColor colorWithWhite:1 alpha:0.07];
        langRow.layer.cornerRadius = 14;
        langRow.layer.borderWidth  = 0.6;
        langRow.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
        NSArray *codes = @[@"ES", @"EN", @"VI"];
        CGFloat lbtnW = 56, lbtnH = 30, lgap = 8;
        CGFloat lTotalW = codes.count * lbtnW + (codes.count-1) * lgap;
        CGFloat lStartX = ([self contentWidth] - lTotalW) / 2.0;
        NSInteger curLang = DAAELang();
        for (NSInteger k = 0; k < (NSInteger)codes.count; k++) {
            UIButton *lb = [UIButton buttonWithType:UIButtonTypeCustom];
            lb.frame = CGRectMake(lStartX + k*(lbtnW+lgap), 8, lbtnW, lbtnH);
            lb.backgroundColor = (k == curLang) ? DAAEAccent() : [UIColor colorWithWhite:1 alpha:0.10];
            lb.layer.cornerRadius = 10;
            [lb setTitle:codes[k] forState:UIControlStateNormal];
            lb.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
            [lb setTitleColor:(k == curLang) ? UIColor.blackColor : UIColor.whiteColor
                     forState:UIControlStateNormal];
            NSInteger langIdx = k;
            __weak _0xDEADBEEE *ws = self;
            objc_setAssociatedObject(lb, "langIdx", @(langIdx), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [lb addTarget:self action:@selector(langTap:) forControlEvents:UIControlEventTouchUpInside];
            [langRow addSubview:lb];
        }
        [self.scroll addSubview:langRow];
        y += 54;

        y = [self addSection:TR(@"Acerca de",@"About",@"Giới thiệu") y:y];

        // Info rows
        NSArray *infoTitles = @[
            TR(@"Producto",@"Product",@"Sản phẩm"),
            TR(@"Creador",@"Creator",@"Người tạo"),
            @"Telegram"
        ];
        NSArray *infoValues = @[@"DAAE IOS", @"@didierxit7", @"t.me/didierxit7"];
        for (NSInteger k = 0; k < (NSInteger)infoTitles.count; k++) {
            UIButton *infoRow = [UIButton buttonWithType:UIButtonTypeCustom];
            infoRow.frame = CGRectMake(0, y, [self contentWidth], 46);
            infoRow.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
            infoRow.layer.cornerRadius = 14;
            infoRow.layer.borderWidth  = 0.6;
            infoRow.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.10].CGColor;
            CGFloat rw = [self contentWidth];

            UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, rw*0.45, 46)];
            tl.text = infoTitles[k];
            tl.textColor = [UIColor colorWithWhite:0.90 alpha:1.0];
            tl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
            [infoRow addSubview:tl];

            BOOL isTg = (k == 2);
            UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(rw*0.45, 0, rw*0.48, 46)];
            vl.text = infoValues[k];
            vl.textColor = isTg ? DAAEAccent() : [UIColor colorWithWhite:0.65 alpha:1.0];
            vl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
            vl.textAlignment = NSTextAlignmentRight;
            [infoRow addSubview:vl];

            if (isTg) {
                UIImageView *ar = [[UIImageView alloc] initWithImage:
                    SFSym(@"arrow.up.right", 10, UIImageSymbolWeightBold)];
                ar.tintColor = [UIColor colorWithWhite:0.55 alpha:1.0];
                ar.frame = CGRectMake(rw - 24, 17, 12, 12);
                ar.contentMode = UIViewContentModeScaleAspectFit;
                [infoRow addSubview:ar];
                [infoRow addTarget:self action:@selector(openTelegram)
                    forControlEvents:UIControlEventTouchUpInside];
            }
            [self.scroll addSubview:infoRow];
            y += 52;
        }
    }

    // Credit pie
    UILabel *credit = [[UILabel alloc] initWithFrame:
        CGRectMake(0, y + 10, [self contentWidth], 18)];
    credit.text = @"DAAE IOS";
    credit.textColor = [UIColor colorWithWhite:1 alpha:0.18];
    credit.font = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    credit.textAlignment = NSTextAlignmentCenter;
    [self.scroll addSubview:credit];
    y += 34;

    self.scroll.contentSize = CGSizeMake([self contentWidth], y + 4);
    self.scroll.contentOffset = CGPointMake(0, MAX(0, MIN(offset, y + 4 - self.scroll.bounds.size.height)));
}

// ── ACCIONES ──────────────────────────────────────────────────────────────────
- (void)closeMenu   { if (self.onCloseBlock) self.onCloseBlock(); }
- (void)chooseAim   { self.aimExpanded   = !self.aimExpanded;   [self rebuildAnimated]; }
- (void)toggleAdvanced { self.advancedExpanded = !self.advancedExpanded; [self rebuildAnimated]; }
- (void)openTelegram {
    NSURL *u = [NSURL URLWithString:@"https://t.me/didierxit7"];
    if (u) [UIApplication.sharedApplication openURL:u options:@{} completionHandler:nil];
}
- (void)toggleTheme {
    self.darkMode = !self.darkMode;
    ESPPrefsSetBool(@"DarkTheme", self.darkMode);
    [self rebuildAnimated];
}
- (void)accentTap:(UIButton *)sender {
    NSInteger idx = sender.tag - 400;
    [[NSUserDefaults standardUserDefaults] setInteger:idx forKey:@"DAAE.accentIdx"];
    [self rebuildAnimated];
}
- (void)langTap:(UIButton *)sender {
    NSNumber *n = objc_getAssociatedObject(sender, "langIdx");
    if (n) { DAAESetLang(n.integerValue); [self rebuildAnimated]; }
}
- (void)colorTargetChanged:(UISegmentedControl *)seg {
    (void)seg; // actualmente solo cambia el prefijo de color
    [self buildPage];
}
- (void)boxStyleChanged:(UISegmentedControl *)sender {
    ESPPrefsSetBool(@"Box3D", sender.selectedSegmentIndex == 1);
    ESPPrefsSetBool(@"Box", YES);
    if (sender.selectedSegmentIndex == 1) ESPPrefsSetBool(@"CleanESP", NO);
    ESPSyncFromPrefs();
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

// toggleChanged preserva toda la lógica original de efectos secundarios
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
    if ([key isEqualToString:@"AnLive"] && ![UIView applyCaptureProtectionToRegisteredViews:on]) {
        ESPPrefsSetBool(@"AnLive", NO);
        [UIView applyCaptureProtectionToRegisteredViews:NO];
    }
    if ([key isEqualToString:@"DarkTheme"]) { self.darkMode = on; [self rebuildAnimated]; }
    if ([@[@"SilentAutoConfig",@"AutoFireFloating",@"FlyFloating",@"VisualSpin"]
            containsObject:key]) [self rebuildAnimated];
}

- (void)updateSpinStatus {
    const auto state = PlayerModesRead();
    NSString *text = TR(@"Spin: esperando ciclo del juego",
                        @"Spin: waiting for game tick",
                        @"Spin: chờ nhịp cuối của game");
    if (state.detail && state.detail[0])
        text = [NSString stringWithUTF8String:state.detail];
    else if (state.spinStatus==1) text = TR(@"Spin: esperando personaje",@"Spin: waiting for character",@"Spin: chờ nhân vật");
    else if (state.spinStatus==2) text = TR(@"Spin: sin modelo compatible",@"Spin: no compatible model",@"Spin: chưa có mô hình");
    else if (state.spinStatus==3) text = TR(@"Spin: esperando ángulo",@"Spin: waiting for angle",@"Spin: chờ góc ổn định");
    else if (state.spinStatus==4)
        text = [NSString stringWithFormat:TR(@"Spin: aplicado · %llu",@"Spin: applied · %llu",@"Spin: đã áp dụng · %llu"),
                (unsigned long long)state.spinApplies];
    self.spinStatusLabel.text = text;
}

- (void)dealloc { [self.spinStatusTimer invalidate]; }

// ── DRAG ──────────────────────────────────────────────────────────────────────
- (void)dragPanel:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateBegan)
        self.panelOrigin = self.panel.frame.origin;
    CGPoint delta = [pan translationInView:self.view];
    CGRect f = self.panel.frame;
    f.origin = CGPointMake(self.panelOrigin.x + delta.x, self.panelOrigin.y + delta.y);
    self.panel.frame = f;
    self.blurBG.frame = f;
    [self viewDidLayoutSubviews];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)t {
    for (UIView *v = t.view; v && v != g.view; v = v.superview)
        if ([v isKindOfClass:UIControl.class]) return NO;
    return YES;
}

// ── TOUCH ROUTING (preserva lógica original de input) ─────────────────────────
- (BOOL)_0xF010:(CGPoint)point phase:(NSInteger)phase pointerId:(NSInteger)pointerId {
    if (phase == UITouchPhaseBegan) {
        if (!CGRectContainsPoint(self.panel.frame, point)) return NO;
        if (self.pointer != -1) return YES;
        self.pointer = pointerId; self.began = point;
        self.panelOrigin = self.panel.frame.origin;
        self.scrollOrigin = self.scroll.contentOffset.y;
        self.scrolling = NO; self.activeControl = nil;
        CGPoint local = [self.panel convertPoint:point fromView:self.view];
        // Drag en sidebar o header (top 44 del contentArea)
        self.dragging = (local.x < 72) || (local.y < 44 && local.x < self.panel.bounds.size.width - 40);
        if (self.dragging) return YES;
        // Hit test en controles
        if (CGRectContainsPoint(self.scroll.frame, [self.contentArea convertPoint:local fromView:self.panel])) {
            CGPoint scrollLocal = [self.scroll convertPoint:point fromView:self.view];
            for (UIControl *c in self.controls) {
                if (!c.enabled) continue;
                if (CGRectContainsPoint([c convertRect:c.bounds toView:self.scroll], scrollLocal))
                { self.activeControl = c; break; }
            }
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

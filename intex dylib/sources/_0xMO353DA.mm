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
// IDIOMA — 0=EN (por defecto), 1=ES, 2=VI
// ─────────────────────────────────────────────────────────────────────────────
static NSInteger DAAELang(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.lang"]) return 0; // EN por defecto
    NSInteger v = [ud integerForKey:@"DAAE.lang"];
    return (v >= 0 && v <= 2) ? v : 0;
}
static void DAAESetLang(NSInteger l) {
    [[NSUserDefaults standardUserDefaults] setInteger:l forKey:@"DAAE.lang"];
}

// ─────────────────────────────────────────────────────────────────────────────
// PALETA — oscuro neutro (gris, no marrón)
// ─────────────────────────────────────────────────────────────────────────────
static UIColor *PanelBG(void)     { return [UIColor colorWithWhite:0.12 alpha:0.96]; }
static UIColor *RowOFF(void)      { return [UIColor colorWithWhite:1 alpha:0.07]; }
static UIColor *RowON(void)       { return [UIColor colorWithWhite:1 alpha:0.13]; }
static UIColor *SectionClr(void)  { return [UIColor colorWithWhite:1 alpha:0.40]; }
static UIColor *LblPrimary(void)  { return UIColor.whiteColor; }
static UIColor *LblSec(void)      { return [UIColor colorWithWhite:1 alpha:0.60]; }
static UIColor *LblTer(void)      { return [UIColor colorWithWhite:1 alpha:0.38]; }
static UIColor *CheckON(void)     { return [UIColor colorWithWhite:1 alpha:0.22]; }
static UIColor *CheckOFF(void)    { return [UIColor colorWithWhite:1 alpha:0.12]; }

// ─────────────────────────────────────────────────────────────────────────────
// LABEL TRILINGÜE — EN bold, ES medium dimmed, VI small dimmer
// Tal y como aparece en las imágenes de referencia
// ─────────────────────────────────────────────────────────────────────────────
static UILabel *TriLabel(NSString *en, NSString *es, NSString *vi, CGFloat maxW) {
    NSInteger lang = DAAELang();
    // Siempre 3 líneas: idioma primario arriba (más grande), los otros 2 debajo
    NSString *line0, *line1, *line2;
    NSDictionary *attr0, *attr1, *attr2;

    NSDictionary *aEN = @{NSFontAttributeName:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold],
                          NSForegroundColorAttributeName:LblPrimary()};
    NSDictionary *aES = @{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular],
                          NSForegroundColorAttributeName:LblSec()};
    NSDictionary *aVI = @{NSFontAttributeName:[UIFont systemFontOfSize:11 weight:UIFontWeightRegular],
                          NSForegroundColorAttributeName:LblTer()};

    switch (lang) {
        case 1:  // ES primario
            line0 = es; attr0 = @{NSFontAttributeName:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold], NSForegroundColorAttributeName:LblPrimary()};
            line1 = en; attr1 = aEN; // reutilizamos el mismo tamaño pero dim
            attr1 = @{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular], NSForegroundColorAttributeName:LblSec()};
            line2 = vi; attr2 = aVI;
            break;
        case 2:  // VI primario
            line0 = vi; attr0 = @{NSFontAttributeName:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold], NSForegroundColorAttributeName:LblPrimary()};
            line1 = en; attr1 = @{NSFontAttributeName:[UIFont systemFontOfSize:12 weight:UIFontWeightRegular], NSForegroundColorAttributeName:LblSec()};
            line2 = es; attr2 = aVI;
            break;
        default: // EN primario
            line0 = en; attr0 = aEN;
            line1 = es; attr1 = aES;
            line2 = vi; attr2 = aVI;
            break;
    }

    NSMutableAttributedString *as = [NSMutableAttributedString new];
    [as appendAttributedString:[[NSAttributedString alloc] initWithString:line0 attributes:attr0]];
    [as appendAttributedString:[[NSAttributedString alloc] initWithString:[@"\n" stringByAppendingString:line1] attributes:attr1]];
    [as appendAttributedString:[[NSAttributedString alloc] initWithString:[@"\n" stringByAppendingString:line2] attributes:attr2]];

    UILabel *l = [[UILabel alloc] init];
    l.attributedText = as;
    l.numberOfLines  = 0;
    CGSize sz = [as boundingRectWithSize:CGSizeMake(maxW, 9999)
                                 options:NSStringDrawingUsesLineFragmentOrigin
                                 context:nil].size;
    l.frame = CGRectMake(0, 0, maxW, ceil(sz.height) + 1);
    return l;
}

// ─────────────────────────────────────────────────────────────────────────────
// CHECKMARK CIRCLE
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAECheck : UIView
@property (nonatomic, assign) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end
@implementation DAAECheck {
    UIImageView *_iv;
}
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.layer.cornerRadius = f.size.width / 2.0;
        self.userInteractionEnabled = NO;
        UIImage *img = SFSym(@"checkmark", 12, UIImageSymbolWeightHeavy);
        _iv = [[UIImageView alloc] initWithImage:img];
        _iv.tintColor   = [UIColor colorWithWhite:0.85 alpha:1.0];
        _iv.contentMode = UIViewContentModeScaleAspectFit;
        _iv.frame = CGRectInset(self.bounds, 6, 6);
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
                                  options:UIViewAnimationOptionCurveEaseInOut
                               animations:upd completion:nil];
    else upd();
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE ROW — fondo gris translúcido ON con border blanco
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAERow : UIButton
@property (nonatomic, strong) DAAECheck *check;
@property (nonatomic, assign) BOOL toggleOn;
@property (nonatomic, copy)   void (^onChanged)(BOOL);
- (void)_applyStyle:(BOOL)on;
@end
@implementation DAAERow
- (instancetype)initWithEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                        on:(BOOL)on width:(CGFloat)w {
    // Ancho efectivo de label — dejamos 16 padding izq + 52 para check + 14 padding der
    CGFloat labelW = w - 82;
    UILabel *measure = TriLabel(en, es, vi, labelW);
    CGFloat contentH = MAX(68.0, measure.bounds.size.height + 24);
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, contentH)])) {
        self.toggleOn = on;
        [self _applyStyle:on];
        UILabel *lbl = TriLabel(en, es, vi, labelW);
        CGFloat lblH = lbl.bounds.size.height;
        lbl.frame = CGRectMake(16, (contentH - lblH) / 2.0, labelW, lblH);
        lbl.userInteractionEnabled = NO;
        [self addSubview:lbl];
        self.check = [[DAAECheck alloc] initWithFrame:
            CGRectMake(w - 52, (contentH - 32) / 2.0, 32, 32)];
        [self.check setOn:on animated:NO];
        [self addSubview:self.check];
        [self addTarget:self action:@selector(_tap)
            forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)_applyStyle:(BOOL)on {
    self.backgroundColor    = on ? RowON() : RowOFF();
    self.layer.cornerRadius = 16;
    self.layer.borderWidth  = on ? 0.8 : 0;
    self.layer.borderColor  = on ? [UIColor colorWithWhite:1 alpha:0.22].CGColor
                                 : [UIColor clearColor].CGColor;
    self.clipsToBounds = YES;
}
- (void)_tap {
    self.toggleOn = !self.toggleOn;
    [self.check setOn:self.toggleOn animated:YES];
    BOOL nowOn = self.toggleOn;
    [UIView animateWithDuration:0.18 delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{ [self _applyStyle:nowOn]; }
                     completion:nil];
    if (self.onChanged) self.onChanged(self.toggleOn);
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// SLIDER ROW
// ─────────────────────────────────────────────────────────────────────────────
@interface DAAESlider : UIView
@end
@implementation DAAESlider
- (instancetype)initWithEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                       key:(NSString *)key min:(float)mn max:(float)mx
                  fallback:(float)fb width:(CGFloat)w {
    CGFloat labelW = w - 90;
    UILabel *measure = TriLabel(en, es, vi, labelW);
    CGFloat contentH = MAX(80.0, measure.bounds.size.height + 38);
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, contentH)])) {
        self.backgroundColor    = RowOFF();
        self.layer.cornerRadius = 16;
        UILabel *lbl = TriLabel(en, es, vi, labelW);
        CGFloat lblH = lbl.bounds.size.height;
        lbl.frame = CGRectMake(16, 10, labelW, lblH);
        [self addSubview:lbl];
        UILabel *val = [[UILabel alloc] initWithFrame:CGRectMake(w - 66, 10, 54, 22)];
        val.textAlignment = NSTextAlignmentRight;
        val.textColor = LblPrimary();
        val.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        float cur = ESPPrefsFloat(key, fb);
        val.text = [NSString stringWithFormat:@"%.0f", cur];
        [self addSubview:val];
        UISlider *sl = [[UISlider alloc]
            initWithFrame:CGRectMake(14, contentH - 30, w - 28, 22)];
        sl.minimumValue          = mn;
        sl.maximumValue          = mx;
        sl.value                 = cur;
        sl.minimumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.85];
        sl.maximumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.20];
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
// FILA DE INFO (settings)
// ─────────────────────────────────────────────────────────────────────────────
static UIView *InfoRow(NSString *title, NSString *value, CGFloat w, BOOL accent) {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, 52)];
    row.backgroundColor    = RowOFF();
    row.layer.cornerRadius = 16;

    UILabel *tl = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, w * 0.45, 52)];
    tl.text = title;
    tl.textColor = LblPrimary();
    tl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [row addSubview:tl];

    UILabel *vl = [[UILabel alloc] initWithFrame:CGRectMake(w * 0.45, 0, w * 0.50 - 16, 52)];
    vl.text = value;
    vl.textColor = accent ? [UIColor colorWithWhite:1 alpha:0.50] : LblSec();
    vl.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
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
@property (nonatomic, assign) NSInteger  page;          // 0=ESP 1=Aim 2=Colors 3=Misc 4=Settings
@property (nonatomic, assign) NSInteger  colorTarget;   // 0=Box 1=FOV
@property (nonatomic, assign) CGFloat    builtWidth;
@property (nonatomic, strong) NSMutableArray<UIView *> *controls;
@property (nonatomic, strong) UILabel  *spinStatusLabel;
@property (nonatomic, strong) NSTimer  *spinStatusTimer;
@property (nonatomic, assign) NSInteger pointer;
@property (nonatomic, assign) CGPoint   began;
@property (nonatomic, assign) CGPoint   panelOrigin;
@property (nonatomic, assign) CGFloat   scrollOrigin;
@property (nonatomic, assign) BOOL      dragging;
@property (nonatomic, assign) BOOL      scrolling;
@property (nonatomic, strong) UIControl *activeControl;
@end

@implementation _0xDEADBEEE

// ─────────────────────────────────────────────────────────────────────────────
// DEFAULTS
// ─────────────────────────────────────────────────────────────────────────────
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
        @"BalancedRender":@NO, @"HideFeatureButtons":@NO,
        @"AimType":@(0.0f), @"AimActivation":@(1.0f),
        @"FovSize":@(40.0f), @"SilentFovSize":@(18.0f),
    };
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if ([ud objectForKey:@"_MizzeDefaultsApplied"]) return;
    for (NSString *key in defaults) {
        id val = defaults[key];
        if (![val isKindOfClass:NSNumber.class]) continue;
        const char *t = ((NSNumber *)val).objCType;
        if (strcmp(t,@encode(BOOL))==0||strcmp(t,@encode(bool))==0||strcmp(t,@encode(char))==0)
            ESPPrefsSetBool(key, ((NSNumber *)val).boolValue);
        else
            ESPPrefsSetFloat(key, ((NSNumber *)val).floatValue);
    }
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

    // Blur oscuro detrás del panel
    self.blurBG = [[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    self.blurBG.layer.cornerRadius = 22;
    self.blurBG.clipsToBounds = YES;
    [self.view addSubview:self.blurBG];

    // Panel — gris oscuro neutro
    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.backgroundColor    = PanelBG();
    self.panel.layer.cornerRadius = 22;
    self.panel.layer.borderWidth  = 0.5;
    self.panel.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.12].CGColor;
    self.panel.clipsToBounds = YES;
    [self.view addSubview:self.panel];

    // Sidebar
    self.sidebar = [[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.10];
    [self.panel addSubview:self.sidebar];

    // Divisor
    UIView *div = [[UIView alloc] initWithFrame:CGRectZero];
    div.tag = 99;
    div.backgroundColor = [UIColor colorWithWhite:1 alpha:0.08];
    [self.panel addSubview:div];

    // Content area
    self.contentArea = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentArea.backgroundColor = UIColor.clearColor;
    [self.panel addSubview:self.contentArea];

    // Scroll — con padding interno para que no se corten las filas
    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator = NO;
    self.scroll.bounces = YES;
    self.scroll.clipsToBounds = NO; // las filas no se cortan en el scroll
    [self.contentArea addSubview:self.scroll];

    // Pan gestures para drag del panel
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

    // Panel: cubre bien la pantalla sin tocar los bordes
    CGFloat pw = MIN(440.0, MAX(280.0, sw - 140.0));
    CGFloat ph = MIN(560.0, MAX(340.0, sh - 60.0));

    CGRect f = self.panel.frame;
    if (f.size.width == 0) {
        // Primera vez: centrar
        f = CGRectMake((sw - pw) / 2.0, (sh - ph) / 2.0, pw, ph);
    } else {
        f.size = CGSizeMake(pw, ph);
        f.origin.x = MAX(8, MIN(f.origin.x, sw - pw - 8));
        f.origin.y = MAX(8, MIN(f.origin.y, sh - ph - 8));
    }
    self.panel.frame  = f;
    self.blurBG.frame = f;

    // Sidebar: 68pt — botones más grandes
    const CGFloat sbW = 68.0;
    self.sidebar.frame = CGRectMake(0, 0, sbW, ph);

    UIView *div = [self.panel viewWithTag:99];
    div.frame = CGRectMake(sbW, 0, 0.5, ph);

    CGFloat caX = sbW + 0.5;
    CGFloat caW = pw - caX;
    self.contentArea.frame = CGRectMake(caX, 0, caW, ph);

    // Header: 52pt
    const CGFloat headerH = 52.0;
    // Scroll con padding horizontal 10pt para que las filas no toquen el borde
    const CGFloat scrollPad = 10.0;
    self.scroll.frame = CGRectMake(scrollPad, headerH,
                                   caW - scrollPad * 2,
                                   ph - headerH - 8);
    self.scroll.clipsToBounds = YES;

    [self layoutSidebarButtons];
    if (fabs(self.builtWidth - self.scroll.bounds.size.width) > 0.5) [self buildPage];
    [self refreshSidebarSelection];
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR
// Tab 0: ESP          eye.fill
// Tab 1: Aim          scope
// Tab 2: Colors       paintpalette.fill
// Tab 3: Misc         shippingbox.fill
// Tab 4: Settings     gearshape.fill
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
        btn.layer.cornerRadius = 25; // 50×50 → radius 25
        UIImage *img = SFSym(icons[i], 20, UIImageSymbolWeightSemibold);
        [btn setImage:img forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(sidebarTap:)
            forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
    }
    [self layoutSidebarButtons];
    [self refreshSidebarSelection];
}

- (void)layoutSidebarButtons {
    const CGFloat btnSz = 50, gap = 12;
    CGFloat total = 5 * btnSz + 4 * gap;
    CGFloat sbH = self.sidebar.bounds.size.height;
    if (sbH < 1) sbH = 380;
    CGFloat startY = (sbH - total) / 2.0;
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300 + i];
        if (!btn) continue;
        btn.frame = CGRectMake((68 - btnSz) / 2.0,
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
        btn.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.18].CGColor;
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
    if (cw < 10) cw = 300;

    // Fondo header
    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(10, 8, cw - 20, 38)];
    hdr.tag = 500;
    hdr.backgroundColor    = [UIColor colorWithWhite:1 alpha:0.05];
    hdr.layer.cornerRadius = 13;
    [self.contentArea addSubview:hdr];

    // Ícono
    UIImageView *iv = [[UIImageView alloc] initWithImage:
        SFSym(TabIcons()[self.page], 14, UIImageSymbolWeightSemibold)];
    iv.tag = 501;
    iv.tintColor   = LblPrimary();
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.frame = CGRectMake(24, 17, 16, 16);
    [self.contentArea addSubview:iv];

    // Título
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(46, 10, cw - 110, 32)];
    title.tag       = 502;
    title.text      = TabNames()[self.page];
    title.textColor = LblPrimary();
    title.font      = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [self.contentArea addSubview:title];

    // Botón cerrar
    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.tag   = 503;
    close.frame = CGRectMake(cw - 42, 10, 30, 32);
    [close setImage:SFSym(@"xmark", 12, UIImageSymbolWeightBold) forState:UIControlStateNormal];
    close.tintColor = [UIColor colorWithWhite:1 alpha:0.40];
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

- (CGFloat)addToggleEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key fallback:(BOOL)fb y:(CGFloat)y {
    CGFloat w = [self contentWidth];
    DAAERow *row = [[DAAERow alloc] initWithEN:en ES:es VI:vi
                                            on:ESPPrefsBool(key, fb) width:w];
    row.frame = CGRectMake(0, y, w, row.bounds.size.height);
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
    return y + row.bounds.size.height + 8;
}

- (CGFloat)addSection:(NSString *)title y:(CGFloat)y {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(4, y + 6, [self contentWidth] - 8, 20)];
    l.text      = title;
    l.textColor = SectionClr();
    l.font      = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    [self.scroll addSubview:l];
    return y + 32;
}

- (CGFloat)addSliderEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key min:(float)mn max:(float)mx fallback:(float)fb y:(CGFloat)y {
    CGFloat w = [self contentWidth];
    DAAESlider *sl = [[DAAESlider alloc] initWithEN:en ES:es VI:vi
                                                key:key min:mn max:mx fallback:fb width:w];
    CGFloat h = sl.bounds.size.height;
    sl.frame = CGRectMake(0, y, w, h);
    [self.controls addObject:(UIControl *)sl];
    [self.scroll addSubview:sl];
    return y + h + 8;
}

// ─────────────────────────────────────────────────────────────────────────────
// rebuildAnimated
// ─────────────────────────────────────────────────────────────────────────────
- (void)rebuildAnimated {
    if (UIAccessibilityIsReduceMotionEnabled()) { [self buildPage]; return; }
    [UIView transitionWithView:self.scroll duration:0.18
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

    // ─── TAB 0: ESP ──────────────────────────────────────────────────────────
    if (self.page == 0) {
        y = [self addToggleEN:@"ESP Master"  ES:@"Maestro ESP"    VI:@"Chế độ ESP"    key:@"ESPEnabled"  fallback:YES y:y];
        y = [self addSection:@"— DRAW —" y:y];
        y = [self addToggleEN:@"Box ESP"     ES:@"Caja ESP"       VI:@"Hộp ESP"       key:@"Box"         fallback:YES y:y];
        y = [self addToggleEN:@"Line ESP"    ES:@"Ejes XYZ"       VI:@"Đường thẳng"  key:@"Line"        fallback:NO  y:y];
        y = [self addToggleEN:@"Skeleton"    ES:@"Esqueleto"      VI:@"Xương"         key:@"Skeleton"    fallback:NO  y:y];
        y = [self addToggleEN:@"Head Dot"    ES:@"Punto cabeza"   VI:@"Chấm đầu"      key:@"HeadRedDot"  fallback:NO  y:y];
        y = [self addToggleEN:@"Health Bar"  ES:@"Barra de vida"  VI:@"Thanh máu"    key:@"Health"      fallback:YES y:y];
        y = [self addToggleEN:@"Name"        ES:@"Nombre"         VI:@"Tên"           key:@"Name"        fallback:YES y:y];
        y = [self addToggleEN:@"Distance"    ES:@"Distancia"      VI:@"Khoảng cách"  key:@"Dis"         fallback:YES y:y];
        y = [self addToggleEN:@"Clean ESP"   ES:@"ESP limpio"     VI:@"ESP sạch"      key:@"CleanESP"    fallback:YES y:y];
        y = [self addSection:@"— FOV —" y:y];
        y = [self addToggleEN:@"Show FOV"    ES:@"Mostrar FOV"    VI:@"Hiện FOV"      key:@"ShowFov"     fallback:YES y:y];
        y = [self addSliderEN:@"FOV Size"    ES:@"Tamaño FOV"     VI:@"Cỡ FOV"
                          key:@"FovSize" min:5 max:48 fallback:40 y:y];

    // ─── TAB 1: AIM ──────────────────────────────────────────────────────────
    } else if (self.page == 1) {
        y = [self addSection:@"— AIM TYPE —" y:y];

        NSArray *aimEN = @[@"Aim Head",   @"Aim Neck",          @"Silent Aim"];
        NSArray *aimES = @[@"Apuntar cabeza", @"Apuntar cuello",@"Apuntado silencioso"];
        NSArray *aimVI = @[@"Bắn đầu",   @"Bắn cổ",           @"Bắn im lặng"];
        const NSInteger curType = static_cast<int>(
            AimModePolicy::ReadType(ESPPrefsFloat(@"AimType", 0)));
        const BOOL hasValidType = (curType >= 0 && curType <= 2);

        NSMutableArray<DAAERow *> *aimRows = [NSMutableArray array];
        for (NSInteger i = 0; i < 3; i++) {
            CGFloat w = [self contentWidth];
            DAAERow *row = [[DAAERow alloc] initWithEN:aimEN[i] ES:aimES[i] VI:aimVI[i]
                                                    on:(hasValidType && curType == i) width:w];
            row.frame = CGRectMake(0, y, w, row.bounds.size.height);
            [aimRows addObject:row];
            [self.scroll addSubview:row];
            y += row.bounds.size.height + 8;
        }
        for (NSInteger i = 0; i < 3; i++) {
            NSInteger idx = i;
            __weak NSMutableArray<DAAERow *> *wRows = aimRows;
            aimRows[i].onChanged = ^(BOOL on) {
                NSMutableArray<DAAERow *> *rows = wRows;
                if (on) {
                    for (NSInteger j = 0; j < (NSInteger)rows.count; j++) {
                        if (j != idx) {
                            rows[j].toggleOn = NO;
                            [rows[j].check setOn:NO animated:YES];
                            [UIView animateWithDuration:0.18
                                            animations:^{ [rows[j] _applyStyle:NO]; }];
                        }
                    }
                    ESPPrefsSetFloat(@"AimType", (float)idx);
                    ESPPrefsSetFloat(@"AimActivation", static_cast<int>(
                        AimModePolicy::AfterTypeSelection(AimModePolicy::ReadType((float)idx))));
                    ESPPrefsSetBool(@"SilentAim", NO);
                } else {
                    ESPPrefsSetFloat(@"AimType", -1);
                }
                ESPClearAimLock(); ESPSyncFromPrefs();
            };
        }

        // Activation — visible si hay aim activo y no es Silent
        const BOOL isSilent = (AimModePolicy::ReadType(ESPPrefsFloat(@"AimType",0))
                               == AimModePolicy::Type::Silent);
        if (hasValidType && !isSilent) {
            y = [self addSection:@"— ACTIVATION —" y:y];
            NSArray *actEN = @[@"On Shoot",   @"On Scope",    @"Always",     @"Fire+Scope"];
            NSArray *actES = @[@"Al disparar",@"Al apuntar",  @"Siempre",    @"Disparar+Scope"];
            NSArray *actVI = @[@"Khi bắn",    @"Khi ngắm",  @"Luôn luôn", @"Bắn+Ngắm"];
            const NSInteger curAct = static_cast<int>(
                AimModePolicy::ReadActivation(ESPPrefsFloat(@"AimActivation",0)));
            NSMutableArray<DAAERow *> *actRows = [NSMutableArray array];
            for (NSInteger i = 0; i < 4; i++) {
                CGFloat w = [self contentWidth];
                DAAERow *row = [[DAAERow alloc] initWithEN:actEN[i] ES:actES[i] VI:actVI[i]
                                                        on:(curAct == i + 1) width:w];
                row.frame = CGRectMake(0, y, w, row.bounds.size.height);
                [actRows addObject:row];
                [self.scroll addSubview:row];
                y += row.bounds.size.height + 8;
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
                                [UIView animateWithDuration:0.18
                                                animations:^{ [rows[j] _applyStyle:NO]; }];
                            }
                        }
                        ESPPrefsSetFloat(@"AimActivation", (float)choice);
                    } else {
                        ESPPrefsSetFloat(@"AimActivation", 0);
                    }
                    ESPClearAimLock(); ESPSyncFromPrefs();
                };
            }
        }

        y = [self addToggleEN:@"Aim Lag"     ES:@"Retraso de aim" VI:@"Trễ aim"          key:@"AimLag"           fallback:NO  y:y];
        y = [self addToggleEN:@"Target Line" ES:@"Línea objetivo"  VI:@"Đường mục tiêu"  key:@"AimTargetLine"    fallback:YES y:y];
        y = [self addToggleEN:@"AimKill"     ES:@"Matar con aim"   VI:@"Aim giết"         key:@"AutoFireFloating" fallback:NO  y:y];
        y = [self addSliderEN:@"FOV"         ES:@"FOV"             VI:@"FOV"
                          key:@"FovSize" min:5 max:48 fallback:40 y:y];
        y = [self addSection:@"— WEAPONS —" y:y];
        y = [self addToggleEN:@"Fast Fire"   ES:@"Disparo rápido" VI:@"Bắn nhanh"        key:@"FastFire"         fallback:NO  y:y];
        y = [self addToggleEN:@"No Reload"   ES:@"Sin recarga"    VI:@"Không nạp đạn"   key:@"ShootNoReload"    fallback:NO  y:y];

    // ─── TAB 2: COLORS ───────────────────────────────────────────────────────
    } else if (self.page == 2) {
        CGFloat w = [self contentWidth];
        UISegmentedControl *target = [[UISegmentedControl alloc] initWithItems:@[@"Box", @"FOV"]];
        target.frame = CGRectMake(0, y, w, 36);
        target.selectedSegmentIndex = self.colorTarget;
        target.selectedSegmentTintColor = [UIColor colorWithWhite:1 alpha:0.22];
        [target setTitleTextAttributes:@{NSForegroundColorAttributeName:LblPrimary(),
            NSFontAttributeName:[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]}
                               forState:UIControlStateNormal];
        [target setTitleTextAttributes:@{NSForegroundColorAttributeName:LblPrimary()}
                               forState:UIControlStateSelected];
        [target addTarget:self action:@selector(colorTargetChanged:)
             forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:target];
        [self.controls addObject:(UIControl *)target];
        y += 44;

        NSString *pfx = (self.colorTarget == 0) ? @"BoxColor" : @"FovColor";
        float r = ESPPrefsFloat([pfx stringByAppendingString:@"R"], 0.46);
        float g = ESPPrefsFloat([pfx stringByAppendingString:@"G"], 0.86);
        float b = ESPPrefsFloat([pfx stringByAppendingString:@"B"], 0.73);
        UIColor *swCol = [UIColor colorWithRed:r green:g blue:b alpha:1.0];

        UILabel *swatch = [[UILabel alloc] initWithFrame:CGRectMake(0, y, w, 50)];
        swatch.text = [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)round(r*255), (int)round(g*255), (int)round(b*255)];
        swatch.textAlignment   = NSTextAlignmentCenter;
        swatch.backgroundColor = swCol;
        CGFloat lum = r*0.299 + g*0.587 + b*0.114;
        swatch.textColor   = lum > 0.6 ? UIColor.blackColor : UIColor.whiteColor;
        swatch.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        swatch.layer.cornerRadius = 16;
        swatch.clipsToBounds = YES;
        [self.scroll addSubview:swatch];
        y += 58;

        NSArray *rgbEN  = @[@"Red",   @"Green",   @"Blue"];
        NSArray *rgbES  = @[@"Rojo",  @"Verde",   @"Azul"];
        NSArray *rgbVI  = @[@"Đỏ",    @"Xanh lá", @"Xanh dương"];
        NSArray *rgbSuf = @[@"R",     @"G",       @"B"];
        float    rgbDef[3] = {0.46f,  0.86f,      0.73f};
        for (int i = 0; i < 3; i++) {
            NSString *key = [pfx stringByAppendingString:rgbSuf[i]];
            y = [self addSliderEN:rgbEN[i] ES:rgbES[i] VI:rgbVI[i]
                              key:key min:0 max:1 fallback:rgbDef[i] y:y];
        }

    // ─── TAB 3: MISC — incluye Extras + Movement + efectos (Visual Spin, etc.) ──
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
        y = [self addToggleEN:@"Hide Capture"    ES:@"Ocultar capturas"  VI:@"Ẩn chụp màn hình"
                          key:@"AnLive" fallback:NO y:y];
        y = [self addToggleEN:@"Balanced Render" ES:@"Render equilibrado" VI:@"Render cân bằng"
                          key:@"BalancedRender" fallback:NO y:y];

    // ─── TAB 4: SETTINGS ─────────────────────────────────────────────────────
    } else {
        CGFloat w = [self contentWidth];

        // Idioma
        y = [self addSection:@"— LANGUAGE —" y:y];
        UIView *langRow = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, 52)];
        langRow.backgroundColor    = RowOFF();
        langRow.layer.cornerRadius = 16;
        NSArray *codes = @[@"EN", @"ES", @"VI"];
        NSArray *fullNames = @[@"English", @"Español", @"Tiếng Việt"];
        CGFloat lbtnW = (w - 32 - 12) / 3.0;
        NSInteger curLang = DAAELang();
        for (NSInteger k = 0; k < 3; k++) {
            UIButton *lb = [UIButton buttonWithType:UIButtonTypeCustom];
            lb.frame = CGRectMake(16 + k * (lbtnW + 6), 10, lbtnW, 32);
            lb.backgroundColor    = (k == curLang) ? UIColor.whiteColor
                                                    : [UIColor colorWithWhite:1 alpha:0.10];
            lb.layer.cornerRadius = 10;
            [lb setTitle:codes[k] forState:UIControlStateNormal];
            lb.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
            [lb setTitleColor:(k == curLang) ? UIColor.blackColor : LblPrimary()
                     forState:UIControlStateNormal];
            objc_setAssociatedObject(lb, "langIdx", @(k), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [lb addTarget:self action:@selector(langTap:) forControlEvents:UIControlEventTouchUpInside];
            [langRow addSubview:lb];
        }
        [self.scroll addSubview:langRow];
        y += 60;

        // Mostrar nombre del idioma seleccionado
        UILabel *langHint = [[UILabel alloc] initWithFrame:CGRectMake(4, y, w - 8, 18)];
        langHint.text = fullNames[curLang];
        langHint.textColor = SectionClr();
        langHint.font = [UIFont systemFontOfSize:11];
        langHint.textAlignment = NSTextAlignmentCenter;
        [self.scroll addSubview:langHint];
        y += 26;

        // Info
        y = [self addSection:@"— INFO —" y:y];

        struct { NSString *title; NSString *value; } infoRows[] = {
            { @"Product",  @"DAAE IOS"        },
            { @"Creator",  @"@didierxit7"      },
            { @"Telegram", @"t.me/didierxit7"  },
            { @"Key",      @"TEST"             },
        };
        for (int i = 0; i < 4; i++) {
            BOOL isKey = (i == 3);
            UIView *row = InfoRow(infoRows[i].title, infoRows[i].value, w, isKey);
            row.frame = CGRectMake(0, y, w, 52);
            [self.scroll addSubview:row];
            y += 58;
        }
    }

    // Pie
    UILabel *credit = [[UILabel alloc] initWithFrame:
        CGRectMake(0, y + 10, [self contentWidth], 16)];
    credit.text          = @"DAAE IOS";
    credit.textColor     = [UIColor colorWithWhite:1 alpha:0.14];
    credit.font          = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    credit.textAlignment = NSTextAlignmentCenter;
    [self.scroll addSubview:credit];
    y += 32;

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
    CGRect f  = self.panel.frame;
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
// _0xF010 — touch routing preservado
// ─────────────────────────────────────────────────────────────────────────────
- (BOOL)_0xF010:(CGPoint)point phase:(NSInteger)phase pointerId:(NSInteger)pointerId {
    if (phase == UITouchPhaseBegan) {
        if (!CGRectContainsPoint(self.panel.frame, point)) return NO;
        if (self.pointer != -1) return YES;
        self.pointer = pointerId; self.began = point;
        self.panelOrigin  = self.panel.frame.origin;
        self.scrollOrigin = self.scroll.contentOffset.y;
        self.scrolling = NO; self.activeControl = nil;
        CGPoint local = [self.panel convertPoint:point fromView:self.view];
        // Sidebar (x < 70) o header (y < 54, fuera del botón cerrar) → drag
        self.dragging = (local.x < 70) ||
                        (local.y < 54 && local.x < self.panel.bounds.size.width - 44);
        if (self.dragging) return YES;
        // Hit controls
        CGPoint scrollLocal = [self.scroll convertPoint:point fromView:self.view];
        for (UIView *c in self.controls) {
            if (![c isKindOfClass:UIControl.class]) continue;
            UIControl *ctrl = (UIControl *)c;
            if (!ctrl.enabled) continue;
            if (CGRectContainsPoint([ctrl convertRect:ctrl.bounds toView:self.scroll], scrollLocal))
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

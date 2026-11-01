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
// PALETA — solo oscuro
// ─────────────────────────────────────────────────────────────────────────────
static UIColor *PanelBG(void)     { return [UIColor colorWithRed:0.17 green:0.13 blue:0.11 alpha:0.93]; }
static UIColor *RowOFF(void)      { return [UIColor colorWithWhite:1 alpha:0.06]; }
static UIColor *RowON(void)       { return [UIColor colorWithRed:0.25 green:0.20 blue:0.17 alpha:0.85]; }
static UIColor *SectionClr(void)  { return [UIColor colorWithWhite:1 alpha:0.45]; }
static UIColor *LblPrimary(void)  { return UIColor.whiteColor; }
static UIColor *LblSec(void)      { return [UIColor colorWithWhite:1 alpha:0.65]; }
static UIColor *LblTer(void)      { return [UIColor colorWithWhite:1 alpha:0.45]; }

// ─────────────────────────────────────────────────────────────────────────────
// LABEL TRILINGÜE
// ─────────────────────────────────────────────────────────────────────────────
static UILabel *TriLabel(NSString *en, NSString *es, NSString *vi, CGFloat maxW) {
    NSMutableAttributedString *as = [NSMutableAttributedString new];
    NSDictionary *a0 = @{NSFontAttributeName:[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold],
                         NSForegroundColorAttributeName:LblPrimary()};
    NSDictionary *a1 = @{NSFontAttributeName:[UIFont systemFontOfSize:11 weight:UIFontWeightRegular],
                         NSForegroundColorAttributeName:LblSec()};
    NSDictionary *a2 = @{NSFontAttributeName:[UIFont systemFontOfSize:10 weight:UIFontWeightRegular],
                         NSForegroundColorAttributeName:LblTer()};
    [as appendAttributedString:[[NSAttributedString alloc] initWithString:en attributes:a0]];
    [as appendAttributedString:[[NSAttributedString alloc] initWithString:[@"\n" stringByAppendingString:es] attributes:a1]];
    [as appendAttributedString:[[NSAttributedString alloc] initWithString:[@"\n" stringByAppendingString:vi] attributes:a2]];
    UILabel *l = [[UILabel alloc] init];
    l.attributedText = as;
    l.numberOfLines  = 0;
    CGSize sz = [as boundingRectWithSize:CGSizeMake(maxW, 9999)
                                 options:NSStringDrawingUsesLineFragmentOrigin
                                 context:nil].size;
    l.frame = CGRectMake(0, 0, maxW, ceil(sz.height));
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
        _iv.tintColor   = [UIColor colorWithWhite:0.1 alpha:1.0];
        _iv.contentMode = UIViewContentModeScaleAspectFit;
        _iv.frame = CGRectInset(self.bounds, 5, 5);
        [self addSubview:_iv];
        [self setOn:NO animated:NO];
    }
    return self;
}
- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }
- (void)setOn:(BOOL)on animated:(BOOL)anim {
    _on = on;
    void (^upd)(void) = ^{
        self.backgroundColor = on ? [UIColor colorWithWhite:1 alpha:0.22]
                                  : [UIColor colorWithWhite:1 alpha:0.10];
        self->_iv.hidden = !on;
    };
    if (anim) [UIView animateWithDuration:0.18 delay:0
                                  options:UIViewAnimationOptionCurveEaseInOut
                               animations:upd completion:nil];
    else upd();
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE ROW
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
    CGFloat labelW = w - 70;
    UILabel *measure = TriLabel(en, es, vi, labelW);
    CGFloat contentH = MAX(52.0, measure.bounds.size.height + 20);
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, contentH)])) {
        self.toggleOn = on;
        [self _applyStyle:on];
        UILabel *lbl = TriLabel(en, es, vi, labelW);
        CGFloat lblH = lbl.bounds.size.height;
        lbl.frame = CGRectMake(16, (contentH - lblH) / 2.0, labelW, lblH);
        [self addSubview:lbl];
        self.check = [[DAAECheck alloc] initWithFrame:
            CGRectMake(w - 46, (contentH - 28) / 2.0, 28, 28)];
        [self.check setOn:on animated:NO];
        [self addSubview:self.check];
        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)_applyStyle:(BOOL)on {
    self.backgroundColor    = on ? RowON() : RowOFF();
    self.layer.cornerRadius = 14;
    self.layer.borderWidth  = on ? 0.8 : 0;
    self.layer.borderColor  = on ? [UIColor colorWithWhite:1 alpha:0.18].CGColor
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
    if ((self = [super initWithFrame:CGRectMake(0, 0, w, 76)])) {
        self.backgroundColor    = RowOFF();
        self.layer.cornerRadius = 14;
        UILabel *lbl = TriLabel(en, es, vi, w - 90);
        lbl.frame = CGRectMake(16, 8, w - 90, lbl.bounds.size.height);
        [self addSubview:lbl];
        UILabel *val = [[UILabel alloc] initWithFrame:CGRectMake(w - 64, 6, 52, 22)];
        val.textAlignment = NSTextAlignmentRight;
        val.textColor = LblPrimary();
        val.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        float cur = ESPPrefsFloat(key, fb);
        val.text = [NSString stringWithFormat:@"%.0f", cur];
        [self addSubview:val];
        UISlider *sl = [[UISlider alloc] initWithFrame:CGRectMake(14, 48, w - 28, 22)];
        sl.minimumValue          = mn;
        sl.maximumValue          = mx;
        sl.value                 = cur;
        sl.minimumTrackTintColor = [UIColor colorWithWhite:1 alpha:0.80];
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

    self.blurBG = [[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark]];
    self.blurBG.layer.cornerRadius = 22;
    self.blurBG.clipsToBounds = YES;
    [self.view addSubview:self.blurBG];

    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.backgroundColor    = PanelBG();
    self.panel.layer.cornerRadius = 22;
    self.panel.layer.borderWidth  = 0.7;
    self.panel.layer.borderColor  = [UIColor colorWithWhite:1 alpha:0.14].CGColor;
    self.panel.clipsToBounds = YES;
    [self.view addSubview:self.panel];

    self.sidebar = [[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08];
    [self.panel addSubview:self.sidebar];

    UIView *div = [[UIView alloc] initWithFrame:CGRectZero];
    div.tag = 99;
    div.backgroundColor = [UIColor colorWithWhite:1 alpha:0.06];
    [self.panel addSubview:div];

    self.contentArea = [[UIView alloc] initWithFrame:CGRectZero];
    self.contentArea.backgroundColor = UIColor.clearColor;
    [self.panel addSubview:self.contentArea];

    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator = NO;
    self.scroll.bounces = YES;
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sw = self.view.bounds.size.width;
    CGFloat sh = self.view.bounds.size.height;
    if (sw <= 0) sw = 320; if (sh <= 0) sh = 480;

    CGFloat pw = MIN(380.0, MAX(220.0, sw - 32.0));
    CGFloat ph = MIN(520.0, MAX(300.0, sh - 48.0));

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

    const CGFloat sbW = 62.0;
    self.sidebar.frame = CGRectMake(0, 0, sbW, ph);

    UIView *div = [self.panel viewWithTag:99];
    div.frame = CGRectMake(sbW, 0, 0.5, ph);

    CGFloat caX = sbW + 0.5;
    self.contentArea.frame = CGRectMake(caX, 0, pw - caX, ph);

    const CGFloat headerH = 48.0;
    self.scroll.frame = CGRectMake(0, headerH, pw - caX, ph - headerH);

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
// Tab 4: Config       wrench.and.screwdriver.fill
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildSidebar {
    for (UIView *v in self.sidebar.subviews) [v removeFromSuperview];
    NSArray *icons = @[@"eye.fill", @"scope", @"paintpalette.fill",
                       @"shippingbox.fill", @"wrench.and.screwdriver.fill"];
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag = 300 + i;
        btn.layer.cornerRadius = 22;
        UIImage *img = SFSym(icons[i], 18, UIImageSymbolWeightSemibold);
        [btn setImage:img forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(sidebarTap:)
            forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
    }
    [self layoutSidebarButtons];
    [self refreshSidebarSelection];
}

- (void)layoutSidebarButtons {
    const CGFloat btnSz = 44, gap = 14;
    CGFloat total = 5 * btnSz + 4 * gap;
    CGFloat sbH = self.sidebar.bounds.size.height;
    if (sbH < 1) sbH = 300;
    CGFloat startY = (sbH - total) / 2.0;
    for (NSInteger i = 0; i < 5; i++) {
        UIButton *btn = (UIButton *)[self.sidebar viewWithTag:300 + i];
        if (!btn) continue;
        btn.frame = CGRectMake((62 - btnSz) / 2.0, startY + i * (btnSz + gap), btnSz, btnSz);
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
    if (cw < 10) cw = 280;

    NSArray *icons = @[@"eye.fill", @"scope", @"paintpalette.fill",
                       @"shippingbox.fill", @"wrench.and.screwdriver.fill"];
    NSArray *names = @[@"ESP", @"Aim", @"Colors", @"Misc", @"Config"];

    UIView *hdr = [[UIView alloc] initWithFrame:CGRectMake(8, 6, cw - 16, 36)];
    hdr.tag = 500;
    hdr.backgroundColor    = [UIColor colorWithWhite:1 alpha:0.05];
    hdr.layer.cornerRadius = 12;
    [self.contentArea addSubview:hdr];

    UIImageView *iv = [[UIImageView alloc] initWithImage:
        SFSym(icons[self.page], 13, UIImageSymbolWeightSemibold)];
    iv.tag = 501;
    iv.tintColor   = LblPrimary();
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.frame = CGRectMake(22, 16, 15, 15);
    [self.contentArea addSubview:iv];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(42, 9, cw - 100, 28)];
    title.tag       = 502;
    title.text      = names[self.page];
    title.textColor = LblPrimary();
    title.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    [self.contentArea addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.tag   = 503;
    close.frame = CGRectMake(cw - 38, 10, 26, 26);
    [close setImage:SFSym(@"xmark", 11, UIImageSymbolWeightBold) forState:UIControlStateNormal];
    close.tintColor = [UIColor colorWithWhite:1 alpha:0.40];
    [close addTarget:self action:@selector(closeMenu)
        forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:close];
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
- (CGFloat)contentWidth {
    return self.scroll.bounds.size.width > 10 ? self.scroll.bounds.size.width : 280;
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
    return y + row.bounds.size.height + 6;
}

- (CGFloat)addSection:(NSString *)title y:(CGFloat)y {
    UILabel *l = [[UILabel alloc] initWithFrame:CGRectMake(4, y + 4, [self contentWidth] - 8, 20)];
    l.text      = title;
    l.textColor = SectionClr();
    l.font      = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
    [self.scroll addSubview:l];
    return y + 28;
}

- (CGFloat)addSliderEN:(NSString *)en ES:(NSString *)es VI:(NSString *)vi
                   key:(NSString *)key min:(float)mn max:(float)mx fallback:(float)fb y:(CGFloat)y {
    CGFloat w = [self contentWidth];
    DAAESlider *sl = [[DAAESlider alloc] initWithEN:en ES:es VI:vi
                                                key:key min:mn max:mx fallback:fb width:w];
    sl.frame = CGRectMake(0, y, w, 76);
    [self.controls addObject:(UIControl *)sl];
    [self.scroll addSubview:sl];
    return y + 82;
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
    CGFloat y = 8;

    // ── TAB 0: ESP ────────────────────────────────────────────────────────────
    if (self.page == 0) {
        y = [self addToggleEN:@"ESP Master"  ES:@"Maestro ESP"    VI:@"Chế độ ESP"    key:@"ESPEnabled" fallback:YES y:y];
        y = [self addSection:@"— DRAW —" y:y];
        y = [self addToggleEN:@"Box ESP"     ES:@"Caja ESP"        VI:@"Hộp ESP"       key:@"Box"        fallback:YES y:y];
        y = [self addToggleEN:@"Line ESP"    ES:@"Ejes XYZ"        VI:@"Đường thẳng"  key:@"Line"       fallback:NO  y:y];
        y = [self addToggleEN:@"Skeleton"    ES:@"Esqueleto"       VI:@"Xương"         key:@"Skeleton"   fallback:NO  y:y];
        y = [self addToggleEN:@"Head Dot"    ES:@"Punto cabeza"    VI:@"Chấm đầu"      key:@"HeadRedDot" fallback:NO  y:y];
        y = [self addToggleEN:@"Health Bar"  ES:@"Barra de vida"   VI:@"Thanh máu"    key:@"Health"     fallback:YES y:y];
        y = [self addToggleEN:@"Name"        ES:@"Nombre"          VI:@"Tên"           key:@"Name"       fallback:YES y:y];
        y = [self addToggleEN:@"Distance"    ES:@"Distancia"       VI:@"Khoảng cách"  key:@"Dis"        fallback:YES y:y];
        y = [self addToggleEN:@"Clean ESP"   ES:@"ESP limpio"      VI:@"ESP sạch"      key:@"CleanESP"   fallback:YES y:y];
        y = [self addSection:@"— FOV —" y:y];
        y = [self addToggleEN:@"Show FOV"    ES:@"Mostrar FOV"     VI:@"Hiện FOV"      key:@"ShowFov"    fallback:YES y:y];
        y = [self addSliderEN:@"FOV Size"    ES:@"Tamaño FOV"      VI:@"Cỡ FOV"
                          key:@"FovSize" min:5 max:48 fallback:40 y:y];

    // ── TAB 1: AIM ────────────────────────────────────────────────────────────
    } else if (self.page == 1) {
        y = [self addSection:@"— AIM TYPE —" y:y];

        // Grupo exclusivo — todos pueden estar OFF
        NSArray *aimEN = @[@"Aim Head",    @"Aim Neck",                @"Silent Aim"];
        NSArray *aimES = @[@"Apuntar cabeza", @"Apuntar cuello",       @"Apuntado silencioso"];
        NSArray *aimVI = @[@"Bắn đầu",    @"Bắn cổ",                  @"Bắn im lặng"];
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
            y += row.bounds.size.height + 6;
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
                            [UIView animateWithDuration:0.18 animations:^{ [rows[j] _applyStyle:NO]; }];
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

        // Activation — solo si hay aim activo y no es Silent
        const BOOL isSilent = (AimModePolicy::ReadType(ESPPrefsFloat(@"AimType",0))
                               == AimModePolicy::Type::Silent);
        if (hasValidType && !isSilent) {
            y = [self addSection:@"— ACTIVATION —" y:y];
            NSArray *actEN = @[@"On Shoot",   @"On Scope",    @"Always",      @"Fire+Scope"];
            NSArray *actES = @[@"Al disparar",@"Al apuntar",  @"Siempre",     @"Disparar+Scope"];
            NSArray *actVI = @[@"Khi bắn",    @"Khi ngắm",   @"Luôn luôn",  @"Bắn+Ngắm"];
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
                y += row.bounds.size.height + 6;
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
                                [UIView animateWithDuration:0.18 animations:^{ [rows[j] _applyStyle:NO]; }];
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

        y = [self addToggleEN:@"Aim Lag"     ES:@"Retraso de aim"  VI:@"Trễ aim"           key:@"AimLag"           fallback:NO  y:y];
        y = [self addToggleEN:@"Target Line" ES:@"Línea objetivo"   VI:@"Đường mục tiêu"   key:@"AimTargetLine"    fallback:YES y:y];
        y = [self addToggleEN:@"AimKill"     ES:@"Matar con aim"    VI:@"Aim giết"          key:@"AutoFireFloating" fallback:NO  y:y];
        y = [self addSliderEN:@"FOV"         ES:@"FOV"              VI:@"FOV"
                          key:@"FovSize" min:5 max:48 fallback:40 y:y];
        y = [self addSection:@"— WEAPONS —" y:y];
        y = [self addToggleEN:@"Fast Fire"   ES:@"Disparo rápido"  VI:@"Bắn nhanh"         key:@"FastFire"         fallback:NO  y:y];
        y = [self addToggleEN:@"No Reload"   ES:@"Sin recarga"     VI:@"Không nạp đạn"    key:@"ShootNoReload"    fallback:NO  y:y];

    // ── TAB 2: COLORS ─────────────────────────────────────────────────────────
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

        UILabel *swatch = [[UILabel alloc] initWithFrame:CGRectMake(0, y, w, 48)];
        swatch.text = [NSString stringWithFormat:@"#%02X%02X%02X",
            (int)round(r*255), (int)round(g*255), (int)round(b*255)];
        swatch.textAlignment  = NSTextAlignmentCenter;
        swatch.backgroundColor = swCol;
        CGFloat lum = r*0.299 + g*0.587 + b*0.114;
        swatch.textColor  = lum > 0.6 ? UIColor.blackColor : UIColor.whiteColor;
        swatch.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
        swatch.layer.cornerRadius = 14;
        swatch.clipsToBounds = YES;
        [self.scroll addSubview:swatch];
        y += 56;

        NSArray *rgbEN  = @[@"Red",    @"Green",   @"Blue"];
        NSArray *rgbES  = @[@"Rojo",   @"Verde",   @"Azul"];
        NSArray *rgbVI  = @[@"Đỏ",     @"Xanh lá", @"Xanh dương"];
        NSArray *rgbSuf = @[@"R",      @"G",       @"B"];
        float    rgbDef[3] = {0.46f,   0.86f,      0.73f};
        for (int i = 0; i < 3; i++) {
            NSString *key = [pfx stringByAppendingString:rgbSuf[i]];
            y = [self addSliderEN:rgbEN[i] ES:rgbES[i] VI:rgbVI[i]
                              key:key min:0 max:1 fallback:rgbDef[i] y:y];
        }

    // ── TAB 3: MISC ───────────────────────────────────────────────────────────
    } else if (self.page == 3) {
        y = [self addSection:@"— EXTRAS —" y:y];
        y = [self addToggleEN:@"Ghost"        ES:@"Fantasma"          VI:@"Bóng ma"              key:@"GhostModeFloating"  fallback:NO y:y];
        y = [self addToggleEN:@"FakeLag"      ES:@"Lag falso"         VI:@"Lag giả"              key:@"FakeLagFloating"    fallback:NO y:y];
        y = [self addToggleEN:@"Fly"          ES:@"Volar"             VI:@"Bay"                  key:@"FlyFloating"        fallback:NO y:y];
        y = [self addToggleEN:@"Speed"        ES:@"Velocidad"         VI:@"Tốc độ"               key:@"RunSpeedFloating"   fallback:NO y:y];
        y = [self addToggleEN:@"Hide Buttons" ES:@"Ocultar botones"   VI:@"Ẩn nút"               key:@"HideFeatureButtons" fallback:NO y:y];
        y = [self addToggleEN:@"AimKill"      ES:@"Matar con aim"     VI:@"Aim giết"             key:@"AutoFireFloating"   fallback:NO y:y];
        y = [self addSection:@"— MOVEMENT —" y:y];
        y = [self addToggleEN:@"Speed Toggle" ES:@"Velocidad"         VI:@"Tốc độ"               key:@"RunSpeed"           fallback:NO y:y];
        y = [self addSliderEN:@"Speed Value"  ES:@"Velocidad (m/s)"   VI:@"Tốc độ (m/s)"
                          key:@"RunSpeedValue" min:1 max:15 fallback:6 y:y];
        if (ESPPrefsBool(@"FlyFloating", NO))
            y = [self addSliderEN:@"Fly Height" ES:@"Altura vuelo"    VI:@"Độ cao bay"
                              key:@"FlyHeight" min:1 max:6 fallback:4 y:y];

    // ── TAB 4: CONFIG ─────────────────────────────────────────────────────────
    } else {
        y = [self addToggleEN:@"Visual Spin"     ES:@"Giro visual"        VI:@"Xoay hiển thị"
                          key:@"VisualSpin" fallback:NO y:y];
        if (ESPPrefsBool(@"VisualSpin", NO)) {
            y = [self addSliderEN:@"Spin Speed"  ES:@"Vel. giro"          VI:@"Tốc độ xoay"
                              key:@"VisualSpinSpeed" min:0.1 max:3 fallback:0.5 y:y];
            self.spinStatusLabel = [[UILabel alloc] initWithFrame:
                CGRectMake(6, y, [self contentWidth]-12, 34)];
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
    }

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
        self.dragging = (local.x < 64) ||
                        (local.y < 50 && local.x < self.panel.bounds.size.width - 40);
        if (self.dragging) return YES;
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

//
//  _0xMO353DA.mm
//  FLOATING MODERN MENU â€” LIGHT MODE / DARK MODE ONLY.
//  No accent colors. No gradients. Complete visual redesign.
//  Categories: ESP | AIM | DRAW | TOOLS | SETTINGS
//  "Menu Size" slider scales the ROOT container uniformly (menuScale), centered, real-time, persistent.
//

#import <UIKit/UIKit.h>
#import "ModMenuViewController.h"
#import "MizzeTheme.h"
#import "MizzeMenuPrefs.h"
#include <cmath>
#import <objc/runtime.h>
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPStyle.h"
#import "../esp/Core/PlayerModes.h"
#import "UIView+SecureView.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

#pragma mark - Layout constants

static CGFloat const kSideW   = 68.0f;   // sidebar width
static CGFloat const kSidePad = 10.0f;   // outer margin
static CGFloat const kSideBtn = 46.0f;   // circular nav button
static CGFloat const kPanelR  = 30.0f;   // panel corner radius
static CGFloat const kCardR   = 24.0f;   // card corner radius
static CGFloat const kPad     = 16.0f;   // inner padding
static CGFloat const kRowH    = 60.0f;   // row height
static CGFloat const kHeadH   = 52.0f;   // header height

static CGFloat gMenuScale = 1.0f;        // GLOBAL UI SCALE (0.7 ... 1.3)

#pragma mark - Prefs helpers

static NSUserDefaults *UD() { return [NSUserDefaults standardUserDefaults]; }
static inline float PF(NSString *key, float def) { return ESPPrefsFloat(key, def); }
static inline void  PS(NSString *key, float v)  { ESPPrefsSetFloat(key, v); ESPSyncFromPrefs(); }
static inline void  PDef(NSString *key, float v) { if (ESPPrefsFloat(key, 999999.0f) == 999999.0f) ESPPrefsSetFloat(key, v); }

static inline NSInteger MMLang() { return [UD() integerForKey:@"DAAE.lang"]; }
static inline BOOL      MMDark() { return [UD() boolForKey:@"DAAE.darkMode"]; }

static inline NSString *L(NSString *en, NSString *es, NSString *vi) {
    switch (MMLang()) { case 1: return es; case 2: return vi; default: return en; }
}

#pragma mark - Theme (LIGHT / DARK only â€” NO accent colors)

static BOOL gDark = YES;

static UIColor *HexRGB(NSInteger h, CGFloat a) {
    return [UIColor colorWithRed:((h >> 16) & 0xFF) / 255.0f
                           green:((h >>  8) & 0xFF) / 255.0f
                            blue:((h      ) & 0xFF) / 255.0f
                           alpha:a];
}
#define GRAY(dk, lt) (gDark ? (dk) : (lt))
static UIColor *CPanelBG()  { return GRAY(HexRGB(0x242426, 0.88f), HexRGB(0xFFFFFF, 0.82f)); }
static UIColor *CControl()  { return GRAY(HexRGB(0x303034, 1.0f), HexRGB(0xE8E8ED, 1.0f)); }
static UIColor *CSelected() { return GRAY(HexRGB(0x414146, 1.0f), HexRGB(0xDCDCE2, 1.0f)); }
static UIColor *CText()     { return GRAY(HexRGB(0xF5F5F7, 1.0f), HexRGB(0x171717, 1.0f)); }
static UIColor *CDim()      { return GRAY(HexRGB(0xA5A5AA, 1.0f), HexRGB(0x77777D, 1.0f)); }
static UIColor *CIcon()     { return GRAY(HexRGB(0xEEEEF0, 1.0f), HexRGB(0x292929, 1.0f)); }
static UIColor *CIconDim()  { return GRAY(HexRGB(0xA5A5AA, 1.0f), HexRGB(0x77777D, 1.0f)); }
static UIColor *CBorder()   { return GRAY([[UIColor whiteColor] colorWithAlphaComponent:0.10f], HexRGB(0xD5D5DA, 0.55f)); }
static UIColor *CSep()      { return GRAY([[UIColor whiteColor] colorWithAlphaComponent:0.08f], HexRGB(0xDADAE0, 1.0f)); }
static UIColor *CKnob()     { return GRAY(HexRGB(0x242426, 1.0f), HexRGB(0xFFFFFF, 1.0f)); }

static NSHashTable *gThemed = nil;
static void DAAEThemeRegister(id obj) {
    if (!gThemed) gThemed = [NSHashTable weakObjectsHashTable];
    [gThemed addObject:obj];
}
static void DAAEThemeApplyAll(BOOL dark) {
    gDark = dark;
    for (id o in gThemed) if ([o respondsToSelector:@selector(applyTheme)]) [o applyTheme];
}

static UIImage *UISI(NSString *name, NSString *fallback) {
    UIImage *i = [UIImage systemImageNamed:name];
    if (!i && fallback.length) i = [UIImage systemImageNamed:fallback];
    return i;
}

static void DAAESecureView(UIView *v) {
    if (!v) return;
    NSArray *names = @[@"makeSecure", @"secureThisView", @"applySecure", @"addSecureOverlay"];
    for (NSString *n in names) {
        SEL s = NSSelectorFromString(n);
        if ([v respondsToSelector:s]) { ((void (*)(id, SEL))objc_msgSend)(v, s); return; }
    }
}

#pragma mark - Themed label / slider (themeable without crashes)

@interface DAAEThemedLabel : UILabel
@end
@implementation DAAEThemedLabel
- (void)applyTheme { self.textColor = CText(); }
@end

@interface DAAEThemedSlider : UISlider
@end
@implementation DAAEThemedSlider
- (void)applyTheme {
    self.minimumTrackTintColor = CSelected();
    self.maximumTrackTintColor = CBorder();
    self.thumbTintColor = CKnob();
}
@end

#pragma mark - Switch (capsule, neutral â€” no green/blue)

@interface DAAESwitch : UIControl
@property (nonatomic, assign) BOOL on;
@end

@implementation DAAESwitch {
    UIView *_track;
    UIView *_knob;
}
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        _track = [[UIView alloc] initWithFrame:CGRectZero];
        _track.layer.masksToBounds = YES;
        [self addSubview:_track];
        _knob = [[UIView alloc] initWithFrame:CGRectZero];
        _knob.layer.shadowColor = [UIColor blackColor].CGColor;
        _knob.layer.shadowOpacity = 0.15f;
        _knob.layer.shadowRadius = 2.0f;
        _knob.layer.shadowOffset = CGSizeMake(0, 1);
        [self addSubview:_knob];
        _on = NO;
        [self _layoutKnobAnimated:NO];
        DAAEThemeRegister(self);
        [self applyTheme];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _track.frame = self.bounds;
    _track.layer.cornerRadius = self.bounds.size.height / 2.0f;
    [self _layoutKnobAnimated:NO];
}
- (void)_layoutKnobAnimated:(BOOL)animated {
    CGFloat kn = self.bounds.size.height - 4.0f;
    CGFloat x = _on ? self.bounds.size.width - kn - 2.0f : 2.0f;
    CGRect nf = CGRectMake(x, 2.0f, kn, kn);
    if (animated) {
        [UIView animateWithDuration:0.22f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            _knob.frame = nf;
            _track.backgroundColor = _on ? CSelected() : CControl();
        } completion:^(BOOL _) { _knob.layer.cornerRadius = _knob.frame.size.width / 2.0f; }];
    } else {
        _knob.frame = nf;
        _knob.layer.cornerRadius = kn / 2.0f;
    }
}
- (void)setOn:(BOOL)on {
    _on = on;
    [self _layoutKnobAnimated:YES];
    [self applyTheme];
}
- (void)applyTheme {
    _track.backgroundColor = _on ? CSelected() : CControl();
    _knob.backgroundColor = CText();
}
@end

#pragma mark - Radio (circle + check)

@interface DAAERadio : UIView
@property (nonatomic, assign) BOOL on;
@end

@implementation DAAERadio {
    UIImageView *_img;
}
- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.layer.cornerRadius = f.size.width / 2.0f;
        self.layer.borderWidth = 1.5f;
        _img = [[UIImageView alloc] initWithFrame:CGRectInset(self.bounds, f.size.width * 0.22f, f.size.width * 0.22f)];
        _img.contentMode = UIViewContentModeScaleAspectFit;
        _img.image = UISI(@"checkmark", @"check");
        _img.alpha = 0.0f;
        [self addSubview:_img];
        DAAEThemeRegister(self);
        [self applyTheme];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = self.bounds.size.width / 2.0f;
    _img.frame = CGRectInset(self.bounds, self.bounds.size.width * 0.22f, self.bounds.size.width * 0.22f);
}
- (void)setOn:(BOOL)on {
    _on = on;
    [UIView animateWithDuration:0.18f animations:^{ _img.alpha = on ? 1.0f : 0.0f; }];
    [self applyTheme];
}
- (void)applyTheme {
    self.backgroundColor = _on ? CText() : CControl();
    self.layer.borderColor = (_on ? CText() : CBorder()).CGColor;
    _img.tintColor = _on ? (gDark ? HexRGB(0x171719, 1.0f) : [UIColor whiteColor]) : CDim();
}
@end

#pragma mark - Toggle row (card + switch)

@interface DAAEToggleRow : UIControl
@property (nonatomic, assign) BOOL on;
@property (nonatomic, copy) void (^onChanged)(BOOL);
@end

@implementation DAAEToggleRow {
    UILabel *_lbl;
    DAAESwitch *_sw;
    NSString *_key;
}
- (instancetype)initWithFrame:(CGRect)f key:(NSString *)key title:(NSString *)title def:(BOOL)def {
    if ((self = [super initWithFrame:f])) {
        _key = key;
        self.layer.cornerRadius = kCardR;
        self.layer.borderWidth = 0.5f;
        _on = PF(key, def ? 1.0f : 0.0f) > 0.5f;
        _lbl = [[UILabel alloc] initWithFrame:CGRectZero];
        _lbl.text = title;
        _lbl.font = [UIFont systemFontOfSize:15.5f weight:UIFontWeightMedium];
        [self addSubview:_lbl];
        _sw = [[DAAESwitch alloc] initWithFrame:CGRectMake(0, 0, 46.0f, 27.0f)];
        _sw.userInteractionEnabled = NO;
        _sw.on = _on;
        [self addSubview:_sw];
        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
        DAAEThemeRegister(self);
        [self applyTheme];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _lbl.frame = CGRectMake(kPad, 0, self.bounds.size.width - kPad * 2 - 60.0f, self.bounds.size.height);
    _sw.center = CGPointMake(self.bounds.size.width - kPad - 23.0f, self.bounds.size.height / 2.0f);
    [_sw setNeedsLayout];
}
- (void)_tap {
    _on = !_on;
    _sw.on = _on;
    PS(_key, _on ? 1.0f : 0.0f);
    [self applyTheme];
    if (_onChanged) _onChanged(_on);
}
- (void)setOn:(BOOL)on { _on = on; _sw.on = on; [self applyTheme]; }
- (void)applyTheme {
    self.backgroundColor = CControl();
    self.layer.borderColor = CBorder().CGColor;
    _lbl.textColor = CText();
}
@end

#pragma mark - Slider row (card + value pill)

@interface DAAESliderRow : UIControl
@property (nonatomic, copy) void (^onChanged)(float);
@end

@implementation DAAESliderRow {
    UILabel *_lbl, *_val;
    UISlider *_sl;
    NSString *_key;
    BOOL _dec2;
}
- (instancetype)initWithFrame:(CGRect)f key:(NSString *)key title:(NSString *)title min:(CGFloat)min max:(CGFloat)max def:(CGFloat)def {
    if ((self = [super initWithFrame:CGRectMake(f.origin.x, f.origin.y, f.size.width, 74.0f)])) {
        _key = key;
        _dec2 = (max <= 3.0f);
        self.layer.cornerRadius = kCardR;
        self.layer.borderWidth = 0.5f;
        _lbl = [[UILabel alloc] initWithFrame:CGRectZero];
        _lbl.text = title;
        _lbl.font = [UIFont systemFontOfSize:15.5f weight:UIFontWeightMedium];
        [self addSubview:_lbl];
        _val = [[UILabel alloc] initWithFrame:CGRectZero];
        _val.font = [UIFont systemFontOfSize:13.0f weight:UIFontWeightSemibold];
        _val.textAlignment = NSTextAlignmentCenter;
        _val.layer.cornerRadius = 10.0f;
        _val.layer.masksToBounds = YES;
        [self addSubview:_val];
        _sl = [[DAAESlider alloc] initWithFrame:CGRectZero];
        _sl.minimumValue = min;
        _sl.maximumValue = max;
        _sl.value = PF(key, def);
        [_sl addTarget:self action:@selector(_chg:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_sl];
        [self _fmt];
        DAAEThemeRegister(self);
        [self applyTheme];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    _lbl.frame = CGRectMake(kPad, 10.0f, w - kPad * 2 - 88.0f, 20.0f);
    _val.frame = CGRectMake(w - kPad - 80.0f, 6.0f, 80.0f, 26.0f);
    _sl.frame = CGRectMake(kPad, 40.0f, w - kPad * 2, 24.0f);
}
- (void)_fmt {
    float v = _sl.value;
    _val.text = _dec2 ? [NSString stringWithFormat:@"%.2f", v] : [NSString stringWithFormat:@"%.0f", v];
}
- (void)_chg:(UISlider *)s {
    [self _fmt];
    if (_onChanged) _onChanged(s.value);   // live, real-time update
}
- (void)applyTheme {
    self.backgroundColor = CControl();
    self.layer.borderColor = CBorder().CGColor;
    _lbl.textColor = CText();
    _val.textColor = CText();
    _val.backgroundColor = CSelected();
    _sl.minimumTrackTintColor = CSelected();
    _sl.maximumTrackTintColor = CBorder();
    _sl.thumbTintColor = CKnob();
}
@end

#pragma mark - Option row (radio card)

@interface DAAEOptionRow : UIControl
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, copy) void (^onTap)(void);
@end

@implementation DAAEOptionRow {
    UILabel *_lbl;
    DAAERadio *_radio;
}
- (instancetype)initWithFrame:(CGRect)f title:(NSString *)title {
    if ((self = [super initWithFrame:f])) {
        self.layer.cornerRadius = kCardR;
        self.layer.borderWidth = 0.5f;
        _lbl = [[UILabel alloc] initWithFrame:CGRectZero];
        _lbl.text = title;
        _lbl.font = [UIFont systemFontOfSize:15.5f weight:UIFontWeightMedium];
        [self addSubview:_lbl];
        _radio = [[DAAERadio alloc] initWithFrame:CGRectMake(0, 0, 22.0f, 22.0f)];
        [self addSubview:_radio];
        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
        DAAEThemeRegister(self);
        [self applyTheme];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _lbl.frame = CGRectMake(kPad, 0, self.bounds.size.width - kPad * 2 - 36.0f, self.bounds.size.height);
    _radio.center = CGPointMake(self.bounds.size.width - kPad - 11.0f, self.bounds.size.height / 2.0f);
}
- (void)_tap {
    [UIView animateWithDuration:0.10f animations:^{ self.transform = CGAffineTransformMakeScale(0.97f, 0.97f); }
                     completion:^(BOOL _) { [UIView animateWithDuration:0.10f animations:^{ self.transform = CGAffineTransformIdentity; }]; }];
    if (_onTap) _onTap();
}
- (void)setSelected:(BOOL)s { _selected = s; _radio.on = s; [self applyTheme]; }
- (void)applyTheme {
    self.backgroundColor = _selected ? CSelected() : CControl();
    self.layer.borderColor = CBorder().CGColor;
    _lbl.textColor = CText();
}
@end

#pragma mark - Section / Warning / Info

@interface DAAESectionLabel : UILabel
- (instancetype)initWithFrame:(CGRect)f title:(NSString *)title;
@end
@implementation DAAESectionLabel
- (instancetype)initWithFrame:(CGRect)f title:(NSString *)title {
    if ((self = [super initWithFrame:f])) {
        self.text = title;
        self.font = [UIFont systemFontOfSize:12.5f weight:UIFontWeightSemibold];
        DAAEThemeRegister(self);
        [self applyTheme];
    }
    return self;
}
- (void)applyTheme { self.textColor = CDim(); }
@end

@interface DAAEWarningLabel : UILabel
- (instancetype)initWithFrame:(CGRect)f title:(NSString *)title;
@end
@implementation DAAEWarningLabel
- (instancetype)initWithFrame:(CGRect)f title:(NSString *)title {
    if ((self = [super initWithFrame:f])) {
        self.text = title;
        self.numberOfLines = 0;
        self.font = [UIFont systemFontOfSize:12.0f weight:UIFontWeightRegular];
        DAAEThemeRegister(self);
        [self applyTheme];
    }
    return self;
}
- (void)applyTheme { self.textColor = CDim(); }
@end

@interface DAAEInfoRow : UIView
- (instancetype)initWithFrame:(CGRect)f title:(NSString *)title value:(NSString *)value;
@end
@implementation DAAEInfoRow {
    UILabel *_lbl, *_val;
}
- (instancetype)initWithFrame:(CGRect)f title:(NSString *)title value:(NSString *)value {
    if ((self = [super initWithFrame:f])) {
        self.layer.cornerRadius = kCardR;
        self.layer.borderWidth = 0.5f;
        _lbl = [[UILabel alloc] initWithFrame:CGRectZero];
        _lbl.text = title;
        _lbl.font = [UIFont systemFontOfSize:15.5f weight:UIFontWeightMedium];
        [self addSubview:_lbl];
        _val = [[UILabel alloc] initWithFrame:CGRectZero];
        _val.text = value;
        _val.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightSemibold];
        _val.textAlignment = NSTextAlignmentRight;
        [self addSubview:_val];
        DAAEThemeRegister(self);
        [self applyTheme];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    _lbl.frame = CGRectMake(kPad, 0, w * 0.45f, self.bounds.size.height);
    _val.frame = CGRectMake(w * 0.45f, 0, w - kPad - w * 0.45f, self.bounds.size.height);
}
- (void)applyTheme {
    self.backgroundColor = CControl();
    self.layer.borderColor = CBorder().CGColor;
    _lbl.textColor = CText();
    _val.textColor = CDim();
}
@end
#pragma mark - Sidebar button

@interface DAAESideBtn : UIControl
@property (nonatomic, assign) BOOL active;
@property (nonatomic, copy) void (^onTap)(void);
@end

@implementation DAAESideBtn {
    UIImageView *_img;
}
- (instancetype)initWithFrame:(CGRect)f icon:(NSString *)icon {
    if ((self = [super initWithFrame:f])) {
        self.layer.cornerRadius = f.size.width / 2.0f;
        _img = [[UIImageView alloc] initWithImage:UISI(icon, @"circle")];
        _img.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_img];
        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
        DAAEThemeRegister(self);
        [self applyTheme];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _img.frame = CGRectInset(self.bounds, self.bounds.size.width * 0.26f, self.bounds.size.height * 0.26f);
    self.layer.cornerRadius = self.bounds.size.width / 2.0f;
}
- (void)_tap {
    [UIView animateWithDuration:0.10f animations:^{ self.transform = CGAffineTransformMakeScale(0.90f, 0.90f); }
                     completion:^(BOOL _) { [UIView animateWithDuration:0.10f animations:^{ self.transform = CGAffineTransformIdentity; }]; }];
    if (_onTap) _onTap();
}
- (void)setActive:(BOOL)a {
    _active = a;
    [UIView animateWithDuration:0.20f animations:^{
        self.backgroundColor = a ? CSelected() : CControl();
        _img.tintColor = a ? CText() : CIconDim();
    }];
}
- (void)applyTheme {
    self.backgroundColor = _active ? CSelected() : CControl();
    _img.tintColor = _active ? CText() : CIconDim();
}
@end

#pragma mark - Main panel class

@interface _0xDEADBEEE ()
@property (nonatomic, strong) UIView *rootContainer;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIView *sidebar;
@property (nonatomic, strong) UIView *contentArea;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIView *page;
@property (nonatomic, strong) UILabel *headerTitle;
@property (nonatomic, strong) UIControl *btnDark;
@property (nonatomic, strong) UIControl *btnLight;
@property (nonatomic, strong) UIView *headerSep;
@property (nonatomic, strong) NSMutableArray<DAAESideBtn *> *sideBtns;
@property (nonatomic, assign) NSInteger tab;
@property (nonatomic, assign) CGFloat lastW;
@end

@implementation _0xDEADBEEE

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.opaque = NO;
    [self _applyDefaults];
    gMenuScale = PF(@"DAAE.menuScale", 1.0f);
    gDark = MMDark();

    // ROOT container â€” the whole menu scales as ONE unit
    self.rootContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.rootContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.rootContainer];

    self.panel = [[UIView alloc] initWithFrame:CGRectZero];
    self.panel.layer.cornerRadius = kPanelR;
    self.panel.layer.borderWidth = 0.5f;
    self.panel.clipsToBounds = YES;
    [self.rootContainer addSubview:self.panel];

    self.sidebar = [[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.layer.cornerRadius = kPanelR;
    self.sidebar.layer.borderWidth = 0.5f;
    [self.rootContainer addSubview:self.sidebar];

    self.contentArea = [[UIView alloc] initWithFrame:CGRectZero];
    [self.panel addSubview:self.contentArea];

    self.scroll = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator = NO;
    self.scroll.alwaysBounceVertical = YES;
    self.scroll.delaysContentTouches = NO;
    [self.contentArea addSubview:self.scroll];

    self.page = [[UIView alloc] initWithFrame:CGRectZero];
    [self.scroll addSubview:self.page];

    self.sideBtns = [NSMutableArray array];
    [self _buildHeader];
    [self _buildSidebar];
    [self _buildGestures];
    [self _applyThemeAll];
    DAAESecureView(self.view);
}

- (void)_applyDefaults {
    PDef(@"ESPEnabled", 0); PDef(@"Box", 0); PDef(@"Box3D", 0); PDef(@"CleanESP", 0);
    PDef(@"Name", 0); PDef(@"Health", 0); PDef(@"Line", 0); PDef(@"Skeleton", 0);
    PDef(@"HeadRedDot", 0); PDef(@"Dis", 0); PDef(@"AimLag", 0); PDef(@"AimTargetLine", 0);
    PDef(@"SilentAim", 0); PDef(@"AutoFire", 0); PDef(@"AutoFireFloating", 0);
    PDef(@"FastFire", 0); PDef(@"ShootNoReload", 0); PDef(@"GhostModeFloating", 0);
    PDef(@"FakeLagFloating", 0); PDef(@"FlyFloating", 0); PDef(@"RunSpeedFloating", 0);
    PDef(@"RunSpeed", 0); PDef(@"VisualSpin", 0); PDef(@"BalancedRender", 0);
    PDef(@"HideFeatureButtons", 0);
    PDef(@"ShowFov", 1); PDef(@"ExplicitAimMenuV1", 1);
    PDef(@"AimType", -1); PDef(@"AimActivation", 1);
    PDef(@"FovSize", 40); PDef(@"SilentFovSize", 18);
    PDef(@"RunSpeedValue", 6); PDef(@"FlyHeight", 4); PDef(@"VisualSpinSpeed", 0.5f);
    if ([UD() objectForKey:@"DAAE.darkMode"] == nil) [UD() setBool:YES forKey:@"DAAE.darkMode"];
    if (ESPPrefsFloat(@"DAAE.menuScale", 999999.0f) == 999999.0f) ESPPrefsSetFloat(@"DAAE.menuScale", 1.0f);
}

- (void)_buildHeader {
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectZero];
    t.font = [UIFont systemFontOfSize:18.0f weight:UIFontWeightSemibold];
    t.text = @"ESP";
    _headerTitle = t;
    [self.contentArea addSubview:t];

    UIControl *sun = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    UIImageView *si = [[UIImageView alloc] initWithImage:UISI(@"sun.max", @"sun.max.fill")];
    si.contentMode = UIViewContentModeScaleAspectFit;
    si.frame = CGRectInset(sun.bounds, 5, 5);
    [sun addSubview:si];
    [sun addTarget:self action:@selector(_lightTap) forControlEvents:UIControlEventTouchUpInside];
    _btnLight = sun;
    [self.contentArea addSubview:sun];

    UIControl *moon = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    UIImageView *mi = [[UIImageView alloc] initWithImage:UISI(@"moon", @"moon.fill")];
    mi.contentMode = UIViewContentModeScaleAspectFit;
    mi.frame = CGRectInset(moon.bounds, 5, 5);
    [moon addTarget:self action:@selector(_darkTap) forControlEvents:UIControlEventTouchUpInside];
    _btnDark = moon;
    [self.contentArea addSubview:moon];

    UIView *sep = [[UIView alloc] initWithFrame:CGRectZero];
    _headerSep = sep;
    [self.contentArea addSubview:sep];
}

- (void)_buildSidebar {
    NSArray *icons = @[@"eye", @"scope", @"cube", @"wrench.and.screwdriver", @"gearshape"];
    for (NSUInteger i = 0; i < 5; i++) {
        NSInteger idx = (NSInteger)i;
        DAAESideBtn *b = [[DAAESideBtn alloc] initWithFrame:CGRectMake(0, 0, kSideBtn, kSideBtn) icon:icons[i]];
        b.onTap = ^{ [self _selectTab:idx]; };
        [self.sidebar addSubview:b];
        [self.sideBtns addObject:b];
    }
}

- (void)_buildGestures {
    UIPanGestureRecognizer *drag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_dragPanel:)];
    [self.sidebar addGestureRecognizer:drag];
    self.scroll.panGestureRecognizer.requireGestureRecognizerToFail = drag;
}

- (void)_dragPanel:(UIPanGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [g translationInView:self.view];
        CGFloat f = 1.0f / gMenuScale; // screen-space -> unscaled space
        self.rootContainer.center = CGPointMake(self.rootContainer.center.x + t.x * f,
                                                self.rootContainer.center.y + t.y * f);
        [g setTranslation:CGPointZero inView:self.view];
    }
}

- (void)_selectTab:(NSInteger)idx {
    if (idx < 0 || idx > 4) return;
    _tab = idx;
    for (NSUInteger i = 0; i < self.sideBtns.count; i++) [self.sideBtns[i] setActive:((NSInteger)i == idx)];
    NSArray *names = @[
        L(@"ESP", @"ESP", @"ESP"), L(@"AIM", @"AIM", @"AIM"),
        L(@"DRAW", @"DRAW", @"DRAW"), L(@"TOOLS", @"TOOLS", @"HERRAMIENTAS"),
        L(@"SETTINGS", @"AJUSTES", @"CÃ€I Äáº¶T")
    ];
    _headerTitle.text = names[idx];
    [UIView transitionWithView:self.page duration:0.22f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        for (UIView *v in self.page.subviews) [v removeFromSuperview];
        [self _buildTab:idx];
    } completion:nil];
}

- (void)_lightTap { [self _setDark:NO]; }
- (void)_darkTap  { [self _setDark:YES]; }

- (void)_setDark:(BOOL)dark {
    [UD() setBool:dark forKey:@"DAAE.darkMode"];
    [UD() synchronize];
    [UIView animateWithDuration:0.25f animations:^{
        DAAEThemeApplyAll(dark);
        [self _applyThemeAll];
    }];
}

- (void)_applyThemeAll {
    self.panel.backgroundColor = CPanelBG();
    self.sidebar.backgroundColor = CPanelBG();
    self.panel.layer.borderColor = CBorder().CGColor;
    self.sidebar.layer.borderColor = CBorder().CGColor;
    _headerSep.backgroundColor = CSep();
    _headerTitle.textColor = CText();
    _btnLight.alpha = gDark ? 0.45f : 1.0f;
    _btnDark.alpha  = gDark ? 1.0f : 0.45f;
    for (UIImageView *iv in _btnLight.subviews) iv.tintColor = gDark ? CIconDim() : CIcon();
    for (UIImageView *iv in _btnDark.subviews)  iv.tintColor = gDark ? CIcon() : CIconDim();
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sw = CGRectGetWidth(self.view.bounds);
    CGFloat sh = CGRectGetHeight(self.view.bounds);
    if (sh < 100.0f) return;
    if (sw == self.lastW) return;
    self.lastW = sw;

    // Base (unscaled) size â€” adapted to screen space
    CGFloat pw = MIN(340.0f, sw - 16.0f);
    CGFloat ph = MIN(460.0f, sh - 24.0f);

    self.rootContainer.bounds = CGRectMake(0, 0, pw, ph);
    self.rootContainer.center = CGPointMake(sw / 2.0f, sh / 2.0f);

    self.sidebar.frame = CGRectMake(kSidePad, kSidePad, kSideW, ph - kSidePad * 2.0f);

    CGFloat pX = kSidePad * 2.0f + kSideW;
    self.panel.frame = CGRectMake(pX, kSidePad, pw - pX - kSidePad, ph - kSidePad * 2.0f);
    self.contentArea.frame = self.panel.bounds;
    self.scroll.frame = self.contentArea.bounds;

    _headerTitle.frame = CGRectMake(kPad, (kHeadH - 24.0f) / 2.0f, 140.0f, 24.0f);
    _btnLight.center = CGPointMake(self.panel.bounds.size.width - kPad - 16.0f, kHeadH / 2.0f);
    _btnDark.center  = CGPointMake(self.panel.bounds.size.width - kPad - 52.0f, kHeadH / 2.0f);
    _headerSep.frame = CGRectMake(kPad, kHeadH - 0.5f, self.panel.bounds.size.width - kPad * 2, 1.0f);

    CGFloat step = self.sidebar.bounds.size.height / 5.0f;
    for (NSUInteger i = 0; i < self.sideBtns.count; i++) {
        self.sideBtns[i].center = CGPointMake(kSideW / 2.0f, step * i + step / 2.0f);
    }

    [self _applyScale];
    [self _selectTab:0];
}

#pragma mark - GLOBAL SCALE (Menu Size)

- (void)_applyScale {
    // Uniform scaling of the ROOT container â€” every component scales together.
    self.rootContainer.transform = CGAffineTransformMakeScale(gMenuScale, gMenuScale);
}

- (void)_recenter {
    // Re-center after every scale change â€” menu never drifts to a corner.
    self.rootContainer.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
}

- (void)_menuScaleChanged:(float)v {
    gMenuScale = v;
    ESPPrefsSetFloat(@"DAAE.menuScale", v);
    ESPSyncFromPrefs();
    [self _applyScale];
    [self _recenter];
}

#pragma mark - Builders

- (CGFloat)_cw { return self.scroll.bounds.size.width - kPad * 2; }

- (DAAEToggleRow *)_toggle:(CGFloat)y key:(NSString *)k title:(NSString *)t def:(BOOL)d {
    DAAEToggleRow *r = [[DAAEToggleRow alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], kRowH) key:k title:t def:d];
    [self.page addSubview:r];
    return r;
}

- (DAAESliderRow *)_slider:(CGFloat)y key:(NSString *)k title:(NSString *)t min:(CGFloat)mn max:(CGFloat)mx def:(CGFloat)d {
    DAAESliderRow *r = [[DAAESliderRow alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], 74.0f) key:k title:t min:mn max:mx def:d];
    r.onChanged = ^(float v) { PS(k, v); };
    [self.page addSubview:r];
    return r;
}

- (void)_section:(CGFloat)y title:(NSString *)t {
    DAAESectionLabel *s = [[DAAESectionLabel alloc] initWithFrame:CGRectMake(kPad + 4, y, [self _cw], 18.0f) title:t];
    [self.page addSubview:s];
}

- (void)_option:(CGFloat)y title:(NSString *)t sel:(BOOL)sel tap:(void (^)(void))tap {
    DAAEOptionRow *o = [[DAAEOptionRow alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], kRowH) title:t];
    o.selected = sel;
    o.onTap = tap;
    [self.page addSubview:o];
}

- (void)_info:(CGFloat)y title:(NSString *)t value:(NSString *)v {
    DAAEInfoRow *i = [[DAAEInfoRow alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], 46.0f) title:t value:v];
    [self.page addSubview:i];
}

- (void)_buildTab:(NSInteger)tab {
    self.page.frame = CGRectMake(0, 0, self.scroll.bounds.size.width, self.scroll.bounds.size.height);
    CGFloat y = kHeadH + 10.0f;
    switch (tab) {
        case 0: y = [self _tabESP:y];   break;
        case 1: y = [self _tabAIM:y];   break;
        case 2: y = [self _tabDRAW:y];  break;
        case 3: y = [self _tabTOOLS:y]; break;
        case 4: y = [self _tabSETTINGS:y]; break;
    }
    y += 12.0f;
    CGFloat minH = self.scroll.bounds.size.height;
    self.page.frame = CGRectMake(0, 0, self.scroll.bounds.size.width, MAX(y, minH));
    self.scroll.contentSize = self.page.bounds.size;
}

- (CGFloat)_tabESP:(CGFloat)y0 {
    CGFloat y = y0;
    NSArray *keys   = @[@"ESPEnabled", @"Box", @"Line", @"Skeleton", @"HeadRedDot", @"Health", @"Name", @"Dis", @"CleanESP"];
    NSArray *titles = @[
        L(@"Master ESP", @"ESP Maestro", @"ESP ChÃ­nh"),
        L(@"Box ESP", @"Caja ESP", @"Há»™p ESP"),
        L(@"Line ESP", @"LÃ­nea ESP", @"ÄÆ°á»ng ESP"),
        L(@"Skeleton", @"Esqueleto", @"XÆ°Æ¡ng"),
        L(@"Head Dot", @"Punto Cabeza", @"Cháº¥m Äáº§u"),
        L(@"Health Bar", @"Barra de Salud", @"Thanh MÃ¡u"),
        L(@"Name", @"Nombre", @"TÃªn"),
        L(@"Distance", @"Distancia", @"Khoáº£ng CÃ¡ch"),
        L(@"Clean ESP", @"ESP Limpio", @"ESP Gá»n")
    ];
    for (NSUInteger i = 0; i < keys.count; i++) {
        [self _toggle:y key:keys[i] title:titles[i] def:NO];
        y += kRowH + 8.0f;
    }
    [self _slider:y key:@"FovSize" title:L(@"FOV Size", @"TamaÃ±o FOV", @"Cá»¡ FOV") min:5 max:48 def:40];
    y += 82.0f;
    [self _toggle:y key:@"ShowFov" title:L(@"Show FOV", @"Mostrar FOV", @"Hiá»‡n FOV") def:YES];
    y += kRowH + 8.0f;
    return y;
}

- (CGFloat)_tabAIM:(CGFloat)y0 {
    CGFloat y = y0;
    DAAEWarningLabel *warn = [[DAAEWarningLabel alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], 40.0f) title:L(@"Use Aimbot with restraint. Excessive headshots may trigger detections.", @"Usa el aimbot con moderaciÃ³n.", @"DÃ¹ng aimbot cÃ³ chá»«ng má»±c.")];
    [self.page addSubview:warn];
    y += 46.0f;
    [self _toggle:y key:@"AimType" title:L(@"Aimbot", @"Aimbot", @"Aimbot") def:NO]; y += kRowH + 8.0f;
    [self _toggle:y key:@"AimTargetLine" title:L(@"Aim Line", @"LÃ­nea de Apuntado", @"ÄÆ°á»ng Ngáº¯m") def:NO]; y += kRowH + 8.0f;
    [self _toggle:y key:@"ShowFov" title:L(@"Show FOV", @"Mostrar FOV", @"Hiá»‡n FOV") def:YES]; y += kRowH + 8.0f;
    [self _toggle:y key:@"AimLag" title:L(@"Skip Bots", @"Saltar Bots", @"Bá» Bots") def:NO]; y += kRowH + 8.0f;

    [self _section:y title:L(@"ACTIVATION", @"ACTIVACIÃ“N", @"KÃCH HOáº T")]; y += 26.0f;
    NSArray *actT = @[L(@"Always", @"Siempre", @"LuÃ´n"), L(@"On Shoot", @"Al Disparar", @"Khi Báº¯n"), L(@"On Scope", @"Con Mira", @"Khi Ngáº¯m")];
    for (NSUInteger i = 0; i < 3; i++) {
        NSInteger idx = (NSInteger)i;
        __weak typeof(self) ws = self;
        [self _option:y title:actT[i] sel:(PF(@"AimActivation", 1) == idx + 1) tap:^{ PS(@"AimActivation", idx + 1); [ws _selectTab:1]; }];
        y += kRowH + 8.0f;
    }

    [self _section:y title:L(@"AIM POSITION", @"POSICIÃ“N DE APUNTADO", @"Vá»Š TRÃ NGáº®M")]; y += 26.0f;
    NSArray *posT = @[@"Head", L(@"Neck", @"Cuello", @"Cá»•"), L(@"Body", @"Cuerpo", @"ThÃ¢n")];
    for (NSUInteger i = 0; i < 3; i++) {
        NSInteger idx = (NSInteger)i;
        __weak typeof(self) ws = self;
        [self _option:y title:posT[i] sel:(PF(@"AimType", -1) == idx) tap:^{ PS(@"AimType", idx); [ws _selectTab:1]; }];
        y += kRowH + 8.0f;
    }

    [self _section:y title:L(@"WEAPONS", @"ARMAS", @"VÅ¨ KHÃ")]; y += 26.0f;
    [self _toggle:y key:@"FastFire" title:L(@"Fast Fire", @"Disparo RÃ¡pido", @"Báº¯n Nhanh") def:NO]; y += kRowH + 8.0f;
    [self _toggle:y key:@"ShootNoReload" title:L(@"No Reload", @"Sin Recarga", @"KhÃ´ng Náº¡p Äáº¡n") def:NO]; y += kRowH + 8.0f;
    [self _slider:y key:@"FovSize" title:L(@"FOV Radius", @"Radio FOV", @"BÃ¡n KÃ­nh FOV") min:5 max:48 def:40]; y += 82.0f;
    [self _slider:y key:@"SilentFovSize" title:L(@"FOV Thickness", @"Grosor FOV", @"Äá»™ DÃ y FOV") min:0 max:10 def:18]; y += 82.0f;
    return y;
}

- (CGFloat)_tabDRAW:(CGFloat)y0 {
    CGFloat y = y0;
    [self _section:y title:L(@"ESP COLORS", @"COLORES ESP", @"MÃ€U ESP")]; y += 26.0f;
    NSArray *targ = @[L(@"Box Color", @"Color de Caja", @"MÃ u Há»™p"), L(@"FOV Color", @"Color de FOV", @"MÃ u FOV")];
    for (NSUInteger i = 0; i < targ.count; i++) {
        NSInteger idx = (NSInteger)i;
        __weak typeof(self) ws = self;
        [self _option:y title:targ[i] sel:(PF(@"ColorTarget", 0) == idx) tap:^{ PS(@"ColorTarget", idx); [ws _selectTab:2]; }];
        y += kRowH + 8.0f;
    }
    [self _slider:y key:@"BoxColorR" title:@"Red"   min:0 max:1 def:0.26]; y += 82.0f;
    [self _slider:y key:@"BoxColorG" title:@"Green" min:0 max:1 def:0.78]; y += 82.0f;
    [self _slider:y key:@"BoxColorB" title:@"Blue"  min:0 max:1 def:0.90]; y += 82.0f;
    return y;
}

- (CGFloat)_tabTOOLS:(CGFloat)y0 {
    CGFloat y = y0;
    DAAEWarningLabel *warn = [[DAAEWarningLabel alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], 40.0f) title:L(@"Some options may not be entirely safe. Use with caution.", @"Algunas opciones pueden no ser seguras. Ãšsalas con precauciÃ³n.", @"Má»™t sá»‘ tÃ¹y chá»n cÃ³ thá»ƒ khÃ´ng an toÃ n.")];
    [self.page addSubview:warn];
    y += 46.0f;

    [self _section:y title:L(@"EXTRAS", @"EXTRAS", @"Má»ž Rá»˜NG")]; y += 26.0f;
    NSArray *exKeys = @[@"GhostModeFloating", @"FakeLagFloating", @"FlyFloating", @"RunSpeedFloating", @"HideFeatureButtons"];
    NSArray *exT = @[
        L(@"Ghost Mode", @"Modo Fantasma", @"Cháº¿ Äá»™ Ma"),
        L(@"Fake Lag", @"Lag Falso", @"Giáº£ Lag"),
        L(@"Fly", @"Volar", @"Bay"),
        L(@"Speed", @"Velocidad", @"Tá»‘c Äá»™"),
        L(@"Hide Buttons", @"Ocultar Botones", @"áº¨n NÃºt")
    ];
    for (NSUInteger i = 0; i < exKeys.count; i++) {
        [self _toggle:y key:exKeys[i] title:exT[i] def:NO];
        y += kRowH + 8.0f;
    }

    [self _section:y title:L(@"MOVEMENT", @"MOVIMIENTO", @"DI CHUYá»‚N")]; y += 26.0f;
    [self _toggle:y key:@"RunSpeed" title:L(@"Speed Toggle", @"Interruptor Velocidad", @"CÃ´ng Táº¯c Tá»‘c Äá»™") def:NO]; y += kRowH + 8.0f;
    [self _slider:y key:@"RunSpeedValue" title:L(@"Speed Value", @"Valor Velocidad", @"GiÃ¡ Trá»‹ Tá»‘c Äá»™") min:1 max:15 def:6]; y += 82.0f;
    [self _slider:y key:@"FlyHeight" title:L(@"Fly Height", @"Altura Vuelo", @"Äá»™ Cao Bay") min:1 max:6 def:4]; y += 82.0f;

    [self _section:y title:L(@"EFFECTS", @"EFECTOS", @"HIá»†U á»¨NG")]; y += 26.0f;
    [self _toggle:y key:@"VisualSpin" title:L(@"Visual Spin", @"Giro Visual", @"Xoay HÃ¬nh") def:NO]; y += kRowH + 8.0f;
    [self _slider:y key:@"VisualSpinSpeed" title:L(@"Spin Speed", @"Velocidad Giro", @"Tá»‘c Äá»™ Xoay") min:0.1f max:3.0f def:0.5f]; y += 82.0f;
    [self _toggle:y key:@"BalancedRender" title:L(@"Balanced Render", @"Render Equilibrado", @"Render CÃ¢n Báº±ng") def:NO]; y += kRowH + 8.0f;
    return y;
}

- (CGFloat)_tabSETTINGS:(CGFloat)y0 {
    CGFloat y = y0;

    // â€”â€” MENU SIZE â€” global uniform scale of the WHOLE menu (rootContainer) â€”â€”
    [self _section:y title:L(@"MENU SIZE", @"TAMAÃ‘O DEL MENÃš", @"Cá»  MENU")]; y += 26.0f;
    UILabel *sl = [[UILabel alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], 18.0f)];
    sl.font = [UIFont systemFontOfSize:15.5f weight:UIFontWeightMedium];
    sl.text = L(@"Menu Size", @"TamaÃ±o del MenÃº", @"Cá»¡ Menu");
    [self.page addSubview:sl];
    DAAEThemeRegister(sl);
    sl.textColor = CText();
    y += 22.0f;

    UISlider *scale = [[UISlider alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], 24.0f)];
    scale.minimumValue = 0.7f;
    scale.maximumValue = 1.3f;
    scale.value = gMenuScale;
    [scale addTarget:self action:@selector(_scaleChanged:) forControlEvents:UIControlEventValueChanged];
    [self.page addSubview:scale];
    scale.minimumTrackTintColor = CSelected();
    scale.maximumTrackTintColor = CBorder();
    scale.thumbTintColor = CKnob();
    y += 28.0f;

    // â€”â€” LANGUAGE â€”â€”
    [self _section:y title:L(@"LANGUAGE", @"IDIOMA", @"NGÃ”N NGá»®")]; y += 26.0f;
    NSArray *langT = @[@"English", @"EspaÃ±ol", @"Tiáº¿ng Viá»‡t"];
    for (NSUInteger i = 0; i < 3; i++) {
        NSInteger idx = (NSInteger)i;
        __weak typeof(self) ws = self;
        [self _option:y title:langT[i] sel:(MMLang() == idx) tap:^{
            [UD() setInteger:idx forKey:@"DAAE.lang"];
            [UD() synchronize];
            [ws _selectTab:4];
        }];
        y += kRowH + 8.0f;
    }

    // â€”â€” APPEARANCE (Light / Dark) â€”â€”
    [self _section:y title:L(@"APPEARANCE", @"APARIENCIA", @"GIAO DIá»†N")]; y += 26.0f;
    __weak typeof(self) ws = self;
    [self _option:y title:L(@"Light", @"Claro", @"SÃ¡ng") sel:!gDark tap:^{ [ws _setDark:NO]; [ws _selectTab:4]; }];
    y += kRowH + 8.0f;
    [self _option:y title:L(@"Dark", @"Oscuro", @"Tá»‘i") sel:gDark tap:^{ [ws _setDark:YES]; [ws _selectTab:4]; }];
    y += kRowH + 8.0f;

    // â€”â€” INFO â€”â€”
    [self _section:y title:L(@"INFO", @"INFO", @"THÃ”NG TIN")]; y += 26.0f;
    [self _info:y title:L(@"Product", @"Producto", @"Sáº£n Pháº©m") value:@"DAAE IOS"]; y += 54.0f;
    [self _info:y title:L(@"Creator", @"Creador", @"TÃ¡c Giáº£") value:@"@didierxit7"]; y += 54.0f;
    [self _info:y title:L(@"Telegram", @"Telegram", @"Telegram") value:@"t.me/didierxit7"]; y += 54.0f;
    [self _info:y title:L(@"Key", @"Clave", @"Key") value:@"TEST"]; y += 54.0f;
    return y;
}

- (void)_scaleChanged:(UISlider *)s {
    // Real-time uniform scaling â€” persists via DAAE.menuScale
    [self _menuScaleChanged:s.value];
}

- (void)dealloc { /* prefs are owned by MizzeMenuPrefs */ }

@end

// BUILD OK

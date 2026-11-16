//
//  _0xMO353DA.mm
//  FLOATING MODERN MENU â€” v4 (build-fixed, compiles clean with -Werror)
//
//  FULL REDESIGN matching the reference images:
//    â€¢ Floating translucent panel (UIVisualEffectView) + circular left sidebar
//    â€¢ LIGHT MODE / DARK MODE only â€” NO accent colors, NO gradients
//    â€¢ Categories: ESP | AIM | DRAW | TOOLS | SETTINGS
//    â€¢ "Menu Size" slider = GLOBAL uniform scale of the whole menu
//      (rootContainer scales as ONE unit, centered, real-time, persistent)
//
//  Build fixes vs v3:
//    1. @protocol DAAETheming â€” [o applyTheme] now resolves (error line 79)
//    2. #import <objc/message.h> â€” objc_msgSend declared (error line 93)
//    3. DAAEOptionRow: property 'selected' renamed to 'checked' â€” no clash
//       with UIControl.selected (errors 337/371/373)
//    4. requireGestureRecognizerToFail â€” message syntax, not property
//    5. __weak __typeof__(self) â€” typeof is invalid in C++ (errors 818/827/846)
//    6. All static color helpers are 'static inline' â€” no -Wunused-function
//    7. DAAESlider renamed DAAEThemedSlider (declared before use)
//
//  Compatible with existing mod functions and preference keys:
//    ESPPrefsFloat / ESPPrefsSetFloat / ESPSyncFromPrefs / class _0xDEADBEEE
//

#import <UIKit/UIKit.h>
#import "ModMenuViewController.h"
#import "MizzeTheme.h"
#import "MizzeMenuPrefs.h"
#include <cmath>
#import <objc/runtime.h>
#import <objc/message.h>
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPStyle.h"
#import "../esp/Core/PlayerModes.h"
#import "UIView+SecureView.h"

#pragma clang diagnostic ignored "-Wundeclared-selector"
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

// ---------------------------------------------------------------------------
// MARK: 1. Layout constants
// ---------------------------------------------------------------------------

static CGFloat const kSideW   = 68.0f;   // sidebar width
static CGFloat const kSidePad = 10.0f;   // outer margin
static CGFloat const kSideBtn = 46.0f;   // circular nav button size
static CGFloat const kPanelR  = 30.0f;   // outer panel corner radius
static CGFloat const kCardR   = 24.0f;   // card corner radius
static CGFloat const kPad     = 16.0f;   // inner horizontal padding
static CGFloat const kRowH    = 60.0f;   // standard card height
static CGFloat const kHeadH   = 52.0f;   // header height
static CGFloat const kSlideH  = 74.0f;   // slider card height
static CGFloat const kGap     = 8.0f;    // vertical gap between cards

// GLOBAL UI SCALE ------------------------------------------------------------
// One variable controls the size of the ENTIRE menu. It is applied ONLY to
// rootContainer.transform, so every component (panel, sidebar, buttons,
// icons, texts, cards, switches, sliders, paddings, margins, corner radii)
// scales together as one unit. Reference: 100% = original size.
static CGFloat gMenuScale = 1.0f;   // user preference (0.7 ... 1.3)
static CGFloat gEffScale  = 1.0f;   // effective scale (clamped to screen)

// ---------------------------------------------------------------------------
// MARK: 2. Preferences & language helpers
// ---------------------------------------------------------------------------

static NSUserDefaults *UD() { return [NSUserDefaults standardUserDefaults]; }

static inline float PF(NSString *key, float def) { return ESPPrefsFloat(key, def); }
static inline void  PS(NSString *key, float v)  { ESPPrefsSetFloat(key, v); ESPSyncFromPrefs(); }
static inline void  PDef(NSString *key, float v) {
    if (ESPPrefsFloat(key, 999999.0f) == 999999.0f) ESPPrefsSetFloat(key, v);
}

static inline NSInteger MMLang() { return [UD() integerForKey:@"DAAE.lang"]; }
static inline BOOL      MMDark() { return [UD() boolForKey:@"DAAE.darkMode"]; }

// Localized string: English / Spanish / Vietnamese
static inline NSString *L(NSString *en, NSString *es, NSString *vi) {
    switch (MMLang()) { case 1: return es; case 2: return vi; default: return en; }
}

// ---------------------------------------------------------------------------
// MARK: 3. Theme system (LIGHT / DARK only â€” NO accent colors)
// ---------------------------------------------------------------------------

static BOOL gDark = YES;   // current theme state

static inline UIColor *HexRGB(NSInteger h, CGFloat a) {
    return [UIColor colorWithRed:((h >> 16) & 0xFF) / 255.0f
                           green:((h >>  8) & 0xFF) / 255.0f
                            blue:((h      ) & 0xFF) / 255.0f
                           alpha:a];
}
#define GRAY(dk, lt) (gDark ? (dk) : (lt))

// Palettes exactly as specified:
//   DARK:  panel #242426 (88%), control #303034, selected #414146,
//          text #F5F5F7, dim #A5A5AA, disabled #68686E, icon #EEEEF0,
//          border white 10%, separator white 8%
//   LIGHT: panel #FFFFFF (82%), control #E8E8ED, selected #DCDCE2,
//          text #171717, dim #77777D, disabled #AAAAAF, icon #292929,
//          border #D5D5DA, separator #DADAE0
static inline UIColor *CPanelBG()  { return GRAY(HexRGB(0x242426, 0.88f), HexRGB(0xFFFFFF, 0.82f)); }
static inline UIColor *CControl()  { return GRAY(HexRGB(0x303034, 1.0f), HexRGB(0xE8E8ED, 1.0f)); }
static inline UIColor *CSelected() { return GRAY(HexRGB(0x414146, 1.0f), HexRGB(0xDCDCE2, 1.0f)); }
static inline UIColor *CText()     { return GRAY(HexRGB(0xF5F5F7, 1.0f), HexRGB(0x171717, 1.0f)); }
static inline UIColor *CDim()      { return GRAY(HexRGB(0xA5A5AA, 1.0f), HexRGB(0x77777D, 1.0f)); }
static inline UIColor *CDisabled() { return GRAY(HexRGB(0x68686E, 1.0f), HexRGB(0xAAAAAF, 1.0f)); }
static inline UIColor *CIcon()     { return GRAY(HexRGB(0xEEEEF0, 1.0f), HexRGB(0x292929, 1.0f)); }
static inline UIColor *CIconDim()  { return GRAY(HexRGB(0xA5A5AA, 1.0f), HexRGB(0x77777D, 1.0f)); }
static inline UIColor *CBorder()   { return GRAY([[UIColor whiteColor] colorWithAlphaComponent:0.10f], HexRGB(0xD5D5DA, 0.55f)); }
static inline UIColor *CSep()      { return GRAY([[UIColor whiteColor] colorWithAlphaComponent:0.08f], HexRGB(0xDADAE0, 1.0f)); }
static inline UIColor *CKnob()     { return GRAY(HexRGB(0x242426, 1.0f), HexRGB(0xFFFFFF, 1.0f)); }

// FIX 1: protocol so the compiler knows an instance method applyTheme exists
@protocol DAAETheming
- (void)applyTheme;
@end

// Centralized theme registry: every component re-styles itself on theme
// change WITHOUT rebuilding the whole interface.
static NSHashTable *gThemed = nil;
static void DAAEThemeRegister(id obj) {
    if (!gThemed) gThemed = [NSHashTable weakObjectsHashTable];
    [gThemed addObject:obj];
}
static void DAAEThemeApplyAll(BOOL dark) {
    gDark = dark;
    for (id o in gThemed)
        if ([o respondsToSelector:@selector(applyTheme)])
            [(id<DAAETheming>)o applyTheme];
}

static inline UIImage *UISI(NSString *name, NSString *fallback) {
    UIImage *i = [UIImage systemImageNamed:name];
    if (!i && fallback.length) i = [UIImage systemImageNamed:fallback];
    return i;
}

// FIX 2: objc/message.h imported above, so objc_msgSend is declared
static void DAAESecureView(UIView *v) {
    if (!v) return;
    NSArray *names = @[@"makeSecure", @"secureThisView", @"applySecure", @"addSecureOverlay"];
    for (NSString *n in names) {
        SEL s = NSSelectorFromString(n);
        if ([v respondsToSelector:s]) { ((void (*)(id, SEL))objc_msgSend)(v, s); return; }
    }
}

// ---------------------------------------------------------------------------
// MARK: 4. Base UI classes
// ---------------------------------------------------------------------------

// Touch pass-through for the area OUTSIDE the panel (game stays playable)
@interface DAAEPassView : UIView
@end
@implementation DAAEPassView
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    for (UIView *sub in self.subviews)
        if (!sub.isHidden && CGRectContainsPoint(sub.frame, point)) return YES;
    return NO;
}
@end

@interface DAAEThemedLabel : UILabel
@end
@implementation DAAEThemedLabel
- (void)applyTheme { self.textColor = CText(); }
@end

// FIX 7: named DAAEThemedSlider (was DAAESlider in a broken intermediate build)
@interface DAAEThemedSlider : UISlider
@end
@implementation DAAEThemedSlider
- (void)applyTheme {
    self.minimumTrackTintColor = CSelected();
    self.maximumTrackTintColor = CBorder();
    self.thumbTintColor = CKnob();
}
@end

// ---------------------------------------------------------------------------
// MARK: 5. Section & warning labels
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// MARK: 6. Components
// ---------------------------------------------------------------------------

// Capsule switch â€” neutral grays only, animated knob (NO green / blue / accent)
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

// Selection circle with checkmark (inverted colors depending on theme)
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

// Toggle card â€” label left, switch right, saves to its own pref key
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
        _sw.userInteractionEnabled = NO;   // the whole card is the tap target
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

// Slider card â€” label + value capsule + thin neutral slider
@interface DAAESliderRow : UIControl
@property (nonatomic, copy) void (^onChanged)(float);
@end

@implementation DAAESliderRow {
    UILabel *_lbl, *_val;
    DAAEThemedSlider *_sl;
    NSString *_key;
    BOOL _dec2;
}
- (instancetype)initWithFrame:(CGRect)f key:(NSString *)key title:(NSString *)title min:(CGFloat)min max:(CGFloat)max def:(CGFloat)def {
    if ((self = [super initWithFrame:CGRectMake(f.origin.x, f.origin.y, f.size.width, kSlideH)])) {
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
        _sl = [[DAAEThemedSlider alloc] initWithFrame:CGRectZero];
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
    if (_onChanged) _onChanged(s.value);   // real-time update while dragging
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

// Dropdown selector â€” option name left, current value right, chevron down,
// expands an inline list of value cards below it (spec, section 5)
@interface DAAEPickerRow : UIControl
@property (nonatomic, copy) void (^onPick)(NSInteger);
@end

@implementation DAAEPickerRow {
    UILabel *_lbl, *_val;
    UIImageView *_arr;
    NSArray *_opts;
    NSInteger _sel;
    UIView *_list;
    BOOL _open;
}
- (instancetype)initWithFrame:(CGRect)f title:(NSString *)title options:(NSArray *)opts sel:(NSInteger)sel {
    if ((self = [super initWithFrame:f])) {
        _opts = opts;
        _sel = sel;
        self.layer.cornerRadius = kCardR;
        self.layer.borderWidth = 0.5f;
        _lbl = [[UILabel alloc] initWithFrame:CGRectZero];
        _lbl.text = title;
        _lbl.font = [UIFont systemFontOfSize:15.5f weight:UIFontWeightMedium];
        [self addSubview:_lbl];
        _val = [[UILabel alloc] initWithFrame:CGRectZero];
        _val.text = ((NSUInteger)sel < opts.count && sel >= 0) ? opts[sel] : @"â€”";
        _val.font = [UIFont systemFontOfSize:14.0f weight:UIFontWeightSemibold];
        _val.textAlignment = NSTextAlignmentRight;
        [self addSubview:_val];
        _arr = [[UIImageView alloc] initWithImage:UISI(@"chevron.down", nil)];
        _arr.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_arr];
        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
        DAAEThemeRegister(self);
        [self applyTheme];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width;
    _lbl.frame = CGRectMake(kPad, 0, w * 0.42f, self.bounds.size.height);
    _arr.frame = CGRectMake(w - kPad - 14.0f, self.bounds.size.height / 2.0f - 7.0f, 14.0f, 14.0f);
    _val.frame = CGRectMake(w * 0.42f, 0, w - kPad - 22.0f - w * 0.42f, self.bounds.size.height);
}
- (void)_tap {
    _open = !_open;
    [UIView transitionWithView:self.superview duration:0.25f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        if (_open) [self _expand]; else [self _collapse];
    } completion:nil];
}
- (void)_expand {
    if (_list) return;
    _list = [[UIView alloc] initWithFrame:CGRectZero];
    _list.layer.cornerRadius = kCardR;
    _list.layer.borderWidth = 0.5f;
    _list.layer.borderColor = CBorder().CGColor;
    _list.backgroundColor = CControl();
    CGFloat lw = self.frame.size.width;
    CGFloat lh = 44.0f * (CGFloat)_opts.count + 8.0f;
    _list.frame = CGRectMake(self.frame.origin.x, CGRectGetMaxY(self.frame) + kGap, lw, lh);
    [self.superview insertSubview:_list aboveSubview:self];
    for (NSUInteger i = 0; i < _opts.count; i++) {
        UIControl *o = [[UIControl alloc] initWithFrame:CGRectMake(8.0f, 4.0f + 44.0f * (CGFloat)i, lw - 16.0f, 40.0f)];
        UILabel *ol = [[UILabel alloc] initWithFrame:CGRectMake(12.0f, 0, o.bounds.size.width - 24.0f, 40.0f)];
        ol.text = _opts[i];
        ol.font = [UIFont systemFontOfSize:14.0f weight:((NSInteger)i == _sel ? UIFontWeightSemibold : UIFontWeightRegular)];
        ol.textColor = ((NSInteger)i == _sel) ? CText() : CDim();
        [o addSubview:ol];
        [o addTarget:self action:@selector(_pick:) forControlEvents:UIControlEventTouchUpInside];
        [o setTag:500 + (NSInteger)i];
        [_list addSubview:o];
    }
    _list.alpha = 0.0f;
    [UIView animateWithDuration:0.20f animations:^{ _list.alpha = 1.0f; }];
}
- (void)_collapse {
    [_list removeFromSuperview];
    _list = nil;
}
- (void)_pick:(UIControl *)s {
    _sel = s.tag - 500;
    _val.text = ((NSUInteger)_sel < _opts.count) ? _opts[_sel] : @"â€”";
    [self _collapse];
    if (_onPick) _onPick(_sel);
}
- (void)applyTheme {
    self.backgroundColor = CControl();
    self.layer.borderColor = CBorder().CGColor;
    _lbl.textColor = CText();
    _val.textColor = CDim();
    _arr.tintColor = CIconDim();
}
@end

// FIX 3: property renamed 'checked' â€” UIControl already has 'selected'
@interface DAAEOptionRow : UIControl
@property (nonatomic, assign) BOOL checked;
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
- (void)setChecked:(BOOL)s { _checked = s; _radio.on = s; [self applyTheme]; }
- (void)applyTheme {
    self.backgroundColor = _checked ? CSelected() : CControl();
    self.layer.borderColor = CBorder().CGColor;
    _lbl.textColor = CText();
}
@end

// Info card â€” title left, value right (Product / Creator / Telegram / Key)
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

// Circular sidebar navigation button
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

// ---------------------------------------------------------------------------
// MARK: 7. Main panel class
// ---------------------------------------------------------------------------

@interface _0xDEADBEEE ()
@property (nonatomic, strong) UIView *rootContainer;
@property (nonatomic, strong) UIVisualEffectView *panelBlur;
@property (nonatomic, strong) UIView *panel;
@property (nonatomic, strong) UIView *sidebar;
@property (nonatomic, strong) UIView *contentArea;
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) UIView *page;
@property (nonatomic, strong) UILabel *headerTitle;
@property (nonatomic, strong) UIControl *btnDark;
@property (nonatomic, strong) UIControl *btnLight;
@property (nonatomic, strong) UIControl *btnClose;
@property (nonatomic, strong) UIView *headerSep;
@property (nonatomic, strong) NSMutableArray<DAAESideBtn *> *sideBtns;
@property (nonatomic, assign) NSInteger tab;
@property (nonatomic, assign) CGFloat lastW;
@end

@implementation _0xDEADBEEE

- (void)viewDidLoad {
    [super viewDidLoad];

    // Pass-through layer: only the menu itself receives touches
    DAAEPassView *pv = [[DAAEPassView alloc] initWithFrame:self.view.bounds];
    pv.backgroundColor = [UIColor clearColor];
    pv.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = pv;

    [self _applyDefaults];
    gMenuScale = PF(@"DAAE.menuScale", 1.0f);
    gDark = MMDark();

    // ROOT container â€” the WHOLE menu scales as ONE unit via transform
    self.rootContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.rootContainer.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.rootContainer];

    // ---- Sidebar (circular buttons) ----
    self.sidebar = [[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.layer.cornerRadius = kPanelR;
    self.sidebar.layer.borderWidth = 0.5f;
    [self.rootContainer addSubview:self.sidebar];

    // ---- Main panel with real translucency (UIVisualEffectView blur) ----
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:(gDark ? UIBlurEffectStyleSystemMaterialDark
                                                              : UIBlurEffectStyleSystemMaterialLight)];
    self.panelBlur = [[UIVisualEffectView alloc] initWithFrame:CGRectZero];
    self.panelBlur.effect = blur;
    self.panelBlur.layer.cornerRadius = kPanelR;
    self.panelBlur.layer.masksToBounds = YES;
    self.panel = self.panelBlur.contentView;
    [self.rootContainer addSubview:self.panelBlur];

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

    // Apply saved panel opacity on launch
    [self _applyPanelAlpha:PF(@"PanelAlpha", 0.85f)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // Fade-in (spec: menu appears with fade-in, 0.18â€“0.30 s)
    self.rootContainer.alpha = 0.0f;
    [UIView animateWithDuration:0.25f animations:^{ self.rootContainer.alpha = 1.0f; }];
}

- (void)_applyDefaults {
    PDef(@"ESPEnabled", 0); PDef(@"Box", 0); PDef(@"Box3D", 0); PDef(@"CleanESP", 0);
    PDef(@"Name", 0); PDef(@"Health", 0); PDef(@"Line", 0); PDef(@"Skeleton", 0);
    PDef(@"HeadRedDot", 0); PDef(@"Dis", 0); PDef(@"AimLag", 0); PDef(@"AimTargetLine", 0);
    PDef(@"SilentAim", 0); PDef(@"AutoFire", 0); PDef(@"AutoFireFloating", 0);
    PDef(@"FastFire", 0); PDef(@"ShootNoReload", 0); PDef(@"GhostModeFloating", 0);
    PDef(@"FakeLagFloating", 0); PDef(@"FlyFloating", 0); PDef(@"RunSpeedFloating", 0);
    PDef(@"RunSpeed", 0); PDef(@"VisualSpin", 0); PDef(@"BalancedRender", 0);
    PDef(@"HideFeatureButtons", 0); PDef(@"AnLive", 0);
    PDef(@"ShowFov", 1); PDef(@"ExplicitAimMenuV1", 1);
    PDef(@"AimType", -1); PDef(@"AimActivation", 1);
    PDef(@"FovSize", 40); PDef(@"SilentFovSize", 18);
    PDef(@"RunSpeedValue", 6); PDef(@"FlyHeight", 4); PDef(@"VisualSpinSpeed", 0.5f);
    PDef(@"PanelAlpha", 0.85f);
    PDef(@"BoxColorR", 0.26f); PDef(@"BoxColorG", 0.78f); PDef(@"BoxColorB", 0.90f);
    PDef(@"ColorTarget", 0);
    if ([UD() objectForKey:@"DAAE.darkMode"] == nil) [UD() setBool:YES forKey:@"DAAE.darkMode"];
    if (ESPPrefsFloat(@"DAAE.menuScale", 999999.0f) == 999999.0f) ESPPrefsSetFloat(@"DAAE.menuScale", 1.0f);
}

- (void)_buildHeader {
    UILabel *t = [[UILabel alloc] initWithFrame:CGRectZero];
    t.font = [UIFont systemFontOfSize:18.0f weight:UIFontWeightSemibold];
    t.text = @"ESP";
    _headerTitle = t;
    [self.contentArea addSubview:t];

    // Sun / moon appearance buttons (monochromatic, no accent)
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

    // Close button (xmark) â€” fades the menu out
    UIControl *cls = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    UIImageView *ci = [[UIImageView alloc] initWithImage:UISI(@"xmark", nil)];
    ci.contentMode = UIViewContentModeScaleAspectFit;
    ci.frame = CGRectInset(cls.bounds, 7, 7);
    [cls addSubview:ci];
    [cls addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    _btnClose = cls;
    [self.contentArea addSubview:cls];

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

// FIX 4: requireGestureRecognizerToFail is a method, not an assignable property
- (void)_buildGestures {
    UIPanGestureRecognizer *drag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_dragPanel:)];
    [self.sidebar addGestureRecognizer:drag];
    [self.scroll.panGestureRecognizer requireGestureRecognizerToFail:drag];
}

- (void)_dragPanel:(UIPanGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan || g.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [g translationInView:self.view];
        CGFloat f = 1.0f / gEffScale;   // screen-space drag -> unscaled space
        self.rootContainer.center = CGPointMake(self.rootContainer.center.x + t.x * f,
                                                 self.rootContainer.center.y + t.y * f);
        [g setTranslation:CGPointZero inView:self.view];
    }
}

- (void)closeMenu {
    // Fade-out (spec: disappearance via fade-out, 0.18â€“0.30 s)
    [UIView animateWithDuration:0.25f animations:^{ self.rootContainer.alpha = 0.0f; }
                     completion:^(BOOL _) { self.view.hidden = YES; }];
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
        // Swap the blur style so real translucency matches the new theme
        self.panelBlur.effect = [UIBlurEffect effectWithStyle:(dark ? UIBlurEffectStyleSystemMaterialDark
                                                                    : UIBlurEffectStyleSystemMaterialLight)];
        [self _applyThemeAll];
    }];
}

- (void)_applyThemeAll {
    self.sidebar.backgroundColor = CPanelBG();
    self.sidebar.layer.borderColor = CBorder().CGColor;
    self.panelBlur.layer.borderColor = CBorder().CGColor;
    _headerSep.backgroundColor = CSep();
    _headerTitle.textColor = CText();
    _btnLight.alpha = gDark ? 0.45f : 1.0f;
    _btnDark.alpha  = gDark ? 1.0f : 0.45f;
    for (UIImageView *iv in _btnLight.subviews) iv.tintColor = gDark ? CIconDim() : CIcon();
    for (UIImageView *iv in _btnDark.subviews)  iv.tintColor = gDark ? CIcon() : CIconDim();
    for (UIImageView *iv in _btnClose.subviews) iv.tintColor = CIconDim();
}

- (void)_applyPanelAlpha:(float)a {
    // Clamp to 0.35â€“1.0 like the old menu
    a = fminf(1.0f, fmaxf(0.35f, a));
    self.panelBlur.alpha = a;
    self.sidebar.alpha = a;
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sw = CGRectGetWidth(self.view.bounds);
    CGFloat sh = CGRectGetHeight(self.view.bounds);
    if (sh < 100.0f) return;
    if (sw == self.lastW) return;
    self.lastW = sw;

    // Base (unscaled) size â€” adapts to available screen space
    CGFloat pw = MIN(340.0f, sw - 16.0f);
    CGFloat ph = MIN(460.0f, sh - 24.0f);

    self.rootContainer.bounds = CGRectMake(0, 0, pw, ph);
    self.rootContainer.center = CGPointMake(sw / 2.0f, sh / 2.0f);

    self.sidebar.frame = CGRectMake(kSidePad, kSidePad, kSideW, ph - kSidePad * 2.0f);

    CGFloat pX = kSidePad * 2.0f + kSideW;
    self.panelBlur.frame = CGRectMake(pX, kSidePad, pw - pX - kSidePad, ph - kSidePad * 2.0f);
    self.contentArea.frame = self.panel.bounds;
    self.scroll.frame = self.contentArea.bounds;

    _headerTitle.frame = CGRectMake(kPad, (kHeadH - 24.0f) / 2.0f, 110.0f, 24.0f);
    _btnClose.center  = CGPointMake(self.panel.bounds.size.width - kPad - 16.0f, kHeadH / 2.0f);
    _btnLight.center = CGPointMake(self.panel.bounds.size.width - kPad - 52.0f, kHeadH / 2.0f);
    _btnDark.center  = CGPointMake(self.panel.bounds.size.width - kPad - 88.0f, kHeadH / 2.0f);
    _headerSep.frame = CGRectMake(kPad, kHeadH - 0.5f, self.panel.bounds.size.width - kPad * 2, 1.0f);

    CGFloat step = self.sidebar.bounds.size.height / 5.0f;
    for (NSUInteger i = 0; i < self.sideBtns.count; i++) {
        self.sideBtns[i].center = CGPointMake(kSideW / 2.0f, step * i + step / 2.0f);
    }

    [self _applyScale];
    [self _selectTab:0];
}

// ---------------------------------------------------------------------------
// MARK: 8. GLOBAL SCALE (Menu Size)
// ---------------------------------------------------------------------------

- (void)_applyScale {
    // Clamp the user scale so the scaled menu ALWAYS fits the visible screen
    // (spec: adapt to available space, never leave the visible bounds).
    CGFloat sw = CGRectGetWidth(self.view.bounds);
    CGFloat sh = CGRectGetHeight(self.view.bounds);
    CGFloat baseW = self.rootContainer.bounds.size.width;
    CGFloat baseH = self.rootContainer.bounds.size.height;
    CGFloat maxS = 1.0f;
    if (baseW > 0 && baseH > 0) {
        CGFloat fx = (sw - 8.0f) / baseW;
        CGFloat fy = (sh - 8.0f) / baseH;
        maxS = fminf(fx, fy);
    }
    gEffScale = fminf(gMenuScale, maxS);

    // Uniform scaling of the ROOT container â€” every component scales together,
    // anchored at the menu center so it never drifts to a corner.
    self.rootContainer.transform = CGAffineTransformMakeScale(gEffScale, gEffScale);
}

- (void)_recenter {
    // Re-center the menu on screen after every scale change.
    self.rootContainer.center = CGPointMake(CGRectGetMidX(self.view.bounds),
                                             CGRectGetMidY(self.view.bounds));
}

- (void)_menuScaleChanged:(float)v {
    gMenuScale = v;
    ESPPrefsSetFloat(@"DAAE.menuScale", v);
    ESPSyncFromPrefs();
    [self _applyScale];   // real-time, while the slider moves
    [self _recenter];
}

// ---------------------------------------------------------------------------
// MARK: 9. Builders & tabs
// ---------------------------------------------------------------------------

- (CGFloat)_cw { return self.scroll.bounds.size.width - kPad * 2; }

- (DAAEToggleRow *)_toggle:(CGFloat)y key:(NSString *)k title:(NSString *)t def:(BOOL)d {
    DAAEToggleRow *r = [[DAAEToggleRow alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], kRowH) key:k title:t def:d];
    [self.page addSubview:r];
    return r;
}

- (DAAESliderRow *)_slider:(CGFloat)y key:(NSString *)k title:(NSString *)t min:(CGFloat)mn max:(CGFloat)mx def:(CGFloat)d {
    DAAESliderRow *r = [[DAAESliderRow alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], kSlideH) key:k title:t min:mn max:mx def:d];
    r.onChanged = ^(float v) { PS(k, v); };
    [self.page addSubview:r];
    return r;
}

- (void)_section:(CGFloat)y title:(NSString *)t {
    DAAESectionLabel *s = [[DAAESectionLabel alloc] initWithFrame:CGRectMake(kPad + 4, y, [self _cw], 18.0f) title:t];
    [self.page addSubview:s];
}

// FIX 3 (continued): uses 'checked', not the UIControl 'selected' property
- (void)_option:(CGFloat)y title:(NSString *)t sel:(BOOL)sel tap:(void (^)(void))tap {
    DAAEOptionRow *o = [[DAAEOptionRow alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], kRowH) title:t];
    o.checked = sel;
    o.onTap = tap;
    [self.page addSubview:o];
}

- (DAAEPickerRow *)_picker:(CGFloat)y title:(NSString *)t options:(NSArray *)opts sel:(NSInteger)sel {
    DAAEPickerRow *p = [[DAAEPickerRow alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], kRowH) title:t options:opts sel:sel];
    [self.page addSubview:p];
    return p;
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

// ---- TAB 0: ESP ------------------------------------------------------------

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
        y += kRowH + kGap;
    }
    [self _slider:y key:@"FovSize" title:L(@"FOV Size", @"TamaÃ±o FOV", @"Cá»¡ FOV") min:5 max:48 def:40];
    y += kSlideH + kGap;
    [self _toggle:y key:@"ShowFov" title:L(@"Show FOV", @"Mostrar FOV", @"Hiá»‡n FOV") def:YES];
    y += kRowH + kGap;
    return y;
}

// ---- TAB 1: AIM ------------------------------------------------------------

// FIX 5: __typeof__ (typeof is invalid in C++ / .mm files)
- (CGFloat)_tabAIM:(CGFloat)y0 {
    CGFloat y = y0;
    DAAEWarningLabel *warn = [[DAAEWarningLabel alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], 40.0f) title:L(@"Use Aimbot with restraint. Excessive headshots may trigger detections.", @"Usa el aimbot con moderaciÃ³n. Excesivos tiros a la cabeza pueden activar detecciones.", @"DÃ¹ng aimbot cÃ³ chá»«ng má»±c.")];
    [self.page addSubview:warn];
    y += 46.0f;

    [self _toggle:y key:@"SilentAim" title:L(@"Aimbot", @"Aimbot", @"Aimbot") def:NO]; y += kRowH + kGap;
    [self _toggle:y key:@"AimTargetLine" title:L(@"Aim Line", @"LÃ­nea de Apuntado", @"ÄÆ°á»ng Ngáº¯m") def:NO]; y += kRowH + kGap;
    [self _toggle:y key:@"ShowFov" title:L(@"Show FOV", @"Mostrar FOV", @"Hiá»‡n FOV") def:YES]; y += kRowH + kGap;
    [self _toggle:y key:@"AimLag" title:L(@"Skip Bots", @"Saltar Bots", @"Bá» Bots") def:NO]; y += kRowH + kGap;

    // ACTIVATION (dropdown)
    DAAEPickerRow *act = [self _picker:y title:L(@"ACTIVATION", @"ACTIVACIÃ“N", @"KÃCH HOáº T")
                                 options:@[L(@"Always", @"Siempre", @"LuÃ´n"), L(@"On Shoot", @"Al Disparar", @"Khi Báº¯n"), L(@"On Scope", @"Con Mira", @"Khi Ngáº¯m")]
                                    sel:(NSInteger)(PF(@"AimActivation", 1) - 1)];
    y += kRowH + kGap;
    __weak __typeof__(self) ws = self;
    act.onPick = ^(NSInteger idx) {
        PS(@"AimActivation", (float)(idx + 1));
        [ws _selectTab:1];
    };

    // AIM POSITION (dropdown)
    DAAEPickerRow *pos = [self _picker:y title:L(@"AIM POSITION", @"POSICIÃ“N DE APUNTADO", @"Vá»Š TRÃ NGáº®M")
                                 options:@[@"Head", L(@"Neck", @"Cuello", @"Cá»•"), L(@"Body", @"Cuerpo", @"ThÃ¢n")]
                                    sel:(NSInteger)(PF(@"AimType", -1) + 1)];
    y += kRowH + kGap;
    pos.onPick = ^(NSInteger idx) {
        PS(@"AimType", (float)(idx - 1));
        [ws _selectTab:1];
    };

    // WEAPONS
    [self _section:y title:L(@"WEAPONS", @"ARMAS", @"VÅ¨ KHÃ")]; y += 26.0f;
    [self _toggle:y key:@"FastFire" title:L(@"Fast Fire", @"Disparo RÃ¡pido", @"Báº¯n Nhanh") def:NO]; y += kRowH + kGap;
    [self _toggle:y key:@"ShootNoReload" title:L(@"No Reload", @"Sin Recarga", @"KhÃ´ng Náº¡p Äáº¡n") def:NO]; y += kRowH + kGap;

    [self _slider:y key:@"FovSize" title:L(@"FOV Radius", @"Radio FOV", @"BÃ¡n KÃ­nh FOV") min:5 max:48 def:40]; y += kSlideH + kGap;
    [self _slider:y key:@"SilentFovSize" title:L(@"FOV Thickness", @"Grosor FOV", @"Äá»™ DÃ y FOV") min:0 max:10 def:18]; y += kSlideH + kGap;
    return y;
}

// ---- TAB 2: DRAW ------------------------------------------------------------

- (CGFloat)_tabDRAW:(CGFloat)y0 {
    CGFloat y = y0;
    [self _section:y title:L(@"ESP COLORS", @"COLORES ESP", @"MÃ€U ESP")]; y += 26.0f;

    // Color target picker
    DAAEPickerRow *ct = [self _picker:y title:L(@"Color Target", @"Objetivo de Color", @"Má»¥c TiÃªu MÃ u")
                                 options:@[L(@"Box", @"Caja", @"Há»™p"), L(@"FOV", @"FOV", @"FOV")]
                                    sel:(NSInteger)PF(@"ColorTarget", 0)];
    y += kRowH + kGap;
    __weak __typeof__(self) ws = self;
    ct.onPick = ^(NSInteger idx) { PS(@"ColorTarget", (float)idx); [ws _selectTab:2]; };

    [self _slider:y key:@"BoxColorR" title:L(@"Red", @"Rojo", @"Äá»") min:0 max:1 def:0.26]; y += kSlideH + kGap;
    [self _slider:y key:@"BoxColorG" title:L(@"Green", @"Verde", @"Xanh") min:0 max:1 def:0.78]; y += kSlideH + kGap;
    [self _slider:y key:@"BoxColorB" title:L(@"Blue", @"Azul", @"Xanh DÆ°Æ¡ng") min:0 max:1 def:0.90]; y += kSlideH + kGap;
    return y;
}

// ---- TAB 3: TOOLS -----------------------------------------------------------

- (CGFloat)_tabTOOLS:(CGFloat)y0 {
    CGFloat y = y0;
    DAAEWarningLabel *warn = [[DAAEWarningLabel alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], 40.0f) title:L(@"Some options may not be entirely safe. Use with caution.", @"Algunas opciones pueden no ser seguras. Ãšsalas con precauciÃ³n.", @"Má»™t sá»‘ tÃ¹y chá»n cÃ³ thá»ƒ khÃ´ng an toÃ n.")];
    [self.page addSubview:warn];
    y += 46.0f;

    [self _section:y title:L(@"EXTRAS", @"EXTRAS", @"Má»ž Rá»˜NG")]; y += 26.0f;
    NSArray *exKeys = @[@"GhostModeFloating", @"FakeLagFloating", @"FlyFloating", @"RunSpeedFloating", @"HideFeatureButtons", @"AutoFireFloating"];
    NSArray *exT = @[
        L(@"Ghost", @"Fantasma", @"Ma"),
        L(@"FakeLag", @"Lag Falso", @"Giáº£ Lag"),
        L(@"Fly", @"Volar", @"Bay"),
        L(@"Speed", @"Velocidad", @"Tá»‘c Äá»™"),
        L(@"Hide Buttons", @"Ocultar Botones", @"áº¨n NÃºt"),
        L(@"Auto Fire", @"Disparo AutomÃ¡tico", @"Báº¯n Tá»± Äá»™ng")
    ];
    for (NSUInteger i = 0; i < exKeys.count; i++) {
        [self _toggle:y key:exKeys[i] title:exT[i] def:NO];
        y += kRowH + kGap;
    }

    [self _section:y title:L(@"MOVEMENT", @"MOVIMIENTO", @"DI CHUYá»‚N")]; y += 26.0f;
    [self _toggle:y key:@"RunSpeed" title:L(@"Speed Toggle", @"Interruptor Velocidad", @"CÃ´ng Táº¯c Tá»‘c Äá»™") def:NO]; y += kRowH + kGap;
    [self _slider:y key:@"RunSpeedValue" title:L(@"Speed Value", @"Valor Velocidad", @"GiÃ¡ Trá»‹ Tá»‘c Äá»™") min:1 max:15 def:6]; y += kSlideH + kGap;
    [self _slider:y key:@"FlyHeight" title:L(@"Fly Height", @"Altura Vuelo", @"Äá»™ Cao Bay") min:1 max:6 def:4]; y += kSlideH + kGap;

    [self _section:y title:L(@"EFFECTS", @"EFECTOS", @"HIá»†U á»¨NG")]; y += 26.0f;
    [self _toggle:y key:@"VisualSpin" title:L(@"Visual Spin", @"Giro Visual", @"Xoay HÃ¬nh") def:NO]; y += kRowH + kGap;
    [self _slider:y key:@"VisualSpinSpeed" title:L(@"Spin Speed", @"Velocidad Giro", @"Tá»‘c Äá»™ Xoay") min:0.1f max:3.0f def:0.5f]; y += kSlideH + kGap;
    [self _toggle:y key:@"BalancedRender" title:L(@"Balanced Render", @"Render Equilibrado", @"Render CÃ¢n Báº±ng") def:NO]; y += kRowH + kGap;
    return y;
}

// ---- TAB 4: SETTINGS ----------------------------------------------------------

- (CGFloat)_tabSETTINGS:(CGFloat)y0 {
    CGFloat y = y0;

    // â€”â€” MENU SIZE: global uniform scale of the WHOLE menu â€”â€”
    [self _section:y title:L(@"MENU SIZE", @"TAMAÃ‘O DEL MENÃš", @"Cá»  MENU")]; y += 26.0f;
    UILabel *sl = [[UILabel alloc] initWithFrame:CGRectMake(kPad, y, [self _cw], 18.0f)];
    sl.font = [UIFont systemFontOfSize:15.5f weight:UIFontWeightMedium];
    sl.text = L(@"Menu Size", @"TamaÃ±o del MenÃº", @"Cá»¡ Menu");
    [self.page addSubview:sl];
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

    // â€”â€” PRESETS 70% / 80% / 100% / 120% / 130% â€”â€”
    NSArray *preT = @[@"70%", @"80%", @"100%", @"120%", @"130%"];
    NSArray *preV = @[@0.7f, @0.8f, @1.0f, @1.2f, @1.3f];
    for (NSUInteger i = 0; i < preT.count; i++) {
        float v = [preV[i] floatValue];
        __weak __typeof__(self) ws = self;
        [self _option:y title:preT[i] sel:(fabsf(gMenuScale - v) < 0.001f) tap:^{ [ws _menuScaleChanged:v]; [ws _selectTab:4]; }];
        y += 46.0f + kGap;
    }

    // â€”â€” TRANSPARENCY (panel opacity, 0.35 â€“ 1.0, live) â€”â€”
    [self _section:y title:L(@"TRANSPARENCY", @"TRANSPARENCIA", @"TRONG SUá»T")]; y += 26.0f;
    DAAESliderRow *alpha = [self _slider:y key:@"PanelAlpha" title:L(@"Panel Opacity", @"Opacidad del Panel", @"Äá»™ Má» Panel") min:0.35f max:1.0f def:0.85f];
    y += kSlideH + kGap;
    __weak __typeof__(self) ws2 = self;
    alpha.onChanged = ^(float v) {
        ESPPrefsSetFloat(@"PanelAlpha", v);
        ESPSyncFromPrefs();
        // Live: apply panel/sidebar opacity immediately
        [ws2 _applyPanelAlpha:v];
    };

    // â€”â€” STREAM MODE (AnLive â€” hide menu from recordings) â€”â€”
    [self _section:y title:L(@"PRIVACY", @"PRIVACIDAD", @"RIÃŠNG TÆ¯")]; y += 26.0f;
    [self _toggle:y key:@"AnLive" title:L(@"Stream Mode", @"Modo Stream", @"Cháº¿ Äá»™ Stream") def:NO]; y += kRowH + kGap;

    // â€”â€” LANGUAGE â€”â€”
    [self _section:y title:L(@"LANGUAGE", @"IDIOMA", @"NGÃ”N NGá»®")]; y += 26.0f;
    NSArray *langT = @[@"English", @"EspaÃ±ol", @"Tiáº¿ng Viá»‡t"];
    for (NSUInteger i = 0; i < 3; i++) {
        NSInteger idx = (NSInteger)i;
        __weak __typeof__(self) ws = self;
        [self _option:y title:langT[i] sel:(MMLang() == idx) tap:^{
            [UD() setInteger:idx forKey:@"DAAE.lang"];
            [UD() synchronize];
            [ws _selectTab:4];
        }];
        y += kRowH + kGap;
    }

    // â€”â€” APPEARANCE (Light / Dark only) â€”â€”
    [self _section:y title:L(@"APPEARANCE", @"APARIENCIA", @"GIAO DIá»†N")]; y += 26.0f;
    __weak __typeof__(self) ws = self;
    [self _option:y title:L(@"Light", @"Claro", @"SÃ¡ng") sel:!gDark tap:^{ [ws _setDark:NO]; [ws _selectTab:4]; }];
    y += kRowH + kGap;
    [self _option:y title:L(@"Dark", @"Oscuro", @"Tá»‘i") sel:gDark tap:^{ [ws _setDark:YES]; [ws _selectTab:4]; }];
    y += kRowH + kGap;

    // â€”â€” INFO â€”â€”
    [self _section:y title:L(@"INFO", @"INFO", @"THÃ”NG TIN")]; y += 26.0f;
    [self _info:y title:L(@"Product", @"Producto", @"Sáº£n Pháº©m") value:@"DAAE IOS"]; y += 54.0f;
    [self _info:y title:L(@"Creator", @"Creador", @"TÃ¡c Giáº£") value:@"@didierxit7"]; y += 54.0f;
    [self _info:y title:L(@"Telegram", @"Telegram", @"Telegram") value:@"t.me/didierxit7"]; y += 54.0f;
    [self _info:y title:L(@"Key", @"Clave", @"Key") value:@"TEST"]; y += 54.0f;
    return y;
}

- (void)_scaleChanged:(UISlider *)s {
    [self _menuScaleChanged:s.value];
}

- (void)dealloc { /* preferences are owned by MizzeMenuPrefs */ }

@end

// BUILD OK

#import "Menu.h"
#import "Loc.h"
#import <objc/runtime.h>

static NSString *const kProduct    = @"Fine ios";
static NSString *const kVersion    = @"Beta 1";
static NSString *const kCreator    = @"@didierxit7";
static NSString *const kContactURL = @"https://t.me/didierxit7";
static NSString *const kGroupURL   = @"https://t.me/primexios";

// ---------------------------------------------------------------------------
// Associated-object keys for iOS 13-compatible block actions
// ---------------------------------------------------------------------------
static const void *kBlockKey    = &kBlockKey;
static const void *kChoiceKey   = &kChoiceKey;

// ---------------------------------------------------------------------------
// Estado y registro
// ---------------------------------------------------------------------------
namespace {

enum class Kind { Section, Toggle, Slider, Choice, Button };

struct Item {
    Kind kind = Kind::Toggle;
    MyMenu::Tab tab = MyMenu::Tab::Esp;
    std::string key;
    float mn = 0, mx = 1, def = 0;
    int defIdx = 0;
    std::vector<std::string> options;
    std::function<void(bool)>  onToggle;
    std::function<void(float)> onSlider;
    std::function<void(int)>   onChoice;
    std::function<void()>      onTap;
};

std::vector<Item> &Items() {
    static std::vector<Item> v;
    return v;
}

MyMenu::AccountInfo gAccount;

struct Theme { float opacity = 0.85f; int accent = 0; bool square = false; };
Theme gTheme;

NSArray<UIColor *> *Accents() {
    static NSArray *a = @[
        [UIColor colorWithRed:0.25 green:0.85 blue:0.78 alpha:1],  // turquesa
        [UIColor colorWithRed:1.00 green:0.30 blue:0.33 alpha:1],  // rojo
        [UIColor colorWithRed:0.66 green:0.48 blue:1.00 alpha:1],  // violeta
        [UIColor colorWithRed:0.28 green:0.62 blue:1.00 alpha:1],  // azul
        [UIColor colorWithRed:1.00 green:0.62 blue:0.22 alpha:1],  // naranja
        [UIColor colorWithRed:1.00 green:0.45 blue:0.72 alpha:1],  // rosa
    ];
    return a;
}
UIColor *Accent() { return Accents()[gTheme.accent]; }

void LoadTheme() {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if ([ud objectForKey:@"MyMenu.theme.opacity"]) gTheme.opacity = [ud floatForKey:@"MyMenu.theme.opacity"];
    gTheme.accent = (int)[ud integerForKey:@"MyMenu.theme.accent"];
    if (gTheme.accent < 0 || gTheme.accent >= (int)Accents().count) gTheme.accent = 0;
    gTheme.square = [ud boolForKey:@"MyMenu.theme.square"];
}
void SaveTheme() {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    [ud setFloat:gTheme.opacity forKey:@"MyMenu.theme.opacity"];
    [ud setInteger:gTheme.accent forKey:@"MyMenu.theme.accent"];
    [ud setBool:gTheme.square forKey:@"MyMenu.theme.square"];
}

NSString *KeyFor(const Item &it) {
    return [NSString stringWithFormat:@"MyMenu.%d.%s", (int)it.tab, it.key.c_str()];
}

// ---------------------------------------------------------------------------
// Utilidades de dibujo
// ---------------------------------------------------------------------------
UIColor *W(CGFloat a) { return [UIColor colorWithWhite:1 alpha:a]; }

UILabel *Label(NSString *t, CGRect f, CGFloat size, UIFontWeight w, UIColor *c) {
    UILabel *l = [[UILabel alloc] initWithFrame:f];
    l.text = t;
    l.font = [UIFont systemFontOfSize:size weight:w];
    l.textColor = c;
    l.adjustsFontSizeToFitWidth = YES;
    l.minimumScaleFactor = 0.7;
    return l;
}

void StylePill(UIView *v) {
    v.backgroundColor = W(0.10);
    v.layer.cornerRadius = gTheme.square ? 8 : v.bounds.size.height / 2;
    v.layer.borderWidth = 0.8;
    v.layer.borderColor = W(0.20).CGColor;
}

UIImage *Sym(NSString *name, CGFloat size, UIImageSymbolWeight w) {
    return [UIImage systemImageNamed:name
                   withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:size weight:w]];
}

void OpenURL(NSString *url) {
    NSURL *u = [NSURL URLWithString:url];
    if (u) [UIApplication.sharedApplication openURL:u options:@{} completionHandler:nil];
}

void SetCheck(UIView *c, BOOL on) {
    c.layer.cornerRadius = gTheme.square ? 7 : 13;
    c.backgroundColor = on ? Accent() : W(0.10);
    c.layer.borderWidth = on ? 0 : 0.8;
    c.layer.borderColor = W(0.25).CGColor;
    [c viewWithTag:1].hidden = !on;
}

UIView *MakeCheck(BOOL on) {
    UIView *c = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 26, 26)];
    c.userInteractionEnabled = NO;
    UIImageView *iv = [[UIImageView alloc] initWithImage:Sym(@"checkmark", 12, UIImageSymbolWeightHeavy)];
    iv.tintColor = UIColor.whiteColor;
    iv.frame = c.bounds;
    iv.contentMode = UIViewContentModeCenter;
    iv.tag = 1;
    [c addSubview:iv];
    SetCheck(c, on);
    return c;
}

void AddSectionLabel(UIScrollView *sv, CGFloat &y, CGFloat w, NSString *title) {
    UILabel *l = Label([title uppercaseString], CGRectMake(8, y + 4, w - 16, 16),
                       11, UIFontWeightSemibold, W(0.45));
    [sv addSubview:l];
    y += 26;
}

// ---------------------------------------------------------------------------
// _MMBlockTarget — iOS 13-compatible block trampoline
// ---------------------------------------------------------------------------

} // namespace (temporarily close to declare ObjC class at file scope)

@interface _MMBlockTarget : NSObject
@property (nonatomic, copy) dispatch_block_t action;
- (void)fire;
@end
@implementation _MMBlockTarget
- (void)fire { if (self.action) self.action(); }
@end

// ---------------------------------------------------------------------------
// _MMSliderTarget — carries the slider + fmt + label + callback
// ---------------------------------------------------------------------------
@interface _MMSliderTarget : NSObject
@property (nonatomic, weak)   UILabel *valueLabel;
@property (nonatomic, copy)   NSString *fmt;
@property (nonatomic, copy)   void (^onChange)(float);
- (void)sliderChanged:(UISlider *)sender;
@end
@implementation _MMSliderTarget
- (void)sliderChanged:(UISlider *)sender {
    float v = sender.value;
    self.valueLabel.text = [NSString stringWithFormat:self.fmt, v];
    if (self.onChange) self.onChange(v);
}
@end

// ---------------------------------------------------------------------------
// _MMChoiceRow — iOS 13 UIAlertController-based choice picker
// ---------------------------------------------------------------------------
@interface _MMChoiceRow : NSObject
@property (nonatomic, weak)   UIButton *button;
@property (nonatomic, weak)   UILabel  *valueLabel;
@property (nonatomic, copy)   NSArray<NSString *> *labels;
@property (nonatomic, assign) int current;
@property (nonatomic, copy)   void (^onPick)(int);
- (void)tapped;
@end
@implementation _MMChoiceRow
- (void)tapped {
    // Find the topmost view controller to present from
    UIWindow *keyWin = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (![s isKindOfClass:UIWindowScene.class]) continue;
        if (s.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *w in ((UIWindowScene *)s).windows)
            if (w.isKeyWindow) { keyWin = w; break; }
        if (keyWin) break;
    }
    if (!keyWin) return;
    UIViewController *vc = keyWin.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;

    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil
                                                                message:nil
                                                         preferredStyle:UIAlertControllerStyleActionSheet];
    __weak _MMChoiceRow *wself = self;
    for (int k = 0; k < (int)self.labels.count; k++) {
        NSString *lbl = self.labels[k];
        BOOL isCur = (k == self.current);
        NSString *title = isCur ? [NSString stringWithFormat:@"✓ %@", lbl] : lbl;
        [ac addAction:[UIAlertAction actionWithTitle:title
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *act) {
            _MMChoiceRow *sr = wself;
            if (!sr) return;
            sr.current = k;
            sr.valueLabel.text = lbl;
            if (sr.onPick) sr.onPick(k);
        }]];
    }
    [ac addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                          style:UIAlertActionStyleCancel
                                        handler:nil]];
    // iPad popover anchor
    if (ac.popoverPresentationController && self.button) {
        ac.popoverPresentationController.sourceView = self.button;
        ac.popoverPresentationController.sourceRect = self.button.bounds;
    }
    [vc presentViewController:ac animated:YES completion:nil];
}
@end

namespace {

// Re-open namespace for the rest of the helpers

static void AddBlockAction(UIControl *ctrl, UIControlEvents events, dispatch_block_t blk) {
    _MMBlockTarget *t = [_MMBlockTarget new];
    t.action = blk;
    objc_setAssociatedObject(ctrl, (__bridge void *)t, t, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [ctrl addTarget:t action:@selector(fire) forControlEvents:events];
}

UIView *ToggleRow(CGFloat y, CGFloat w, NSString *title, BOOL on,
                  void (^onTap)(BOOL newValue, UIView *check)) {
    UIButton *row = [UIButton buttonWithType:UIButtonTypeCustom];
    row.frame = CGRectMake(2, y, w - 4, 44);
    StylePill(row);
    [row addSubview:Label(title, CGRectMake(16, 0, row.bounds.size.width - 70, 44),
                          15, UIFontWeightMedium, W(1))];
    UIView *chk = MakeCheck(on);
    chk.center = CGPointMake(row.bounds.size.width - 26, 22);
    [row addSubview:chk];
    __block BOOL state = on;
    AddBlockAction(row, UIControlEventTouchUpInside, ^{
        state = !state;
        SetCheck(chk, state);
        onTap(state, chk);
    });
    return row;
}

UIView *SliderRow(CGFloat y, CGFloat w, NSString *title, float mn, float mx, float val,
                  NSString *fmt, void (^onChange)(float)) {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(2, y, w - 4, 64)];
    StylePill(row);
    [row addSubview:Label(title, CGRectMake(16, 8, row.bounds.size.width - 100, 22),
                          15, UIFontWeightMedium, W(1))];

    UILabel *vp = Label([NSString stringWithFormat:fmt, val],
                        CGRectMake(row.bounds.size.width - 70, 10, 56, 20),
                        12, UIFontWeightBold, UIColor.whiteColor);
    vp.textAlignment = NSTextAlignmentCenter;
    vp.backgroundColor = Accent();
    vp.layer.cornerRadius = gTheme.square ? 5 : 10;
    vp.clipsToBounds = YES;
    [row addSubview:vp];

    UISlider *s = [[UISlider alloc] initWithFrame:CGRectMake(14, 34, row.bounds.size.width - 28, 22)];
    s.minimumValue = mn;
    s.maximumValue = mx;
    s.value = val;
    s.minimumTrackTintColor = Accent();
    s.maximumTrackTintColor = W(0.2);
    s.thumbTintColor = UIColor.whiteColor;

    // iOS 13-compatible: trampoline target carries label + fmt + callback
    _MMSliderTarget *st = [_MMSliderTarget new];
    st.valueLabel = vp;
    st.fmt = fmt;
    st.onChange = onChange;
    objc_setAssociatedObject(s, kBlockKey, st, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [s addTarget:st action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];

    [row addSubview:s];
    return row;
}

void AttachChoice(UIButton *btn, UILabel *valueLbl, NSArray<NSString *> *labels,
                  int cur, void (^onPick)(int)) {
    _MMChoiceRow *cr = [_MMChoiceRow new];
    cr.button     = btn;
    cr.valueLabel = valueLbl;
    cr.labels     = labels;
    cr.current    = cur;
    cr.onPick     = onPick;
    // Keep alive via associated object on the button
    objc_setAssociatedObject(btn, kChoiceKey, cr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [btn addTarget:cr action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
}

UIView *InfoRow(CGFloat y, CGFloat w, NSString *title, NSString *value, NSString *url) {
    UIButton *row = [UIButton buttonWithType:UIButtonTypeCustom];
    row.frame = CGRectMake(2, y, w - 4, 44);
    StylePill(row);
    CGFloat rw = row.bounds.size.width;
    [row addSubview:Label(title, CGRectMake(16, 0, rw * 0.38, 44), 15, UIFontWeightMedium, W(1))];
    UILabel *v = Label(value, CGRectMake(rw * 0.38, 0, rw * 0.62 - (url ? 40 : 16), 44),
                       14, UIFontWeightSemibold, url ? Accent() : W(0.85));
    v.textAlignment = NSTextAlignmentRight;
    [row addSubview:v];
    if (url) {
        UIImageView *ar = [[UIImageView alloc] initWithImage:Sym(@"arrow.up.right", 12, UIImageSymbolWeightBold)];
        ar.tintColor = W(0.6);
        ar.frame = CGRectMake(rw - 30, 15, 14, 14);
        ar.contentMode = UIViewContentModeScaleAspectFit;
        [row addSubview:ar];
        NSString *urlCopy = [url copy];
        AddBlockAction(row, UIControlEventTouchUpInside, ^{ OpenURL(urlCopy); });
    }
    return row;
}

UIViewController *TopVC(UIWindow *w) {
    UIViewController *vc = w.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

UIWindow *FindKeyWindow() {
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (![s isKindOfClass:UIWindowScene.class]) continue;
        if (s.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *w in ((UIWindowScene *)s).windows)
            if (w.isKeyWindow) return w;
    }
    return nil;
}

} // namespace

// ---------------------------------------------------------------------------
// Panel glass
// ---------------------------------------------------------------------------
@interface MMPanel : UIView
@property (nonatomic, strong) UIVisualEffectView *glass;
@property (nonatomic, strong) UIView *tint;
@property (nonatomic, strong) UIView *sidebar;
@property (nonatomic, strong) UIView *header;
@property (nonatomic, strong) UIScrollView *content;
@property (nonatomic, assign) int tab;   // 0 ESP, 1 AIMBOT, 2 EXTRAS, 3 CONFIG, 4 CUENTA
- (void)rebuild;
- (void)applyGlass;
@end

@implementation MMPanel

- (instancetype)initWithFrame:(CGRect)f {
    if ((self = [super initWithFrame:f])) {
        self.clipsToBounds = YES;

        self.glass = [[UIVisualEffectView alloc] initWithEffect:
            [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
        self.glass.frame = self.bounds;
        [self addSubview:self.glass];

        self.tint = [[UIView alloc] initWithFrame:self.bounds];
        self.tint.userInteractionEnabled = NO;
        [self addSubview:self.tint];

        self.sidebar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 70, f.size.height)];
        [self addSubview:self.sidebar];

        self.header = [[UIView alloc] initWithFrame:CGRectMake(76, 12, f.size.width - 88, 40)];
        [self addSubview:self.header];

        self.content = [[UIScrollView alloc] initWithFrame:
            CGRectMake(76, 60, f.size.width - 88, f.size.height - 68)];
        self.content.showsVerticalScrollIndicator = NO;
        [self addSubview:self.content];

        for (UIView *v in @[self.sidebar, self.header])
            [v addGestureRecognizer:[[UIPanGestureRecognizer alloc]
                initWithTarget:self action:@selector(drag:)]];

        [self rebuild];
    }
    return self;
}

- (void)drag:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
    [g setTranslation:CGPointZero inView:self.superview];
}

- (void)applyGlass {
    self.layer.cornerRadius = gTheme.square ? 6 : 24;
    self.layer.borderWidth = 0.8;
    self.layer.borderColor = W(0.22).CGColor;
    self.glass.alpha = gTheme.opacity;
    self.tint.backgroundColor = [UIColor colorWithWhite:0 alpha:0.28 * gTheme.opacity];
}

- (void)rebuild {
    [self applyGlass];
    for (UIView *v in [self.sidebar.subviews copy]) [v removeFromSuperview];
    for (UIView *v in [self.header.subviews copy])  [v removeFromSuperview];
    for (UIView *v in [self.content.subviews copy]) [v removeFromSuperview];
    [self buildSidebar];
    [self buildHeader];
    [self buildContent];
}

- (void)rebuildAsync {
    dispatch_async(dispatch_get_main_queue(), ^{ [self rebuild]; });
}

- (void)buildSidebar {
    NSArray *icons = @[@"eye.fill", @"scope", @"sparkles", @"gearshape.fill", @"person.fill"];
    CGFloat pitch = MIN(54.0, (self.bounds.size.height - 74.0) / 4.0);
    for (int i = 0; i < 5; i++) {
        BOOL sel = (i == self.tab);
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(12, 14 + i * pitch, 46, 46);
        b.backgroundColor = sel ? UIColor.whiteColor : W(0.12);
        b.layer.cornerRadius = gTheme.square ? 10 : 23;
        b.layer.borderWidth = 0.8;
        b.layer.borderColor = W(0.22).CGColor;
        [b setImage:Sym(icons[i], 18, UIImageSymbolWeightSemibold) forState:UIControlStateNormal];
        b.tintColor = sel ? UIColor.blackColor : W(0.85);
        __weak MMPanel *wself = self;
        int tabIdx = i;
        AddBlockAction(b, UIControlEventTouchUpInside, ^{
            wself.tab = tabIdx;
            [wself rebuildAsync];
        });
        [self.sidebar addSubview:b];
    }
}

- (void)buildHeader {
    StylePill(self.header);
    NSArray *icons = @[@"eye.fill", @"scope", @"sparkles", @"gearshape.fill", @"person.fill"];
    NSArray *keys  = @[@"tab.esp", @"tab.aim", @"tab.extras", @"tab.config", @"tab.account"];
    UIImageView *iv = [[UIImageView alloc] initWithImage:Sym(icons[self.tab], 15, UIImageSymbolWeightSemibold)];
    iv.tintColor = Accent();
    iv.frame = CGRectMake(16, 11, 20, 18);
    iv.contentMode = UIViewContentModeScaleAspectFit;
    [self.header addSubview:iv];
    [self.header addSubview:Label(Loc::T([keys[self.tab] UTF8String]),
                                  CGRectMake(44, 0, self.header.bounds.size.width - 60, 40),
                                  17, UIFontWeightBold, W(1))];
}

- (void)buildContent {
    CGFloat w = self.content.bounds.size.width, y = 2;
    UIScrollView *sv = self.content;
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;

    if (self.tab <= 2) {
        auto &items = Items();
        for (size_t i = 0; i < items.size(); i++) {
            Item &it = items[i];
            if ((int)it.tab != self.tab) continue;
            NSString *title = Loc::T(it.key.c_str());
            NSString *key = KeyFor(it);

            if (it.kind == Kind::Section) {
                AddSectionLabel(sv, y, w, title);

            } else if (it.kind == Kind::Toggle) {
                [sv addSubview:ToggleRow(y, w, title, [ud boolForKey:key],
                    ^(BOOL on, UIView *chk) {
                        [NSUserDefaults.standardUserDefaults setBool:on forKey:key];
                        if (Items()[i].onToggle) Items()[i].onToggle(on);
                    })];
                y += 52;

            } else if (it.kind == Kind::Slider) {
                float saved = [ud objectForKey:key] ? [ud floatForKey:key] : it.def;
                [sv addSubview:SliderRow(y, w, title, it.mn, it.mx, saved, @"%.1f",
                    ^(float v) {
                        [NSUserDefaults.standardUserDefaults setFloat:v forKey:key];
                        if (Items()[i].onSlider) Items()[i].onSlider(v);
                    })];
                y += 72;

            } else if (it.kind == Kind::Choice) {
                NSMutableArray<NSString *> *labels = [NSMutableArray array];
                for (auto &o : it.options) [labels addObject:Loc::T(o.c_str())];
                if (!labels.count) continue;
                int cur = [ud objectForKey:key] ? (int)[ud integerForKey:key] : it.defIdx;
                if (cur < 0 || cur >= (int)labels.count) cur = 0;

                UIButton *row = [UIButton buttonWithType:UIButtonTypeCustom];
                row.frame = CGRectMake(2, y, w - 4, 44);
                StylePill(row);
                CGFloat rw = row.bounds.size.width;
                [row addSubview:Label(title, CGRectMake(16, 0, rw * 0.5, 44), 15, UIFontWeightMedium, W(1))];
                UILabel *vl = Label(labels[cur], CGRectMake(rw * 0.5, 0, rw * 0.5 - 40, 44),
                                    14, UIFontWeightSemibold, Accent());
                vl.textAlignment = NSTextAlignmentRight;
                [row addSubview:vl];
                UIImageView *chev = [[UIImageView alloc] initWithImage:
                    Sym(@"chevron.up.chevron.down", 11, UIImageSymbolWeightBold)];
                chev.tintColor = W(0.6);
                chev.frame = CGRectMake(rw - 30, 15, 14, 14);
                chev.contentMode = UIViewContentModeScaleAspectFit;
                [row addSubview:chev];
                AttachChoice(row, vl, labels, cur, ^(int k) {
                    [NSUserDefaults.standardUserDefaults setInteger:k forKey:key];
                    if (Items()[i].onChoice) Items()[i].onChoice(k);
                });
                [sv addSubview:row];
                y += 52;

            } else if (it.kind == Kind::Button) {
                UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
                b.frame = CGRectMake(2, y, w - 4, 44);
                StylePill(b);
                b.backgroundColor = [Accent() colorWithAlphaComponent:0.28];
                [b setTitle:title forState:UIControlStateNormal];
                b.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
                AddBlockAction(b, UIControlEventTouchUpInside, ^{
                    if (Items()[i].onTap) Items()[i].onTap();
                });
                [sv addSubview:b];
                y += 52;
            }
        }
    } else if (self.tab == 3) {
        [self buildConfig:&y width:w];
    } else {
        [self buildAccount:&y width:w];
    }

    sv.contentSize = CGSizeMake(w, y + 6);
    sv.contentOffset = CGPointZero;
}

// ---- CONFIGURACIÓN -------------------------------------------------------
- (void)buildConfig:(CGFloat *)py width:(CGFloat)w {
    CGFloat y = *py;
    UIScrollView *sv = self.content;
    __weak MMPanel *wself = self;

    AddSectionLabel(sv, y, w, Loc::T("cfg.custom"));

    // Opacidad
    [sv addSubview:SliderRow(y, w, Loc::T("cfg.opacity"), 0.3f, 1.0f, gTheme.opacity, @"%.2f",
        ^(float v) {
            gTheme.opacity = v;
            SaveTheme();
            [wself applyGlass];
        })];
    y += 72;

    // Color de acento
    UIView *accRow = [[UIView alloc] initWithFrame:CGRectMake(2, y, w - 4, 50)];
    StylePill(accRow);
    CGFloat rw = accRow.bounds.size.width;
    [accRow addSubview:Label(Loc::T("cfg.accent"), CGRectMake(16, 0, 120, 50), 15, UIFontWeightMedium, W(1))];
    CGFloat sx = rw - 14 - (6 * 22 + 5 * 8);
    for (int k = 0; k < (int)Accents().count; k++) {
        UIButton *sw = [UIButton buttonWithType:UIButtonTypeCustom];
        sw.frame = CGRectMake(sx + k * 30, 14, 22, 22);
        sw.backgroundColor = Accents()[k];
        sw.layer.cornerRadius = gTheme.square ? 6 : 11;
        sw.layer.borderWidth = (k == gTheme.accent) ? 2 : 0;
        sw.layer.borderColor = UIColor.whiteColor.CGColor;
        int accentIdx = k;
        AddBlockAction(sw, UIControlEventTouchUpInside, ^{
            gTheme.accent = accentIdx;
            SaveTheme();
            [wself rebuildAsync];
        });
        [accRow addSubview:sw];
    }
    [sv addSubview:accRow];
    y += 58;

    // Puntas cuadradas
    [sv addSubview:ToggleRow(y, w, Loc::T("cfg.square"), gTheme.square,
        ^(BOOL on, UIView *chk) {
            gTheme.square = on;
            SaveTheme();
            [wself rebuildAsync];
        })];
    y += 52;

    // Idioma
    UIView *langRow = [[UIView alloc] initWithFrame:CGRectMake(2, y, w - 4, 50)];
    StylePill(langRow);
    [langRow addSubview:Label(Loc::T("cfg.language"), CGRectMake(16, 0, 100, 50), 15, UIFontWeightMedium, W(1))];
    NSArray *codes = @[@"EN", @"ES", @"VI"];
    CGFloat lx = langRow.bounds.size.width - 14 - (3 * 46 + 2 * 6);
    for (int k = 0; k < 3; k++) {
        BOOL sel = ((int)Loc::Get() == k);
        UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
        b.frame = CGRectMake(lx + k * 52, 11, 46, 28);
        b.backgroundColor = sel ? Accent() : W(0.10);
        b.layer.cornerRadius = gTheme.square ? 6 : 14;
        [b setTitle:codes[k] forState:UIControlStateNormal];
        b.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        int langIdx = k;
        AddBlockAction(b, UIControlEventTouchUpInside, ^{
            Loc::Set((Loc::Lang)langIdx);
            [wself rebuildAsync];
        });
        [langRow addSubview:b];
    }
    [sv addSubview:langRow];
    y += 58;

    *py = y;
}

// ---- CUENTA --------------------------------------------------------------
- (void)buildAccount:(CGFloat *)py width:(CGFloat)w {
    CGFloat y = *py;
    UIScrollView *sv = self.content;

    AddSectionLabel(sv, y, w, Loc::T("sec.license"));
    [sv addSubview:InfoRow(y, w, Loc::T("acc.key"),
                           [NSString stringWithUTF8String:gAccount.key.c_str()], nil)];
    y += 52;
    NSString *days = gAccount.daysLeft < 0 ? @"—" : [NSString stringWithFormat:@"%d", gAccount.daysLeft];
    [sv addSubview:InfoRow(y, w, Loc::T("acc.days"), days, nil)];
    y += 52;

    AddSectionLabel(sv, y, w, Loc::T("sec.about"));
    [sv addSubview:InfoRow(y, w, Loc::T("acc.product"), kProduct, nil)];
    y += 52;
    [sv addSubview:InfoRow(y, w, Loc::T("acc.version"), kVersion, nil)];
    y += 52;
    [sv addSubview:InfoRow(y, w, Loc::T("acc.creator"), kCreator, nil)];
    y += 52;

    AddSectionLabel(sv, y, w, Loc::T("sec.links"));
    [sv addSubview:InfoRow(y, w, Loc::T("acc.contact"), @"t.me/didierxit7", kContactURL)];
    y += 52;
    [sv addSubview:InfoRow(y, w, Loc::T("acc.group"), @"t.me/primexios", kGroupURL)];
    y += 52;

    *py = y;
}

@end

// ---------------------------------------------------------------------------
// Botón flotante
// ---------------------------------------------------------------------------
@interface MMFloat : UIButton
@property (nonatomic, weak) MMPanel *panel;
@end

@implementation MMFloat
- (void)dragButton:(UIPanGestureRecognizer *)g {
    CGPoint t = [g translationInView:self.superview];
    self.center = CGPointMake(self.center.x + t.x, self.center.y + t.y);
    [g setTranslation:CGPointZero inView:self.superview];
}
- (void)togglePanel {
    MMPanel *p = self.panel;
    if (p.hidden) {
        p.alpha = 0;
        p.hidden = NO;
        [UIView animateWithDuration:0.18 animations:^{ p.alpha = 1; }];
    } else {
        [UIView animateWithDuration:0.15 animations:^{ p.alpha = 0; }
                         completion:^(BOOL f) { p.hidden = YES; }];
    }
}
@end

// ---------------------------------------------------------------------------
// API pública
// ---------------------------------------------------------------------------
namespace MyMenu {

static void Push(Item it) { Items().push_back(std::move(it)); }

void AddSection(Tab tab, const std::string &k) {
    Item it; it.kind = Kind::Section; it.tab = tab; it.key = k; Push(std::move(it));
}

void AddToggle(Tab tab, const std::string &k, std::function<void(bool)> cb) {
    Item it; it.kind = Kind::Toggle; it.tab = tab; it.key = k; it.onToggle = std::move(cb);
    Push(std::move(it));
}

void AddSlider(Tab tab, const std::string &k, float mn, float mx, float def,
               std::function<void(float)> cb) {
    Item it; it.kind = Kind::Slider; it.tab = tab; it.key = k;
    it.mn = mn; it.mx = mx; it.def = def; it.onSlider = std::move(cb);
    Push(std::move(it));
}

void AddChoice(Tab tab, const std::string &k, std::vector<std::string> opts, int def,
               std::function<void(int)> cb) {
    Item it; it.kind = Kind::Choice; it.tab = tab; it.key = k;
    it.options = std::move(opts); it.defIdx = def; it.onChoice = std::move(cb);
    Push(std::move(it));
}

void AddButton(Tab tab, const std::string &k, std::function<void()> cb) {
    Item it; it.kind = Kind::Button; it.tab = tab; it.key = k; it.onTap = std::move(cb);
    Push(std::move(it));
}

void SetAccount(const AccountInfo &info) { gAccount = info; }

// Aviso de Telegram: solo la primera vez que se abre el juego.
static void MaybePromptTelegram(UIWindow *win) {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if ([ud boolForKey:@"MyMenu.tgShown"]) return;
    [ud setBool:YES forKey:@"MyMenu.tgShown"];

    UIAlertController *ac = [UIAlertController alertControllerWithTitle:Loc::T("tg.title")
                                                                message:Loc::T("tg.msg")
                                                         preferredStyle:UIAlertControllerStyleAlert];
    [ac addAction:[UIAlertAction actionWithTitle:Loc::T("tg.later")
                                           style:UIAlertActionStyleCancel handler:nil]];
    [ac addAction:[UIAlertAction actionWithTitle:Loc::T("tg.open")
                                           style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *a) { OpenURL(kGroupURL); }]];
    [TopVC(win) presentViewController:ac animated:YES completion:nil];
}

static void Attach(int attempt) {
    UIWindow *win = FindKeyWindow();
    if (!win) {
        if (attempt < 30)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{ Attach(attempt + 1); });
        return;
    }

    LoadTheme();

    // Restaurar el estado guardado en las funciones
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    for (auto &it : Items()) {
        NSString *key = KeyFor(it);
        if (it.kind == Kind::Toggle && it.onToggle && [ud boolForKey:key])
            it.onToggle(true);
        else if (it.kind == Kind::Slider && it.onSlider && [ud objectForKey:key])
            it.onSlider([ud floatForKey:key]);
        else if (it.kind == Kind::Choice && it.onChoice && [ud objectForKey:key])
            it.onChoice((int)[ud integerForKey:key]);
    }

    CGFloat pw = MIN(440.0, win.bounds.size.width - 24);
    CGFloat ph = MIN(300.0, win.bounds.size.height - 24);
    MMPanel *panel = [[MMPanel alloc] initWithFrame:CGRectMake(0, 0, pw, ph)];
    panel.center = CGPointMake(win.bounds.size.width / 2, win.bounds.size.height / 2);
    panel.hidden = YES;
    [win addSubview:panel];

    MMFloat *fab = [MMFloat buttonWithType:UIButtonTypeCustom];
    fab.frame = CGRectMake(14, 70, 46, 46);
    fab.clipsToBounds = YES;
    fab.layer.cornerRadius = 23;
    fab.layer.borderWidth = 0.8;
    fab.layer.borderColor = W(0.28).CGColor;
    UIVisualEffectView *fb = [[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    fb.frame = fab.bounds;
    fb.userInteractionEnabled = NO;
    [fab insertSubview:fb atIndex:0];
    [fab setImage:Sym(@"square.grid.2x2.fill", 17, UIImageSymbolWeightSemibold) forState:UIControlStateNormal];
    fab.tintColor = UIColor.whiteColor;
    fab.panel = panel;
    [fab addTarget:fab action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [fab addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:fab action:@selector(dragButton:)]];
    [win addSubview:fab];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{ MaybePromptTelegram(win); });
}

void Show() {
    dispatch_async(dispatch_get_main_queue(), ^{ Attach(0); });
}

} // namespace MyMenu

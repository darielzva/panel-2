// _0xMO353DA.mm — Nuevo diseño monocromático (igual a las imágenes de referencia)
// Sin colores de acento — solo Light / Dark
// Mismo _0xDEADBEEE, mismas claves ESP, misma API _0xF010
// Escalado global: slider "Menu Size" escala TODO el panel uniformemente
// ─────────────────────────────────────────────────────────────────────────────
#import <UIKit/UIKit.h>
#import "ModMenuViewController.h"
#import "MizzeTheme.h"
#import "MizzeMenuPrefs.h"
#include <cmath>
#import <objc/runtime.h>
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPStyle.h"
#import "../esp/Core/PlayerModes.h"
#import "../esp/Core/AimModePolicy.h"
#import "UIView+SecureView.h"

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — SF Symbol helper
// ─────────────────────────────────────────────────────────────────────────────
static UIImage *MZSym(NSString *name, CGFloat pts, UIImageSymbolWeight w) {
    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:pts weight:w];
    return [[UIImage systemImageNamed:name withConfiguration:cfg]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Dimensiones BASE (a escala 1×)
// ─────────────────────────────────────────────────────────────────────────────
static const CGFloat kBasePanelW  = 310.0;
static const CGFloat kBasePanelH  = 420.0;
static const CGFloat kBaseSidebarW= 64.0;
static const CGFloat kBaseHeaderH = 56.0;
static const CGFloat kBaseRowH    = 56.0;
static const CGFloat kBaseRowStep = 62.0;
static const CGFloat kBaseSliderH = 68.0;
static const CGFloat kBaseSliderSt= 74.0;
static const CGFloat kBaseSectionH= 28.0;
static const CGFloat kBasePad     = 12.0;
static const CGFloat kBaseRadPanel= 26.0;
static const CGFloat kBaseRadRow  = 20.0;
static const CGFloat kBaseRadSb   = 22.0;
static const CGFloat kBaseSbD     = 46.0;
static const CGFloat kBaseSbGap   = 10.0;

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Escala global (Menu Size)
// guardada en DAAE.menuScale  rango 0.70–1.30
// ─────────────────────────────────────────────────────────────────────────────
static CGFloat MZMenuScale(void) {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if (![ud objectForKey:@"DAAE.menuScale"]) return 1.0;
    double v = [ud doubleForKey:@"DAAE.menuScale"];
    if (v < 0.70 || v > 1.30) return 1.0;
    return (CGFloat)v;
}
static void MZSetMenuScale(CGFloat s) {
    [[NSUserDefaults standardUserDefaults]
        setDouble:(double)MAX(0.70, MIN(1.30, s)) forKey:@"DAAE.menuScale"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
// Shortcut: escala un valor base
static inline CGFloat SC(CGFloat base) { return base * MZMenuScale(); }

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Idioma
// ─────────────────────────────────────────────────────────────────────────────
static NSInteger DAAELang(void) {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if (![ud objectForKey:@"DAAE.lang"]) return 0;
    NSInteger v = [ud integerForKey:@"DAAE.lang"];
    return (v >= 0 && v <= 2) ? v : 0;
}
static void DAAESetLang(NSInteger l) {
    [[NSUserDefaults standardUserDefaults] setInteger:l forKey:@"DAAE.lang"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
static NSString *DStr(NSString *en, NSString *es, NSString *vi) {
    switch (DAAELang()) { case 1: return es; case 2: return vi; default: return en; }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Tema: Dark / Light
// ─────────────────────────────────────────────────────────────────────────────
static BOOL MZDark(void) {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if (![ud objectForKey:@"DAAE.darkMode"]) return YES;
    return [ud boolForKey:@"DAAE.darkMode"];
}
static void MZSetDark(BOOL d) {
    [[NSUserDefaults standardUserDefaults] setBool:d forKey:@"DAAE.darkMode"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Paleta monocromática (sin ningún color de acento)
// ─────────────────────────────────────────────────────────────────────────────
static UIColor *MZPanelBG(void) {
    return MZDark()
        ? [UIColor colorWithWhite:0.12 alpha:0.88]
        : [UIColor colorWithWhite:0.97 alpha:0.90];
}
static UIColor *MZCtrlBG(void) {
    return MZDark()
        ? [UIColor colorWithWhite:1 alpha:0.08]
        : [UIColor colorWithWhite:0 alpha:0.05];
}
static UIColor *MZCtrlBGOn(void) {
    return MZDark()
        ? [UIColor colorWithWhite:1 alpha:0.14]
        : [UIColor colorWithWhite:0 alpha:0.09];
}
static UIColor *MZSidebarBG(void) {
    return MZDark()
        ? [UIColor colorWithWhite:0 alpha:0.08]
        : [UIColor colorWithWhite:0 alpha:0.04];
}
static UIColor *MZSbBtnBG(void)   { // botón sidebar inactivo
    return MZDark()
        ? [UIColor colorWithWhite:1 alpha:0.08]
        : [UIColor colorWithWhite:0 alpha:0.06];
}
static UIColor *MZSbBtnSel(void)  { // botón sidebar activo
    return MZDark()
        ? [UIColor colorWithWhite:1 alpha:0.18]
        : [UIColor colorWithWhite:0 alpha:0.14];
}
static UIColor *MZTxtMain(void) {
    return MZDark() ? [UIColor colorWithWhite:0.95 alpha:1] : [UIColor colorWithWhite:0.08 alpha:1];
}
static UIColor *MZTxtDim(void) {
    return MZDark() ? [UIColor colorWithWhite:1 alpha:0.45] : [UIColor colorWithWhite:0 alpha:0.42];
}
static UIColor *MZSep(void) {
    return MZDark() ? [UIColor colorWithWhite:1 alpha:0.09] : [UIColor colorWithWhite:0 alpha:0.09];
}
static UIColor *MZSwTrack(void) {   // switch apagado
    return MZDark() ? [UIColor colorWithWhite:1 alpha:0.18] : [UIColor colorWithWhite:0 alpha:0.14];
}
static UIColor *MZSwOn(void) {      // switch encendido
    return MZDark() ? [UIColor colorWithWhite:0.80 alpha:1] : [UIColor colorWithWhite:0.25 alpha:1];
}
static UIColor *MZSlTrack(void) {   // slider pista activa
    return MZDark() ? [UIColor colorWithWhite:0.75 alpha:1] : [UIColor colorWithWhite:0.30 alpha:1];
}
static UIColor *MZSlInactive(void) {// slider pista inactiva
    return MZDark() ? [UIColor colorWithWhite:1 alpha:0.16] : [UIColor colorWithWhite:0 alpha:0.12];
}
static UIColor *MZSlThumb(void) {
    return MZDark() ? [UIColor colorWithWhite:0.95 alpha:1] : [UIColor colorWithWhite:0.12 alpha:1];
}
static UIColor *MZCapBG(void) {     // cápsula valor slider
    return MZDark() ? [UIColor colorWithWhite:1 alpha:0.14] : [UIColor colorWithWhite:0 alpha:0.09];
}
static UIColor *MZIcoMain(void) {
    return MZDark() ? [UIColor colorWithWhite:0.92 alpha:1] : [UIColor colorWithWhite:0.14 alpha:1];
}
static UIColor *MZIcoDim(void) {
    return MZDark() ? [UIColor colorWithWhite:1 alpha:0.45] : [UIColor colorWithWhite:0 alpha:0.40];
}
static UIColor *MZBorder(void) {
    return MZDark() ? [UIColor colorWithWhite:1 alpha:0.12] : [UIColor colorWithWhite:0 alpha:0.09];
}
static UIBlurEffectStyle MZBlur(void) {
    return MZDark() ? UIBlurEffectStyleSystemUltraThinMaterialDark
                    : UIBlurEffectStyleSystemUltraThinMaterialLight;
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Tabs
// ─────────────────────────────────────────────────────────────────────────────
static NSArray<NSString *> *MZTabIcons(void) {
    return @[@"eye.fill",@"scope",@"paintpalette.fill",@"shippingbox.fill",@"gearshape.fill"];
}
static NSString *MZTabName(NSInteger i) {
    NSArray *en = @[@"ESP",@"AIM",@"CUSTOM",@"MISC",@"SETTINGS"];
    NSArray *es = @[@"ESP",@"APUNT",@"ESTILO",@"EXTRA",@"CONFIG"];
    NSArray *vi = @[@"ESP",@"AIM",@"GIAO",@"KHÁC",@"CÀI"];
    switch (DAAELang()) { case 1: return es[(NSUInteger)i]; case 2: return vi[(NSUInteger)i]; default: return en[(NSUInteger)i]; }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — AIM helpers
// ─────────────────────────────────────────────────────────────────────────────
static float AimRaw(void)    { return ESPPrefsFloat(@"AimType", -1); }
static BOOL  AimActive(void) { return AimRaw() >= 0; }

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — MZSwitch — interruptor cápsula monocromático
// ─────────────────────────────────────────────────────────────────────────────
@interface MZSwitch : UIControl
@property (nonatomic, assign) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)anim;
- (void)refreshTheme;
@end
@implementation MZSwitch { UIView *_track; UIView *_thumb; }
- (instancetype)initWithFrame:(CGRect)f {
    if ((self=[super initWithFrame:f])) {
        _track = [[UIView alloc] initWithFrame:self.bounds];
        _track.layer.cornerRadius = f.size.height / 2.0;
        _track.userInteractionEnabled = NO;
        [self addSubview:_track];
        CGFloat d = f.size.height - 6;
        _thumb = [[UIView alloc] initWithFrame:CGRectMake(3,3,d,d)];
        _thumb.layer.cornerRadius = d/2.0;
        _thumb.backgroundColor = UIColor.whiteColor;
        _thumb.userInteractionEnabled = NO;
        _thumb.layer.shadowColor   = UIColor.blackColor.CGColor;
        _thumb.layer.shadowOffset  = CGSizeMake(0,1);
        _thumb.layer.shadowRadius  = 2;
        _thumb.layer.shadowOpacity = 0.22;
        [self addSubview:_thumb];
        [self setOn:NO animated:NO];
        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }
- (void)setOn:(BOOL)on animated:(BOOL)anim {
    _on = on;
    CGFloat w = self.bounds.size.width, d = self.bounds.size.height-6;
    CGFloat xOn=w-d-3, xOff=3;
    UIColor *trackClr = on ? MZSwOn() : MZSwTrack();
    void (^upd)(void) = ^{
        self->_track.backgroundColor = trackClr;
        CGRect tf = self->_thumb.frame; tf.origin.x = on?xOn:xOff; self->_thumb.frame=tf;
    };
    if (anim) [UIView animateWithDuration:0.22 delay:0
        usingSpringWithDamping:0.75 initialSpringVelocity:0.6
        options:UIViewAnimationOptionCurveEaseInOut animations:upd completion:nil];
    else upd();
}
- (void)_tap { [self setOn:!_on animated:YES]; [self sendActionsForControlEvents:UIControlEventValueChanged]; }
- (void)refreshTheme { [self setOn:_on animated:NO]; }
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — MZRow — fila con switch
// ─────────────────────────────────────────────────────────────────────────────
@interface MZRow : UIView
@property (nonatomic, strong) MZSwitch *sw;
@property (nonatomic, copy)   void (^onChanged)(BOOL);
- (instancetype)initWithLabel:(NSString *)txt on:(BOOL)on width:(CGFloat)w;
- (void)refreshTheme;
@end
@implementation MZRow { UILabel *_lbl; }
- (instancetype)initWithLabel:(NSString *)txt on:(BOOL)on width:(CGFloat)w {
    CGFloat h = SC(kBaseRowH);
    if ((self=[super initWithFrame:CGRectMake(0,0,w,h)])) {
        self.backgroundColor    = on ? MZCtrlBGOn() : MZCtrlBG();
        self.layer.cornerRadius = SC(kBaseRadRow);
        self.clipsToBounds      = YES;
        _lbl = [[UILabel alloc] init];
        _lbl.text      = txt;
        _lbl.textColor = MZTxtMain();
        _lbl.font      = [UIFont systemFontOfSize:SC(15) weight:UIFontWeightMedium];
        _lbl.adjustsFontSizeToFitWidth = YES;
        _lbl.minimumScaleFactor = 0.7;
        [self addSubview:_lbl];
        CGFloat swW=SC(50), swH=SC(30);
        self.sw = [[MZSwitch alloc] initWithFrame:CGRectMake(0,0,swW,swH)];
        [self.sw setOn:on animated:NO];
        [self.sw addTarget:self action:@selector(_changed) forControlEvents:UIControlEventValueChanged];
        [self addSubview:self.sw];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_rowTap)];
        [self addGestureRecognizer:tap];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w=self.bounds.size.width, h=self.bounds.size.height, pad=SC(kBasePad);
    CGFloat swW=self.sw.bounds.size.width, swH=self.sw.bounds.size.height;
    _lbl.frame  = CGRectMake(pad*1.5, 0, w-swW-pad*3, h);
    self.sw.frame = CGRectMake(w-swW-pad, (h-swH)/2.0, swW, swH);
}
- (void)_rowTap { [self.sw _tap]; }
- (void)_changed {
    self.backgroundColor = self.sw.on ? MZCtrlBGOn() : MZCtrlBG();
    if (self.onChanged) self.onChanged(self.sw.on);
}
- (void)refreshTheme {
    self.backgroundColor    = self.sw.on ? MZCtrlBGOn() : MZCtrlBG();
    self.layer.cornerRadius = SC(kBaseRadRow);
    _lbl.textColor = MZTxtMain();
    _lbl.font = [UIFont systemFontOfSize:SC(15) weight:UIFontWeightMedium];
    [self.sw refreshTheme];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — MZSliderRow — slider con cápsula de valor
// ─────────────────────────────────────────────────────────────────────────────
@interface MZSliderRow : UIView
- (instancetype)initWithLabel:(NSString *)txt key:(NSString *)key
                          min:(float)mn max:(float)mx fallback:(float)fb width:(CGFloat)w;
- (void)refreshTheme;
@end
@implementation MZSliderRow { UILabel *_lbl; UILabel *_capLbl; UIView *_cap; UISlider *_sl; BOOL _isFloat; }
- (instancetype)initWithLabel:(NSString *)txt key:(NSString *)key
                          min:(float)mn max:(float)mx fallback:(float)fb width:(CGFloat)w {
    _isFloat = ((mx-mn) <= 3.5f);
    CGFloat h = SC(kBaseSliderH);
    if ((self=[super initWithFrame:CGRectMake(0,0,w,h)])) {
        self.backgroundColor    = MZCtrlBG();
        self.layer.cornerRadius = SC(kBaseRadRow);
        self.clipsToBounds      = YES;
        _lbl = [[UILabel alloc] init];
        _lbl.text      = txt;
        _lbl.textColor = MZTxtMain();
        _lbl.font      = [UIFont systemFontOfSize:SC(15) weight:UIFontWeightMedium];
        [self addSubview:_lbl];
        // Cápsula valor — igual a las imágenes: fondo gris, texto principal
        _cap = [[UIView alloc] init];
        _cap.backgroundColor = MZCapBG();
        [self addSubview:_cap];
        _capLbl = [[UILabel alloc] init];
        _capLbl.textAlignment = NSTextAlignmentCenter;
        _capLbl.textColor = MZTxtMain();
        _capLbl.font = [UIFont systemFontOfSize:SC(13) weight:UIFontWeightSemibold];
        float cur = ESPPrefsFloat(key, fb);
        _capLbl.text = _isFloat ? [NSString stringWithFormat:@"%.1f",cur]
                                : [NSString stringWithFormat:@"%.0f",cur];
        [_cap addSubview:_capLbl];
        _sl = [[UISlider alloc] init];
        _sl.minimumValue = mn; _sl.maximumValue = mx; _sl.value = cur;
        _sl.minimumTrackTintColor = MZSlTrack();
        _sl.maximumTrackTintColor = MZSlInactive();
        _sl.thumbTintColor = MZSlThumb();
        objc_setAssociatedObject(_sl,"capLbl",_capLbl,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(_sl,"espKey", key,   OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(_sl,"isFlt",@(_isFloat),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [_sl addTarget:self action:@selector(_slid:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:_sl];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w=self.bounds.size.width, h=self.bounds.size.height, pad=SC(kBasePad);
    CGFloat capW=SC(56), capH=SC(24);
    _lbl.frame  = CGRectMake(pad*1.5, SC(6), w-capW-pad*3.5, SC(22));
    _cap.frame  = CGRectMake(w-capW-pad, SC(6), capW, capH);
    _cap.layer.cornerRadius = capH/2.0;
    _capLbl.frame = _cap.bounds;
    _sl.frame = CGRectMake(pad, h-SC(26), w-pad*2, SC(20));
}
- (void)_slid:(UISlider *)sl {
    UILabel  *c   = objc_getAssociatedObject(sl,"capLbl");
    NSString *key = objc_getAssociatedObject(sl,"espKey");
    BOOL isF      = [objc_getAssociatedObject(sl,"isFlt") boolValue];
    c.text = isF ? [NSString stringWithFormat:@"%.1f",sl.value]
                 : [NSString stringWithFormat:@"%.0f",sl.value];
    ESPPrefsSetFloat(key,sl.value); ESPSyncFromPrefs();
}
- (void)refreshTheme {
    self.backgroundColor    = MZCtrlBG();
    self.layer.cornerRadius = SC(kBaseRadRow);
    _lbl.textColor = MZTxtMain();
    _cap.backgroundColor = MZCapBG();
    _capLbl.textColor = MZTxtMain();
    _sl.minimumTrackTintColor = MZSlTrack();
    _sl.maximumTrackTintColor = MZSlInactive();
    _sl.thumbTintColor = MZSlThumb();
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — MZPillPicker — pills monocromáticos
// ─────────────────────────────────────────────────────────────────────────────
@interface MZPillPicker : UIView
@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, copy)   void (^onSelected)(NSInteger);
- (instancetype)initWithOptions:(NSArray<NSString *> *)opts selected:(NSInteger)sel width:(CGFloat)w;
- (void)refreshTheme;
@end
@implementation MZPillPicker { NSArray<UIButton *> *_pills; }
- (instancetype)initWithOptions:(NSArray<NSString *> *)opts selected:(NSInteger)sel width:(CGFloat)w {
    NSInteger n=(NSInteger)opts.count;
    CGFloat h=SC(44);
    if ((self=[super initWithFrame:CGRectMake(0,0,w,h)])) {
        _selectedIndex=sel;
        self.backgroundColor    = MZCtrlBG();
        self.layer.cornerRadius = SC(kBaseRadRow);
        self.clipsToBounds      = YES;
        CGFloat pad=SC(6),gap=SC(5);
        CGFloat bw=(w-pad*2-gap*(n-1))/(CGFloat)n;
        NSMutableArray *pills=[NSMutableArray array];
        for (NSInteger i=0;i<n;i++) {
            UIButton *b=[UIButton buttonWithType:UIButtonTypeCustom];
            b.frame=CGRectMake(pad+i*(bw+gap),SC(5),bw,h-SC(10));
            b.layer.cornerRadius=SC(14);
            b.clipsToBounds=YES;
            b.titleLabel.font=[UIFont systemFontOfSize:SC(13) weight:UIFontWeightSemibold];
            b.titleLabel.adjustsFontSizeToFitWidth=YES;
            [b setTitle:opts[(NSUInteger)i] forState:UIControlStateNormal];
            b.tag=700+i;
            [b addTarget:self action:@selector(_pillTap:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:b];
            [pills addObject:b];
        }
        _pills=pills;
        [self _refresh];
    }
    return self;
}
- (void)_refresh {
    for (NSInteger i=0;i<(NSInteger)_pills.count;i++) {
        UIButton *b=_pills[(NSUInteger)i];
        BOOL sel=(i==_selectedIndex);
        b.backgroundColor = sel ? MZSbBtnSel() : UIColor.clearColor;
        [b setTitleColor:sel?MZTxtMain():MZTxtDim() forState:UIControlStateNormal];
    }
}
- (void)_pillTap:(UIButton *)s {
    NSInteger idx=s.tag-700;
    if (idx==_selectedIndex) return;
    _selectedIndex=idx;
    [UIView animateWithDuration:0.14 animations:^{ [self _refresh]; }];
    if (self.onSelected) self.onSelected(idx);
}
- (void)refreshTheme {
    self.backgroundColor=MZCtrlBG();
    self.layer.cornerRadius=SC(kBaseRadRow);
    [self _refresh];
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — DropRow — selector con valor + chevron (sin acento)
// ─────────────────────────────────────────────────────────────────────────────
@interface MZDropRow : UIControl
@property (nonatomic, copy) void (^onTap)(void);
@property (nonatomic, weak) UILabel *valueLbl;
- (instancetype)initWithLabel:(NSString *)lbl value:(NSString *)val width:(CGFloat)w;
- (void)refreshTheme;
@end
@implementation MZDropRow { UILabel *_lbl; UILabel *_val; UIImageView *_arrow; }
- (instancetype)initWithLabel:(NSString *)lbl value:(NSString *)val width:(CGFloat)w {
    CGFloat h=SC(kBaseRowH);
    if ((self=[super initWithFrame:CGRectMake(0,0,w,h)])) {
        self.backgroundColor=MZCtrlBG(); self.layer.cornerRadius=SC(kBaseRadRow); self.clipsToBounds=YES;
        _lbl=[[UILabel alloc] init]; _lbl.text=lbl; _lbl.textColor=MZTxtMain();
        _lbl.font=[UIFont systemFontOfSize:SC(15) weight:UIFontWeightMedium];
        [self addSubview:_lbl];
        _val=[[UILabel alloc] init]; _val.text=val; _val.textColor=MZTxtDim();
        _val.font=[UIFont systemFontOfSize:SC(14) weight:UIFontWeightRegular];
        _val.textAlignment=NSTextAlignmentRight;
        [self addSubview:_val]; self.valueLbl=_val;
        _arrow=[[UIImageView alloc] initWithImage:MZSym(@"chevron.down",SC(11),UIImageSymbolWeightMedium)];
        _arrow.tintColor=MZIcoDim(); [self addSubview:_arrow];
        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w=self.bounds.size.width, h=self.bounds.size.height, pad=SC(kBasePad);
    CGFloat arW=SC(14);
    _lbl.frame  = CGRectMake(pad*1.5, 0, w*0.42, h);
    _val.frame  = CGRectMake(w*0.44, 0, w-w*0.44-arW-pad*2, h);
    _arrow.frame = CGRectMake(w-arW-pad, (h-arW*0.7)/2.0, arW, arW*0.7);
}
- (void)_tap { if (self.onTap) self.onTap(); }
- (void)refreshTheme {
    self.backgroundColor=MZCtrlBG(); self.layer.cornerRadius=SC(kBaseRadRow);
    _lbl.textColor=MZTxtMain(); _val.textColor=MZTxtDim(); _arrow.tintColor=MZIcoDim();
}
@end

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Warning label helper
// ─────────────────────────────────────────────────────────────────────────────
static CGFloat MZAddWarn(NSString *text, NSArray<NSString*> *hl,
                          UIScrollView *sv, CGFloat w, CGFloat y) {
    UIView *box=[[UIView alloc] init];
    box.backgroundColor=MZDark()
        ?[UIColor colorWithWhite:1 alpha:0.06]:[UIColor colorWithWhite:0 alpha:0.04];
    box.layer.cornerRadius=SC(kBaseRadRow);
    UIFont *font=[UIFont systemFontOfSize:SC(12.5) weight:UIFontWeightMedium];
    NSMutableAttributedString *as=[[NSMutableAttributedString alloc]
        initWithString:text attributes:@{NSFontAttributeName:font,
                                         NSForegroundColorAttributeName:MZTxtDim()}];
    for (NSString *h in hl) {
        NSRange r=[text rangeOfString:h];
        if (r.location!=NSNotFound)
            [as addAttribute:NSForegroundColorAttributeName value:MZTxtMain() range:r];
    }
    UILabel *l=[[UILabel alloc] init];
    l.attributedText=as; l.numberOfLines=0;
    CGSize sz=[l sizeThatFits:CGSizeMake(w-SC(28),999)];
    l.frame=CGRectMake(SC(14),SC(10),w-SC(28),sz.height);
    box.frame=CGRectMake(0,y,w,sz.height+SC(20));
    [box addSubview:l]; [sv addSubview:box];
    return y+sz.height+SC(28);
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — _0xDEADBEEE — panel principal
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
@end

@implementation _0xDEADBEEE

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Defaults
// ─────────────────────────────────────────────────────────────────────────────
- (void)applyDefaults {
    NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
    if (![ud boolForKey:@"_MZThemeV1"]) {
        [ud setBool:YES   forKey:@"DAAE.darkMode"];
        [ud setDouble:1.0 forKey:@"DAAE.menuScale"];
        [ud setBool:YES   forKey:@"_MZThemeV1"];
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
    ESPPrefsSetBool(@"ShowFov",YES);
    ESPPrefsSetFloat(@"AimType",-1); ESPPrefsSetFloat(@"AimActivation",1);
    ESPPrefsSetFloat(@"FovSize",40); ESPPrefsSetFloat(@"SilentFovSize",18);
    ESPPrefsSetFloat(@"RunSpeedValue",6); ESPPrefsSetFloat(@"FlyHeight",4);
    ESPPrefsSetFloat(@"VisualSpinSpeed",0.5);
    ESPPrefsSetBool(@"ExplicitAimMenuV1",YES);
    [ud setBool:YES forKey:@"_MizzeDefaultsApplied"]; [ud synchronize];
    ESPSyncFromPrefs();
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — viewDidLoad
// ─────────────────────────────────────────────────────────────────────────────
- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyDefaults];
    MizzePrepareMenuPrefs();
    self.pointer=-1; self.colorTarget=0; self.page=0;
    self.controls=[NSMutableArray array];
    self.view.backgroundColor=UIColor.clearColor;

    __weak _0xDEADBEEE *ws=self;
    self.spinStatusTimer=[NSTimer scheduledTimerWithTimeInterval:0.5 repeats:YES
        block:^(NSTimer *_){ [ws updateSpinStatus]; }];

    self.blurBG=[[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:MZBlur()]];
    self.blurBG.layer.cornerRadius=SC(kBaseRadPanel);
    self.blurBG.clipsToBounds=YES;
    [self.view addSubview:self.blurBG];

    self.panel=[[UIView alloc] initWithFrame:CGRectZero];
    self.panel.backgroundColor=MZPanelBG();
    self.panel.layer.cornerRadius=SC(kBaseRadPanel);
    self.panel.layer.borderWidth=0.5;
    self.panel.layer.borderColor=MZBorder().CGColor;
    self.panel.clipsToBounds=YES;
    [self.view addSubview:self.panel];

    self.sidebar=[[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.backgroundColor=MZSidebarBG();
    [self.panel addSubview:self.sidebar];

    UIView *div=[[UIView alloc] initWithFrame:CGRectZero];
    div.tag=99; div.backgroundColor=MZSep();
    [self.panel addSubview:div];

    self.contentArea=[[UIView alloc] initWithFrame:CGRectZero];
    self.contentArea.backgroundColor=UIColor.clearColor;
    [self.panel addSubview:self.contentArea];

    self.scroll=[[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator=NO;
    self.scroll.bounces=YES; self.scroll.clipsToBounds=YES;
    [self.contentArea addSubview:self.scroll];

    for (UIView *t in @[self.sidebar,self.contentArea]) {
        UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]
            initWithTarget:self action:@selector(dragPanel:)];
        pan.delegate=self; [t addGestureRecognizer:pan];
    }
    [self buildSidebar];
    [self buildPage];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    NSUserDefaults *ud=NSUserDefaults.standardUserDefaults;
    if (![ud boolForKey:@"DAAE.tgOpened"]) {
        [ud setBool:YES forKey:@"DAAE.tgOpened"]; [ud synchronize];
        NSURL *u=[NSURL URLWithString:@"https://t.me/didierxit7"];
        if (u) dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(0.8*NSEC_PER_SEC)),
            dispatch_get_main_queue(),^{[UIApplication.sharedApplication openURL:u options:@{} completionHandler:nil];});
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Layout (usa SC() en cada medida para aplicar escala)
// ─────────────────────────────────────────────────────────────────────────────
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sw=self.view.bounds.size.width, sh=self.view.bounds.size.height;
    if (sw<=0) sw=375; if (sh<=0) sh=667;

    CGFloat pw=MIN(SC(kBasePanelW), sw-16.0);
    CGFloat ph=MIN(SC(kBasePanelH), sh-16.0);
    pw=MAX(pw,220); ph=MAX(ph,240);

    CGRect f=self.panel.frame;
    if (f.size.width<1)
        f=CGRectMake(floorf((sw-pw)/2.0), floorf((sh-ph)/2.0), pw, ph);
    else {
        f.size=CGSizeMake(pw,ph);
        f.origin.x=MAX(4,MIN(f.origin.x,sw-pw-4));
        f.origin.y=MAX(4,MIN(f.origin.y,sh-ph-4));
    }
    self.panel.frame=f; self.blurBG.frame=f;
    self.panel.layer.cornerRadius=SC(kBaseRadPanel);
    self.blurBG.layer.cornerRadius=SC(kBaseRadPanel);

    CGFloat sbW=SC(kBaseSidebarW);
    self.sidebar.frame=CGRectMake(0,0,sbW,ph);
    UIView *div=[self.panel viewWithTag:99];
    div.frame=CGRectMake(sbW,SC(10),0.5,ph-SC(20));

    CGFloat caW=pw-sbW-0.5;
    self.contentArea.frame=CGRectMake(sbW+0.5,0,caW,ph);
    CGFloat hdrH=SC(kBaseHeaderH), padH=SC(kBasePad);
    self.scroll.frame=CGRectMake(padH,hdrH,caW-padH*2,ph-hdrH-SC(8));

    [self layoutSidebarButtons];
    if (fabs(self.builtWidth-self.scroll.bounds.size.width)>1.0) [self buildPage];
    [self refreshSidebarSelection];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Sidebar
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildSidebar {
    for (UIView *v in self.sidebar.subviews) [v removeFromSuperview];
    for (NSInteger i=0;i<5;i++) {
        UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag=300+i;
        btn.layer.cornerRadius=SC(kBaseRadSb);
        btn.clipsToBounds=YES;
        [btn setImage:MZSym(MZTabIcons()[(NSUInteger)i],SC(18),UIImageSymbolWeightMedium)
             forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(sidebarTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
    }
    [self layoutSidebarButtons];
    [self refreshSidebarSelection];
}
- (void)layoutSidebarButtons {
    CGFloat d=SC(kBaseSbD), gap=SC(kBaseSbGap);
    CGFloat sbH=MAX(self.sidebar.bounds.size.height,200);
    CGFloat sbW=self.sidebar.bounds.size.width;
    CGFloat startY=MAX(SC(8),(sbH-(5*d+4*gap))/2.0);
    for (NSInteger i=0;i<5;i++) {
        UIButton *btn=(UIButton *)[self.sidebar viewWithTag:300+i];
        if (!btn) continue;
        btn.frame=CGRectMake((sbW-d)/2.0, startY+i*(d+gap), d, d);
        btn.layer.cornerRadius=d/2.0;
    }
}
- (void)refreshSidebarSelection {
    for (NSInteger i=0;i<5;i++) {
        UIButton *btn=(UIButton *)[self.sidebar viewWithTag:300+i];
        if (!btn) continue;
        BOOL sel=(i==self.page);
        btn.backgroundColor = sel ? MZSbBtnSel() : MZSbBtnBG();
        btn.tintColor       = sel ? MZIcoMain()  : MZIcoDim();
        btn.layer.borderWidth = sel ? 0.5 : 0;
        btn.layer.borderColor = MZBorder().CGColor;
    }
}
- (void)sidebarTap:(UIButton *)sender {
    NSInteger pg=sender.tag-300;
    if (pg==self.page) return;
    self.page=pg;
    self.scroll.contentOffset=CGPointZero;
    [self refreshSidebarSelection];
    [self rebuildAnimated];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Header — título grande + botones circulares luna/X
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildHeader {
    for (UIView *v in self.contentArea.subviews)
        if (v.tag>=500&&v.tag<600) [v removeFromSuperview];
    CGFloat cw=MAX(self.contentArea.bounds.size.width,200);
    CGFloat hdrH=SC(kBaseHeaderH);
    CGFloat btnD=SC(32), pad=SC(10), gap=SC(6);

    // Título tab — grande y sin fondo de píldora
    UILabel *title=[[UILabel alloc] initWithFrame:
        CGRectMake(pad+SC(22), 0, cw-pad-SC(22)-(btnD+gap)*2-pad, hdrH)];
    title.tag=502; title.text=MZTabName(self.page);
    title.textColor=MZTxtMain();
    title.font=[UIFont systemFontOfSize:SC(17) weight:UIFontWeightBold];
    title.adjustsFontSizeToFitWidth=YES; title.minimumScaleFactor=0.75;
    [self.contentArea addSubview:title];

    // Icono a la izquierda del título
    UIImageView *iv=[[UIImageView alloc]
        initWithImage:MZSym(MZTabIcons()[(NSUInteger)self.page],SC(14),UIImageSymbolWeightSemibold)];
    iv.tag=501; iv.tintColor=MZTxtMain();
    iv.contentMode=UIViewContentModeScaleAspectFit;
    iv.frame=CGRectMake(pad,SC(2)+(hdrH-SC(16))/2.0,SC(16),SC(16));
    [self.contentArea addSubview:iv];

    // Botón luna/sol
    UIButton *darkBtn=[UIButton buttonWithType:UIButtonTypeSystem];
    darkBtn.tag=505;
    darkBtn.frame=CGRectMake(cw-pad-(btnD+gap)*2, (hdrH-btnD)/2.0, btnD, btnD);
    darkBtn.backgroundColor=MZCtrlBG();
    darkBtn.layer.cornerRadius=btnD/2.0; darkBtn.clipsToBounds=YES;
    NSString *dIco=MZDark()?@"sun.max.fill":@"moon.fill";
    [darkBtn setImage:MZSym(dIco,SC(13),UIImageSymbolWeightSemibold) forState:UIControlStateNormal];
    darkBtn.tintColor=MZIcoMain();
    [darkBtn addTarget:self action:@selector(darkModeToggleTap) forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:darkBtn];

    // Botón cerrar
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem];
    close.tag=503; close.frame=CGRectMake(cw-pad-btnD,(hdrH-btnD)/2.0,btnD,btnD);
    close.backgroundColor=MZCtrlBG();
    close.layer.cornerRadius=btnD/2.0; close.clipsToBounds=YES;
    [close setImage:MZSym(@"xmark",SC(12),UIImageSymbolWeightBold) forState:UIControlStateNormal];
    close.tintColor=MZIcoDim();
    [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:close];

    // Separador
    UIView *sep=[[UIView alloc] initWithFrame:CGRectMake(0,hdrH-0.5,cw,0.5)];
    sep.tag=510; sep.backgroundColor=MZSep();
    [self.contentArea addSubview:sep];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Helpers construcción de página
// ─────────────────────────────────────────────────────────────────────────────
- (CGFloat)contentWidth { CGFloat w=self.scroll.bounds.size.width; return w>10?w:220; }

- (CGFloat)addToggle:(NSString *)txt key:(NSString *)key fallback:(BOOL)fb y:(CGFloat)y {
    CGFloat w=[self contentWidth];
    MZRow *row=[[MZRow alloc] initWithLabel:txt on:ESPPrefsBool(key,fb) width:w];
    row.frame=CGRectMake(0,y,w,SC(kBaseRowH));
    objc_setAssociatedObject(row,"espKey",key,OBJC_ASSOCIATION_COPY_NONATOMIC);
    __weak MZRow *wr=row; __weak _0xDEADBEEE *ws=self;
    row.onChanged=^(BOOL on){
        NSString *k=objc_getAssociatedObject(wr,"espKey");
        ESPPrefsSetBool(k,on); ESPSyncFromPrefs();
        [ws toggleChanged:k value:on];
    };
    [self.controls addObject:row]; [self.scroll addSubview:row];
    return y+SC(kBaseRowStep);
}

- (CGFloat)addCustomToggle:(NSString *)txt on:(BOOL)on y:(CGFloat)y handler:(void(^)(BOOL))h {
    CGFloat w=[self contentWidth];
    MZRow *row=[[MZRow alloc] initWithLabel:txt on:on width:w];
    row.frame=CGRectMake(0,y,w,SC(kBaseRowH));
    row.onChanged=h;
    [self.controls addObject:row]; [self.scroll addSubview:row];
    return y+SC(kBaseRowStep);
}

- (CGFloat)addSection:(NSString *)title y:(CGFloat)y {
    NSString *t=[[title stringByReplacingOccurrencesOfString:@"—" withString:@""]
        stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].uppercaseString;
    UILabel *l=[[UILabel alloc] initWithFrame:CGRectMake(SC(6),y+SC(4),[self contentWidth]-SC(12),SC(16))];
    l.text=t; l.textColor=MZTxtDim();
    l.font=[UIFont systemFontOfSize:SC(11) weight:UIFontWeightSemibold];
    [self.scroll addSubview:l];
    return y+SC(kBaseSectionH);
}

- (CGFloat)addSlider:(NSString *)txt key:(NSString *)key min:(float)mn max:(float)mx fb:(float)fb y:(CGFloat)y {
    CGFloat w=[self contentWidth];
    MZSliderRow *sr=[[MZSliderRow alloc] initWithLabel:txt key:key min:mn max:mx fallback:fb width:w];
    sr.frame=CGRectMake(0,y,w,SC(kBaseSliderH));
    [self.scroll addSubview:sr];
    return y+SC(kBaseSliderSt);
}

- (void)rebuildAnimated {
    if (UIAccessibilityIsReduceMotionEnabled()) { [self buildPage]; return; }
    [UIView transitionWithView:self.scroll duration:0.14
        options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionAllowUserInteraction
        animations:^{ [self buildPage]; } completion:nil];
}

- (void)refreshThemeInPlace {
    self.panel.backgroundColor=MZPanelBG();
    self.panel.layer.cornerRadius=SC(kBaseRadPanel);
    self.panel.layer.borderColor=MZBorder().CGColor;
    self.blurBG.effect=[UIBlurEffect effectWithStyle:MZBlur()];
    self.blurBG.layer.cornerRadius=SC(kBaseRadPanel);
    self.sidebar.backgroundColor=MZSidebarBG();
    UIView *div=[self.panel viewWithTag:99]; div.backgroundColor=MZSep();
    [self buildSidebar];
    [self buildPage];
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — buildPage
// ─────────────────────────────────────────────────────────────────────────────
- (void)buildPage {
    CGFloat saved=self.scroll.contentOffset.y;
    for (UIView *v in self.scroll.subviews) [v removeFromSuperview];
    [self.controls removeAllObjects];
    self.spinStatusLabel=nil;
    self.builtWidth=[self contentWidth];
    [self buildHeader];

    CGFloat y=SC(4), w=[self contentWidth];

    // ── TAB 0: ESP ───────────────────────────────────────────────────────────
    if (self.page==0) {
        y=[self addToggle:DStr(@"ESP Master",@"ESP Master",@"ESP Master") key:@"ESPEnabled" fallback:YES y:y];
        y=[self addSection:DStr(@"DRAW",@"DIBUJO",@"VẼ") y:y];
        y=[self addToggle:@"Box ESP"   key:@"Box"       fallback:YES y:y];
        y=[self addToggle:@"Line ESP"  key:@"Line"      fallback:NO  y:y];
        y=[self addToggle:DStr(@"Skeleton",@"Esqueleto",@"Xương") key:@"Skeleton" fallback:NO y:y];
        y=[self addToggle:DStr(@"Head Dot",@"Punto cabeza",@"Đầu Đỏ") key:@"HeadRedDot" fallback:NO y:y];
        y=[self addToggle:DStr(@"Health Bar",@"Vida",@"Thanh Máu") key:@"Health" fallback:YES y:y];
        y=[self addToggle:DStr(@"Name",@"Nombre",@"Tên") key:@"Name" fallback:YES y:y];
        y=[self addToggle:DStr(@"Distance",@"Distancia",@"Khoảng Cách") key:@"Dis" fallback:YES y:y];
        y=[self addToggle:DStr(@"Clean ESP",@"ESP Limpio",@"ESP Sạch") key:@"CleanESP" fallback:YES y:y];
        y=[self addSection:@"FOV" y:y];
        y=[self addToggle:DStr(@"Show FOV",@"Mostrar FOV",@"Hiện FOV") key:@"ShowFov" fallback:YES y:y];
        y=[self addSlider:DStr(@"FOV Size",@"Tamaño FOV",@"Bán Kính") key:@"FovSize" min:5 max:48 fb:40 y:y];

    // ── TAB 1: AIM ───────────────────────────────────────────────────────────
    } else if (self.page==1) {
        y=MZAddWarn(
            DStr(@"Use Aimbot with restraint. Excessive headshots may trigger detections.",
                 @"Usa el Aimbot con moderación. Muchos headshots pueden activar detecciones.",
                 @"Dùng Aimbot có chừng mực. Headshot quá nhiều có thể bị phát hiện."),
            @[DStr(@"restraint",@"moderación",@"có chừng mực"),
              DStr(@"detections",@"detecciones",@"phát hiện")],
            self.scroll, w, y);

        __weak _0xDEADBEEE *wa=self;
        y=[self addCustomToggle:@"Aimbot" on:AimActive() y:y handler:^(BOOL on){
            if (on) {
                ESPPrefsSetFloat(@"AimType",0);
                ESPPrefsSetFloat(@"AimActivation",(float)static_cast<int>(
                    AimModePolicy::AfterTypeSelection(AimModePolicy::ReadType(0.0f))));
                ESPPrefsSetBool(@"SilentAim",NO);
            } else { ESPPrefsSetFloat(@"AimType",-1); }
            ESPClearAimLock(); ESPSyncFromPrefs();
            [wa rebuildAnimated];
        }];

        // Tipo aim — dropdown
        NSArray *aimNames=@[DStr(@"Head",@"Cabeza",@"Đầu"),
                            DStr(@"Neck",@"Cuello",@"Cổ"),
                            DStr(@"Body",@"Cuerpo",@"Thân")];
        float ar=AimRaw();
        NSString *curAimName=(ar>=0&&ar<=2)?aimNames[(NSUInteger)ar]:aimNames[0];
        {
            MZDropRow *dr=[[MZDropRow alloc] initWithLabel:DStr(@"Tipo aim",@"Tipo aim",@"Kiểu aim")
                                                    value:curAimName width:w];
            dr.frame=CGRectMake(0,y,w,SC(kBaseRowH));
            __weak MZDropRow *wdr=dr;
            dr.onTap=^{
                UIAlertController *ac=[UIAlertController
                    alertControllerWithTitle:DStr(@"Aim Position",@"Posición aim",@"Vị trí ngắm")
                    message:nil preferredStyle:UIAlertControllerStyleActionSheet];
                for (NSInteger i=0;i<3;i++) {
                    float fi=(float)i;
                    NSString *nm=aimNames[(NSUInteger)i];
                    [ac addAction:[UIAlertAction actionWithTitle:nm style:UIAlertActionStyleDefault
                        handler:^(UIAlertAction *_){
                            ESPPrefsSetFloat(@"AimType",fi);
                            ESPPrefsSetFloat(@"AimActivation",(float)static_cast<int>(
                                AimModePolicy::AfterTypeSelection(AimModePolicy::ReadType(fi))));
                            ESPPrefsSetBool(@"SilentAim",NO);
                            ESPClearAimLock(); ESPSyncFromPrefs();
                            if (wdr) wdr.valueLbl.text=nm;
                        }]];
                }
                [ac addAction:[UIAlertAction actionWithTitle:DStr(@"Cancel",@"Cancelar",@"Hủy")
                    style:UIAlertActionStyleCancel handler:nil]];
                [wa presentViewController:ac animated:YES completion:nil];
            };
            [self.scroll addSubview:dr];
            y+=SC(kBaseRowStep);
        }

        y=[self addToggle:DStr(@"Aim Line",@"Línea objetivo",@"Aim Line") key:@"AimTargetLine" fallback:NO y:y];
        y=[self addToggle:DStr(@"Show FOV",@"Mostrar FOV",@"Hiện FOV") key:@"ShowFov" fallback:YES y:y];
        y=[self addToggle:DStr(@"Skip Bots",@"Ignorar bots",@"Bỏ Qua Bot") key:@"AimLag" fallback:NO y:y];

        y=[self addSection:DStr(@"ACTIVATION",@"ACTIVACIÓN",@"KÍCH HOẠT") y:y];
        NSArray *actOpts=@[DStr(@"Always",@"Siempre",@"Luôn Luôn"),
                           DStr(@"On Shoot",@"Al Disparar",@"Khi Bắn"),
                           DStr(@"On Scope",@"Al Apuntar",@"Khi Ngắm")];
        const NSInteger curAct=static_cast<int>(
            AimModePolicy::ReadActivation(ESPPrefsFloat(@"AimActivation",0)));
        NSInteger actSel=(curAct>=1&&curAct<=3)?curAct-1:0;
        MZPillPicker *actP=[[MZPillPicker alloc] initWithOptions:actOpts selected:actSel width:w];
        actP.frame=CGRectMake(0,y,w,SC(44));
        actP.onSelected=^(NSInteger idx){
            ESPPrefsSetFloat(@"AimActivation",(float)(idx+1));
            ESPClearAimLock(); ESPSyncFromPrefs();
        };
        [self.scroll addSubview:actP]; y+=SC(50);

        y=[self addSlider:DStr(@"FOV Radius",@"Radio FOV",@"Bán Kính FOV") key:@"FovSize" min:5 max:48 fb:40 y:y];
        y=[self addSlider:DStr(@"FOV Thickness",@"Grosor FOV",@"Độ Dày FOV") key:@"SilentFovSize" min:0 max:10 fb:0 y:y];
        y=[self addSection:DStr(@"WEAPONS",@"ARMAS",@"VŨ KHÍ") y:y];
        y=[self addToggle:DStr(@"Fast Fire",@"Disparo rápido",@"Bắn Nhanh") key:@"FastFire" fallback:NO y:y];
        y=[self addToggle:DStr(@"No Reload",@"Sin recarga",@"Không Nạp") key:@"ShootNoReload" fallback:NO y:y];

    // ── TAB 2: CUSTOM (colores ESP) ──────────────────────────────────────────
    } else if (self.page==2) {
        y=[self addSection:DStr(@"ESP COLORS",@"COLORES ESP",@"MÀU ESP") y:y];
        UISegmentedControl *seg=[[UISegmentedControl alloc] initWithItems:@[@"Box",@"FOV"]];
        seg.frame=CGRectMake(0,y,w,SC(36));
        seg.selectedSegmentIndex=self.colorTarget;
        seg.selectedSegmentTintColor=MZSbBtnSel();
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:MZTxtMain(),
            NSFontAttributeName:[UIFont systemFontOfSize:SC(13) weight:UIFontWeightMedium]}
                            forState:UIControlStateNormal];
        [seg setTitleTextAttributes:@{NSForegroundColorAttributeName:MZTxtMain()}
                            forState:UIControlStateSelected];
        [seg addTarget:self action:@selector(colorTargetChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:seg]; y+=SC(42);

        NSString *pfx=(self.colorTarget==0)?@"BoxColor":@"FovColor";
        float r=ESPPrefsFloat([pfx stringByAppendingString:@"R"],0.26f);
        float g2=ESPPrefsFloat([pfx stringByAppendingString:@"G"],0.78f);
        float b2=ESPPrefsFloat([pfx stringByAppendingString:@"B"],0.90f);
        UILabel *sw=[[UILabel alloc] initWithFrame:CGRectMake(0,y,w,SC(44))];
        sw.text=[NSString stringWithFormat:@"#%02X%02X%02X",(int)round(r*255),(int)round(g2*255),(int)round(b2*255)];
        sw.textAlignment=NSTextAlignmentCenter;
        sw.backgroundColor=[UIColor colorWithRed:r green:g2 blue:b2 alpha:1];
        CGFloat lum=r*0.299f+g2*0.587f+b2*0.114f;
        sw.textColor=lum>0.6f?UIColor.blackColor:UIColor.whiteColor;
        sw.font=[UIFont systemFontOfSize:SC(13) weight:UIFontWeightBold];
        sw.layer.cornerRadius=SC(kBaseRadRow); sw.clipsToBounds=YES; sw.tag=990;
        [self.scroll addSubview:sw]; y+=SC(50);

        NSArray *rgbEN=@[@"Red",@"Green",@"Blue"];
        NSArray *rgbES=@[@"Rojo",@"Verde",@"Azul"];
        NSArray *rgbVI=@[@"Đỏ",@"Xanh lá",@"Xanh"];
        NSArray *suf=@[@"R",@"G",@"B"]; float def[3]={0.26f,0.78f,0.90f};
        __weak UILabel *wSw=sw; __weak _0xDEADBEEE *ws2=self;
        for (int i=0;i<3;i++) {
            NSString *key=[pfx stringByAppendingString:suf[(NSUInteger)i]];
            UIView *row=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,SC(kBaseSliderH))];
            row.backgroundColor=MZCtrlBG(); row.layer.cornerRadius=SC(kBaseRadRow);
            UILabel *lbl=[[UILabel alloc] initWithFrame:CGRectMake(SC(14),SC(7),w-SC(90),SC(20))];
            lbl.text=DStr(rgbEN[(NSUInteger)i],rgbES[(NSUInteger)i],rgbVI[(NSUInteger)i]);
            lbl.textColor=MZTxtMain();
            lbl.font=[UIFont systemFontOfSize:SC(15) weight:UIFontWeightMedium];
            [row addSubview:lbl];
            UILabel *val=[[UILabel alloc] initWithFrame:CGRectMake(w-SC(72),SC(7),SC(60),SC(20))];
            val.textAlignment=NSTextAlignmentRight; val.textColor=MZTxtMain();
            val.font=[UIFont systemFontOfSize:SC(14) weight:UIFontWeightBold];
            float cur2=ESPPrefsFloat(key,def[i]);
            val.text=[NSString stringWithFormat:@"%.0f",(double)cur2*100];
            [row addSubview:val];
            UISlider *sl=[[UISlider alloc] initWithFrame:CGRectMake(SC(12),SC(36),w-SC(24),SC(22))];
            sl.minimumValue=0; sl.maximumValue=1; sl.value=cur2;
            sl.minimumTrackTintColor=MZSlTrack();
            sl.maximumTrackTintColor=MZSlInactive();
            sl.thumbTintColor=MZSlThumb();
            objc_setAssociatedObject(sl,"espKey",key,OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(sl,"valLbl",val,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(sl,"swRef",wSw,OBJC_ASSOCIATION_ASSIGN);
            objc_setAssociatedObject(sl,"swPfx",pfx,OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(sl,"menuRef",ws2,OBJC_ASSOCIATION_ASSIGN);
            [sl addTarget:self action:@selector(_colorSliderChanged:) forControlEvents:UIControlEventValueChanged];
            [row addSubview:sl]; [self.scroll addSubview:row]; y+=SC(kBaseSliderSt);
        }

    // ── TAB 3: MISC ──────────────────────────────────────────────────────────
    } else if (self.page==3) {
        y=MZAddWarn(
            DStr(@"Some options may not be entirely safe. Use with caution.",
                 @"Algunas opciones pueden no ser completamente seguras. Úsalas con precaución.",
                 @"Một số tùy chọn có thể không an toàn. Hãy cẩn thận."),
            @[DStr(@"not be entirely safe",@"no ser completamente seguras",@"không an toàn"),
              DStr(@"caution",@"precaución",@"cẩn thận")],
            self.scroll, w, y);
        y=[self addSection:@"EXTRAS" y:y];
        y=[self addToggle:DStr(@"Ghost",@"Fantasma",@"Ghost") key:@"GhostModeFloating" fallback:NO y:y];
        y=[self addToggle:DStr(@"FakeLag",@"Lag Falso",@"FakeLag") key:@"FakeLagFloating" fallback:NO y:y];
        y=[self addToggle:DStr(@"Fly",@"Volar",@"Bay") key:@"FlyFloating" fallback:NO y:y];
        y=[self addToggle:DStr(@"Speed",@"Velocidad",@"Tốc Độ") key:@"RunSpeedFloating" fallback:NO y:y];
        y=[self addToggle:DStr(@"Hide Buttons",@"Ocultar",@"Ẩn Nút") key:@"HideFeatureButtons" fallback:NO y:y];
        y=[self addToggle:DStr(@"AimKill",@"Matar aim",@"AimKill") key:@"AutoFireFloating" fallback:NO y:y];
        y=[self addSection:DStr(@"MOVEMENT",@"MOVIMIENTO",@"DI CHUYỂN") y:y];
        y=[self addToggle:DStr(@"Speed Toggle",@"Velocidad",@"Tốc Độ") key:@"RunSpeed" fallback:NO y:y];
        y=[self addSlider:DStr(@"Speed m/s",@"Velocidad m/s",@"Tốc Độ m/s") key:@"RunSpeedValue" min:1 max:15 fb:6 y:y];
        if (ESPPrefsBool(@"FlyFloating",NO))
            y=[self addSlider:DStr(@"Fly Height",@"Altura",@"Độ Cao") key:@"FlyHeight" min:1 max:6 fb:4 y:y];
        y=[self addSection:DStr(@"EFFECTS",@"EFECTOS",@"HIỆU ỨNG") y:y];
        y=[self addToggle:DStr(@"Visual Spin",@"Giro Visual",@"Xoay") key:@"VisualSpin" fallback:NO y:y];
        if (ESPPrefsBool(@"VisualSpin",NO)) {
            y=[self addSlider:DStr(@"Spin Speed",@"Vel. Giro",@"Tốc Độ Xoay") key:@"VisualSpinSpeed" min:0.1 max:3 fb:0.5 y:y];
            self.spinStatusLabel=[[UILabel alloc] initWithFrame:CGRectMake(SC(4),y,w-SC(8),SC(30))];
            self.spinStatusLabel.textColor=MZTxtDim();
            self.spinStatusLabel.font=[UIFont systemFontOfSize:SC(11)];
            self.spinStatusLabel.numberOfLines=2;
            [self.scroll addSubview:self.spinStatusLabel];
            [self updateSpinStatus]; y+=SC(36);
        }
        y=[self addToggle:DStr(@"Balanced Render",@"Render eq.",@"Render") key:@"BalancedRender" fallback:NO y:y];

    // ── TAB 4: SETTINGS ──────────────────────────────────────────────────────
    } else {
        y=[self addToggle:DStr(@"Stream Mode",@"Modo Stream",@"Stream") key:@"AnLive" fallback:NO y:y];

        // — Transparencia —
        {
            UIView *tr=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,SC(kBaseSliderH))];
            tr.backgroundColor=MZCtrlBG(); tr.layer.cornerRadius=SC(kBaseRadRow);
            UILabel *tl=[[UILabel alloc] initWithFrame:CGRectMake(SC(14),SC(7),w-SC(90),SC(20))];
            tl.text=DStr(@"Transparency",@"Transparencia",@"Độ Mờ");
            tl.textColor=MZTxtMain(); tl.font=[UIFont systemFontOfSize:SC(15) weight:UIFontWeightMedium];
            [tr addSubview:tl];
            UILabel *tv=[[UILabel alloc] initWithFrame:CGRectMake(w-SC(72),SC(7),SC(60),SC(20))];
            tv.textAlignment=NSTextAlignmentRight; tv.textColor=MZTxtMain();
            tv.font=[UIFont systemFontOfSize:SC(14) weight:UIFontWeightBold];
            float alpha2 = (float)[[NSUserDefaults standardUserDefaults] doubleForKey:@"DAAE.panelAlpha"];
            if (alpha2<0.35f||alpha2>1.0f) alpha2=1.0f;
            tv.text=[NSString stringWithFormat:@"%.2f",alpha2];
            [tr addSubview:tv];
            UISlider *ts=[[UISlider alloc] initWithFrame:CGRectMake(SC(12),SC(36),w-SC(24),SC(22))];
            ts.minimumValue=0.35f; ts.maximumValue=1.0f; ts.value=alpha2;
            ts.minimumTrackTintColor=MZSlTrack(); ts.maximumTrackTintColor=MZSlInactive(); ts.thumbTintColor=MZSlThumb();
            objc_setAssociatedObject(ts,"alphaVal",tv,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [ts addTarget:self action:@selector(_panelAlphaChanged:) forControlEvents:UIControlEventValueChanged];
            [tr addSubview:ts]; [self.scroll addSubview:tr]; y+=SC(kBaseSliderSt);
        }

        // — Menu Size (escalado global) —
        y=[self addSection:DStr(@"MENU SIZE",@"TAMAÑO MENÚ",@"CỠ MENU") y:y];
        {
            UIView *sr=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,SC(kBaseSliderH))];
            sr.backgroundColor=MZCtrlBG(); sr.layer.cornerRadius=SC(kBaseRadRow);
            UILabel *sl2=[[UILabel alloc] initWithFrame:CGRectMake(SC(14),SC(7),w-SC(110),SC(20))];
            sl2.text=DStr(@"Menu Size",@"Tamaño Menú",@"Cỡ Menu");
            sl2.textColor=MZTxtMain(); sl2.font=[UIFont systemFontOfSize:SC(15) weight:UIFontWeightMedium];
            [sr addSubview:sl2];
            UILabel *sv=[[UILabel alloc] initWithFrame:CGRectMake(w-SC(108),SC(7),SC(54),SC(20))];
            sv.textAlignment=NSTextAlignmentRight; sv.textColor=MZTxtMain();
            sv.font=[UIFont systemFontOfSize:SC(14) weight:UIFontWeightBold];
            sv.text=[NSString stringWithFormat:@"%d%%",(int)round(MZMenuScale()*100)];
            [sr addSubview:sv];
            // Botón reset
            UIButton *rb=[UIButton buttonWithType:UIButtonTypeSystem];
            rb.frame=CGRectMake(w-SC(44),SC(2),SC(36),SC(30));
            [rb setImage:MZSym(@"arrow.counterclockwise",SC(12),UIImageSymbolWeightSemibold) forState:UIControlStateNormal];
            rb.tintColor=MZTxtDim();
            UISlider *ss=[[UISlider alloc] initWithFrame:CGRectMake(SC(12),SC(36),w-SC(24),SC(22))];
            ss.minimumValue=0.70f; ss.maximumValue=1.30f; ss.value=(float)MZMenuScale();
            ss.minimumTrackTintColor=MZSlTrack(); ss.maximumTrackTintColor=MZSlInactive(); ss.thumbTintColor=MZSlThumb();
            objc_setAssociatedObject(ss,"scaleVal",sv,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [ss addTarget:self action:@selector(_menuScaleChanged:) forControlEvents:UIControlEventValueChanged];
            objc_setAssociatedObject(rb,"sSlider",ss,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(rb,"sLabel",sv,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [rb addTarget:self action:@selector(_menuScaleReset:) forControlEvents:UIControlEventTouchUpInside];
            [sr addSubview:ss]; [sr addSubview:rb]; [self.scroll addSubview:sr]; y+=SC(kBaseSliderSt);
        }

        // — Forma del menú —
        y=[self addSection:DStr(@"SHAPE",@"FORMA",@"HÌNH DẠNG") y:y];
        // (sin acento: pills monocromáticos)
        // Nota: en este diseño no hay "square corners" - todo redondeado. Mantenemos la opción por compatibilidad.

        // — Idioma —
        y=[self addSection:DStr(@"LANGUAGE",@"IDIOMA",@"NGÔN NGỮ") y:y];
        {
            UIView *lr=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,SC(kBaseRowH))];
            lr.backgroundColor=MZCtrlBG(); lr.layer.cornerRadius=SC(kBaseRadRow);
            NSArray *codes=@[@"EN",@"ES",@"VI"];
            NSInteger curL=DAAELang();
            CGFloat bw=(w-SC(16)-SC(10))/3.0;
            for (NSInteger k=0;k<3;k++) {
                UIButton *lb=[UIButton buttonWithType:UIButtonTypeCustom];
                lb.frame=CGRectMake(SC(8)+k*(bw+SC(5)),(SC(kBaseRowH)-SC(34))/2.0,bw,SC(34));
                BOOL sel=(k==curL);
                lb.backgroundColor=sel?MZSbBtnSel():UIColor.clearColor;
                lb.layer.cornerRadius=SC(14);
                [lb setTitle:codes[(NSUInteger)k] forState:UIControlStateNormal];
                lb.titleLabel.font=[UIFont systemFontOfSize:SC(13) weight:UIFontWeightBold];
                [lb setTitleColor:sel?MZTxtMain():MZTxtDim() forState:UIControlStateNormal];
                objc_setAssociatedObject(lb,"langIdx",@(k),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                [lb addTarget:self action:@selector(langTap:) forControlEvents:UIControlEventTouchUpInside];
                [lr addSubview:lb];
            }
            [self.scroll addSubview:lr]; y+=SC(kBaseRowStep);
        }

        // — Apariencia Dark/Light —
        y=[self addSection:DStr(@"APPEARANCE",@"APARIENCIA",@"GIAO DIỆN") y:y];
        NSArray *modeOpts=@[DStr(@"Light",@"Claro",@"Sáng"),DStr(@"Dark",@"Oscuro",@"Tối")];
        __weak _0xDEADBEEE *ws=self;
        MZPillPicker *mp=[[MZPillPicker alloc] initWithOptions:modeOpts selected:(MZDark()?1:0) width:w];
        mp.frame=CGRectMake(0,y,w,SC(44));
        mp.onSelected=^(NSInteger idx){ MZSetDark(idx==1); [ws refreshThemeInPlace]; };
        [self.scroll addSubview:mp]; y+=SC(50);

        // — Info —
        y=[self addSection:@"INFO" y:y];
        for (NSArray *pair in @[@[@"Product",@"DAAE IOS"],@[@"Creator",@"@didierxit7"],
                                @[@"Telegram",@"t.me/didierxit7"],@[DStr(@"Key",@"Clave",@"Khóa"),@"TEST"]]) {
            UIView *row=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,SC(kBaseRowH))];
            row.backgroundColor=MZCtrlBG(); row.layer.cornerRadius=SC(kBaseRadRow);
            UILabel *tl=[[UILabel alloc] initWithFrame:CGRectMake(SC(14),0,w*0.42,SC(kBaseRowH))];
            tl.text=pair[0]; tl.textColor=MZTxtMain();
            tl.font=[UIFont systemFontOfSize:SC(14) weight:UIFontWeightMedium];
            [row addSubview:tl];
            UILabel *vl=[[UILabel alloc] initWithFrame:CGRectMake(w*0.42,0,w*0.55,SC(kBaseRowH))];
            vl.text=pair[1]; vl.textColor=MZTxtDim();
            vl.font=[UIFont systemFontOfSize:SC(13) weight:UIFontWeightRegular];
            vl.textAlignment=NSTextAlignmentRight; vl.adjustsFontSizeToFitWidth=YES;
            [row addSubview:vl];
            [self.scroll addSubview:row]; y+=SC(kBaseRowStep);
        }
    }

    UILabel *cr=[[UILabel alloc] initWithFrame:CGRectMake(0,y+SC(6),w,SC(14))];
    cr.text=@"DAAE IOS"; cr.textAlignment=NSTextAlignmentCenter;
    cr.textColor=MZDark()?[UIColor colorWithWhite:1 alpha:0.12]:[UIColor colorWithWhite:0 alpha:0.12];
    cr.font=[UIFont systemFontOfSize:SC(9) weight:UIFontWeightMedium];
    [self.scroll addSubview:cr]; y+=SC(26);

    self.scroll.contentSize=CGSizeMake(w,y+SC(6));
    CGFloat maxY=MAX(0,y+SC(6)-self.scroll.bounds.size.height);
    self.scroll.contentOffset=CGPointMake(0,MAX(0,MIN(saved,maxY)));
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Acciones
// ─────────────────────────────────────────────────────────────────────────────
- (void)closeMenu { if (self.onCloseBlock) self.onCloseBlock(); }

- (void)darkModeToggleTap { MZSetDark(!MZDark()); [self refreshThemeInPlace]; }

- (void)colorTargetChanged:(UISegmentedControl *)seg {
    self.colorTarget=seg.selectedSegmentIndex; [self buildPage];
}

- (void)_colorSliderChanged:(UISlider *)sl {
    NSString *key=objc_getAssociatedObject(sl,"espKey");
    UILabel  *val=objc_getAssociatedObject(sl,"valLbl");
    UILabel  *sw=objc_getAssociatedObject(sl,"swRef");
    NSString *pfx=objc_getAssociatedObject(sl,"swPfx");
    if (!sw) sw=(UILabel *)[self.scroll viewWithTag:990];
    if (!pfx) pfx=(self.colorTarget==0)?@"BoxColor":@"FovColor";
    if (key) ESPPrefsSetFloat(key,sl.value);
    if (val) val.text=[NSString stringWithFormat:@"%.0f",(double)sl.value*100];
    if (sw&&pfx) {
        float r=ESPPrefsFloat([pfx stringByAppendingString:@"R"],0.26f);
        float g=ESPPrefsFloat([pfx stringByAppendingString:@"G"],0.78f);
        float b=ESPPrefsFloat([pfx stringByAppendingString:@"B"],0.90f);
        [UIView performWithoutAnimation:^{
            sw.backgroundColor=[UIColor colorWithRed:r green:g blue:b alpha:1];
            sw.text=[NSString stringWithFormat:@"#%02X%02X%02X",(int)round(r*255),(int)round(g*255),(int)round(b*255)];
            CGFloat lum=r*0.299f+g*0.587f+b*0.114f;
            sw.textColor=lum>0.6f?UIColor.blackColor:UIColor.whiteColor;
        }];
    }
    ESPSyncFromPrefs();
}

// Escala global — recalcula todo el panel en tiempo real
- (void)_menuScaleChanged:(UISlider *)sl {
    UILabel *val=objc_getAssociatedObject(sl,"scaleVal");
    MZSetMenuScale(sl.value);
    if (val) val.text=[NSString stringWithFormat:@"%d%%",(int)round(sl.value*100)];
    // Forzar recálculo centrado completo
    self.panel.frame=CGRectZero;
    self.blurBG.frame=CGRectZero;
    [self viewDidLayoutSubviews];
}
- (void)_menuScaleReset:(UIButton *)btn {
    MZSetMenuScale(1.0);
    UISlider *sl=objc_getAssociatedObject(btn,"sSlider");
    UILabel  *val=objc_getAssociatedObject(btn,"sLabel");
    if (sl) sl.value=1.0f;
    if (val) val.text=@"100%";
    self.panel.frame=CGRectZero;
    self.blurBG.frame=CGRectZero;
    [self viewDidLayoutSubviews];
}

- (void)_panelAlphaChanged:(UISlider *)sl {
    UILabel *val=objc_getAssociatedObject(sl,"alphaVal");
    [[NSUserDefaults standardUserDefaults] setDouble:(double)sl.value forKey:@"DAAE.panelAlpha"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (val) val.text=[NSString stringWithFormat:@"%.2f",sl.value];
    self.panel.backgroundColor=[MZPanelBG() colorWithAlphaComponent:CGColorGetAlpha(MZPanelBG().CGColor)*sl.value];
    self.blurBG.alpha=sl.value;
}

- (void)langTap:(UIButton *)sender {
    NSNumber *n=objc_getAssociatedObject(sender,"langIdx");
    if (!n) return;
    DAAESetLang(n.integerValue);
    [self rebuildAnimated]; [self buildSidebar];
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
    if ([key isEqualToString:@"AnLive"]&&
        ![UIView applyCaptureProtectionToRegisteredViews:on]) {
        ESPPrefsSetBool(@"AnLive",NO); [UIView applyCaptureProtectionToRegisteredViews:NO];
    }
    if ([@[@"AutoFireFloating",@"FlyFloating",@"VisualSpin"] containsObject:key])
        [self rebuildAnimated];
}

- (void)updateSpinStatus {
    if (!self.isViewLoaded||!self.view.window||self.view.hidden||!self.spinStatusLabel) return;
    const auto state=PlayerModesRead();
    NSString *text=@"Spin: waiting";
    if (state.detail&&state.detail[0]) text=[NSString stringWithUTF8String:state.detail];
    else if (state.spinStatus==1) text=@"Spin: waiting for character";
    else if (state.spinStatus==2) text=@"Spin: no compatible model";
    else if (state.spinStatus==3) text=@"Spin: waiting for angle";
    else if (state.spinStatus==4)
        text=[NSString stringWithFormat:@"Spin: applied · %llu",(unsigned long long)state.spinApplies];
    self.spinStatusLabel.text=text;
}

- (void)dealloc { [self.spinStatusTimer invalidate]; }

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — Drag
// ─────────────────────────────────────────────────────────────────────────────
- (void)dragPanel:(UIPanGestureRecognizer *)pan {
    if (pan.state==UIGestureRecognizerStateBegan) self.panelOrigin=self.panel.frame.origin;
    CGPoint d=[pan translationInView:self.view];
    CGRect f=self.panel.frame;
    f.origin=CGPointMake(self.panelOrigin.x+d.x,self.panelOrigin.y+d.y);
    self.panel.frame=f; self.blurBG.frame=f;
    [self viewDidLayoutSubviews];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)g shouldReceiveTouch:(UITouch *)t {
    for (UIView *v=t.view;v&&v!=g.view;v=v.superview)
        if ([v isKindOfClass:UIControl.class]) return NO;
    return YES;
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: — _0xF010 touch routing
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
        self.dragging=(local.x<SC(kBaseSidebarW)+2)||
                      (local.y<SC(kBaseHeaderH)&&local.x<self.panel.bounds.size.width-SC(80));
        if (self.dragging) return YES;
        CGPoint sc2=[self.scroll convertPoint:point fromView:self.view];
        for (UIView *c in self.controls) {
            if (![c isKindOfClass:UIControl.class]) continue;
            UIControl *ctrl=(UIControl *)c;
            if (!ctrl.enabled) continue;
            if (CGRectContainsPoint([ctrl convertRect:ctrl.bounds toView:self.scroll],sc2))
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
        } else if (fabs(dy)>5||self.scrolling) {
            self.scrolling=YES;
            CGFloat maxY=MAX(0,self.scroll.contentSize.height-self.scroll.bounds.size.height);
            self.scroll.contentOffset=CGPointMake(0,MAX(0,MIN(maxY,self.scrollOrigin-dy)));
        }
        return YES;
    }
    if (phase==UITouchPhaseEnded||phase==UITouchPhaseCancelled) {
        BOOL activate=phase==UITouchPhaseEnded&&!self.dragging&&!self.scrolling&&fabs(dx)<20&&fabs(dy)<20;
        UIControl *ctrl=self.activeControl;
        self.pointer=-1; self.activeControl=nil;
        if (activate&&ctrl&&ctrl.enabled) [ctrl sendActionsForControlEvents:UIControlEventTouchUpInside];
        return YES;
    }
    return YES;
}

@end
// BUILD OK

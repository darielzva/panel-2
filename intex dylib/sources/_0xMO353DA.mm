#import "ModMenuViewController.h"
#import "../esp/drawing_view/esp.h"
#import "../esp/drawing_view/ESPStyle.h"
#import <objc/runtime.h>
#import "UIView+SecureView.h"
#import "MizzeTheme.h"
#import "MizzeMenuPrefs.h"
#include <cmath>
#import "../esp/Core/PlayerModes.h"

// ─── SF SYMBOLS ──────────────────────────────────────────────────────────────
static UIImage *SFSym(NSString *name, CGFloat pts, UIImageSymbolWeight w) {
    UIImageSymbolConfiguration *cfg =
        [UIImageSymbolConfiguration configurationWithPointSize:pts weight:w];
    return [UIImage systemImageNamed:name withConfiguration:cfg];
}

// ─── ACENTO (0 Blanco 1 Celeste 2 Amarillo 3 Rojo 4 Rosa 5 Verde) ─────────
static NSArray<UIColor *> *DAAEAccents(void) {
    static NSArray *a; static dispatch_once_t t;
    dispatch_once(&t, ^{ a = @[
        [UIColor colorWithWhite:1.0 alpha:1.0],
        [UIColor colorWithRed:0.28 green:0.72 blue:1.00 alpha:1.0],
        [UIColor colorWithRed:1.00 green:0.85 blue:0.20 alpha:1.0],
        [UIColor colorWithRed:1.00 green:0.27 blue:0.27 alpha:1.0],
        [UIColor colorWithRed:1.00 green:0.45 blue:0.75 alpha:1.0],
        [UIColor colorWithRed:0.25 green:0.88 blue:0.62 alpha:1.0],
    ]; });
    return a;
}
static NSInteger DAAEAccentIdx(void) {
    NSInteger i = [[NSUserDefaults standardUserDefaults] integerForKey:@"DAAE.accentIdx"];
    return (i>=0 && i<(NSInteger)DAAEAccents().count) ? i : 0;
}
static UIColor *DAAEAccent(void) { return DAAEAccents()[DAAEAccentIdx()]; }

// Color del texto "DAAE IOS" en header flotante (tag DAAE.textColorIdx, default 0=blanco)
static NSInteger DAAETextColorIdx(void) {
    NSInteger i = [[NSUserDefaults standardUserDefaults] integerForKey:@"DAAE.textColorIdx"];
    return (i>=0 && i<(NSInteger)DAAEAccents().count) ? i : 0;
}
// Color del ESP enemigos (tag DAAE.enemyColorIdx, default 2=verde=mint)
static NSInteger DAAEEnemyColorIdx(void) {
    NSInteger i = [[NSUserDefaults standardUserDefaults] integerForKey:@"DAAE.enemyColorIdx"];
    return (i>=0 && i<(NSInteger)DAAEAccents().count) ? i : 5;
}

// ─── IDIOMA (0 ES 1 EN 2 VI, default ES) ─────────────────────────────────────
static NSInteger DAAELang(void) {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    if (![ud objectForKey:@"DAAE.lang"]) [ud setInteger:0 forKey:@"DAAE.lang"];
    NSInteger v = [ud integerForKey:@"DAAE.lang"];
    return (v>=0 && v<=2) ? v : 0;
}
static void DAAESetLang(NSInteger l) {
    [[NSUserDefaults standardUserDefaults] setInteger:l forKey:@"DAAE.lang"];
}
static NSString *TR(NSString *es, NSString *en, NSString *vi) {
    switch (DAAELang()) { case 1: return en; case 2: return vi; default: return es; }
}

// ─── COLOR ADAPTATIVO (texto) ────────────────────────────────────────────────
static UIColor *DAAETextColor(void) {
    return ESPPrefsBool(@"DarkTheme",YES)
        ? [UIColor colorWithWhite:0.95 alpha:1.0]
        : [UIColor colorWithWhite:0.08 alpha:1.0];
}
static UIColor *DAAEMutedColor(void) {
    return ESPPrefsBool(@"DarkTheme",YES)
        ? [UIColor colorWithWhite:0.55 alpha:1.0]
        : [UIColor colorWithWhite:0.38 alpha:1.0];
}
static UIColor *DAAERowBg(void) {
    return ESPPrefsBool(@"DarkTheme",YES)
        ? [UIColor colorWithWhite:1 alpha:0.07]
        : [UIColor colorWithWhite:0 alpha:0.05];
}
static UIColor *DAAERowBorder(void) {
    return ESPPrefsBool(@"DarkTheme",YES)
        ? [UIColor colorWithWhite:1 alpha:0.12]
        : [UIColor colorWithWhite:0 alpha:0.10];
}

// ─── CHECKMARK CIRCLE ────────────────────────────────────────────────────────
@interface DAAECheck : UIView
@property (nonatomic,assign) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end
@implementation DAAECheck { UIImageView *_iv; }
- (instancetype)initWithFrame:(CGRect)f {
    if ((self=[super initWithFrame:f])) {
        self.layer.cornerRadius = f.size.width/2.0;
        self.layer.borderWidth  = 1.4;
        self.userInteractionEnabled = NO;
        _iv = [[UIImageView alloc] initWithImage:SFSym(@"checkmark",12,UIImageSymbolWeightHeavy)];
        _iv.tintColor    = UIColor.blackColor;
        _iv.frame        = CGRectInset(self.bounds,4,4);
        _iv.contentMode  = UIViewContentModeScaleAspectFit;
        [self addSubview:_iv];
        [self setOn:NO animated:NO];
    }
    return self;
}
- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }
- (void)setOn:(BOOL)on animated:(BOOL)anim {
    _on = on;
    void(^u)(void)=^{
        self.backgroundColor   = on ? DAAEAccent() : UIColor.clearColor;
        self.layer.borderColor = on ? UIColor.clearColor.CGColor
                                    : [UIColor colorWithWhite:1 alpha:0.35].CGColor;
        self->_iv.hidden       = !on;
        self->_iv.tintColor    = [UIColor colorWithWhite:0.08 alpha:1.0];
    };
    anim ? [UIView animateWithDuration:0.18 delay:0
                options:UIViewAnimationOptionCurveEaseInOut animations:u completion:nil] : u();
}
@end

// ─── TOGGLE ROW ───────────────────────────────────────────────────────────────
// radioMode = YES → al tocar siempre queda ON, no alterna
@interface DAAEToggleRow : UIButton
@property (nonatomic,strong) DAAECheck *check;
@property (nonatomic,assign) BOOL toggleOn;
@property (nonatomic,assign) BOOL radioMode;        // para grupos exclusivos
@property (nonatomic,copy)   void(^onChanged)(BOOL);
@property (nonatomic,strong) UIView *glowView;
@end
@implementation DAAEToggleRow
- (instancetype)initWithTitle:(NSString *)title on:(BOOL)on width:(CGFloat)w {
    if ((self=[super initWithFrame:CGRectMake(0,0,w,50)])) {
        self.backgroundColor     = DAAERowBg();
        self.layer.cornerRadius  = 14;
        self.layer.borderWidth   = 0.6;
        self.layer.borderColor   = DAAERowBorder().CGColor;
        self.clipsToBounds       = YES;
        self.toggleOn = on;

        self.glowView = [[UIView alloc] initWithFrame:self.bounds];
        self.glowView.layer.cornerRadius = 14;
        self.glowView.userInteractionEnabled = NO;
        [self updateGlowForState:on];
        [self insertSubview:self.glowView atIndex:0];

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(16,0,w-68,50)];
        lbl.text      = title;
        lbl.textColor = DAAETextColor();
        lbl.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        lbl.adjustsFontSizeToFitWidth = YES;
        lbl.minimumScaleFactor = 0.7;
        [self addSubview:lbl];

        self.check = [[DAAECheck alloc] initWithFrame:CGRectMake(w-44,12,26,26)];
        [self.check setOn:on animated:NO];
        [self addSubview:self.check];

        [self addTarget:self action:@selector(_tap) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}
- (void)updateGlowForState:(BOOL)on {
    BOOL dark = ESPPrefsBool(@"DarkTheme",YES);
    if (on) {
        self.glowView.backgroundColor = dark
            ? [DAAEAccent() colorWithAlphaComponent:0.20]
            : [DAAEAccent() colorWithAlphaComponent:0.25];
        self.layer.borderColor = [DAAEAccent() colorWithAlphaComponent:0.60].CGColor;
    } else {
        self.glowView.backgroundColor = UIColor.clearColor;
        self.layer.borderColor = DAAERowBorder().CGColor;
    }
}
- (void)setToggleOn:(BOOL)v {
    _toggleOn = v;
    [self.check setOn:v animated:YES];
    [UIView animateWithDuration:0.18 delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{ [self updateGlowForState:v]; } completion:nil];
}
- (void)_tap {
    // Si radioMode, solo ON (nunca apaga al tocar)
    BOOL newState = self.radioMode ? YES : !self.toggleOn;
    _toggleOn = newState;
    [self.check setOn:newState animated:YES];
    [UIView animateWithDuration:0.18 delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{ [self updateGlowForState:newState]; } completion:nil];
    if (self.onChanged) self.onChanged(newState);
}
@end

// ─── SECTION LABEL ───────────────────────────────────────────────────────────
static UILabel *DAAESectionLabel(NSString *title,CGFloat w) {
    UILabel *l=[[UILabel alloc] initWithFrame:CGRectMake(4,0,w-8,22)];
    l.text=[title uppercaseString]; l.textColor=DAAEMutedColor();
    l.font=[UIFont systemFontOfSize:11 weight:UIFontWeightSemibold]; return l;
}

// ─── SLIDER ROW ──────────────────────────────────────────────────────────────
@interface DAAESliderRow : UIView @end
@implementation DAAESliderRow
- (instancetype)initWithTitle:(NSString *)title key:(NSString *)key
                          min:(float)mn max:(float)mx fallback:(float)fb
                        width:(CGFloat)w onChanged:(void(^)(float))cb {
    if ((self=[super initWithFrame:CGRectMake(0,0,w,68)])) {
        self.backgroundColor    = DAAERowBg();
        self.layer.cornerRadius = 14;
        self.layer.borderWidth  = 0.6;
        self.layer.borderColor  = DAAERowBorder().CGColor;

        UILabel *lbl=[[UILabel alloc] initWithFrame:CGRectMake(16,8,w-110,20)];
        lbl.text=title; lbl.textColor=DAAETextColor();
        lbl.font=[UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [self addSubview:lbl];

        UILabel *val=[[UILabel alloc] initWithFrame:CGRectMake(w-74,6,58,24)];
        val.textAlignment=NSTextAlignmentCenter;
        val.textColor=[UIColor colorWithWhite:0.08 alpha:1.0];
        val.font=[UIFont systemFontOfSize:12 weight:UIFontWeightBold];
        val.backgroundColor=DAAEAccent();
        val.layer.cornerRadius=11; val.clipsToBounds=YES;
        float cur=ESPPrefsFloat(key,fb);
        val.text=[NSString stringWithFormat:@"%.0f",cur*(mx<=1?255:1)];
        if(mx<=1)val.text=[NSString stringWithFormat:@"%.0f",cur*255];
        else val.text=[NSString stringWithFormat:@"%.0f",cur];
        [self addSubview:val];

        UISlider *sl=[[UISlider alloc] initWithFrame:CGRectMake(12,38,w-24,24)];
        sl.minimumValue=mn; sl.maximumValue=mx; sl.value=cur;
        sl.minimumTrackTintColor=DAAEAccent();
        sl.maximumTrackTintColor=[UIColor colorWithWhite:0.5 alpha:0.3];
        sl.thumbTintColor=UIColor.whiteColor;
        objc_setAssociatedObject(sl,"valLbl",val,OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(sl,"espKey",key,OBJC_ASSOCIATION_COPY_NONATOMIC);
        objc_setAssociatedObject(sl,"isRatio",@(mx<=1),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        void(^cbCopy)(float)=[cb copy];
        objc_setAssociatedObject(sl,"cb",cbCopy,OBJC_ASSOCIATION_COPY_NONATOMIC);
        [sl addTarget:self action:@selector(_slid:) forControlEvents:UIControlEventValueChanged];
        [self addSubview:sl];
    }
    return self;
}
- (void)_slid:(UISlider *)sl {
    UILabel *val=objc_getAssociatedObject(sl,"valLbl");
    NSString *key=objc_getAssociatedObject(sl,"espKey");
    BOOL ratio=[objc_getAssociatedObject(sl,"isRatio") boolValue];
    void(^cb)(float)=objc_getAssociatedObject(sl,"cb");
    val.text = ratio ? [NSString stringWithFormat:@"%.0f",sl.value*255]
                     : [NSString stringWithFormat:@"%.0f",sl.value];
    ESPPrefsSetFloat(key,sl.value); ESPSyncFromPrefs();
    if(cb)cb(sl.value);
}
@end



// ─── PANEL PRINCIPAL ──────────────────────────────────────────────────────────
@interface _0xDEADBEEE () <UIGestureRecognizerDelegate>
@property (nonatomic,strong) UIVisualEffectView *blurBG;
@property (nonatomic,strong) UIView             *panel;
@property (nonatomic,strong) UIView             *sidebar;
@property (nonatomic,strong) UIView             *contentArea;
@property (nonatomic,strong) UIScrollView       *scroll;
@property (nonatomic,assign) NSInteger  page;
@property (nonatomic,assign) BOOL       darkMode;
@property (nonatomic,assign) BOOL       aimExpanded;
@property (nonatomic,assign) BOOL       advancedExpanded;
@property (nonatomic,assign) NSInteger  colorESPTarget;  // 0=Marco 1=FOV
@property (nonatomic,assign) CGFloat    builtWidth;
@property (nonatomic,strong) NSMutableArray<UIControl*> *controls;
@property (nonatomic,strong) UILabel   *spinStatusLabel;
@property (nonatomic,strong) NSTimer   *spinStatusTimer;
@property (nonatomic,assign) NSInteger  pointer;
@property (nonatomic,assign) CGPoint    began;
@property (nonatomic,assign) CGPoint    panelOrigin;
@property (nonatomic,assign) CGFloat    scrollOrigin;
@property (nonatomic,assign) BOOL       dragging;
@property (nonatomic,assign) BOOL       scrolling;
@property (nonatomic,strong) UIControl *activeControl;
@end

@implementation _0xDEADBEEE

- (void)applyDefaults {
    NSDictionary *defs=@{
        @"ESPEnabled":@NO,@"Box":@NO,@"Box3D":@NO,@"CleanESP":@NO,
        @"Name":@NO,@"Health":@NO,@"Line":@NO,@"Skeleton":@NO,
        @"HeadRedDot":@NO,@"Dis":@NO,@"ShowFov":@YES,
        @"AimLag":@NO,@"AimTargetLine":@NO,@"SilentAim":@NO,
        @"AutoFire":@NO,@"AutoFireFloating":@NO,@"FastFire":@NO,
        @"ShootNoReload":@NO,@"GhostModeFloating":@NO,@"FakeLagFloating":@NO,
        @"FlyFloating":@NO,@"RunSpeedFloating":@NO,@"RunSpeed":@NO,
        @"VisualSpin":@NO,@"AnLive":@NO,@"DarkTheme":@YES,@"BalancedRender":@NO,
        @"AimType":@(0.0f),@"AimActivation":@(1.0f),
        @"FovSize":@(40.0f),@"SilentFovSize":@(18.0f),
    };
    NSUserDefaults *ud=NSUserDefaults.standardUserDefaults;
    if([ud objectForKey:@"_MizzeDefaultsApplied"])return;
    for(NSString *k in defs){
        id v=defs[k]; if(![v isKindOfClass:NSNumber.class])continue;
        const char *t=((NSNumber*)v).objCType;
        (strcmp(t,@encode(BOOL))==0||strcmp(t,@encode(bool))==0||strcmp(t,@encode(char))==0)
            ? ESPPrefsSetBool(k,((NSNumber*)v).boolValue)
            : ESPPrefsSetFloat(k,((NSNumber*)v).floatValue);
    }
    ESPPrefsSetBool(@"ExplicitAimMenuV1",YES);
    [ud setBool:YES forKey:@"_MizzeDefaultsApplied"]; [ud synchronize]; ESPSyncFromPrefs();
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self applyDefaults]; MizzePrepareMenuPrefs();
    self.darkMode=ESPPrefsBool(@"DarkTheme",YES);
    self.pointer=-1; self.controls=[NSMutableArray array];
    self.view.backgroundColor=UIColor.clearColor;

    __weak _0xDEADBEEE *ws=self;
    self.spinStatusTimer=[NSTimer scheduledTimerWithTimeInterval:.5 repeats:YES
        block:^(NSTimer *_){ _0xDEADBEEE *s=ws;
            if(s.isViewLoaded&&s.view.window&&!s.view.hidden&&s.spinStatusLabel)[s updateSpinStatus]; }];

    self.blurBG=[[UIVisualEffectView alloc] initWithEffect:
        [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialDark]];
    self.blurBG.layer.cornerRadius=22; self.blurBG.clipsToBounds=YES;
    [self.view addSubview:self.blurBG];

    self.panel=[[UIView alloc] initWithFrame:CGRectZero];
    self.panel.layer.cornerRadius=22;
    self.panel.layer.borderWidth=0.7;
    self.panel.layer.borderColor=[UIColor colorWithWhite:1 alpha:0.18].CGColor;
    self.panel.clipsToBounds=YES;
    [self.view addSubview:self.panel];

    // Sidebar: casi transparente — solo los botones la definen
    self.sidebar=[[UIView alloc] initWithFrame:CGRectZero];
    self.sidebar.backgroundColor=[UIColor colorWithWhite:0 alpha:0.04];
    [self.panel addSubview:self.sidebar];

    UIView *div=[[UIView alloc] initWithFrame:CGRectZero];
    div.tag=99; div.backgroundColor=[UIColor colorWithWhite:1 alpha:0.06];
    [self.panel addSubview:div];

    self.contentArea=[[UIView alloc] initWithFrame:CGRectZero];
    self.contentArea.backgroundColor=UIColor.clearColor;
    [self.panel addSubview:self.contentArea];

    self.scroll=[[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scroll.showsVerticalScrollIndicator=NO; self.scroll.bounces=YES;
    [self.contentArea addSubview:self.scroll];

    UIPanGestureRecognizer *pa=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPanel:)];
    pa.delegate=self; [self.sidebar addGestureRecognizer:pa];
    UIPanGestureRecognizer *pb=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragPanel:)];
    pb.delegate=self; [self.contentArea addGestureRecognizer:pb];

    [self buildSidebar]; [self buildPage];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat sw=self.view.bounds.size.width, sh=self.view.bounds.size.height;
    if(sw<=0)sw=320; if(sh<=0)sh=480;

    CGFloat pw=MIN(680.0,MAX(320.0,sw-32.0));
    CGFloat ph=MIN(480.0,MAX(260.0,sh-48.0));

    CGRect f=self.panel.frame;
    if(f.size.width==0){ f=CGRectMake((sw-pw)/2,(sh-ph)/2,pw,ph); }
    else { f.size=CGSizeMake(pw,ph);
           f.origin.x=MAX(8,MIN(f.origin.x,sw-pw-8));
           f.origin.y=MAX(8,MIN(f.origin.y,sh-ph-8)); }
    self.panel.frame=f; self.blurBG.frame=f;

    // Panel background según tema
    self.panel.backgroundColor=self.darkMode
        ? [UIColor colorWithWhite:0.06 alpha:0.96]
        : [UIColor colorWithWhite:0.93 alpha:0.96];
    self.blurBG.effect=[UIBlurEffect effectWithStyle:self.darkMode
        ? UIBlurEffectStyleSystemUltraThinMaterialDark
        : UIBlurEffectStyleSystemUltraThinMaterial];

    CGFloat sbW=70.0;
    self.sidebar.frame=CGRectMake(0,0,sbW,ph);
    self.sidebar.layer.mask=nil;

    UIView *div=[self.panel viewWithTag:99];
    div.frame=CGRectMake(sbW,0,0.6,ph);

    CGFloat caX=sbW+0.6;
    self.contentArea.frame=CGRectMake(caX,0,pw-caX,ph);
    self.scroll.frame=CGRectMake(0,44,pw-caX,ph-44);

    if(fabs(self.builtWidth-self.scroll.bounds.size.width)>0.5)[self buildPage];
    [self refreshSidebarSelection];
}

// ─── SIDEBAR ──────────────────────────────────────────────────────────────────
- (void)buildSidebar {
    NSArray *icons=@[@"scope",@"eye.fill",@"cube.box.fill",@"paintpalette.fill",@"gearshape.fill"];
    CGFloat sbW=70, btnS=46;
    // 5 botones centrados verticalmente — spacing automático
    // Se posicionan en viewDidLayoutSubviews solo la primera vez; aquí los creamos con y provisional
    for(NSInteger i=0;i<5;i++){
        UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
        btn.tag=300+i;
        btn.frame=CGRectMake((sbW-btnS)/2, 0, btnS, btnS); // y se actualiza en refreshSidebarLayout
        btn.layer.cornerRadius=btnS/2.0;
        btn.layer.borderWidth=0.7;
        [btn setImage:SFSym(icons[i],19,UIImageSymbolWeightSemibold) forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(sidebarTap:) forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
    }
    [self refreshSidebarSelection];
}

- (void)refreshSidebarSelection {
    CGFloat sbH = self.sidebar.bounds.size.height > 0 ? self.sidebar.bounds.size.height : 300;
    CGFloat btnS = 46;
    CGFloat totalH = 5*btnS + 4*12; // 5 botones + 4 gaps de 12
    CGFloat startY = (sbH - totalH) / 2.0;
    if(startY < 12) startY = 12;

    BOOL dark = self.darkMode;
    for(NSInteger i=0;i<5;i++){
        UIButton *btn=(UIButton*)[self.sidebar viewWithTag:300+i];
        if(!btn)continue;
        CGFloat y = startY + i*(btnS+12);
        btn.frame = CGRectMake((70-btnS)/2.0, y, btnS, btnS);
        BOOL sel=(i==self.page);
        btn.backgroundColor = sel ? UIColor.whiteColor
                                  : (dark ? [UIColor colorWithWhite:1 alpha:0.08]
                                          : [UIColor colorWithWhite:0 alpha:0.08]);
        btn.tintColor       = sel ? UIColor.blackColor
                                  : (dark ? [UIColor colorWithWhite:0.80 alpha:1.0]
                                          : [UIColor colorWithWhite:0.25 alpha:1.0]);
        btn.layer.borderColor = sel ? UIColor.clearColor.CGColor
                                    : (dark ? [UIColor colorWithWhite:1 alpha:0.15].CGColor
                                            : [UIColor colorWithWhite:0 alpha:0.12].CGColor);
    }
}

- (void)sidebarTap:(UIButton *)sender {
    NSInteger np=sender.tag-300; if(np==self.page)return;
    self.page=np; self.scroll.contentOffset=CGPointZero;
    [self refreshSidebarSelection]; [self rebuildAnimated];
}

// ─── HEADER ───────────────────────────────────────────────────────────────────
- (void)buildHeader {
    for(UIView *v in self.contentArea.subviews) if(v.tag>=500&&v.tag<600)[v removeFromSuperview];
    CGFloat cw=self.contentArea.bounds.size.width;
    NSArray *icons=@[@"scope",@"eye.fill",@"cube.box.fill",@"paintpalette.fill",@"gearshape.fill"];
    NSArray *titlesES=@[@"Aims",@"ESP",@"Misc",@"Colores",@"Ajustes"];
    NSArray *titlesEN=@[@"Aims",@"ESP",@"Misc",@"Colors",@"Settings"];
    NSArray *titlesVI=@[@"Aims",@"ESP",@"Khác",@"Màu sắc",@"Cài đặt"];
    NSArray *titles=(DAAELang()==1)?titlesEN:(DAAELang()==2)?titlesVI:titlesES;

    UIView *hdr=[[UIView alloc] initWithFrame:CGRectMake(0,0,cw,44)]; hdr.tag=500;
    hdr.backgroundColor=[UIColor colorWithWhite:0 alpha:0.04];
    [self.contentArea addSubview:hdr];
    UIView *sep=[[UIView alloc] initWithFrame:CGRectMake(0,43.5,cw,0.5)]; sep.tag=501;
    sep.backgroundColor=[UIColor colorWithWhite:0.5 alpha:0.15]; [self.contentArea addSubview:sep];

    UIImageView *iv=[[UIImageView alloc] initWithImage:SFSym(icons[self.page],13,UIImageSymbolWeightSemibold)];
    iv.tag=502; iv.tintColor=DAAEAccent();
    iv.frame=CGRectMake(14,15,15,15); iv.contentMode=UIViewContentModeScaleAspectFit;
    [self.contentArea addSubview:iv];

    UILabel *ttl=[[UILabel alloc] initWithFrame:CGRectMake(34,0,cw-90,44)]; ttl.tag=503;
    ttl.text=titles[self.page]; ttl.textColor=DAAETextColor();
    ttl.font=[UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [self.contentArea addSubview:ttl];

    // Luna / Sol
    UIButton *moon=[UIButton buttonWithType:UIButtonTypeSystem]; moon.tag=504;
    moon.frame=CGRectMake(cw-70,8,28,28);
    [moon setImage:SFSym(self.darkMode?@"moon.fill":@"sun.max.fill",14,UIImageSymbolWeightSemibold)
          forState:UIControlStateNormal];
    moon.tintColor=DAAEMutedColor();
    [moon addTarget:self action:@selector(toggleTheme) forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:moon];

    // Cerrar
    UIButton *close=[UIButton buttonWithType:UIButtonTypeSystem]; close.tag=505;
    close.frame=CGRectMake(cw-38,8,28,28);
    [close setImage:SFSym(@"xmark",12,UIImageSymbolWeightBold) forState:UIControlStateNormal];
    close.tintColor=DAAEMutedColor();
    [close addTarget:self action:@selector(closeMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.contentArea addSubview:close];
}

// ─── HELPERS DE CONSTRUCCIÓN ──────────────────────────────────────────────────
- (CGFloat)contentWidth { return self.scroll.bounds.size.width>10?self.scroll.bounds.size.width:280; }

- (CGFloat)addToggle:(NSString *)title key:(NSString *)key fallback:(BOOL)fb y:(CGFloat)y {
    CGFloat w=[self contentWidth];
    DAAEToggleRow *row=[[DAAEToggleRow alloc] initWithTitle:title on:ESPPrefsBool(key,fb) width:w];
    row.frame=CGRectMake(0,y,w,50);
    objc_setAssociatedObject(row,"espKey",key,OBJC_ASSOCIATION_COPY_NONATOMIC);
    __weak DAAEToggleRow *wr=row; __weak _0xDEADBEEE *ws=self;
    row.onChanged=^(BOOL on){
        NSString *k=objc_getAssociatedObject(wr,"espKey");
        ESPPrefsSetBool(k,on); ESPSyncFromPrefs(); [ws toggleChanged:k value:on];
    };
    [self.controls addObject:row]; [self.scroll addSubview:row]; return y+56;
}

- (CGFloat)addSection:(NSString *)title y:(CGFloat)y {
    UILabel *l=DAAESectionLabel(title,[self contentWidth]);
    l.frame=CGRectMake(4,y+6,[self contentWidth]-8,22);
    [self.scroll addSubview:l]; return y+32;
}

- (CGFloat)addSlider:(NSString *)title key:(NSString *)key
                 min:(float)mn max:(float)mx fallback:(float)fb y:(CGFloat)y {
    CGFloat w=[self contentWidth];
    DAAESliderRow *row=[[DAAESliderRow alloc] initWithTitle:title key:key
        min:mn max:mx fallback:fb width:w onChanged:nil];
    row.frame=CGRectMake(0,y,w,68);
    [self.controls addObject:(UIControl*)row]; [self.scroll addSubview:row]; return y+74;
}

// Construye un grupo radio (solo 1 activo)
// names: títulos, valueOffset: los valores son 0-based o (i+1)-based
- (CGFloat)addRadioGroup:(NSArray<NSString*>*)names
                  prefsKey:(NSString*)key
                   current:(NSInteger)current
                valueOffset:(NSInteger)offset   // valor = i + offset
                   columns:(NSInteger)cols
                        y:(CGFloat)y {
    CGFloat w=[self contentWidth];
    CGFloat itemW = cols==2 ? (w-8)/2.0 : w;
    CGFloat gapX  = cols==2 ? 8 : 0;

    NSMutableArray<DAAEToggleRow*> *rows=[NSMutableArray array];
    for(NSUInteger i=0;i<names.count;i++){
        NSInteger val=(NSInteger)i+offset;
        DAAEToggleRow *row=[[DAAEToggleRow alloc]
            initWithTitle:names[i] on:(current==val) width:itemW];
        row.radioMode=YES;
        row.frame=CGRectMake((i%cols)*(itemW+gapX), y+(i/cols)*56, itemW, 50);
        [rows addObject:row]; [self.scroll addSubview:row];
    }
    NSUInteger rowCount=(names.count+cols-1)/cols;
    CGFloat totalH=rowCount*56;

    for(NSUInteger i=0;i<rows.count;i++){
        NSInteger val=(NSInteger)i+offset;
        __weak NSMutableArray<DAAEToggleRow*> *wr=rows;
        rows[i].onChanged=^(BOOL on){
            if(!on)return;
            NSMutableArray<DAAEToggleRow*> *rs=wr;
            for(NSUInteger j=0;j<rs.count;j++){
                BOOL isMe=(j==i);
                rs[j].toggleOn=isMe;
                [rs[j].check setOn:isMe animated:YES];
                [UIView animateWithDuration:0.18 delay:0
                    options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{ [rs[j] updateGlowForState:isMe]; } completion:nil];
            }
            if([key isEqualToString:@"AimType"]){
                ESPPrefsSetFloat(key,(float)val);
                ESPPrefsSetFloat(@"AimActivation",static_cast<int>(
                    AimModePolicy::AfterTypeSelection(AimModePolicy::ReadType((float)val))));
                ESPPrefsSetBool(@"SilentAim",NO);
                ESPClearAimLock(); ESPSyncFromPrefs();
            } else {
                ESPPrefsSetFloat(key,(float)val);
                ESPClearAimLock(); ESPSyncFromPrefs();
            }
        };
    }
    return y+totalH;
}

- (void)rebuildAnimated {
    if(UIAccessibilityIsReduceMotionEnabled()){[self buildPage];return;}
    [UIView transitionWithView:self.scroll duration:0.18
        options:UIViewAnimationOptionTransitionCrossDissolve|UIViewAnimationOptionAllowUserInteraction
        animations:^{[self buildPage];} completion:nil];
}

// ─── BUILD PAGE ───────────────────────────────────────────────────────────────
- (void)buildPage {
    const CGFloat offset=self.scroll.contentOffset.y;
    for(UIView *v in self.scroll.subviews)[v removeFromSuperview];
    [self.controls removeAllObjects]; self.spinStatusLabel=nil;
    self.builtWidth=[self contentWidth];
    self.darkMode=ESPPrefsBool(@"DarkTheme",YES);
    [self buildHeader]; [self refreshSidebarSelection];

    CGFloat y=8;

    // ── 0: AIMS ───────────────────────────────────────────────────────────────
    if(self.page==0){
        NSArray *aimNames=@[
            TR(@"Aim Cabeza",@"Head Aim",@"Aim Đầu"),
            TR(@"Aim Cuello",@"Neck Aim",@"Aim Cổ"),
            @"Silent Aim"
        ];
        const NSInteger type=static_cast<int>(AimModePolicy::ReadType(ESPPrefsFloat(@"AimType",0)));

        UIButton *chooser=[UIButton buttonWithType:UIButtonTypeSystem];
        chooser.frame=CGRectMake(0,y,[self contentWidth],46);
        chooser.backgroundColor=DAAERowBg();
        chooser.layer.cornerRadius=14; chooser.layer.borderWidth=0.6;
        chooser.layer.borderColor=DAAERowBorder().CGColor;
        chooser.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft;
        chooser.contentEdgeInsets=UIEdgeInsetsMake(0,16,0,16);
        [chooser setTitle:[NSString stringWithFormat:@"%@  %@",
            TR(@"Tipo de aim",@"Aim type",@"Loại aim"),
            self.aimExpanded?@"▲":@"▼"] forState:UIControlStateNormal];
        [chooser setTitleColor:DAAEAccent() forState:UIControlStateNormal];
        chooser.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [chooser addTarget:self action:@selector(chooseAim) forControlEvents:UIControlEventTouchUpInside];
        [self.scroll addSubview:chooser]; y+=52;

        if(self.aimExpanded){
            y=[self addRadioGroup:aimNames prefsKey:@"AimType" current:type valueOffset:0 columns:1 y:y];
        }

        const BOOL silent=AimModePolicy::ReadType(ESPPrefsFloat(@"AimType",0))==AimModePolicy::Type::Silent;
        if(silent){
            y=[self addToggle:TR(@"Activar Silent Aim",@"Enable Silent Aim",@"Bật Silent Aim")
                          key:@"SilentAim" fallback:NO y:y];
        } else {
            y=[self addSection:TR(@"Activación",@"Activation",@"Kích hoạt") y:y];
            NSArray *actNames=@[
                TR(@"Al disparar",@"When firing",@"Khi bắn"),
                TR(@"Al apuntar",@"When aiming",@"Khi ngắm"),
                TR(@"Siempre",@"Always",@"Luôn luôn"),
                @"Fire+Scope"
            ];
            const NSInteger mode=static_cast<int>(AimModePolicy::ReadActivation(ESPPrefsFloat(@"AimActivation",0)));
            y=[self addRadioGroup:actNames prefsKey:@"AimActivation" current:mode valueOffset:1 columns:2 y:y];
        }

        y=[self addToggle:TR(@"Aimlag al apuntar",@"Aimlag",@"Aimlag khi ngắm") key:@"AimLag" fallback:NO y:y];
        y=[self addToggle:TR(@"Línea al objetivo",@"Target line",@"Dây tới mục tiêu") key:@"AimTargetLine" fallback:YES y:y];
        y=[self addSlider:@"FOV"
                      key:(silent||ESPPrefsBool(@"AutoFire",NO))?@"SilentFovSize":@"FovSize"
                      min:5 max:48 fallback:(silent||ESPPrefsBool(@"AutoFire",NO))?18:40 y:y];
        y=[self addToggle:TR(@"Mostrar FOV",@"Show FOV",@"Hiện vòng FOV") key:@"ShowFov" fallback:YES y:y];
        y=[self addToggle:@"AimKill" key:@"AutoFireFloating" fallback:NO y:y];
        if(silent||ESPPrefsBool(@"AutoFireFloating",NO))
            y=[self addSlider:TR(@"% Headshot",@"% Headshot",@"Tỷ lệ headshot") key:@"SilentHeadPercent" min:0 max:100 fallback:75 y:y];
        y=[self addSection:TR(@"Armas",@"Weapons",@"Súng") y:y];
        y=[self addToggle:TR(@"Disparo rápido (2×)",@"Fast fire (2×)",@"Bắn nhanh") key:@"FastFire" fallback:NO y:y];
        y=[self addToggle:TR(@"Sin recarga",@"No reload",@"Không nạp đạn") key:@"ShootNoReload" fallback:NO y:y];

        // Advanced
        UIButton *adv=[UIButton buttonWithType:UIButtonTypeSystem];
        adv.frame=CGRectMake(0,y,[self contentWidth],44);
        adv.backgroundColor=DAAERowBg(); adv.layer.cornerRadius=14;
        [adv setTitle:[NSString stringWithFormat:@"%@  %@",
            TR(@"Avanzado",@"Advanced",@"Nâng cao"),self.advancedExpanded?@"▲":@"▼"]
             forState:UIControlStateNormal];
        [adv setTitleColor:DAAETextColor() forState:UIControlStateNormal];
        adv.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [adv addTarget:self action:@selector(toggleAdvanced) forControlEvents:UIControlEventTouchUpInside];
        [self.scroll addSubview:adv]; y+=50;
        if(self.advancedExpanded&&silent){
            y=[self addToggle:TR(@"Rango auto",@"Auto range",@"Tự chọn tầm") key:@"SilentAutoConfig" fallback:YES y:y];
            if(!ESPPrefsBool(@"SilentAutoConfig",YES))
                y=[self addSlider:TR(@"Rango Silent",@"Silent range",@"Tầm Silent") key:@"SilentMaxDistance" min:10 max:150 fallback:100 y:y];
        }

    // ── 1: ESP ────────────────────────────────────────────────────────────────
    } else if(self.page==1){
        y=[self addToggle:TR(@"Activar ESP",@"Enable ESP",@"Bật ESP") key:@"ESPEnabled" fallback:YES y:y];

        UIButton *preset=[UIButton buttonWithType:UIButtonTypeSystem];
        preset.frame=CGRectMake(0,y,[self contentWidth],44);
        preset.layer.cornerRadius=14;
        preset.backgroundColor=[DAAEAccent() colorWithAlphaComponent:0.15];
        [preset setTitle:TR(@"⚡ ESP mínimo",@"⚡ Minimal ESP",@"⚡ ESP tối giản") forState:UIControlStateNormal];
        [preset setTitleColor:DAAEAccent() forState:UIControlStateNormal];
        preset.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [preset addTarget:self action:@selector(applyMinimalESP) forControlEvents:UIControlEventTouchUpInside];
        [self.scroll addSubview:preset]; y+=50;

        y=[self addSection:TR(@"Dibujo",@"Draw",@"Vẽ") y:y];
        y=[self addToggle:TR(@"Marco limpio",@"Clean box",@"Khung góc") key:@"CleanESP" fallback:YES y:y];
        y=[self addToggle:TR(@"Nombre",@"Name",@"Tên") key:@"Name" fallback:YES y:y];
        y=[self addToggle:TR(@"Barra de vida",@"Health bar",@"Thanh máu") key:@"Health" fallback:YES y:y];
        y=[self addToggle:TR(@"Ejes XYZ",@"XYZ axes",@"Trục XYZ") key:@"Line" fallback:NO y:y];
        y=[self addToggle:TR(@"Caja del jugador",@"Player box",@"Khung người") key:@"Box" fallback:YES y:y];
        y=[self addToggle:TR(@"Esqueleto",@"Skeleton",@"Xương") key:@"Skeleton" fallback:NO y:y];
        y=[self addToggle:TR(@"Punto cabeza",@"Head dot",@"Điểm đầu") key:@"HeadRedDot" fallback:NO y:y];
        y=[self addToggle:TR(@"Distancia",@"Distance",@"Khoảng cách") key:@"Dis" fallback:YES y:y];

        y=[self addSection:TR(@"Estilo caja",@"Box style",@"Kiểu khung") y:y];
        UISegmentedControl *boxSt=[[UISegmentedControl alloc] initWithItems:@[@"2D",@"3D"]];
        boxSt.frame=CGRectMake(0,y,[self contentWidth],36);
        boxSt.selectedSegmentIndex=ESPPrefsBool(@"Box3D",NO)?1:0;
        boxSt.selectedSegmentTintColor=DAAEAccent();
        [boxSt setTitleTextAttributes:@{NSForegroundColorAttributeName:DAAETextColor()} forState:UIControlStateNormal];
        [boxSt setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.1 alpha:1.0]} forState:UIControlStateSelected];
        [boxSt addTarget:self action:@selector(boxStyleChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:boxSt]; [self.controls addObject:boxSt]; y+=44;

        y=[self addSlider:TR(@"Distancia ESP",@"ESP Distance",@"Tầm ESP") key:@"ESPMaxDistance" min:50 max:500 fallback:150 y:y];
        y=[self addSlider:TR(@"Amarillo si vida ≤",@"Yellow if HP ≤",@"Vàng khi máu ≤") key:@"HealthYellowPercent" min:10 max:90 fallback:50 y:y];
        y=[self addSlider:TR(@"Rojo si vida ≤",@"Red if HP ≤",@"Đỏ khi máu ≤") key:@"HealthRedPercent" min:5 max:80 fallback:25 y:y];

    // ── 2: MISC ───────────────────────────────────────────────────────────────
    } else if(self.page==2){
        y=[self addSection:TR(@"Botones flotantes",@"Float buttons",@"Nút nổi") y:y];
        y=[self addToggle:@"Ghost" key:@"GhostModeFloating" fallback:NO y:y];
        y=[self addToggle:@"FakeLag" key:@"FakeLagFloating" fallback:NO y:y];
        y=[self addToggle:TR(@"Volar",@"Fly",@"Bay") key:@"FlyFloating" fallback:NO y:y];
        y=[self addToggle:TR(@"Ocultar botones",@"Hide buttons",@"Ẩn nút") key:@"HideFeatureButtons" fallback:NO y:y];
        y=[self addToggle:TR(@"Botón Speed",@"Speed button",@"Nút Speed") key:@"RunSpeedFloating" fallback:ESPPrefsBool(@"RunSpeed",NO) y:y];
        y=[self addSection:TR(@"Movimiento",@"Movement",@"Di chuyển") y:y];
        if(ESPPrefsBool(@"FlyFloating",NO))
            y=[self addSlider:TR(@"Altura Fly",@"Fly height",@"Độ cao Fly") key:@"FlyHeight" min:1 max:6 fallback:4 y:y];
        y=[self addToggle:TR(@"Velocidad",@"Speed",@"Speed") key:@"RunSpeed" fallback:NO y:y];
        y=[self addSection:TR(@"Efectos",@"Effects",@"Hiệu ứng") y:y];
        y=[self addToggle:TR(@"Spin (solo tú)",@"Spin (only you)",@"Spin") key:@"VisualSpin" fallback:NO y:y];
        if(ESPPrefsBool(@"VisualSpin",NO)){
            y=[self addSlider:TR(@"Vueltas/seg",@"Turns/sec",@"Vòng/giây") key:@"VisualSpinSpeed" min:0.1 max:3 fallback:0.5 y:y];
            self.spinStatusLabel=[[UILabel alloc] initWithFrame:CGRectMake(6,y,[self contentWidth]-12,36)];
            self.spinStatusLabel.textColor=DAAEMutedColor();
            self.spinStatusLabel.font=[UIFont systemFontOfSize:11]; self.spinStatusLabel.numberOfLines=2;
            [self.scroll addSubview:self.spinStatusLabel]; [self updateSpinStatus]; y+=42;
        }
        y=[self addToggle:TR(@"Ocultar en capturas",@"Hide in screen",@"Ẩn khi chụp") key:@"AnLive" fallback:NO y:y];
        y=[self addToggle:TR(@"Ahorro batería (30 FPS)",@"Save battery (30 FPS)",@"Tiết kiệm pin") key:@"BalancedRender" fallback:NO y:y];

    // ── 3: COLORES ────────────────────────────────────────────────────────────
    } else if(self.page==3){
        // COLOR DE ACENTO
        y=[self addSection:TR(@"Color de acento",@"Accent color",@"Màu nhấn") y:y];
        NSInteger curAcc=DAAEAccentIdx();
        UIView *chipRow=[[UIView alloc] initWithFrame:CGRectMake(0,y,[self contentWidth],70)];
        chipRow.backgroundColor=DAAERowBg(); chipRow.layer.cornerRadius=14;
        chipRow.layer.borderWidth=0.6; chipRow.layer.borderColor=DAAERowBorder().CGColor;
        CGFloat cW=38,cH=38,cGap=9;
        CGFloat totalCW=6*cW+5*cGap;
        CGFloat cStartX=([self contentWidth]-totalCW)/2.0;
        for(NSInteger k=0;k<6;k++){
            UIButton *chip=[UIButton buttonWithType:UIButtonTypeCustom];
            chip.frame=CGRectMake(cStartX+k*(cW+cGap),16,cW,cH);
            chip.backgroundColor=DAAEAccents()[k];
            chip.layer.cornerRadius=cW/2.0;
            chip.layer.borderWidth=(k==curAcc)?2.5:0;
            chip.layer.borderColor=UIColor.whiteColor.CGColor;
            chip.tag=600+k;
            [chip addTarget:self action:@selector(accentTap:) forControlEvents:UIControlEventTouchUpInside];
            [chipRow addSubview:chip];
        }
        [self.scroll addSubview:chipRow]; y+=76;

        // COLOR TEXTO "DAAE IOS"
        y=[self addSection:TR(@"Color texto DAAE IOS",@"DAAE IOS text color",@"Màu chữ DAAE IOS") y:y];
        y=[self buildColorPickerRow:TR(@"DAAE IOS",@"DAAE IOS",@"DAAE IOS")
                          colorKey:@"DAAE.textColorIdx"
                         expandKey:@"DAAE.textColorExpand"
                       currentIdx:DAAETextColorIdx() y:y];

        // COLOR ENEMIGOS
        y=[self addSection:TR(@"Color enemigos",@"Enemy color",@"Màu kẻ địch") y:y];
        y=[self buildColorPickerRow:TR(@"Enemigos",@"Enemies",@"Kẻ địch")
                          colorKey:@"DAAE.enemyColorIdx"
                         expandKey:@"DAAE.enemyColorExpand"
                       currentIdx:DAAEEnemyColorIdx() y:y];

        // COLORES ESP
        y=[self addSection:TR(@"Colores ESP",@"ESP Colors",@"Màu ESP") y:y];
        // Selector Marco / FOV
        UISegmentedControl *espSeg=[[UISegmentedControl alloc]
            initWithItems:@[TR(@"Marco",@"Box",@"Hộp"),@"FOV"]];
        espSeg.frame=CGRectMake(0,y,[self contentWidth],36);
        espSeg.selectedSegmentIndex=self.colorESPTarget;
        espSeg.selectedSegmentTintColor=DAAEAccent();
        [espSeg setTitleTextAttributes:@{NSForegroundColorAttributeName:DAAETextColor()} forState:UIControlStateNormal];
        [espSeg setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:0.08 alpha:1.0]} forState:UIControlStateSelected];
        [espSeg addTarget:self action:@selector(colorESPTargetChanged:) forControlEvents:UIControlEventValueChanged];
        [self.scroll addSubview:espSeg]; [self.controls addObject:espSeg]; y+=44;

        NSString *pfx=(self.colorESPTarget==1)?@"FovColor":@"BoxColor";
        NSArray *rgbN=@[TR(@"Rojo",@"Red",@"Đỏ"),TR(@"Verde",@"Green",@"Xanh lá"),TR(@"Azul",@"Blue",@"Xanh lam")];
        NSArray *rgbS=@[@"R",@"G",@"B"];
        float rgbD[3]={0.46f,0.86f,0.73f};
        for(int i=0;i<3;i++)
            y=[self addSlider:rgbN[i] key:[pfx stringByAppendingString:rgbS[i]] min:0 max:1 fallback:rgbD[i] y:y];

    // ── 4: SETTINGS ───────────────────────────────────────────────────────────
    } else {
        y=[self addSection:TR(@"Apariencia",@"Appearance",@"Giao diện") y:y];
        y=[self addToggle:TR(@"Modo oscuro",@"Dark mode",@"Giao diện tối") key:@"DarkTheme" fallback:YES y:y];

        y=[self addSection:TR(@"Idioma",@"Language",@"Ngôn ngữ") y:y];
        UIView *langRow=[[UIView alloc] initWithFrame:CGRectMake(0,y,[self contentWidth],46)];
        langRow.backgroundColor=DAAERowBg(); langRow.layer.cornerRadius=14;
        langRow.layer.borderWidth=0.6; langRow.layer.borderColor=DAAERowBorder().CGColor;
        NSArray *codes=@[@"ES",@"EN",@"VI"];
        CGFloat lbW=56,lbH=30,lgap=8;
        CGFloat lTot=3*lbW+2*lgap;
        CGFloat lSX=([self contentWidth]-lTot)/2.0;
        NSInteger curL=DAAELang();
        for(NSInteger k=0;k<3;k++){
            UIButton *lb=[UIButton buttonWithType:UIButtonTypeCustom];
            lb.frame=CGRectMake(lSX+k*(lbW+lgap),8,lbW,lbH);
            lb.backgroundColor=(k==curL)?DAAEAccent():[UIColor colorWithWhite:0.5 alpha:0.15];
            lb.layer.cornerRadius=10;
            [lb setTitle:codes[k] forState:UIControlStateNormal];
            lb.titleLabel.font=[UIFont systemFontOfSize:13 weight:UIFontWeightBold];
            [lb setTitleColor:(k==curL)?[UIColor colorWithWhite:0.1 alpha:1.0]:DAAETextColor() forState:UIControlStateNormal];
            NSInteger li=k;
            objc_setAssociatedObject(lb,"langIdx",@(li),OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [lb addTarget:self action:@selector(langTap:) forControlEvents:UIControlEventTouchUpInside];
            [langRow addSubview:lb];
        }
        [self.scroll addSubview:langRow]; y+=54;

        y=[self addSection:TR(@"Acerca de",@"About",@"Giới thiệu") y:y];
        NSArray *infoT=@[TR(@"Producto",@"Product",@"Sản phẩm"),TR(@"Creador",@"Creator",@"Người tạo"),@"Telegram"];
        NSArray *infoV=@[@"DAAE IOS",@"@didierxit7",@"t.me/didierxit7"];
        for(NSInteger k=0;k<3;k++){
            UIButton *infoRow=[UIButton buttonWithType:UIButtonTypeCustom];
            infoRow.frame=CGRectMake(0,y,[self contentWidth],46);
            infoRow.backgroundColor=DAAERowBg();
            infoRow.layer.cornerRadius=14; infoRow.layer.borderWidth=0.6;
            infoRow.layer.borderColor=DAAERowBorder().CGColor;
            CGFloat rw=[self contentWidth];
            UILabel *tl=[[UILabel alloc] initWithFrame:CGRectMake(16,0,rw*0.46,46)];
            tl.text=infoT[k]; tl.textColor=DAAETextColor();
            tl.font=[UIFont systemFontOfSize:14 weight:UIFontWeightMedium]; [infoRow addSubview:tl];
            BOOL isTg=(k==2);
            UILabel *vl=[[UILabel alloc] initWithFrame:CGRectMake(rw*0.46,0,rw*0.46,46)];
            vl.text=infoV[k]; vl.textColor=isTg?DAAEAccent():DAAEMutedColor();
            vl.font=[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
            vl.textAlignment=NSTextAlignmentRight; [infoRow addSubview:vl];
            if(isTg){
                UIImageView *ar=[[UIImageView alloc] initWithImage:SFSym(@"arrow.up.right",10,UIImageSymbolWeightBold)];
                ar.tintColor=DAAEMutedColor(); ar.frame=CGRectMake(rw-26,17,12,12);
                ar.contentMode=UIViewContentModeScaleAspectFit; [infoRow addSubview:ar];
                [infoRow addTarget:self action:@selector(openTelegram) forControlEvents:UIControlEventTouchUpInside];
            }
            [self.scroll addSubview:infoRow]; y+=52;
        }
    }

    // Pie
    UILabel *credit=[[UILabel alloc] initWithFrame:CGRectMake(0,y+10,[self contentWidth],18)];
    credit.text=@"DAAE IOS";
    credit.textColor=[UIColor colorWithWhite:0.5 alpha:0.25];
    credit.font=[UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    credit.textAlignment=NSTextAlignmentCenter; [self.scroll addSubview:credit]; y+=34;

    self.scroll.contentSize=CGSizeMake([self contentWidth],y+4);
    self.scroll.contentOffset=CGPointMake(0,MAX(0,MIN(offset,y+4-self.scroll.bounds.size.height)));
}

// ─── COLOR PICKER ROW (expandible inline) ────────────────────────────────────
- (CGFloat)buildColorPickerRow:(NSString *)rowTitle
                      colorKey:(NSString *)colorKey
                     expandKey:(NSString *)expandKey
                   currentIdx:(NSInteger)curIdx
                             y:(CGFloat)y {
    CGFloat w=[self contentWidth];
    BOOL expanded=[[NSUserDefaults standardUserDefaults] boolForKey:expandKey];

    UIButton *hdr=[UIButton buttonWithType:UIButtonTypeCustom];
    hdr.frame=CGRectMake(0,y,w,46);
    hdr.backgroundColor=DAAERowBg(); hdr.layer.cornerRadius=14;
    hdr.layer.borderWidth=0.6; hdr.layer.borderColor=DAAERowBorder().CGColor;
    hdr.contentHorizontalAlignment=UIControlContentHorizontalAlignmentLeft;
    hdr.contentEdgeInsets=UIEdgeInsetsMake(0,16,0,16);

    // Círculo del color actual
    UIView *dot=[[UIView alloc] initWithFrame:CGRectMake(w-54,13,20,20)];
    dot.backgroundColor=DAAEAccents()[curIdx]; dot.layer.cornerRadius=10;
    dot.userInteractionEnabled=NO; [hdr addSubview:dot];
    UILabel *arw=[[UILabel alloc] initWithFrame:CGRectMake(w-30,0,20,46)];
    arw.text=expanded?@"▲":@"▼"; arw.textColor=DAAEMutedColor();
    arw.font=[UIFont systemFontOfSize:11]; arw.textAlignment=NSTextAlignmentCenter;
    arw.userInteractionEnabled=NO; [hdr addSubview:arw];
    [hdr setTitle:rowTitle forState:UIControlStateNormal];
    [hdr setTitleColor:DAAETextColor() forState:UIControlStateNormal];
    hdr.titleLabel.font=[UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    objc_setAssociatedObject(hdr,"cpExpandKey",expandKey,OBJC_ASSOCIATION_COPY_NONATOMIC);
    [hdr addTarget:self action:@selector(colorPickerHdrTap:) forControlEvents:UIControlEventTouchUpInside];
    [self.scroll addSubview:hdr]; y+=52;

    if(expanded){
        UIView *chipRow=[[UIView alloc] initWithFrame:CGRectMake(0,y,w,68)];
        chipRow.backgroundColor=DAAERowBg(); chipRow.layer.cornerRadius=14;
        chipRow.layer.borderWidth=0.6; chipRow.layer.borderColor=DAAERowBorder().CGColor;
        CGFloat cW=36,cH=36,cGap=8;
        CGFloat totW=6*cW+5*cGap;
        CGFloat sx=(w-totW)/2.0;
        for(NSInteger k=0;k<6;k++){
            UIButton *chip=[UIButton buttonWithType:UIButtonTypeCustom];
            chip.frame=CGRectMake(sx+k*(cW+cGap),16,cW,cH);
            chip.backgroundColor=DAAEAccents()[k];
            chip.layer.cornerRadius=cW/2.0;
            chip.layer.borderWidth=(k==curIdx)?2.5:0;
            chip.layer.borderColor=UIColor.whiteColor.CGColor;
            // Tag alto para diferenciarlo del selector de acento
            chip.tag=700+k;
            objc_setAssociatedObject(chip,"cpColorKey",colorKey,OBJC_ASSOCIATION_COPY_NONATOMIC);
            objc_setAssociatedObject(chip,"cpExpandKey",expandKey,OBJC_ASSOCIATION_COPY_NONATOMIC);
            [chip addTarget:self action:@selector(colorPickerChipTap:) forControlEvents:UIControlEventTouchUpInside];
            [chipRow addSubview:chip];
        }
        [self.scroll addSubview:chipRow]; y+=74;
    }
    return y;
}

// ─── ACCIONES ────────────────────────────────────────────────────────────────
- (void)closeMenu   { if(self.onCloseBlock)self.onCloseBlock(); }
- (void)chooseAim   { self.aimExpanded=!self.aimExpanded; [self rebuildAnimated]; }
- (void)toggleAdvanced { self.advancedExpanded=!self.advancedExpanded; [self rebuildAnimated]; }
- (void)openTelegram {
    NSURL *u=[NSURL URLWithString:@"https://t.me/didierxit7"];
    if(u)[UIApplication.sharedApplication openURL:u options:@{} completionHandler:nil];
}
- (void)toggleTheme {
    self.darkMode=!self.darkMode; ESPPrefsSetBool(@"DarkTheme",self.darkMode); [self rebuildAnimated];
}
- (void)accentTap:(UIButton *)sender {
    NSInteger idx=sender.tag-600;
    if(idx<0||idx>5)return;
    [[NSUserDefaults standardUserDefaults] setInteger:idx forKey:@"DAAE.accentIdx"];
    [self rebuildAnimated];
}
- (void)colorESPTargetChanged:(UISegmentedControl *)seg {
    self.colorESPTarget=seg.selectedSegmentIndex; [self buildPage];
}
- (void)colorPickerHdrTap:(UIButton *)sender {
    NSString *ek=objc_getAssociatedObject(sender,"cpExpandKey");
    if(!ek)return;
    NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
    [ud setBool:![ud boolForKey:ek] forKey:ek];
    [self rebuildAnimated];
}
- (void)colorPickerChipTap:(UIButton *)sender {
    NSString *ck=objc_getAssociatedObject(sender,"cpColorKey");
    NSString *ek=objc_getAssociatedObject(sender,"cpExpandKey");
    if(!ck)return;
    NSInteger idx=sender.tag-700;
    if(idx<0||idx>5)return;
    [[NSUserDefaults standardUserDefaults] setInteger:idx forKey:ck];
    // Si es enemyColor, propagamos a ESP preferences
    if([ck isEqualToString:@"DAAE.enemyColorIdx"]){
        UIColor *c=DAAEAccents()[idx];
        CGFloat r=0,g=0,b=0,a=0; [c getRed:&r green:&g blue:&b alpha:&a];
        ESPPrefsSetFloat(@"BoxColorR",r); ESPPrefsSetFloat(@"BoxColorG",g); ESPPrefsSetFloat(@"BoxColorB",b);
        ESPSyncFromPrefs();
    }
    (void)ek;
    [self rebuildAnimated];
}
- (void)langTap:(UIButton *)sender {
    NSNumber *n=objc_getAssociatedObject(sender,"langIdx");
    if(n){DAAESetLang(n.integerValue);[self rebuildAnimated];}
}
- (void)boxStyleChanged:(UISegmentedControl *)sender {
    ESPPrefsSetBool(@"Box3D",sender.selectedSegmentIndex==1);
    ESPPrefsSetBool(@"Box",YES);
    if(sender.selectedSegmentIndex==1)ESPPrefsSetBool(@"CleanESP",NO);
    ESPSyncFromPrefs();
}
- (void)applyMinimalESP {
    for(NSString *k in @[@"ESPEnabled",@"Box",@"Health",@"Name",@"Dis",@"CleanESP"])ESPPrefsSetBool(k,YES);
    for(NSString *k in @[@"Line",@"Skeleton",@"HeadRedDot",@"Box3D",@"BalancedRender"])ESPPrefsSetBool(k,NO);
    for(NSString *pfx in @[@"BoxColor",@"LineColor",@"FovColor"]){
        ESPPrefsSetFloat([pfx stringByAppendingString:@"R"],0.46);
        ESPPrefsSetFloat([pfx stringByAppendingString:@"G"],0.86);
        ESPPrefsSetFloat([pfx stringByAppendingString:@"B"],0.73);
    }
    ESPSyncFromPrefs(); [self buildPage];
}
- (void)toggleChanged:(NSString *)key value:(BOOL)on {
    if([@[@"GhostModeFloating",@"FakeLagFloating",@"AutoFireFloating",@"FlyFloating"] containsObject:key]){
        NSString *feat=[key stringByReplacingOccurrencesOfString:@"Floating" withString:@""];
        ESPPrefsSetBool(feat,on);
        if(on)ESPPrefsSetBool(@"HideFeatureButtons",NO);
    }
    if([key isEqualToString:@"CleanESP"]&&on)ESPPrefsSetBool(@"Box3D",NO);
    if([key isEqualToString:@"RunSpeed"]&&!AppSettingsObjectForKey(@"RunSpeedFloating"))
        ESPPrefsSetBool(@"RunSpeedFloating",YES);
    if([key isEqualToString:@"AnLive"]&&![UIView applyCaptureProtectionToRegisteredViews:on])
        {ESPPrefsSetBool(@"AnLive",NO);[UIView applyCaptureProtectionToRegisteredViews:NO];}
    if([key isEqualToString:@"DarkTheme"]){self.darkMode=on;[self rebuildAnimated];}
    if([@[@"SilentAutoConfig",@"AutoFireFloating",@"FlyFloating",@"VisualSpin"] containsObject:key])
        [self rebuildAnimated];
}
- (void)updateSpinStatus {
    const auto st=PlayerModesRead();
    NSString *text=TR(@"Spin: esperando ciclo",@"Spin: waiting for tick",@"Spin: chờ tick");
    if(st.detail&&st.detail[0])text=[NSString stringWithUTF8String:st.detail];
    else if(st.spinStatus==1)text=TR(@"Spin: esperando personaje",@"Spin: waiting character",@"Spin: chờ nhân vật");
    else if(st.spinStatus==2)text=TR(@"Spin: sin modelo",@"Spin: no model",@"Spin: không có mô hình");
    else if(st.spinStatus==3)text=TR(@"Spin: esperando ángulo",@"Spin: waiting angle",@"Spin: chờ góc");
    else if(st.spinStatus==4)text=[NSString stringWithFormat:TR(@"Spin: activo · %llu",@"Spin: active · %llu",@"Spin: đang dùng · %llu"),(unsigned long long)st.spinApplies];
    self.spinStatusLabel.text=text;
}
- (void)dealloc { [self.spinStatusTimer invalidate]; }

// ─── DRAG ─────────────────────────────────────────────────────────────────────
- (void)dragPanel:(UIPanGestureRecognizer *)pan {
    if(pan.state==UIGestureRecognizerStateBegan)self.panelOrigin=self.panel.frame.origin;
    CGPoint d=[pan translationInView:self.view];
    CGRect f=self.panel.frame;
    f.origin=CGPointMake(self.panelOrigin.x+d.x,self.panelOrigin.y+d.y);
    self.panel.frame=f; self.blurBG.frame=f; [self viewDidLayoutSubviews];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer*)g shouldReceiveTouch:(UITouch*)t {
    for(UIView*v=t.view;v&&v!=g.view;v=v.superview)
        if([v isKindOfClass:UIControl.class])return NO;
    return YES;
}

// ─── TOUCH ROUTING ───────────────────────────────────────────────────────────
- (BOOL)_0xF010:(CGPoint)point phase:(NSInteger)phase pointerId:(NSInteger)pointerId {
    if(phase==UITouchPhaseBegan){
        if(!CGRectContainsPoint(self.panel.frame,point))return NO;
        if(self.pointer!=-1)return YES;
        self.pointer=pointerId; self.began=point;
        self.panelOrigin=self.panel.frame.origin;
        self.scrollOrigin=self.scroll.contentOffset.y;
        self.scrolling=NO; self.activeControl=nil;
        CGPoint local=[self.panel convertPoint:point fromView:self.view];
        self.dragging=(local.x<72)||(local.y<44&&local.x<self.panel.bounds.size.width-40);
        if(self.dragging)return YES;
        CGPoint scrollLocal=[self.scroll convertPoint:point fromView:self.view];
        for(UIControl *c in self.controls){
            if(!c.enabled)continue;
            if(CGRectContainsPoint([c convertRect:c.bounds toView:self.scroll],scrollLocal))
                {self.activeControl=c;break;}
        }
        return YES;
    }
    if(self.pointer!=pointerId)return NO;
    CGFloat dx=point.x-self.began.x,dy=point.y-self.began.y;
    if(phase==UITouchPhaseMoved){
        if(self.dragging){
            CGRect f=self.panel.frame;
            f.origin=CGPointMake(self.panelOrigin.x+dx,self.panelOrigin.y+dy);
            self.panel.frame=f; self.blurBG.frame=f; [self viewDidLayoutSubviews];
        } else if(fabs(dy)>6||self.scrolling){
            self.scrolling=YES;
            CGFloat maxY=MAX(0,self.scroll.contentSize.height-self.scroll.bounds.size.height);
            self.scroll.contentOffset=CGPointMake(0,MAX(0,MIN(maxY,self.scrollOrigin-dy)));
        }
        return YES;
    }
    if(phase==UITouchPhaseEnded||phase==UITouchPhaseCancelled){
        BOOL act=phase==UITouchPhaseEnded&&!self.dragging&&!self.scrolling&&fabs(dx)<24&&fabs(dy)<24;
        UIControl *ctrl=self.activeControl;
        self.pointer=-1; self.activeControl=nil;
        if(act&&ctrl&&ctrl.enabled)[ctrl sendActionsForControlEvents:UIControlEventTouchUpInside];
        return YES;
    }
    return YES;
}
@end

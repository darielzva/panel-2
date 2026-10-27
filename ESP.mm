#import "ESP.h"

static ESP::DrawCallback gDraw;

@interface MMOverlay : UIView
@property (nonatomic, strong) CADisplayLink *link;
@end

@implementation MMOverlay

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;   // no bloquea los toques del juego
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
        [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)tick {
    if (ESP::Config().enabled) {
        self.hidden = NO;
        [self setNeedsDisplay];
    } else {
        self.hidden = YES;
    }
}

- (void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx || !gDraw) return;
    gDraw(ctx, self.bounds.size);
}

@end

namespace ESP {

ESPConfig &Config() {
    static ESPConfig c;
    return c;
}

void SetDrawCallback(DrawCallback cb) { gDraw = std::move(cb); }

static UIWindow *FindWindow() {
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (![s isKindOfClass:UIWindowScene.class]) continue;
        if (s.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *w in ((UIWindowScene *)s).windows)
            if (w.isKeyWindow) return w;
    }
    return nil;
}

static void Attach(int attempt) {
    UIWindow *win = FindWindow();
    if (!win) {
        if (attempt < 30)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{ Attach(attempt + 1); });
        return;
    }
    MMOverlay *ov = [[MMOverlay alloc] initWithFrame:win.bounds];
    ov.hidden = YES;
    [win addSubview:ov];
}

void Start() {
    dispatch_async(dispatch_get_main_queue(), ^{ Attach(0); });
}

} // namespace ESP

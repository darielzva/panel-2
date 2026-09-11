//Require standard library
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <Foundation/Foundation.h>
#include <iostream>
#include <UIKit/UIKit.h>
#include <vector>
#import "pthread.h"
#include <array>
#import <os/log.h>
#include <cmath>
#include <deque>
#include <fstream>
#include <algorithm>
#include <string>
#include <sstream>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <cstdint>
#include <cinttypes>
#include <cerrno>
#include <cctype>
//Imgui library
#import "Esp/CaptainHook.h"
#import "Esp/ImGuiDrawView.h"
#import "IMGUI/imgui.h"
#import "IMGUI/imgui_internal.h"
#import "IMGUI/imgui_impl_metal.h"
#import "IMGUI/zzz.h"
#include "oxorany/oxorany_include.h"
#import "Helper/Mem.h"
#include "font.h"
//import "Hosts/NSObject+URL.h"
#import "Helper/Vector3.h"
#import "Helper/Vector2.h"
#import "Helper/Quaternion.h"
#import "Helper/Monostring.h"
#include "Helper/font.h"
#include "Helper/data.h"
ImFont* verdana_smol;
ImFont* pixel_big = {};
ImFont* pixel_smol = {};
#include "Helper/Obfuscate.h"
#import "Helper/Hooks.h"
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <unistd.h>
#include <string.h>
#include "Other/dobby_defines.h"
#import "Other/H5hook.h"
#include "Other/Paste.h"

#define Hook(x, y, z) \
{ \
    NSString* result_##y = StaticInlineHookPatch(("Frameworks/UnityFramework.framework/UnityFramework"), x, nullptr); \
    if (result_##y) { \
        void* result = StaticInlineHookFunction(("Frameworks/UnityFramework.framework/UnityFramework"), x, (void *) y); \
        *(void **) (&z) = (void*) result; \
    } \
}

static float fixLoginTimeout = 60.0f;

static bool MenDeal = true;

static char menuTitle[64] = "VN TOOL IPA VIP "; 



@interface ImGuiDrawView () <MTKViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) id <MTLDevice> device;

@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;

@property (nonatomic, strong) UITextField *invisibleTextField;

@property (nonatomic, readonly) MTKView *mtkView; 

@end



@implementation ImGuiDrawView

ImFont *_espFont;

ImFont* verdanab;

ImFont* icons;

ImFont* interb;

ImFont* Urbanist;



- (MTKView *)mtkView { return (MTKView *)self.view; }



- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil bundle:(nullable NSBundle *)nibBundleOrNil

{

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    _device = MTLCreateSystemDefaultDevice();

    _commandQueue = [_device newCommandQueue];

    if (!self.device) abort();



    IMGUI_CHECKVERSION();

    ImGui::CreateContext();

    ImGuiIO& io = ImGui::GetIO(); (void)io;



    // Chuyển sang Light Style làm nền tảng cho màu trắng

    ImGui::StyleColorsLight();

    auto& Style = ImGui::GetStyle();

    

    // --- GIỮ NGUYÊN CÁC BIẾN STYLE CỦA BẠN NHƯNG CHỈNH LẠI SỐ CHO MƯỢT ---

    Style.WindowRounding = 10.0f;    // Tăng nhẹ độ bo cho mượt mắt

    Style.FrameRounding = 6.0f;      

    Style.ChildRounding = 6.0f;

    Style.GrabRounding = 10.0f;     // Bo tròn nút kéo slider

    Style.TabRounding = 8.0f;       

    Style.ScrollbarRounding = 12.0f; 

    

    Style.WindowBorderSize = 0.0f;  // Bỏ viền đen để menu trông nhẹ nhàng hơn

    Style.FrameBorderSize = 1.0f;   // Giữ viền nhẹ cho các ô nhập liệu



    // --- BẢNG MÀU TRẮNG NHẸ NHÀNG ---

    ImVec4* colors = ImGui::GetStyle().Colors;

    colors[ImGuiCol_Text]                   = ImVec4(0.15f, 0.15f, 0.15f, 1.00f); // Chữ xám đậm dễ nhìn

    colors[ImGuiCol_WindowBg]               = ImVec4(0.98f, 0.98f, 0.98f, 1.00f); // Nền trắng tinh khôi

    colors[ImGuiCol_TitleBgActive]          = ImVec4(0.00f, 0.45f, 0.90f, 1.00f); // Thanh tiêu đề xanh Blue dịu

    colors[ImGuiCol_CheckMark]              = ImVec4(0.00f, 0.45f, 0.90f, 1.00f); // Tích màu xanh cho đồng bộ

    colors[ImGuiCol_SliderGrab]             = ImVec4(0.00f, 0.45f, 0.90f, 0.80f); 

    colors[ImGuiCol_Button]                 = ImVec4(0.00f, 0.45f, 0.90f, 0.10f); // Nút trong suốt nhẹ

    colors[ImGuiCol_ButtonHovered]          = ImVec4(0.00f, 0.45f, 0.90f, 0.25f); 

    colors[ImGuiCol_Header]                 = ImVec4(0.00f, 0.45f, 0.90f, 0.20f); 

    colors[ImGuiCol_TabActive]              = ImVec4(0.00f, 0.45f, 0.90f, 1.00f);



    // Font giữ nguyên như code cũ của bạn

    ImFont* font = io.Fonts->AddFontFromMemoryTTF(sansbold, sizeof(sansbold), 15.0f, NULL, io.Fonts->GetGlyphRangesCyrillic());

    verdana_smol = io.Fonts->AddFontFromMemoryTTF(verdana, sizeof verdana, 40, NULL, io.Fonts->GetGlyphRangesCyrillic());

    pixel_big = io.Fonts->AddFontFromMemoryTTF((void*)smallestpixel, sizeof smallestpixel, 128, NULL, io.Fonts->GetGlyphRangesCyrillic());

    pixel_smol = io.Fonts->AddFontFromMemoryTTF((void*)smallestpixel, sizeof smallestpixel, 10*2, NULL, io.Fonts->GetGlyphRangesCyrillic());

    

    ImGui_ImplMetal_Init(_device);

    return self;

}



- (void)loadView {

    self.view = [[MTKView alloc] initWithFrame:[UIScreen mainScreen].bounds];

}



- (void)viewDidLoad {

    [super viewDidLoad];

    self.mtkView.device = self.device;

    self.mtkView.delegate = self;

    self.mtkView.clearColor = MTLClearColorMake(0, 0, 0, 0);

    self.mtkView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];

    self.mtkView.clipsToBounds = YES;



    self.invisibleTextField = [[UITextField alloc] initWithFrame:CGRectZero];

    self.invisibleTextField.delegate = self;

    [self.invisibleTextField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    [self.view addSubview:self.invisibleTextField];



Hook(oxo("0x4EB3E88") , BLAGCMCGEJG1, old_BLAGCMCGEJG1);

Hook(0x1C2549C, Hook_UpdateLocalMark, orig_UpdateLocalMark);

Hook(0x56524D4 , old_AutoFire, _AutoFire);

Hook(0x44C752C, hk_get_ResetGuest, old_get_ResetGuest);

}



- (void)textFieldDidChange:(UITextField *)textField {

    if (textField.text.length > 0) {

        strncpy(menuTitle, [textField.text UTF8String], sizeof(menuTitle) - 1);

    } else {

        strcpy(menuTitle, " "); 

    }

}



- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [textField resignFirstResponder];

    return YES;

}



#pragma mark - Interaction

- (void)updateIOWithTouchEvent:(UIEvent *)event {

    UITouch *anyTouch = event.allTouches.anyObject;

    CGPoint touchLocation = [anyTouch locationInView:self.view];

    ImGuiIO &io = ImGui::GetIO();

    io.MousePos = ImVec2(touchLocation.x, touchLocation.y);

    BOOL hasActiveTouch = NO;

    for (UITouch *touch in event.allTouches) {

        if (touch.phase != UITouchPhaseEnded && touch.phase != UITouchPhaseCancelled) {

            hasActiveTouch = YES;

            break;

        }

    }

    io.MouseDown[0] = hasActiveTouch;

}

- (void)touchesBegan:(NSSet*)t withEvent:(UIEvent*)e { [self updateIOWithTouchEvent:e]; }

- (void)touchesMoved:(NSSet*)t withEvent:(UIEvent*)e { [self updateIOWithTouchEvent:e]; }

- (void)touchesEnded:(NSSet*)t withEvent:(UIEvent*)e { [self updateIOWithTouchEvent:e]; }

- (void)touchesCancelled:(NSSet*)t withEvent:(UIEvent*)e { [self updateIOWithTouchEvent:e]; }



#pragma mark - Render Loop



- (void)drawInMTKView:(MTKView*)view {

    ImGuiIO& io = ImGui::GetIO();

    io.DisplaySize = ImVec2(view.bounds.size.width, view.bounds.size.height);

    CGFloat scale = view.window.screen.nativeScale ?: UIScreen.mainScreen.nativeScale;

    io.DisplayFramebufferScale = ImVec2(scale, scale);

    io.DeltaTime = 1 / float(view.preferredFramesPerSecond ?: 60);

    

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];

    [self.view setUserInteractionEnabled:MenDeal];



    MTLRenderPassDescriptor* desc = view.currentRenderPassDescriptor;

    if (desc != nil) {

        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:desc];

        ImGui_ImplMetal_NewFrame(desc);

        ImGui::NewFrame();



        if (MenDeal) {

            ImGui::SetNextWindowSize(ImVec2(420, 280), ImGuiCond_FirstUseEver); 

            

            ImGui::Begin(menuTitle, &MenDeal);



            if (ImGui::BeginTabBar("Tabs")) {

                

                // TAB INFO DEVELOPER

                if (ImGui::BeginTabItem("Info Developer")) {

                    ImGui::TextColored(ImVec4(0,1,1,1), "RENAME MENU");

                    if (ImGui::InputText("##rename", menuTitle, sizeof(menuTitle), ImGuiInputTextFlags_EnterReturnsTrue)) {

                        if (strlen(menuTitle) == 0) strcpy(menuTitle, " ");

                    }

                    if (ImGui::IsItemClicked()) {

                        self.invisibleTextField.text = [NSString stringWithUTF8String:menuTitle];

                        [self.invisibleTextField becomeFirstResponder];

                    }

                    if (ImGui::Button("Close Keyboard")) [self.view endEditing:YES];

                    ImGui::Separator();

                    ImGui::TextDisabled("@minhiosne");

                    ImGui::EndTabItem();

                }



                // TAB ESP

                if (ImGui::BeginTabItem("ESP")) {

                    ImGui::Checkbox("Enable Cheats", &Vars.Enable);

                    if (ImGui::BeginTable("split", 4)) {

                        ImGui::TableNextColumn(); ImGui::Checkbox("Line", &Vars.lines);

                        ImGui::TableNextColumn(); ImGui::Checkbox("Box", &Vars.Box);

                        ImGui::TableNextColumn(); ImGui::Checkbox("Health", &Vars.Health);

                        ImGui::TableNextColumn(); ImGui::Checkbox("Name", &Vars.Name);

                        ImGui::TableNextColumn(); ImGui::Checkbox("Skeleton", &Vars.skeleton);

                        ImGui::TableNextColumn(); ImGui::Checkbox("Distance", &Vars.Distance);

                        ImGui::TableNextColumn(); ImGui::Checkbox("3D Circle", &Vars.circlepos);

                        ImGui::TableNextColumn(); ImGui::Checkbox("Outline", &Vars.Outline);

                        ImGui::TableNextColumn(); ImGui::Checkbox("OOF", &Vars.OOF);

                        ImGui::TableNextColumn(); ImGui::Checkbox("Count", &Vars.enemycount);

                        ImGui::EndTable();

                    }

                    ImGui::EndTabItem();

                }



                // TAB AIMBOT

                if (ImGui::BeginTabItem("AimBot")) {

                    ImGui::Spacing();

                    ImGui::Checkbox("Enable Aimbot", &Vars.Aimbot);

                    ImGui::Checkbox("Visible", &Vars.VisibleCheck);

                    ImGui::Checkbox("Knocked", &Vars.IgnoreKnocked); 

                    ImGui::Combo("##1", &Vars.AimWhen, Vars.dir, 4);

                    ImGui::Combo("##2", &Vars.AimHitbox, Vars.aimHitboxes, 3);

                    ImGui::Combo("## mode", &Vars.AimMode, Vars.aimModes, 3);

                    ImGui::Checkbox("ResetGuest", &ResetGuest);

                    ImGui::Checkbox("Teleport to Mark", &Vars.TeleportMark1);

                    ImGui::Checkbox("Tele 10m", &Vars.Tele10M);

                    ImGui::Checkbox("Keo Dich", &Vars.AiPlayer2);

                    ImGui::Checkbox("Pull player", &Vars.PullPlayer);

                    ImGui::Checkbox("Auto Chay", &Vars.FlyGravity);

                    if (Vars.FlyGravity) {

                        ImGui::Indent();

                        ImGui::SliderFloat("Toc do chay", &Vars.FlyGravitySpeed, 0.0f, 100.0f, "%.1f");

                        ImGui::SliderFloat("Do nhay cao", &Vars.FlyUpForce, 0.0f, 30.0f, "%.1f");

                        ImGui::Unindent();

                    }



                    if (ImGui::Checkbox("Sieu Antiban VIP", &antiban_thanhprd)) {

                        if (antiban_thanhprd) {

                            ApplyAllBypassHooks();

                        }

                    }                        

                    

                    if (Vars.AimMode == 2) {

                        ImGui::SliderFloat("AimFov", &Vars.AimFov, 0.0f, 360.0f, "Fov %.0f");

                    }

                    ImGui::EndTabItem();

                }



                // TAB MOD SKIN

                if (ImGui::BeginTabItem("Mod Skin VIP")) {

                    ImGui::Spacing();

                    ImGui::TextColored(ImVec4(1, 0, 0, 1), "mod skin igg fifai");

                    ImGui::Separator();



                    if (ImGui::Checkbox("cam co", &s_camco)) {

                        modSkin(new JRMemoryEngine(mach_task_self()), s_camco, 909000001, 909000034);

                    }

                    if (ImGui::Checkbox("Mp40 Mang Xa ", &s_mp40_v7)) {

                        modSkin(new JRMemoryEngine(mach_task_self()), s_mp40_v7, 909000001, 909000068);

                    }

                    if (ImGui::Checkbox("Mp40 Lv8 ", &s_mp40_v8)) {

                        modSkin(new JRMemoryEngine(mach_task_self()), s_mp40_v8, 909000001, 909040010);

                    }

                    if (ImGui::Checkbox("M1014 (V1)", &s_m1014_v8_1)) {

                        modSkin(new JRMemoryEngine(mach_task_self()), s_m1014_v8_1, 909000001, 909000085);

                    }

                    if (ImGui::Checkbox("M1014 (V2)", &s_m1014_v8_2)) {

                        modSkin(new JRMemoryEngine(mach_task_self()), s_m1014_v8_2, 909000001, 909039011);

                    }

                    if (ImGui::Checkbox("Ump Lv7", &s_ump_v7)) {

                        modSkin(new JRMemoryEngine(mach_task_self()), s_ump_v7, 909000001, 909000098);

                    }

                    if (ImGui::Checkbox("Ak Lv7", &s_ak_v7)) {

                        modSkin(new JRMemoryEngine(mach_task_self()), s_ak_v7, 909000001, 909000063);

                    }

                    if (ImGui::Checkbox("An94 Lv7", &s_an94_v7)) {

                        modSkin(new JRMemoryEngine(mach_task_self()), s_an94_v7, 909000001, 909035012);

                    }

                    if (ImGui::Checkbox("Thomson Lv7", &s_thomson_v7)) {

                        modSkin(new JRMemoryEngine(mach_task_self()), s_thomson_v7, 909000001, 909038010);

                    }



                    ImGui::Separator();

                    if (ImGui::Button("RESET ALL SKIN")) { }

                    ImGui::EndTabItem();

                }



                // TAB EXTRA

                if (ImGui::BeginTabItem("Extra")) {

                    ImGui::Spacing();

                    ImGui::Checkbox("SilentAim", &SilentAim);

                    ImGui::Checkbox("CheckIsVisible", &CheckWall1);

                    ImGui::Checkbox("xoay xoay", &spin360); 

                    if (spin360) {

                        ImGui::Indent(); 

                        ImGui::SliderFloat("speed xoay", &SpinSpeed, 0.0f, 30000.0f, "%.0f");

                        ImGui::Unindent();

                    }                                     

                    

                    ImGui::Checkbox("No Reload", &Vars.noreload);

                    ImGui::Checkbox("Infinite Ammo", &Vars.vohandan);

                    ImGui::Checkbox("UpPlayer", &Vars.UpPlayerOne);

                    ImGui::Checkbox("Brutal & FastFire", &Vars.fastfire);

                    ImGui::Checkbox("Remove brutal & FastFire", &Vars.xoaspeed);

                    ImGui::Checkbox("aimkill", &AutoFire);

                    if (ImGui::Checkbox("Fly Altura", &fly_altura)) {

                        FlyController *fly = [[FlyController alloc] init];

                        [fly flyAlturaSwitchChanged:fly_altura];

                    }       



                    if (ImGui::Checkbox("Sung nhanhh ", &fastShotEnabled)) {

                        setFastShot(new JRMemoryEngine(mach_task_self()), fastShotEnabled);

                    } 



                    ImGui::Checkbox("fly cao", &Vars.flyaltura);

                    ImGui::Separator();

                    ImGui::EndTabItem();

                }



                ImGui::EndTabBar();

            } 

            ImGui::End();

        }



        // --- CÁC HÀM RUNTIME ---

        get_players();

        draw_watermark();

        aimbot();

        UpOneEnemy();

        ProcessFlyGravity(); // CHẠY BAY TRỌNG LỰC

        TeleportMarkVoid(); 

        Tele10M();

        AiPlayer2();

        PullPlayer();



        if (game_sdk) game_sdk->init();



        // --- RENDER ---

        ImGui::Render();

        ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), commandBuffer, renderEncoder);

        

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];

    }

    [commandBuffer commit];

}



- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

+ (void)showChange:(BOOL)open { MenDeal = open; }



@end 
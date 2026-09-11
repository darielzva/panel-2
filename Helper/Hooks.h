#import "vinhtran.hpp"
#import "loading.hxx"
#include <fstream>
#define FMT_HEADER_ONLY
#include "fmt/core.h"
#include <math.h>
#import "../JRMemory/JRMemory.framework/Headers/MemScan.h"

bool SilentAim = false;
bool CheckWall1 = false;
Vector3 SavedMapMarker = {0, 0, 0};
bool HasMapMarker = false;
bool fly_altura = false;
static bool campc_active = false;
static float cam_fov_value = 0.4f; // Giá trị mặc định là 0.4
static std::vector<void*> camPCAddrs;
static bool isCamPCScanned = false;
static bool phamvi_active = false;
static std::vector<void*> phamViAddrs1;
static bool isPhamViScanned = false; // Chỉ để duy nhất dòng này ở đầu file
static bool s_camco, s_mp40_v7, s_mp40_v8, s_m1014_v8_1, s_m1014_v8_2, s_ump_v7, s_ak_v7, s_an94_v7, s_thomson_v7;
static std::vector<void*> fastShotAddrs;
static bool isFastShotScanned = false;
static bool fastShotEnabled = false;
bool ResetGuest = false;
bool AutoFire = false;
bool CHECKPLAYER = false;
static float FlyHack3 = 27.0f;
static Vector3 g_TargetPos = {0, 0, 0};
bool spin360 = false;
bool RevealEnemy = false;
static float currentY = 0.0f;
static float SpinSpeed = 5000.0f;
static float RevealDistance = 7.0f;


#include <map>

struct EnemyCacheData {
    Vector3 bestRevealPos;
    bool hasBestPos;
};

// Sử dụng static để tránh lỗi trùng lặp khi link dylib
static std::map<void *, EnemyCacheData> enemyCache;

enum FireMode { 
    MANUL,
    AUTO
}; 

enum FireStatus { 
    NONE,
    FIRING,
    CANCEL
};

struct Vars_t
{
    bool fastfire = false;
    bool xoaspeed = false;
    bool noreload = false;
    bool vohandan = false;
    bool Enable = {};
    bool AimbotEnable = {};
    bool Aimbot = {};
    bool ShowFovCircle = false;
   
    float AimFov = 360.0f;
    int AimCheck = {};
    bool ESPCount = {};
    int AimType = {};
    int AimWhen = 3;
    int AimMode = 2;
    bool isAimFov = {};
    int AimHitbox = 0; 
    bool TeleportMark1 = false;
    const char* aimHitboxes[3] = {"Head", "Neck", "Body"};
    const char *dir[4] = {"None", "Fire", "Scope", "Fire Or Scope"};
    const char *aimModes[3] = {"Aim 360°", "Aim 180°", "AimFov"};
    bool VisibleCheck = true;
    bool lines = {};
    bool Box = {};
    bool Outline = {};
    bool Name = {};
    bool Health = {};
    bool Distance = {};
    bool fovaimglow = {};
    bool circlepos = {};
    bool skeleton = {};
    bool OOF = {};
    bool enemycount = {};
    float fovLineColor[4] = {1.0f, 1.0f, 1.0f, 1.0f};
    ImVec4 boxColor = ImVec4(1.0f, 1.0f, 1.0f, 1.0f);
    float AimSpeed = 10.0f;
    bool IgnoreKnocked = true;
    float FlyGravitySpeed = 0.0f; // Để 0 cho đứng im lúc mới bật
    float FlyUpForce = 0.0f;      // Để 0 luôn
    float GravityForce = 9.8f;
    bool FlyGravity = false;
    bool flyaltura = false;
    bool Tele10M = false;
    bool AiPlayer2 = false;
    bool PullPlayer = false;
    bool UpPlayerOne = false;
} Vars;

struct HitObjectInfo {
    void *klass;
    void *monitor;
    bool m_IsInPool;
    void *HitObject;
    void *HitCollider;
    Vector3 HitLocation;
    Vector3 HitNormal;
    Vector3 RayDir;
    Vector3 StartPosition;
    int32_t Damage;
    float Distance;
    int32_t ActorLayer;
    int32_t HitGroup;
    void *HitPhysicMaterial;
    bool IgnoreHappens;
    bool ViewBlocked;
    struct Vector3 OrigStartPosition;
    uint8_t SpecialHitType;
    uint32_t SpecialHitLevelObjID;
};

class game_sdk_t
{
public:
    void init();
    int (*GetHp)(void *player);
    void *(*Curent_Match)();
    void *(*GetLocalPlayer)(void *Game);
    void *(*GetHeadPositions)(void *player);
    Vector3 (*get_position)(void *player);
    void *(*Component_GetTransform)(void *player);
    void *(*get_camera)();
    Vector3 (*WorldToViewpoint)(void*, Vector3, int);
    bool (*get_isVisible)(void *player);
    bool (*get_isLocalTeam)(void *player);
    bool (*get_IsDieing)(void *player);
    int (*get_MaxHP)(void *player);
    Vector3 (*GetForward)(void *player);
    void (*set_aim)(void *, Quaternion look);
    bool (*get_IsSighting)(void *player);
    bool (*get_IsFiring)(void *player);
    monoString *(*name)(void *player);
    void *(*_GetHeadPositions)(void *);
    void *(*_newHipMods)(void *);
    void *(*_GetLeftAnkleTF)(void *);
    void *(*_GetRightAnkleTF)(void *);
    void *(*_GetLeftToeTF)(void *);
    void *(*_GetRightToeTF)(void *);
    void *(*_getLeftHandTF)(void *);
    void *(*_getRightHandTF)(void *);
    void *(*_getLeftForeArmTF)(void *);
    void *(*_getRightForeArmTF)(void *);
};

game_sdk_t *game_sdk = new game_sdk_t();

void game_sdk_t::init()
{
    this->GetHp = (int (*)(void *))getRealOffset(oxo("0x4A8478C"));
    this->Curent_Match = (void *(*)())getRealOffset(oxo("0x4E355B0"));
    this->GetLocalPlayer = (void *(*)(void *))getRealOffset(oxo("0x28FC854"));
    this->GetHeadPositions = (void *(*)(void *))getRealOffset(oxo("0x4AA1A28"));
    this->get_position = (Vector3(*)(void *))getRealOffset(oxo("0x8552BAC"));
    this->Component_GetTransform = (void *(*)(void *))getRealOffset(oxo("0x854060C"));
    this->get_camera = (void *(*)())getRealOffset(oxo("0x84E7148"));
    this->WorldToViewpoint = (Vector3(*)(void*, Vector3, int))getRealOffset(oxo("0x84E6AC8"));
    this->get_isVisible = (bool (*)(void *))getRealOffset(oxo("0x4A20AF4"));
    this->get_isLocalTeam = (bool (*)(void *))getRealOffset(oxo("0x4A38D90"));
    this->get_IsDieing = (bool (*)(void *))getRealOffset(oxo("0x4A02EA8"));
    this->get_MaxHP = (int (*)(void *))getRealOffset(oxo("0x4A8489C"));
    this->GetForward = (Vector3(*)(void *))getRealOffset(oxo("0x85534CC"));
    this->set_aim = (void (*)(void *, Quaternion))getRealOffset(oxo("0x4A1C91C"));
    this->get_IsSighting = (bool (*)(void *))getRealOffset(oxo("0x4A0FF18"));
    this->get_IsFiring = (bool (*)(void *))getRealOffset(oxo("0x4A05634"));
    this->name = (monoString * (*)(void *player)) getRealOffset(oxo("0x4A16D38"));
    this->_GetHeadPositions = (void *(*)(void *))getRealOffset(oxo("0x4AA1A28"));
    this->_newHipMods = (void *(*)(void *))getRealOffset(oxo("0x4AA1BD8"));
    this->_GetLeftAnkleTF = (void *(*)(void *))getRealOffset(oxo("0x4AA2028"));
    this->_GetRightAnkleTF = (void *(*)(void *))getRealOffset(oxo("0x4AA2134"));
    this->_GetLeftToeTF = (void *(*)(void *))getRealOffset(oxo("0x4AA2240"));
    this->_GetRightToeTF = (void *(*)(void *))getRealOffset(oxo("0x4AA234C"));
    this->_getLeftHandTF = (void *(*)(void *))getRealOffset(oxo("0x4A1B9B4"));
    this->_getRightHandTF = (void *(*)(void *))getRealOffset(oxo("0x4A1BAB8"));
    this->_getLeftForeArmTF = (void *(*)(void *))getRealOffset(oxo("0x4A1BBBC"));
    this->_getRightForeArmTF = (void *(*)(void *))getRealOffset(oxo("0x4A1BCC0"));
}

bool IsGod(void *player){
    return *(bool *)((uint64_t) player + 0xF4C);
}

void *get_gameObject(void *Pthis)
{
    return ((void* (*)(void *))getRealOffset(0x854065C))(Pthis);
}

static void *GetWeaponOnHand1(void *local) {
    void *(*_GetWeaponOnHand1)(void *local) = (void *(*)(void *))getRealOffset(0x4A16560);
    return _GetWeaponOnHand1(local);
}

static Vector3 Transform_INTERNAL_GetPosition(void *transform) {
    if (!transform) return Vector3::zero();
    Vector3 out = Vector3::zero();
    void (*_Transform_INTERNAL_GetPosition)(void *transform, Vector3 * out) = (void (*)(void *, Vector3 *))getRealOffset(ENCRYPTOFFSET("0x8552C10"));
    _Transform_INTERNAL_GetPosition(transform, &out);
    return out;
}

static void Transform_INTERNAL_SetPosition(void *player, Vvector3 inn) {
   void (*_Transform_INTERNAL_SetPosition)(void *transform, Vvector3 in) = (void (*)(void *, Vvector3))getRealOffset(oxo("0x8552CE8"));
    _Transform_INTERNAL_SetPosition(player, inn);
}

static void Transform_INTERNAL_SetRotation(void *transform, Quaternion quat) {
    if (!transform) return;
    void (*_Transform_INTERNAL_SetRotation)(void *transform, Quaternion in) = (void (*)(void *, Quaternion))getRealOffset(0x8552F74);
    _Transform_INTERNAL_SetRotation(transform, quat);
}

// Hàm Xoay xoay
void RotatePlayer360(void* player, float delta) {
    if (!spin360 || !player) return;
    void* transform = game_sdk->Component_GetTransform(player);
    if (!transform) return;

    currentY = fmod(currentY + (SpinSpeed * delta), 360.0f);
    float rad = currentY * (M_PI / 180.0f);
    Quaternion rot;
    rot.x = 0.0f; rot.y = sin(rad / 0.2f); rot.z = 0.0f; rot.w = cos(rad / 0.2f);
    
    Transform_INTERNAL_SetRotation(transform, rot);
}

void RunRevealEnemy2() {
    // Thay 'vars.RevealEnemy' bằng biến bool bạn dùng để bật/tắt menu (ví dụ: RevealEnemy)
    if (!RevealEnemy) return; 
    
    void *match = game_sdk->Curent_Match(); 
    if (!match) return;
    
    void *local = game_sdk->GetLocalPlayer(match);
    if (!local) return;

    auto *players = *(Dictionary<uint8_t *, void **> **)((long)match + 0x120);
    if (!players || players->getSize() <= 0) return;

    for (int i = 0; i < players->getSize(); i++) {
        void *enemy = players->getValues()[i];
        if (!enemy || enemy == local) continue;

        // --- PHẦN NÀY CẦN KIỂM TRA TÊN HÀM TRONG SDK CỦA BẠN ---
        // Nếu IsTeammate không có trong game_sdk, hãy gọi hàm tự do hoặc bỏ qua nếu chưa có
        // if (IsTeammate(enemy)) continue; 
        
        void *enemyTF = game_sdk->Component_GetTransform(enemy);
        if (!enemyTF) continue;
        
        // Gọi get_position thông qua con trỏ hàm trong struct game_sdk_t
        Vector3 enemyPos = game_sdk->get_position(enemyTF);
        EnemyCacheData &cache = enemyCache[enemy];
        
        float RevealDistance = 5.0f;
        float step = RevealDistance / 3.0f;
        float dists[3] = {step, step * 2.0f, RevealDistance};
        float angs[6] = {0, 60, 120, 180, 240, 300};
        bool moved = false;

        for (float d : dists) {
            for (float a : angs) {
                float rad = a * 3.14159f / 180.0f;
                Vector3 newPos = enemyPos + Vector3(cos(rad) * d, 0, sin(rad) * d);
                
                // Ép kiểu Vector3 sang Vvector3 bằng cách cast pointer
                Transform_INTERNAL_SetPosition(enemyTF, *(Vvector3 *)&newPos);
                
                // Tạm thời comment nếu game_sdk không có Visible_Check để compile trước
                /*
                if (game_sdk->Visible_Check(enemy)) {
                    cache.bestRevealPos = newPos;
                    cache.hasBestPos = true;
                    moved = true; 
                    break;
                }
                */
            }
            if (moved) break;
        }
        
        if (!moved) {
            Transform_INTERNAL_SetPosition(enemyTF, *(Vvector3 *)&enemyPos);
        }
    }
}

// Khai báo một biến static để lưu độ cao mục tiêu
static float fixedFlyY = 0.0f;
static bool wasFlying = false;

void FlyHack22() {
    if (!Vars.flyaltura) {
        wasFlying = false; // Reset trạng thái khi tắt hack
        return;
    }

    void* match = game_sdk->Curent_Match();
    if (!match) return;

    void* localPlayer = game_sdk->GetLocalPlayer(match);
    if (!localPlayer) return;

    void* transform = game_sdk->Component_GetTransform(localPlayer);
    if (!transform) return;

    Vector3 currentPos = Transform_INTERNAL_GetPosition(transform);

    // Nếu mới bắt đầu bay, lấy độ cao hiện tại làm mốc
    if (!wasFlying) {
        fixedFlyY = currentPos.y;
        wasFlying = true;
    }

    // FlyHack3 nên được dùng làm "độ cao cộng thêm" so với mặt đất 
    // hoặc điều chỉnh trực tiếp vào fixedFlyY
    float offset = (float)FlyHack3 / 100.0f; 

    // Thay vì cộng dồn vào currentPos.y, chúng ta giữ nhân vật ở một độ cao ổn định
    // targetPos.y = fixedFlyY + offset; 
    
    // Nếu bạn muốn bay lên/xuống mượt, hãy dùng phép gán trực tiếp:
    Vvector3 targetPos(currentPos.x, fixedFlyY + offset, currentPos.z);

    Transform_INTERNAL_SetPosition(transform, targetPos);
    
    // Quan trọng: Để hết giật hoàn toàn, bạn cần tìm offset "Gravity" 
    // của nhân vật và set nó về 0 khi đang bay.
}

bool (*old_get_ResetGuest)();
bool hk_get_ResetGuest() {
    if (ResetGuest) return false; 
    if (old_get_ResetGuest) return old_get_ResetGuest();
    return false;
}

#ifndef HOOKS_H
#define HOOKS_H

#import <Foundation/Foundation.h>
#include <stdint.h>
#include <mach/mach.h> // Thư viện hệ thống iOS
#include "Mem.h"

static bool antiban_thanhprd = false;
static bool isBypassExecuted = false;

// --- HÀM TỰ CHẾ THAY THẾ DOBBY ---
// Hàm này sẽ mở khóa vùng nhớ, ghi dữ liệu và đóng lại
bool VNTOOL_MemoryPatch(void *address, uint32_t data) {
    mach_port_t task = mach_task_self();
    vm_address_t addr = (vm_address_t)address;
    
    // 1. Mở quyền Ghi (Read + Write + Copy)
    kern_return_t kr = vm_protect(task, addr, 4, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (kr != KERN_SUCCESS) return false;
    
    // 2. Ghi 4 byte dữ liệu (Mã RET) vào địa chỉ
    kr = vm_write(task, addr, (vm_offset_t)&data, 4);
    
    // 3. Trả lại quyền Thực thi (Read + Execute) để game chạy tiếp
    vm_protect(task, addr, 4, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    
    return (kr == KERN_SUCCESS);
}

static void ApplyAllBypassHooks() {
    if (isBypassExecuted) return;

    typedef uint64_t (*getOffset_t)(uint64_t);
    getOffset_t getBase = (getOffset_t)getRealOffset;
    uint64_t unityBase = getBase(0);
    
    if (unityBase == 0) return;

    // Danh sách các Offset cần RET
    uintptr_t bypassList[] = {
        0x1CFB29C
    };

    uint32_t ret_opcode = 0xD65F03C0; 
    int count = sizeof(bypassList) / sizeof(bypassList[0]);

    for (int i = 0; i < count; i++) {
        // Sử dụng API Kernel của VNTOOL để ghi đè bộ nhớ
        VNTOOL_MemoryPatch((void*)(unityBase + bypassList[i]), ret_opcode);
    }

    isBypassExecuted = true;
    NSLog(@"[VNTOOL] Bypass thành công %d offsets.", count);
}

#endif



std::map<void*, float> enemyOriginalY; 

namespace Camera$$WorldToScreen
{
    ImVec2 Regular(Vector3 pos) {
        auto cam = game_sdk->get_camera();
        if (!cam) return {0,0};

        Vector3 worldPoint = game_sdk->WorldToViewpoint(cam,pos, 2);
        Vector3 location;

        int ScreenWidth = ImGui::GetIO().DisplaySize.x;
        int ScreenHeight = ImGui::GetIO().DisplaySize.y;

        location.x = ScreenWidth * worldPoint.x;
        location.y = ScreenHeight - worldPoint.y * ScreenHeight;
        location.z  = worldPoint.z;

        return {location.x, location.y};
    }

    ImVec2 Checker(Vector3 pos, bool &checker) {
        auto cam = game_sdk->get_camera();
        if (!cam) return {0, 0};
       
        Vector3 worldPoint = game_sdk->WorldToViewpoint(cam,pos, 4);
        Vector3 location;
     
        int ScreenWidth = ImGui::GetIO().DisplaySize.x;
        int ScreenHeight = ImGui::GetIO().DisplaySize.y;
     
        location.x = ScreenWidth * worldPoint.x;
        location.y = ScreenHeight - worldPoint.y * ScreenHeight;
        location.z = worldPoint.z;
     
        checker = location.z > 1;
     
        return {location.x, location.y};
    }
}

Vector3 GetBonePosition(void *player, void *(*transformGetter)(void *)) {
    if (!player || !transformGetter) return Vector3::zero();
    void *transform = transformGetter(player);
    if (!transform) return Vector3::zero();
    void *compTrans = game_sdk->Component_GetTransform(transform);
    if (!compTrans) return Vector3::zero();
    return game_sdk->get_position(compTrans);
}

Vector3 GetHitboxPosition(void* player, int hitbox) {
    if (!player) return Vector3::zero();
    
    switch (hitbox) {
        case 0: return GetBonePosition(player, game_sdk->GetHeadPositions);
        case 1: {
            Vector3 headPos = GetBonePosition(player, game_sdk->GetHeadPositions);
            return headPos == Vector3::zero() ? headPos : Vector3(headPos.x, headPos.y - 0.2f, headPos.z);
        }
        case 2: {
            Vector3 headPos = GetBonePosition(player, game_sdk->GetHeadPositions);
            return headPos == Vector3::zero() ? headPos : Vector3(headPos.x, headPos.y - 0.4f, headPos.z);
        }
        default: return GetBonePosition(player, game_sdk->GetHeadPositions);
    }
}

Vector3 getPosition(void *player) {
    if (!player) return Vector3::zero();
    void *compTrans = game_sdk->Component_GetTransform(player);
    if (!compTrans) return Vector3::zero();
    return game_sdk->get_position(compTrans);
}

Vector3 GetHeadPosition(void *player) {
    if (!player) return Vector3::zero();
    void *headPos = game_sdk->GetHeadPositions(player);
    if (!headPos) return Vector3::zero();
    return game_sdk->get_position(headPos);
}

static Vector3 CameraMain(void *player) {
    if (!player) return Vector3::zero();
    void* camTransform = *(void **)((uint64_t)player + oxo("0x390"));
    if (!camTransform) return Vector3::zero();
    return game_sdk->get_position(camTransform);
}

Quaternion GetRotationToTheLocation(Vector3 Target, float Height, Vector3 MyEnemy) {
    Vector3 direction = (Target + Vector3(0, Height, 0)) - MyEnemy;
    return Quaternion::LookRotation(direction, Vector3(0, 1, 0));
}

Quaternion GetCurrentRotation(void* player) {
    if (!player) return Quaternion();
    void* transform = game_sdk->Component_GetTransform(player);
    if (!transform) return Quaternion();
    return Quaternion::LookRotation(game_sdk->GetForward(transform), Vector3(0, 1, 0));
}

#include "Helper/Ext.h"

class tanghinh {
public:
    static Vector3 Transform_GetPosition(void *transform) {
        if (!transform) return Vector3::zero();
        Vector3 out = Vector3::zero();
        void (*_Transform_GetPosition)(void *transform, Vector3 *out) = (void (*)(void *, Vector3 *))getRealOffset(oxo("0x8552C10"));
        _Transform_GetPosition(transform, &out);
        return out;
    }

    static void *Player_GetHeadCollider(void *player)
    {
        void *(*_Player_GetHeadCollider)(void *players) = (void *(*)(void *))getRealOffset(oxo("0x4A1A9D4"));
        return _Player_GetHeadCollider(player);
    }

    static bool Physics_Raycast(Vector3 camLocation, Vector3 headLocation, unsigned int LayerID, void *collider)
    {
        bool (*_Physics_Raycast)(Vector3 camLocation, Vector3 headLocation, unsigned int LayerID, void *collider) = (bool (*)(Vector3, Vector3, unsigned int, void *))getRealOffset(oxo("0x5580870"));
        return _Physics_Raycast(camLocation, headLocation, LayerID, collider);
    }

    static bool isVisible(void *enemy) {
        if (!enemy) return false;
        
        void* cam = game_sdk->get_camera();
        if (!cam) return false;
        void* camTrans = game_sdk->Component_GetTransform(cam);
        if (!camTrans) return false;

        void* headCol = Player_GetHeadCollider(enemy);
        if (!headCol) return false;
        void* targetTrans = game_sdk->Component_GetTransform(headCol);
        if (!targetTrans) return false;

        void *hitObj = NULL;
        auto Camera = Transform_GetPosition(camTrans);
        auto Target = Transform_GetPosition(targetTrans);
        return !Physics_Raycast(Camera, Target, 12, &hitObj);
    }
};

void DrawSkeleton(void *player, ImDrawList *drawList)
{
    if (!player || !drawList) return;
    
    bool isPlayerVisible = tanghinh::isVisible(player);
    Vector3 headPos = GetBonePosition(player, game_sdk->_GetHeadPositions);
    Vector3 hipPos = GetBonePosition(player, game_sdk->_newHipMods);
    Vector3 leftAnklePos = GetBonePosition(player, game_sdk->_GetLeftAnkleTF);
    Vector3 rightAnklePos = GetBonePosition(player, game_sdk->_GetRightAnkleTF);
    Vector3 leftToePos = GetBonePosition(player, game_sdk->_GetLeftToeTF);
    Vector3 rightToePos = GetBonePosition(player, game_sdk->_GetRightToeTF);
    Vector3 leftHandPos = GetBonePosition(player, game_sdk->_getLeftHandTF);
    Vector3 rightHandPos = GetBonePosition(player, game_sdk->_getRightHandTF);
    Vector3 leftForeArmPos = GetBonePosition(player, game_sdk->_getLeftForeArmTF);
    Vector3 rightForeArmPos = GetBonePosition(player, game_sdk->_getRightForeArmTF);

    bool visible = false;
    ImVec2 headScreen = Camera$$WorldToScreen::Checker(headPos, visible);
    if (!visible) return;

    ImVec2 hipScreen = Camera$$WorldToScreen::Regular(hipPos);
    ImVec2 leftAnkleScreen = Camera$$WorldToScreen::Regular(leftAnklePos);
    ImVec2 rightAnkleScreen = Camera$$WorldToScreen::Regular(rightAnklePos);
    ImVec2 leftToeScreen = Camera$$WorldToScreen::Regular(leftToePos);
    ImVec2 rightToeScreen = Camera$$WorldToScreen::Regular(rightToePos);
    ImVec2 leftHandScreen = Camera$$WorldToScreen::Regular(leftHandPos);
    ImVec2 rightHandScreen = Camera$$WorldToScreen::Regular(rightHandPos);
    ImVec2 leftForeArmScreen = Camera$$WorldToScreen::Regular(leftForeArmPos);
    ImVec2 rightForeArmScreen = Camera$$WorldToScreen::Regular(rightForeArmPos);
    
    ImColor boneColor = isPlayerVisible ? ImColor(0, 255, 0) : ImColor(255, 255, 255);
    float thickness = 1.0f;

    drawList->AddCircle(headScreen, 2.0f, boneColor, 12, thickness);
    drawList->AddLine(headScreen, hipScreen, boneColor, thickness);
    drawList->AddLine(headScreen, leftForeArmScreen, boneColor, thickness);
    drawList->AddLine(headScreen, rightForeArmScreen, boneColor, thickness);
    drawList->AddLine(leftForeArmScreen, leftHandScreen, boneColor, thickness);
    drawList->AddLine(rightForeArmScreen, rightHandScreen, boneColor, thickness);
    drawList->AddLine(hipScreen, leftAnkleScreen, boneColor, thickness);
    drawList->AddLine(hipScreen, rightAnkleScreen, boneColor, thickness);
    drawList->AddLine(leftAnkleScreen, leftToeScreen, boneColor, thickness);
    drawList->AddLine(rightAnkleScreen, rightToeScreen, boneColor, thickness);
}

bool isFov(Vector3 vec1, Vector3 vec2, int radius)
{
    int x = vec1.x;
    int y = vec1.y;
    int x0 = vec2.x;
    int y0 = vec2.y;
    if ((pow(x - x0, 2) + pow(y - y0, 2)) <= pow(radius, 2))
    {
        return true;
    }
    return false;
}



JRMemoryEngine* engine = nullptr;

void editAll(uint64_t newValue) {
    if (!engine) return;

    vector<void*> results = engine->getAllResults();

    for (int i = 0; i < results.size(); i++) {
        engine->JRWriteMemory((uint64_t)results[i], &newValue, JR_Search_Type_ULong);
    }
}


void searchSpeed() {
    if (!engine) return;

    // clear result cũ
    if (engine->result) {
        ResultDeallocate(engine->result);
        engine->result = ResultAllocate();
    }

    uint64_t value = 4397530849764387586ULL;

    AddrRange range;
    range.start = 0x100000000;
    range.end   = 0x200000000;

    engine->JRScanMemory(range, &value, JR_Search_Type_ULong);

    // isScanned = true;
}

void setSpeed() {
    uint64_t value = 0;
    value = 4397530849735000000ULL;

    editAll(value);
}

void disableSpeed() {
    uint64_t value = 4397530849764387586ULL;
    editAll(value);
}








void modSkin(JRMemoryEngine *engine, bool enabled, int originalID, int skinID) {
    if (!engine) return;

    // Vùng quét chuẩn h5gg của má
    AddrRange range = {0x100000000, 0x160000000};
    
    // Nếu On: Tìm Gốc -> Thay Skin. Nếu Off: Tìm Skin -> Trả về Gốc
    int searchVal = enabled ? originalID : skinID;
    int writeVal = enabled ? skinID : originalID;

    // Quét chính xác kiểu I32 (int)
    engine->JRScanMemory(range, &searchVal, sizeof(int));
    std::vector<void*> results = engine->getAllResults();

    if (!results.empty()) {
        for (void* addr : results) {
            engine->JRWriteMemory((uint64_t)addr, &writeVal, sizeof(int));
        }
        NSLog(@"[VNTOOL] Mod Skin: Success! Found %lu addresses", results.size());
    } else {
        NSLog(@"[VNTOOL] Mod Skin: Not Found ID %d", searchVal);
    }
    
    delete engine; // Cực kỳ quan trọng để không văng game
}




void setFastShot(JRMemoryEngine *engine, bool enabled) {
    if (!engine) return;

    // Vùng nhớ hẹp để quét cực nhanh
    AddrRange range = {0x100000000, 0x130000000}; 
    
    // Giá trị I64 (Long Long trong C++)
    long long originalVal = 72340173878198272LL;
    long long patchVal = 72340172821233664LL;

    if (!isFastShotScanned) {
        // Thực hiện quét giá trị gốc
        engine->JRScanMemory(range, &originalVal, sizeof(long long));
        fastShotAddrs = engine->getAllResults();
        isFastShotScanned = true;
    }

    // Ghi đè giá trị để kích hoạt súng nhanh
    for (void* addr : fastShotAddrs) {
        engine->JRWriteMemory((uintptr_t)addr, enabled ? &patchVal : &originalVal, sizeof(long long));
    }
}







void setCamPC(JRMemoryEngine *engine, bool enabled, float fov_val) {
    if (!engine) return;
    if (!isCamPCScanned) {
        AddrRange range = {0x100000000, 0x130000000};
        float searchVal = 0.4f;
        engine->JRScanMemory(range, &searchVal, sizeof(float));
        camPCAddrs = engine->getAllResults();
        isCamPCScanned = true;
    }
    float valToWrite = enabled ? fov_val : 0.4f;
    for (void* addr : camPCAddrs) {
        engine->JRWriteMemory((uint64_t)addr, &valToWrite, sizeof(float));
    }
}




static std::vector<void*> flyResults;
static bool isFlyScanned = false;
// Giá trị gốc để khôi phục khi tắt, tránh văng trận
static uint64_t flyOriginalValue = 4510805389526423306ULL;

// --- HÀM QUÉT BỘ NHỚ ---
void searchFly(JRMemoryEngine *engine) {
    if (!engine) return;

    flyResults.clear();
    uint64_t scanTarget = flyOriginalValue; 

    AddrRange range;
    range.start = 0x100000000;
    range.end = 0x200000000;

    engine->JRScanMemory(range, &scanTarget, sizeof(scanTarget));
    flyResults = engine->getAllResults(); 
    isFlyScanned = true;
}

// --- HÀM THỰC THI (FIX LỖI MAKE) ---
void applyFly(JRMemoryEngine *engine, bool enable) {
    if (!engine) return;
    
    if (!isFlyScanned && enable) {
        searchFly(engine);
    }

    if (flyResults.empty()) return;

    // Giá trị khi Mod (ông muốn bay thì để 0 hoặc giá trị tùy ý)
    uint64_t flyModValue = 0; 

    for (void* addr : flyResults) {
        if (enable) {
            // Ép kiểu (uintptr_t)addr để hết lỗi error: cannot initialize a parameter
            engine->JRWriteMemory((uintptr_t)addr, &flyModValue, sizeof(flyModValue));
        } else {
            // Khi TẮT: Trả về giá trị gốc để KHÔNG VĂNG TRẬN
            engine->JRWriteMemory((uintptr_t)addr, &flyOriginalValue, sizeof(flyOriginalValue));
        }
    }
}


void setNhanVatPhamVi(JRMemoryEngine *engine, bool enabled) {
    if (!engine) return;

    // 1. Máy quét chạy ngầm (Chỉ chạy 1 lần duy nhất)
    if (!isPhamViScanned) {
        AddrRange range = {0x100000000, 0x160000000};
        uint64_t signature = 4333543704410193920ULL;
        engine->JRScanMemory(range, &signature, sizeof(uint64_t));
        
        phamViAddrs1 = engine->getAllResults();
        isPhamViScanned = true; // Quét xong rồi thì đánh dấu lại
    }

    // 2. Cái công tắc (Dùng biến 'enabled' từ Checkbox truyền vào)
    float val = enabled ? 1.7f : 0.305f;

    for (void* addr : phamViAddrs1) {
        engine->JRWriteMemory((uint64_t)addr, &val, sizeof(float));
    }
}

// --- 4. HÀM THỰC THI (Patch) ---
void patchFly(JRMemoryEngine *engine, bool enabled) {
    if (!engine) return;

    // Tự động scan nếu chưa có dữ liệu
    if (!isFlyScanned || flyResults.empty()) {
        searchFly(engine);
    }

    uint64_t patchedValue  = 4510805389574401144ULL;
    uint64_t originalValue = 4510805389526423306ULL;
    uint64_t valueToWrite = enabled ? patchedValue : originalValue;

    for (size_t i = 0; i < flyResults.size(); i++) {
        engine->JRWriteMemory((uint64_t)flyResults[i], &valueToWrite, sizeof(valueToWrite));
    }
}

// --- 5. CLASS ĐIỀU KHIỂN (Controller) ---
@interface FlyController : NSObject
- (void)flyAlturaSwitchChanged:(BOOL)enabled;
@end

@implementation FlyController

- (void)flyAlturaSwitchChanged:(BOOL)enabled {
    // Cập nhật giá trị vào struct Vars (viết hoa chữ V cho đúng với ImGui của bạn)
    fly_altura = enabled;

    JRMemoryEngine *engine = new JRMemoryEngine(mach_task_self());
    patchFly(engine, enabled);
    delete engine;
}

@end









void *GetClosestEnemy()
{
    try
    {
        float shortestDistance = 9999.0f;
        void *closestEnemy = NULL;
        
        void *get_MatchGame = game_sdk->Curent_Match();
        if (!get_MatchGame) return NULL;
            
        void *LocalPlayer = game_sdk->GetLocalPlayer(get_MatchGame);
        if (!LocalPlayer || !game_sdk->Component_GetTransform(LocalPlayer)) return NULL;
            
        if (!Vars.Enable) return NULL;



        if (Vars.fastfire) {
        setSpeed();
        void* PlayerAttributes = *(void**)((uint64_t)LocalPlayer + 0x708);
        *(float*)((uintptr_t)PlayerAttributes + 0x260) = 0.2f;
    } 
    if (Vars.xoaspeed) {
            disableSpeed();
            void* PlayerAttributes = *(void**)((uint64_t)LocalPlayer + 0x708);
            *(float*)((uintptr_t)PlayerAttributes + 0x260) = 1.2f;
    }



        if(Vars.noreload){
            void* PlayerAttributes = *(void**)((uint64_t)LocalPlayer + 0x708); //protected PlayerAttributes JKPFFNEMJIF; 0x680
            *(bool *)((long)PlayerAttributes + 0xD9) = true; //public bool ShootNoReload; // 0xC1 -> class PlayerAttributes
        }else{
            void* PlayerAttributes = *(void**)((uint64_t)LocalPlayer + 0x708); //protected PlayerAttributes JKPFFNEMJIF; 0x680
            *(bool *)((long)PlayerAttributes + 0xD9) = false; //public bool ShootNoReload; // 0xC1 -> class PlayerAttributes
        }


        if(Vars.vohandan){
            void* WeaponHand = GetWeaponOnHand1(LocalPlayer);
            *(bool *)((long)WeaponHand + 0x7B1) = false; //protected bool m_CostAmmo; // 0x6D0-> bất tử đạn , weapon
                //protected bool OKKJNPGJJOH; // 0x741
            }else{
            void* WeaponHand = GetWeaponOnHand1(LocalPlayer);
            *(bool *)((long)WeaponHand + 0x7B1) = true; //protected bool m_CostAmmo; // 0x6D0-> bất tử đạn , weapon

        }






            
        Dictionary<uint8_t *, void **> *players = *(Dictionary<uint8_t *, void **> **)((long)get_MatchGame + oxo("0x148"));
        if (!players ) return NULL;

        void* camera = game_sdk->get_camera();
        if (!camera) return NULL;
        void* camTransform = game_sdk->Component_GetTransform(camera);
        if (!camTransform) return NULL;
            
        for (int u = 0; u < players->getSize(); u++)
        {
            void *Player = players->getValues()[u];
            if (!Player) continue;
            if (Player == LocalPlayer) continue;
            if (!game_sdk->get_MaxHP(Player)) continue;
            if (game_sdk->get_IsDieing(Player)) continue;
            if (!game_sdk->get_isVisible(Player)) continue;
            if (game_sdk->get_isLocalTeam(Player)) continue;
            
            Vector3 PlayerPos = getPosition(Player);
            Vector3 LocalPlayerPos = getPosition(LocalPlayer);
            ImVec2 screenPos = Camera$$WorldToScreen::Regular(PlayerPos);
            bool isFov1 = isFov(Vector3(screenPos.x, screenPos.y), Vector3(ImGui::GetIO().DisplaySize.x / 2, ImGui::GetIO().DisplaySize.y / 2), Vars.AimFov);
            float distance = Vector3::Distance(LocalPlayerPos, PlayerPos);
            
            if (distance < 200)
            {
                Vector3 targetDir = Vector3::Normalized(PlayerPos - LocalPlayerPos);
                float angle = Vector3::Angle(targetDir, game_sdk->GetForward(camTransform)) * 100.0f;
                if (angle <= Vars.AimFov && isFov1 && angle < shortestDistance)
                {
                    if (tanghinh::isVisible(Player))
                    {
                        shortestDistance = angle;
                        closestEnemy = Player;
                    }
                }
            }
        }
        return closestEnemy;
    }
    catch (...)
    {
        return NULL;
    }
}

void *GetClosestEnemysilent()
{
    try
    {
        float shortestDistance = 99999.0f;
        void *closestEnemy = NULL;

        void *get_MatchGame = game_sdk->Curent_Match();
        if (!get_MatchGame) return NULL;

        void *LocalPlayer = game_sdk->GetLocalPlayer(get_MatchGame);
        if (!LocalPlayer || !game_sdk->Component_GetTransform(LocalPlayer)) return NULL;

        if (!Vars.Enable) return NULL;

        Dictionary<uint8_t *, void **> *players = *(Dictionary<uint8_t *, void **> **)((long) get_MatchGame + 0x148);
        if (!players ) return NULL;

        ImVec2 screenSize = ImGui::GetIO().DisplaySize;
        ImVec2 center(screenSize.x / 2, screenSize.y / 2);

        for (int i = 0; i < players->getSize(); i++) {
            void *Player = players->getValues()[i];

            if (!Player || Player == LocalPlayer) continue;
            if (!game_sdk->get_MaxHP(Player)) continue;
            if (game_sdk->get_IsDieing(Player)) continue;
            if (game_sdk->get_isLocalTeam(Player)) continue;
            if (IsGod(Player)) continue;

            int hp = game_sdk->GetHp(Player);
            if (Vars.IgnoreKnocked && hp <= 0) continue;

            bool isInsideCamera = false;
            Vector3 pos = getPosition(Player);
            ImVec2 screenPos = Camera$$WorldToScreen::Checker(pos, isInsideCamera);

            if (!isInsideCamera) continue;
            if (screenPos.x < 0 || screenPos.x > screenSize.x || screenPos.y < 0 || screenPos.y > screenSize.y) continue;

            if (CheckWall1)
            {
                if (!game_sdk->get_isVisible(Player)) continue;
                if (!tanghinh::isVisible(Player)) continue;
            }

            float dx = screenPos.x - center.x;
            float dy = screenPos.y - center.y;
            float screenDist = sqrtf(dx * dx + dy * dy);

            if (screenDist < shortestDistance)
            {
                shortestDistance = screenDist;
                closestEnemy = Player;
            }
        }

        return closestEnemy;
    }
    catch (...)
    {
        return NULL;
    }
}

int SetDamage = 1;

void *getItransform(void *itransform) {
    void * (*_itransformNode)(void *_this) = (void*(*)(void*))getRealOffset(0x5C52CFC);
    return _itransformNode(itransform);
}

static float get_Range(void *pthis)
{
    return ((float (*)(void *))getRealOffset(ENCRYPTOFFSET("0x4E8703C")))(pthis);
}

bool isEnemyInRangeWeapon(void *player, void *enemy, void* weapon)
{
    if (player != nullptr && enemy != nullptr && weapon != nullptr)
    {
        Vector3 EnemyHeadPosition = GetHeadPosition(enemy);
        Vector3 PlayerHeadPosition = GetHeadPosition(player);
        float distance = Vector3::Distance(PlayerHeadPosition, EnemyHeadPosition);
        float range = get_Range(weapon);

        if (distance <= range) {
            return true;
        }
    }
    return false;
}

Vector3 GetHipPosition(void* player) {
    if(!player) return Vector3::zero();
    void *HipITF= *(void **)((uint64_t) player + 0x648);
    if(!HipITF) return Vector3::zero();
    void *HipTF = getItransform(HipITF);
    Vector3 Hip = Transform_INTERNAL_GetPosition(HipTF);
    return Hip;
}

int (*old_BLAGCMCGEJG1)(void *, HitObjectInfo *);
int BLAGCMCGEJG1(void *ist, HitObjectInfo *HitObject) {
    if (SilentAim && HitObject) {
        void *match = game_sdk->Curent_Match();
        if (match) {
            void *localPlayer = game_sdk->GetLocalPlayer(match);
            if (localPlayer) {
                void *weapon = GetWeaponOnHand1(localPlayer);
                void *enemy = GetClosestEnemysilent();
                if (enemy && weapon) {
                    if (isEnemyInRangeWeapon(localPlayer, enemy, weapon)) {
                        Vector3 enemyPos;
                        if (SetDamage == 1)
                            enemyPos = GetHeadPosition(enemy);
                        else
                            enemyPos = GetHipPosition(enemy);
                        
                        Vector3 startPos = GetHeadPosition(localPlayer);
                        void* headCollider = tanghinh::Player_GetHeadCollider(enemy);
                        
                        if (headCollider) {
                            HitObject->HitObject = get_gameObject(headCollider);
                            HitObject->HitCollider = headCollider;
                            HitObject->HitLocation = enemyPos;
                            HitObject->HitNormal = enemyPos;
                            HitObject->RayDir = Vector3::Normalized(enemyPos - startPos);
                            HitObject->StartPosition = startPos;
                            HitObject->OrigStartPosition = startPos;
                            HitObject->HitGroup = 1; 
                            HitObject->SpecialHitType = 0;
                            HitObject->IgnoreHappens = false;
                            HitObject->ViewBlocked = false;
                        }
                    }
                }
            }
        }
    }
    return old_BLAGCMCGEJG1(ist, HitObject);
}

void ProcessAimbot() {
    if (!Vars.Aimbot) return;
    
    void *CurrentMatch = game_sdk->Curent_Match();
    if (!CurrentMatch) return;
    
    void *LocalPlayer = game_sdk->GetLocalPlayer(CurrentMatch);
    if (!LocalPlayer || !game_sdk->Component_GetTransform(LocalPlayer)) return;
    
    void *closestEnemy = GetClosestEnemy();
    if (!closestEnemy || !game_sdk->Component_GetTransform(closestEnemy)) return;

    Vector3 EnemyLocation = GetHitboxPosition(closestEnemy, Vars.AimHitbox);
    if (EnemyLocation == Vector3::zero()) return;
    
    Vector3 PlayerLocation = CameraMain(LocalPlayer);
    if (PlayerLocation == Vector3::zero()) return;

    bool IsScopeOn = game_sdk->get_IsSighting(LocalPlayer);
    bool IsFiring = game_sdk->get_IsFiring(LocalPlayer);
    bool shouldAim =
        (Vars.AimWhen == 0) ||                        
        (Vars.AimWhen == 1 && IsFiring) ||             
        (Vars.AimWhen == 2 && IsScopeOn) ||           
        (Vars.AimWhen == 3 && (IsFiring || IsScopeOn)); 

    if (shouldAim && (!Vars.VisibleCheck || tanghinh::isVisible(closestEnemy))) {
        if (game_sdk->get_IsDieing(closestEnemy) && Vars.IgnoreKnocked) {
            float shortestDistance = 9999.0f;
            void *newTarget = NULL;
            Dictionary<uint8_t *, void **> *players = *(Dictionary<uint8_t *, void **> **)((long)CurrentMatch + oxo("0x148"));
            
            if (players) {
                for (int u = 0; u < players->getSize(); u++) {
                    void *Player = players->getValues()[u];
                    if (!Player || Player == LocalPlayer || !game_sdk->get_MaxHP(Player) || game_sdk->get_isLocalTeam(Player) || Player == closestEnemy)
                        continue;

                    if (Vars.IgnoreKnocked && game_sdk->get_IsDieing(Player)) continue;
                    if (Vars.VisibleCheck && !tanghinh::isVisible(Player)) continue;

                    Vector3 PlayerPos = GetHitboxPosition(Player, Vars.AimHitbox);
                    float distance = Vector3::Distance(PlayerLocation, PlayerPos);
                    if (distance < 300 && distance < shortestDistance) {
                        shortestDistance = distance;
                        newTarget = Player;
                    }
                }
            }

            if (newTarget) {
                EnemyLocation = GetHitboxPosition(newTarget, Vars.AimHitbox);
                closestEnemy = newTarget;
            } else {
                return;
            }
        }

        Quaternion TargetLook = GetRotationToTheLocation(EnemyLocation, 0.05f, PlayerLocation);
        game_sdk->set_aim(LocalPlayer, TargetLook);
    }
}

void UpdateCHECKPLAYER()
{
    CHECKPLAYER = false;

    void* match = game_sdk->Curent_Match();
    if (!match) return;

    void* local = game_sdk->GetLocalPlayer(match);
    if (!local) return;

    void* cam = game_sdk->get_camera();
    if (!cam) return;

    Vector3 localPos = getPosition(local);
    Vector3 localForward =
        game_sdk->GetForward(game_sdk->Component_GetTransform(cam));

    ImVec2 screenSize = ImGui::GetIO().DisplaySize;
    ImVec2 screenCenter(screenSize.x / 2.f, screenSize.y / 2.f);

    Dictionary<uint8_t *, void **> *players = *(Dictionary<uint8_t *, void **> **)((long)match + 0x148);
if (!players )
return;

    for (int i = 0; i < players->getSize(); i++) {
void *enemy = players->getValues()[i];
        if (!enemy || enemy == local) continue;

        if (!game_sdk->Component_GetTransform(enemy)) continue;
        if (!game_sdk->get_MaxHP(enemy)) continue;
        if (game_sdk->get_IsDieing(enemy)) continue;
        if (game_sdk->get_isLocalTeam(enemy)) continue;
        if (IsGod(enemy)) continue;

        int hp = game_sdk->GetHp(enemy);
        if (Vars.IgnoreKnocked && hp <= 0) continue;

        if (!game_sdk->get_isVisible(enemy)) continue;
        if (!tanghinh::isVisible(enemy)) continue;

        Vector3 enemyPos = getPosition(enemy);
        if (Vector3::Distance(localPos, enemyPos) > 200.f) continue;

        bool isInsideCamera = false;
        ImVec2 screenPos =
            Camera$$WorldToScreen::Checker(enemyPos, isInsideCamera);

        if (!isInsideCamera) continue;

        if (screenPos.x < 0 || screenPos.x > screenSize.x ||
            screenPos.y < 0 || screenPos.y > screenSize.y)
            continue;

        if (!isFov(
            Vector3(screenPos.x, screenPos.y, 0),
            Vector3(screenCenter.x, screenCenter.y, 0),
            Vars.AimFov))
            continue;

        Vector3 targetDir = Vector3::Normalized(enemyPos - localPos);
        float angle = Vector3::Angle(targetDir, localForward);
        if (angle > Vars.AimFov * 0.5f)
            continue;

        CHECKPLAYER = true;
        return;
    }
}

void get_players()
{
    ImDrawList *draw_list = ImGui::GetBackgroundDrawList();
    if (!draw_list) return;
    if (!Vars.Enable) return;

    UpdateCHECKPLAYER();
    if (Vars.flyaltura)
        FlyHack22();

    try
    {
        ProcessAimbot();

        void *current_Match = game_sdk->Curent_Match();
        if (!current_Match) return;

        void *local_player = game_sdk->GetLocalPlayer(current_Match);
        if (!local_player) return;

        if (HasMapMarker && Vars.TeleportMark1) {// Thêm dòng này lên đầu
        }

if (local_player) {
    // Chạy Reveal Enemy
    if (RevealEnemy) {
        RunRevealEnemy2();
    }

    // Chạy Xoay xoay
    if (spin360) {
        float delta_fix = 0.01f; // Fix lỗi GetDeltaTime
        RotatePlayer360(local_player, delta_fix);
    }
}

        Dictionary<uint8_t *, void **> *players = *(Dictionary<uint8_t *, void **> **)((long)current_Match + 0x148);
        if (!players) return;

        void *camera = game_sdk->get_camera();
        if (!camera) return;
        
        void *camTransform = game_sdk->Component_GetTransform(camera);
        if (!camTransform) return;

        for (int u = 0; u < players->getSize(); u++)
        {
            void *closestEnemy = players->getValues()[u];
            if (!closestEnemy) continue;
            if (!game_sdk->Component_GetTransform(closestEnemy)) continue;
            if (closestEnemy == local_player) continue;
            if (!game_sdk->get_MaxHP(closestEnemy)) continue;
            if (game_sdk->get_IsDieing(closestEnemy)) continue;
            if (!game_sdk->get_isVisible(closestEnemy)) continue;
            if (game_sdk->get_isLocalTeam(closestEnemy)) continue;

            Vector3 pos = getPosition(closestEnemy);
            Vector3 pos2 = getPosition(local_player);
            float distance = Vector3::Distance(pos, pos2);
            if (distance > 200.0f) continue;
            
            ImColor line_color = ImColor(255, 255, 255);
            bool w2sc;
            ImVec2 top_pos = Camera$$WorldToScreen::Regular(pos + Vector3(0, 1.6, 0));
            ImVec2 bot_pos = Camera$$WorldToScreen::Regular(pos);
            ImVec2 pos_3 = Camera$$WorldToScreen::Checker(pos, w2sc);
            
            auto pmtXtop = top_pos.x;
            auto pmtXbottom = bot_pos.x;
            
            if (top_pos.x > bot_pos.x)
            {
                pmtXtop = bot_pos.x;
                pmtXbottom = top_pos.x;
            }
            
            Camera$$WorldToScreen::Checker(pos + Vector3(0, 0.75f, 0), w2sc);
            float calculatedPosition = fabs((top_pos.y - bot_pos.y) * (0.0092f / 0.019f) / 2);

            ImRect rect(
                ImVec2(pmtXtop - calculatedPosition, top_pos.y),
                ImVec2(pmtXbottom + calculatedPosition, bot_pos.y));
                
            const auto &viewpos = game_sdk->get_position(camTransform);
            
            if (w2sc)
            {
                if (Vars.lines)
                {
                    if (game_sdk->get_IsDieing(closestEnemy))
                        draw_list->AddLine(ImVec2(ImGui::GetIO().DisplaySize.x / 2, 0), ImVec2(rect.GetCenter().x, rect.Min.y), ImColor(255, 0, 0));
                    else
                        draw_list->AddLine(ImVec2(ImGui::GetIO().DisplaySize.x / 2, 0), ImVec2(rect.GetCenter().x, rect.Min.y), line_color);
                }
                if (Vars.Box)
                {
                    if (game_sdk->get_IsDieing(closestEnemy))
                        draw_list->AddRect(rect.Min, rect.Max, ImColor(255, 0, 0));
                    else
                        draw_list->AddRect(rect.Min, rect.Max, ImColor(255, 255, 255));
                    
                    if (Vars.Outline)
                    {
                        draw_list->AddRect(rect.Min - ImVec2(1, 1), rect.Max + ImVec2(1, 1), ImColor(0, 0, 0), 0.65, 0, 1);
                        draw_list->AddRect(rect.Min + ImVec2(1, 1), rect.Max - ImVec2(1, 1), ImColor(0, 0, 0), 0.65, 0, 1);
                    }
                }
                if (Vars.Name)
                {
                    auto pname = game_sdk->name(closestEnemy);
                    std::string names = "null";
                    if (pname)
                        names = pname->toCPPString();
                    std::transform(names.begin(), names.end(), names.begin(), ::tolower);
                    auto playername = names;
                    std::string name = names;
                    ImVec2 text_size = verdana_smol->CalcTextSizeA(8, FLT_MAX, 0, names.c_str());
                    ImVec2 name_pos = {
                        rect.Min.x + (rect.GetWidth() / 2) - text_size.x / 2,
                        rect.Min.y - 2 - text_size.y};
                    AddText(verdana_smol, 8, false, Vars.Outline, name_pos, ImColor(255, 255, 255), name);
                }
                if (Vars.Health)
                {
                    auto health = game_sdk->GetHp(closestEnemy);
                    auto maxhealth = game_sdk->get_MaxHP(closestEnemy);
                    float health_multiplier = (float)health / (float)maxhealth;
                    float health_bar_pos = rect.Min.x - 4;
                    draw_list->AddLine({health_bar_pos, rect.Min.y - 1}, {health_bar_pos, rect.Max.y}, ImColor(0, 0, 0, 100), 3);
                    draw_list->AddLine({health_bar_pos - 0.5f, rect.Max.y}, {health_bar_pos - 0.5f, rect.Max.y - (rect.GetHeight() + 1) * health_multiplier}, ImColor(0, 255, 0), 3);
                    if (Vars.Outline)
                        draw_list->AddRect({health_bar_pos - 2, rect.Min.y - 1}, {health_bar_pos + 2, rect.Max.y + 1}, ImColor(0, 0, 0));
                    std::string hpstr = fmt::format(oxorany("{}HP"), static_cast<int>(health));
                    ImVec2 text_size_hp = pixel_smol->CalcTextSizeA(8, FLT_MAX, 0, hpstr.c_str());
                    ImVec2 text_pos = {
                        rect.Min.x + (rect.GetWidth() / 2) - text_size_hp.x / 2,
                        rect.Max.y};
                    AddText(pixel_smol, 8, false, true, text_pos, ImColor(0, 255, 0), hpstr.c_str());
                }
                if (Vars.Distance)
                {
                    std::string distancestr = fmt::format(oxorany("{}M"), static_cast<int>(distance));
                    ImVec2 distance_pos = {
                        rect.Max.x + 4,
                        rect.Min.y};
                    AddText(pixel_smol, 8, false, true, distance_pos, ImColor(255, 255, 255), distancestr.c_str());
                }
                if (Vars.circlepos)
                {
                    Draw3DCircle(pos, 1.0f, 0.5f, ImColor(255, 0, 0), 36, false, 0.5f);
                }
                if (Vars.skeleton)
                {
                    DrawSkeleton(closestEnemy, draw_list);
                }
            }
            if (Vars.OOF)
            {
                if ((pos_3.x < 0 || pos_3.x > disp.width) || (pos_3.y < 0 || pos_3.y > disp.height) || !w2sc)
                {
                    constexpr int maxpixels = 150;
                    int pixels = maxpixels;
                    if (w2sc)
                    {
                        if (pos_3.x < 0)
                            pixels = clamp((int)-pos_3.x, 0, (int)maxpixels);
                        if (pos_3.y < 0)
                            pixels = clamp((int)-pos_3.y, 0, (int)maxpixels);

                        if (pos_3.x > disp.width)
                            pixels = clamp((int)pos_3.x - (int)disp.width, 0, (int)maxpixels);
                        if (pos_3.y > disp.height)
                            pixels = clamp((int)pos_3.y - (int)disp.height, 0, (int)maxpixels);
                    }

                    float opacity = (float)pixels / (float)maxpixels;
                    float size = 3.5f;
                    Vector3 viewdir = game_sdk->GetForward(camTransform);
                    Vector3 targetdir = Vector3::Normalized(pos - viewpos);

                    float viewangle = atan2(viewdir.z, viewdir.x) * Rad2Deg;
                    float targetangle = atan2(targetdir.z, targetdir.x) * Rad2Deg;

                    if (viewangle < 0) viewangle += 360;
                    if (targetangle < 0) targetangle += 360;

                    float angle = targetangle - viewangle;

                    while (angle < 0) angle += 360;
                    while (angle > 360) angle -= 360;

                    angle = 360 - angle;
                    angle -= 90;
                    OtFovV1(ImGui::GetIO().DisplaySize.x / 2, ImGui::GetIO().DisplaySize.y / 2, 90 + distance * 2,
                            angle - size,
                            angle + size,
                            ImColor(1.f, 1.f, 1.f, 1.f * opacity), 1);
                }
            }
        }
    }
    catch (...)
    {
        return;
    }
}


static float g_flyGravity_velocity = 0.0f;
static bool g_flyGravity_initialized = false;
static std::chrono::steady_clock::time_point g_flyGravity_lastTime;
void ProcessFlyGravity() {
    if (!Vars.FlyGravity) {
        g_flyGravity_initialized = false;
        return;
    }
    
    void* match = game_sdk->Curent_Match();
    if (!match) return;
    void* localPlayer = game_sdk->GetLocalPlayer(match);
    if (!localPlayer) return;
    void* localTransform = game_sdk->Component_GetTransform(localPlayer);
    if (!localTransform) return;
    
    // Sử dụng biến toàn cục hoặc biến trong struct Vars thay vì static để reset được
    static float currentTargetY = 0.0f; 

    if (!g_flyGravity_initialized) {
        Vector3 startPos = game_sdk->get_position(localTransform);
        // Khi vừa bật, mục tiêu là độ cao hiện tại + 3m
        currentTargetY = startPos.y + 3.0f; 
        g_flyGravity_lastTime = std::chrono::high_resolution_clock::now();
        g_flyGravity_initialized = true;
    }
    
    Vector3 currentPos = game_sdk->get_position(localTransform);
    auto now = std::chrono::high_resolution_clock::now();
    float deltaTime = std::chrono::duration<float>(now - g_flyGravity_lastTime).count();
    g_flyGravity_lastTime = now;
    if (deltaTime > 0.1f) deltaTime = 0.016f; 

    Vector3 nextPos = currentPos;

    // 1. LOGIC GIỮ ĐỘ CAO (Mượt hơn)
    float smoothSpeed = 3.0f; 
    if (currentPos.y < currentTargetY) {
        nextPos.y += smoothSpeed * deltaTime;
        if (nextPos.y > currentTargetY) nextPos.y = currentTargetY;
    } else if (currentPos.y > currentTargetY + 0.05f) {
        nextPos.y -= smoothSpeed * deltaTime;
    }

    // 2. DI CHUYỂN THEO CAMERA (Hỗ trợ Speed = 0 để đứng im)
    if (Vars.FlyGravitySpeed > 0.0f) {
        void* mainCam = game_sdk->get_camera();
        if (mainCam) {
            void* camTF = game_sdk->Component_GetTransform(mainCam);
            if (camTF) {
                Vector3 forward = game_sdk->GetForward(camTF);
                // Di chuyển theo hướng nhìn của Camera
                nextPos.x += forward.x * Vars.FlyGravitySpeed * deltaTime;
                nextPos.z += forward.z * Vars.FlyGravitySpeed * deltaTime;
            }
        }
    }

    // 3. THỰC THI
    Transform_INTERNAL_SetPosition(localTransform, Vvector3(nextPos.x, nextPos.y, nextPos.z));
}



void Tele10M() {
    // 1. Sửa lỗi cú pháp: Thêm toán tử OR (||)
    if (!Vars.Enable || !Vars.Tele10M)
        return;

    void *match = game_sdk->Curent_Match();
    if (!match) return;

    void *local = game_sdk->GetLocalPlayer(match);
    // Sửa lỗi cú pháp logic ở đây
    if (!local || !game_sdk->Component_GetTransform(local)) return;

    void *localTF = game_sdk->Component_GetTransform(local);
    
    // Lấy Dictionary người chơi
    Dictionary<uint8_t *, void *> *players = *(Dictionary<uint8_t *, void *> **)((long)match + oxo("0x148"));
    if (!players || players->getValues().empty()) return;

    // Cache các giá trị của Local Player ra ngoài vòng lặp để tối ưu hiệu suất
    Vector3 localPos = game_sdk->get_position(localTF);
    Vector3 forward = game_sdk->GetForward(localTF);

    float pullDistance = 4.0f;
    float maxDistance = 10.0f; 

    // Lấy danh sách values một lần duy nhất
    auto enemyList = players->getValues();

    for (int i = 0; i < players->getSize(); i++) {
        void *enemy = enemyList[i];

        // Các điều kiện lọc mục tiêu
        if (!enemy || enemy == local) continue;
        
        void *enemyTF = game_sdk->Component_GetTransform(enemy);
        if (!enemyTF) continue;

        if (game_sdk->get_IsDieing(enemy)) continue;
        if (game_sdk->get_isLocalTeam(enemy)) continue;

        Vector3 enemyPos = game_sdk->get_position(enemyTF);

        // Kiểm tra khoảng cách
        float distance = Vector3::Distance(localPos, enemyPos);
        if (distance > maxDistance) continue;

        // Tính toán vị trí mục tiêu: Phía trước mặt Local Player
        // Giữ nguyên cao độ (y) của local để tránh địch rơi xuống đất hoặc bay lên trời quá cao
        Vector3 targetPos = {
            localPos.x + (forward.x * pullDistance),
            localPos.y + 0.5f, // Thêm 0.5f để địch nằm hơi cao hơn mặt đất một chút, dễ trúng headshot
            localPos.z + (forward.z * pullDistance)
        };

        // Thực hiện dịch chuyển
        // Lưu ý: Đảm bảo hàm Vvector3 hoặc Vector3 truyền vào đúng kiểu struct của game
        Transform_INTERNAL_SetPosition(enemyTF, Vvector3(targetPos.x, targetPos.y, targetPos.z));
    }
}



void AiPlayer2() {
    // Sửa lỗi logic ||
    if (!Vars.Enable || !Vars.AiPlayer2)
        return;

    void *match = game_sdk->Curent_Match();
    if (!match) return;

    void *local = game_sdk->GetLocalPlayer(match);
    if (!local || !game_sdk->Component_GetTransform(local)) return;

    void *localTF = game_sdk->Component_GetTransform(local);

    Dictionary<uint8_t *, void *> *players = *(Dictionary<uint8_t *, void *> **)((long)match + oxo("0x148"));
    if (!players || players->getValues().empty()) return;

    // Lấy hướng nhìn của mình
    Vector3 forward = game_sdk->GetForward(localTF);
    // Tính toán hướng bên trái (Vuông góc với hướng nhìn)
    Vector3 leftDir = Vector3(-forward.z, 0.0f, forward.x);

    float pullStep = 1.5f;
    float returnStep = 0.4f;

    static int tick = 0;
    tick++;

    auto enemyList = players->getValues();
    for (int i = 0; i < players->getSize(); i++) {
        void *enemy = enemyList[i];
        
        if (!enemy || enemy == local) continue;
        void *enemyTF = game_sdk->Component_GetTransform(enemy);
        if (!enemyTF) continue;
        
        if (game_sdk->get_IsDieing(enemy)) continue;
        if (game_sdk->get_isLocalTeam(enemy)) continue;

        Vector3 enemyPos = game_sdk->get_position(enemyTF);

        // Logic làm rung lắc vị trí địch
        if (tick % 4 != 0) {
            enemyPos.x += leftDir.x * pullStep;
            enemyPos.z += leftDir.z * pullStep;
        } else {
            enemyPos.x -= leftDir.x * returnStep;
            enemyPos.z -= leftDir.z * returnStep;
        }

        // Fix lỗi Vvector3 như lúc nãy nhé
        Transform_INTERNAL_SetPosition(enemyTF, Vvector3(enemyPos.x, enemyPos.y, enemyPos.z));
    }
}




// --- Hook lấy tọa độ điểm Mark ---
void (*orig_UpdateLocalMark)(void* _this, Vector3 p, uint32_t posType, Vector3 realPos);
void Hook_UpdateLocalMark(void* _this, Vector3 p, uint32_t posType, Vector3 realPos) {
    // Lưu lại vị trí khi bạn bấm trên bản đồ
    SavedMapMarker = realPos;
    HasMapMarker = true;

    if (orig_UpdateLocalMark) {
        orig_UpdateLocalMark(_this, p, posType, realPos);
    }
}

// --- Hàm thực thi Teleport ---
void TeleportMarkVoid() {
    // Chỉ thực thi khi bật Checkbox (Vars.TeleportMark1) và đã có điểm đánh dấu
    if (Vars.TeleportMark1 && HasMapMarker) {        
        void* match = game_sdk->Curent_Match();
        if (!match) return;
        
        void* localPlayer = game_sdk->GetLocalPlayer(match);
        if (!localPlayer) return;

        void* tf = game_sdk->Component_GetTransform(localPlayer);
        if (!tf) return;

        Vector3 currentPos = game_sdk->get_position(tf);
        
        // Dịch chuyển X, Z tới điểm mark, giữ nguyên Y (để không bị lún đất)
        Vector3 targetPos;
        targetPos.x = SavedMapMarker.x;
        targetPos.y = currentPos.y + 1.0f; // Nhích lên 1m cho an toàn
        targetPos.z = SavedMapMarker.z;

        // Dùng hàm INTERNAL để thực thi
        Transform_INTERNAL_SetPosition(tf, Vvector3(targetPos.x, targetPos.y, targetPos.z));
        
        // Sau khi Tele xong thì tự tắt checkbox để tránh bị giật (Tùy bạn chọn)
        Vars.TeleportMark1 = false; 
    }
}



void PullPlayer() {
    // Fix lỗi toán tử logic ||
    if (!Vars.Enable || !Vars.PullPlayer)
        return;

    void *match = game_sdk->Curent_Match();
    if (!match) return;

    void *local = game_sdk->GetLocalPlayer(match);
    if (!local) return;

    void *localTF = game_sdk->Component_GetTransform(local);
    if (!localTF) return;

    Dictionary<uint8_t *, void *> *players = *(Dictionary<uint8_t *, void *> **)((long)match + oxo("0x148"));
    if (!players || players->getValues().empty()) return;

    // Lấy vị trí của mình một lần duy nhất ngoài vòng lặp
    Vector3 localPos = game_sdk->get_position(localTF);

    auto enemyList = players->getValues();
    for (int i = 0; i < players->getSize(); i++) {
        void *enemy = enemyList[i];
        
        if (!enemy || enemy == local) continue;
        void *enemyTF = game_sdk->Component_GetTransform(enemy);
        if (!enemyTF) continue;
        
        if (game_sdk->get_IsDieing(enemy)) continue;
        if (game_sdk->get_isLocalTeam(enemy)) continue;

        Vector3 enemyPos = game_sdk->get_position(enemyTF);

        float distance = Vector3::Distance(localPos, enemyPos);

        float minDistance = 10.0f; // Khoảng cách kích hoạt đẩy
        float step = 1.2f;        // Lực đẩy văng ra

        // Nếu địch ở xa hơn 10m thì bỏ qua
        if (distance >= minDistance) continue;

        // Tính toán vector hướng từ mình đến địch
        Vector3 dir = {
            enemyPos.x - localPos.x,
            0.0f,
            enemyPos.z - localPos.z
        };

        // Chuẩn hóa Vector (Normalize) để chỉ lấy hướng
        float length = sqrt(dir.x * dir.x + dir.z * dir.z);
        if (length > 0.01f) {
            dir.x /= length;
            dir.z /= length;
        }

        // Cập nhật vị trí mới (Vị trí hiện tại + hướng * lực đẩy)
        enemyPos.x += dir.x * step;
        enemyPos.z += dir.z * step;

        // Set lại vị trí cho địch
        Transform_INTERNAL_SetPosition(enemyTF, Vvector3(enemyPos.x, enemyPos.y, enemyPos.z));
    }
}



void UpOneEnemy() {
    // 1. Kiểm tra điều kiện bật hack
    if (!Vars.Enable || !Vars.UpPlayerOne)
        return;

    void *match = game_sdk->Curent_Match();
    if (!match) return;

    void *local = game_sdk->GetLocalPlayer(match);
    if (!local) return;

    // 2. Truy cập Dictionary và cache dữ liệu
    auto *players = *(Dictionary<uint8_t *, void **> **)((long)match + oxo("0x148"));
    if (!players) return;

    // Lấy vector và kích thước ra ngoài để vòng lặp chạy mượt hơn
    auto vValues = players->getValues();
    int size = players->getSize();
    
    // Cache vị trí của local player
    void *localTF = game_sdk->Component_GetTransform(local);
    if (!localTF) return;
    Vector3 localPos = game_sdk->get_position(localTF);

    for (int i = 0; i < size; i++) {
        // Sửa lỗi biên dịch: Ép kiểu từ phần tử vector về void*
        void *enemy = (void *)vValues[i];
        
        // 3. Lọc các đối tượng không cần thiết (Nhanh nhất lên đầu)
        if (!enemy || enemy == local) continue;
        if (game_sdk->get_isLocalTeam(enemy)) continue;
        if (game_sdk->get_IsDieing(enemy) || game_sdk->GetHp(enemy) <= 0) continue;

        void *enemyTF = game_sdk->Component_GetTransform(enemy);
        if (!enemyTF) continue;

        Vector3 enemyPos = game_sdk->get_position(enemyTF);
        float distance = Vector3::Distance(localPos, enemyPos);

        // Khoảng cách an toàn để không bị lỗi camera hoặc văng game
        if (distance <= 10.0f) continue;

        // 4. Thiết lập độ cao và tốc độ bay
        // Tăng targetHeight lên để địch bay cao hơn (18.0f - 25.0f)
        float targetHeight = 1.0f; 
        float targetY = enemyPos.y + targetHeight; 
        
        // Tăng step để bay lên dứt khoát, không bị lờ đờ
        float step = 1.75f; 

        // 5. Cập nhật vị trí Y
        if (enemyPos.y < targetY) {
            enemyPos.y += step;
            // Chống tình trạng vượt quá mục tiêu gây giật
            if (enemyPos.y > targetY) enemyPos.y = targetY;
        }

        // Set vị trí mới vào Engine
        Transform_INTERNAL_SetPosition(enemyTF, Vvector3(enemyPos.x, enemyPos.y, enemyPos.z));
    }
}


// Khai báo con trỏ hàm gốc
void (*_AutoFire)(void *_this, int32_t pFireStatus, int32_t pFireMode);

void old_AutoFire(void *_this, int32_t pFireStatus, int32_t pFireMode) 
{
    // Loại bỏ hoàn toàn static clock và các biến delay
    
    if (_this != NULL && AutoFire) 
    {
        // Kiểm tra xem có mục tiêu trong tầm ngắm/quét không
        // Nếu CHECKPLAYER (đã tìm thấy địch) thì ép bắn 0s
        if (CHECKPLAYER) 
        {
            pFireStatus = FireStatus::FIRING; // Ép trạng thái bắn
            pFireMode = FireMode::AUTO;      // Ép chế độ sấy liên thanh
        }
    }

    // Trả về hàm gốc để thực thi lệnh bắn ngay lập tức
    return _AutoFire(_this, pFireStatus, pFireMode);
}


void aimbot()
{
    ImVec2 center = ImVec2(ImGui::GetIO().DisplaySize.x / 2, ImGui::GetIO().DisplaySize.y / 2);
    if (!Vars.Aimbot) return;
        
    ImDrawList *draw_list = ImGui::GetBackgroundDrawList();
    if (!draw_list) return;
        
    void *Match = game_sdk->Curent_Match();
    if (!Match) return;
        
    if (Vars.isAimFov)
    {
        if (Vars.fovaimglow)
            drawcircleglow(draw_list, center, Vars.AimFov, ImColor(Vars.fovLineColor[0], Vars.fovLineColor[1], Vars.fovLineColor[2], Vars.fovLineColor[3]), 999, 1, 12);
        else
            draw_list->AddCircle(center, Vars.AimFov, ImColor(Vars.fovLineColor[0], Vars.fovLineColor[1], Vars.fovLineColor[2], Vars.fovLineColor[3]), 100);
    }
    void *LocalPlayer = game_sdk->GetLocalPlayer(Match);
    if (!LocalPlayer) return;
        
    void *playertarget = GetClosestEnemy();
    if (!playertarget) return;
        
    ImVec2 EnemyLocation = Camera$$WorldToScreen::Regular(GetHeadPosition(playertarget));
    drawlineglow(draw_list, ImVec2(center.x, center.y), EnemyLocation, ImColor(255, 255, 255), 1, 3);
}

void draw_watermark()
{
    std::string claw = oxorany("");
    ImVec2 text_size = verdana_smol->calc_size(1, claw);
    ImVec2 text_pos(
        10, 
        ImGui::GetIO().DisplaySize.y - text_size.y - 10); 
        
    AddText(verdana_smol, 16, false, false, text_pos + ImVec2(1, 1), ImColor(0, 0, 0, 150), claw);
    
    static float hue = 0.0f;
    hue += ImGui::GetIO().DeltaTime * 0.1f;
    if (hue > 1.0f)
        hue = 0.0f;
        
    ImColor rainbow = ImColor::HSV(hue, 0.8f, 0.8f);
    AddText(verdana_smol, 16, false, false, text_pos, rainbow, claw);
    
    ImDrawList *draw_list = ImGui::GetBackgroundDrawList();
    draw_list->AddLine(
        ImVec2(text_pos.x, text_pos.y + text_size.y + 2),
        ImVec2(text_pos.x + text_size.x, text_pos.y + text_size.y + 2),
        rainbow,
        2.0f);
}

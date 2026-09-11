#ifndef VINHTRAN_HPP_INCLUDED
#define VINHTRAN_HPP_INCLUDED

#define ImCalcTextSize(str) ImGui::CalcTextSize(std::string(str).c_str())

#define calc_size(size, str) CalcTextSizeA(size, FLT_MAX, 0, str.c_str())

#define HOOKAF(ret, func, ...)      \
    ret (*old_##func)(__VA_ARGS__); \
    ret hook_##func(__VA_ARGS__)

#define const_ptr(object, offset) *reinterpret_cast<uintptr_t *>(object + offset)

#define Str(ret) std::to_string(ret).c_str()

#define const_ptr_set(type, object, offset) *reinterpret_cast<type *>(object + offset)

#define const_field(type, object, offset) *reinterpret_cast<type *>(reinterpret_cast<uintptr_t>(object) + offset)

#define const_field_set(ret, first, second, val) *reinterpret_cast<ret *>(reinterpret_cast<uintptr_t>(first) + second) = val

#define const_dict(retf, rets, first, second) *reinterpret_cast<monoDictionary<retf, rets> **>(reinterpret_cast<uintptr_t>(first) + second)

#define const_array(retf, first, second) *reinterpret_cast<monoArray<retf> **>(reinterpret_cast<uintptr_t>(first) + second)

static inline ImVec2 operator*(const ImVec2 &lhs, const float rhs) { return ImVec2(lhs.x * rhs, lhs.y * rhs); }
static inline ImVec2 operator/(const ImVec2 &lhs, const float rhs) { return ImVec2(lhs.x / rhs, lhs.y / rhs); }
static inline ImVec2 operator+(const ImVec2 &lhs, const float rhs) { return ImVec2(lhs.x + rhs, lhs.y + rhs); }
static inline ImVec2 operator+(const ImVec2 &lhs, const ImVec2 &rhs) { return ImVec2(lhs.x + rhs.x, lhs.y + rhs.y); }
static inline ImVec2 operator-(const ImVec2 &lhs, const ImVec2 &rhs) { return ImVec2(lhs.x - rhs.x, lhs.y - rhs.y); }
static inline ImVec2 operator-(const ImVec2 &lhs, const float rhs) { return ImVec2(lhs.x - rhs, lhs.y - rhs); }
static inline ImVec2 operator*(const ImVec2 &lhs, const ImVec2 &rhs) { return ImVec2(lhs.x * rhs.x, lhs.y * rhs.y); }
static inline ImVec2 operator/(const ImVec2 &lhs, const ImVec2 &rhs) { return ImVec2(lhs.x / rhs.x, lhs.y / rhs.y); }
static inline ImVec2 &operator*=(ImVec2 &lhs, const float rhs)
{
    lhs.x *= rhs;
    lhs.y *= rhs;
    return lhs;
}
static inline ImVec2 &operator/=(ImVec2 &lhs, const float rhs)
{
    lhs.x /= rhs;
    lhs.y /= rhs;
    return lhs;
}
static inline ImVec2 &operator+=(ImVec2 &lhs, const ImVec2 &rhs)
{
    lhs.x += rhs.x;
    lhs.y += rhs.y;
    return lhs;
}
static inline ImVec2 &operator-=(ImVec2 &lhs, const ImVec2 &rhs)
{
    lhs.x -= rhs.x;
    lhs.y -= rhs.y;
    return lhs;
}
static inline ImVec2 &operator*=(ImVec2 &lhs, const ImVec2 &rhs)
{
    lhs.x *= rhs.x;
    lhs.y *= rhs.y;
    return lhs;
}
static inline ImVec2 &operator/=(ImVec2 &lhs, const ImVec2 &rhs)
{
    lhs.x /= rhs.x;
    lhs.y /= rhs.y;
    return lhs;
}
static inline ImVec4 operator+(const ImVec4 &lhs, const ImVec4 &rhs) { return ImVec4(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z, lhs.w + rhs.w); }
static inline ImVec4 operator-(const ImVec4 &lhs, const ImVec4 &rhs) { return ImVec4(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z, lhs.w - rhs.w); }
static inline ImVec4 operator*(const ImVec4 &lhs, const ImVec4 &rhs) { return ImVec4(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z, lhs.w * rhs.w); }

inline ImVec2 flooring(ImVec2 vec)
{
    return {static_cast<float>(vec.x), (float)int(vec.y)};
}

inline ImVec2 flooring(float x, float y)
{
    return {(float)int(x), (float)int(y)};
}

inline ImVec2 flooring(int x, int y)
{
    return {(float)x, (float)y};
}

void AddText(ImFont *font, float size, bool shadow, bool outline, const ImVec2 &textpos, ImColor col, std::string value, ImDrawList *drawlist = ImGui::GetBackgroundDrawList())
{

    const char *ctext = value.c_str();

    if (outline)
    {
        drawlist->AddText(font, size, flooring(textpos) + ImVec2(-1, -1), ImColor(0.0f, 0.0f, 0.0f, col.Value.w * 0.75f), ctext);
        drawlist->AddText(font, size, flooring(textpos) + ImVec2(0, -1), ImColor(0.0f, 0.0f, 0.0f, col.Value.w * 0.75f), ctext);
        drawlist->AddText(font, size, flooring(textpos) + ImVec2(1, -1), ImColor(0.0f, 0.0f, 0.0f, col.Value.w * 0.75f), ctext);
        drawlist->AddText(font, size, flooring(textpos) + ImVec2(-1, 0), ImColor(0.0f, 0.0f, 0.0f, col.Value.w * 0.75f), ctext);
        drawlist->AddText(font, size, flooring(textpos) + ImVec2(1, 0), ImColor(0.0f, 0.0f, 0.0f, col.Value.w * 0.75f), ctext);
        drawlist->AddText(font, size, flooring(textpos) + ImVec2(-1, 1), ImColor(0.0f, 0.0f, 0.0f, col.Value.w * 0.75f), ctext);
        drawlist->AddText(font, size, flooring(textpos) + ImVec2(0, 1), ImColor(0.0f, 0.0f, 0.0f, col.Value.w * 0.75f), ctext);
        drawlist->AddText(font, size, flooring(textpos) + ImVec2(1, 1), ImColor(0.0f, 0.0f, 0.0f, col.Value.w * 0.75f), ctext);
    }
    if (shadow)
        drawlist->AddText(font, size, {textpos.x + 2, textpos.y + 2}, ImColor(5, 5, 5, (int)float(col.Value.w * 255)), ctext);
    drawlist->AddText(font, size, textpos, col, ctext);
}

void drawcircleglow(ImDrawList *draw, ImVec2 pos, float rad, ImColor col, int segm, int thickness, int size)
{
    draw->AddCircle(pos, rad, col, segm, thickness);
    for (int i = 0; i < size; i++)
    {
        draw->AddCircle(pos, rad, ImColor(col.Value.x, col.Value.y, col.Value.z, col.Value.w * (1.0f / (float)size) * (((float)(size - i)) / (float)size)), segm, thickness + i);
    }
}

inline ImVec2 delvec(ImVec2 a, float b)
{
    return ImVec2(a.x - b, a.y - b);
}
inline ImVec2 addvec(ImVec2 a, float b)
{
    return ImVec2(a.x + b, a.y + b);
}

void OtFovV1(float x, float y, float radius, float min_angle, float max_angle, ImColor col, float thickness)
{
    auto draw = ImGui::GetBackgroundDrawList();
    float half_angle = (max_angle - min_angle) / 2.0f;
    float center_angle = min_angle + half_angle;

    ImVec2 center(x + cos(Deg2Rad * center_angle) * radius, y + sin(Deg2Rad * center_angle) * radius);
    float triangle_side = sin(Deg2Rad * half_angle) * radius * 2.0f;

    ImVec2 p1(center.x + cos(Deg2Rad * (min_angle + half_angle - 120.0f)) * triangle_side / 2.0f,
              center.y + sin(Deg2Rad * (min_angle + half_angle - 120.0f)) * triangle_side / 2.0f);
    ImVec2 p2(center.x + cos(Deg2Rad * (min_angle + half_angle)) * triangle_side / 2.0f,
              center.y + sin(Deg2Rad * (min_angle + half_angle)) * triangle_side / 2.0f);
    ImVec2 p3(center.x + cos(Deg2Rad * (min_angle + half_angle + 120.0f)) * triangle_side / 2.0f,
              center.y + sin(Deg2Rad * (min_angle + half_angle + 120.0f)) * triangle_side / 2.0f);
    ImVec2 p4(center.x + cos(Deg2Rad * (min_angle + half_angle + 90.f)) * triangle_side / 2.0f,
              center.y + sin(Deg2Rad * (min_angle + half_angle)) * triangle_side / 2.0f);

    ImVec2 triangle_center((p1.x + p2.x + p3.x) / 3.0f, (p1.y + p2.y + p3.y) / 3.0f);

    draw->AddQuad(triangle_center, p1, p2, p3, col, 1);

    auto size = thickness * 20;
    for (int i{}; i < size; i++)
    {

        // draw->AddQuad(delvec(triangle_center, i / 2), delvec(p1, i / 2), delvec(p2, i / 2), delvec(p3, i / 2), IM_COL32(col.Value.x * 255,col.Value.y * 255,col.Value.z * 255, 100), 3); //glow

        draw->AddLine(delvec(triangle_center, i / 2), addvec(p1, i / 2), ImColor(col.Value.x, col.Value.y, col.Value.z, col.Value.w * (1.0f / (float)size) * (((float)(size - i)) / (float)size)), thickness + i);

        draw->AddLine(delvec(p1, i / 2), addvec(p2, i / 2), ImColor(col.Value.x, col.Value.y, col.Value.z, col.Value.w * (1.0f / (float)size) * (((float)(size - i)) / (float)size)), thickness + i);

        draw->AddLine(delvec(p3, i / 2), addvec(p4, i / 2), ImColor(col.Value.x, col.Value.y, col.Value.z, col.Value.w * (1.0f / (float)size) * (((float)(size - i)) / (float)size)), thickness + i);

        draw->AddLine(delvec(p4, i / 2), addvec(triangle_center, i / 2), ImColor(col.Value.x, col.Value.y, col.Value.z, col.Value.w * (1.0f / (float)size) * (((float)(size - i)) / (float)size)), thickness + i);
    }
}
struct Vvector3
{
    float X;
    float Y;
    float Z;
    Vvector3() : X(0), Y(0), Z(0) {}
    Vvector3(float X1, float Y1, float Z1) : X(X1), Y(Y1), Z(Z1) {}
    Vvector3(const Vvector3 &v);
    ~Vvector3();
};
Vvector3::Vvector3(const Vvector3 &v) : X(v.X), Y(v.Y), Z(v.Z) {}
Vvector3::~Vvector3() {}

struct display
{
    ImVec2 wh;
    float width;
    float height;
} disp;

#endif // VINHTRAN_HPP_INCLUDED

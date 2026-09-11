static bool should_show = {};
float fade_speed = 0.03f;
float toasttimer = 0;
float toastmaxtime = 0;
const char* toasttext = 0;

void RenderToast() {
    if (toasttimer <= 0) return;
    toasttimer -= ImGui::GetIO().DeltaTime;
    float alpha;
    if (toasttimer >= 0.1f && toasttimer <= toastmaxtime - 0.1f) alpha = 1;
    if (toasttimer < 0.1f) alpha = toasttimer * 10;
    if (toasttimer > toastmaxtime - 0.1f) alpha = (toastmaxtime - toasttimer) * 10;

    ImGui::GetForegroundDrawList()->AddRectFilled(ImVec2(ImGui::GetIO().DisplaySize.x / 2 - ImGui::CalcTextSize(toasttext).x/2 - 20, ImGui::GetIO().DisplaySize.y * 0.8 - ImGui::CalcTextSize(toasttext).y/2 - 20 - alpha * 5),
                                            ImVec2(ImGui::GetIO().DisplaySize.x / 2 + ImGui::CalcTextSize(toasttext).x/2 + 20, ImGui::GetIO().DisplaySize.y * 0.8 + ImGui::CalcTextSize(toasttext).y/2 + 20 - alpha * 5),
                                            ImColor(0.1f,0.1f,0.1f,alpha), 5.0f);

    ImGui::GetForegroundDrawList()->AddText(ImVec2(ImGui::GetIO().DisplaySize.x / 2 - ImGui::CalcTextSize(toasttext).x/2, ImGui::GetIO().DisplaySize.y * 0.8 - ImGui::CalcTextSize(toasttext).y/2 - alpha * 5),
                                                  ImColor(1.0f,1.0f,1.0f,alpha), toasttext);
}

void Toast(const char *text, int length = 1) {
    toasttext = text;
    toasttimer = length;
    toastmaxtime = length;
}


    void update_alpha(bool condition, float& alpha) {
        if (condition) {
            if (alpha < 1.0f) alpha += fade_speed;
            if (alpha > 1.0f) alpha = 1.0f;
        }
        else {
            if (alpha > 0.0f) alpha -= fade_speed;
            if (alpha < 0.0f) alpha = 0.0f;
        }
    }

float back_alpha = 0.f;
    float text_y = 0.f;
    void draw_present() {
        const std::string& text = oxorany("BRUTALTRIP");
        auto draw_list = ImGui::GetBackgroundDrawList();
        const ImVec2& text_szize = pixel_big->calc_size(128, text);
        ImVec2 text_pos = {
            (ImGui::GetIO().DisplaySize.x / 2) - (text_szize.x / 2),(ImGui::GetIO().DisplaySize.y / 2) - (text_szize.y / 2)
        };;

        if (back_alpha) {
            ImGui::GetBackgroundDrawList()->AddRectFilled({ 0,0 }, ImGui::GetIO().DisplaySize, IM_COL32(60, 60, 60, static_cast<int>(100 * back_alpha)));
            AddText(pixel_big, 128, false, 0, text_pos, IM_COL32(255, 255, 255, static_cast<int>(255 * back_alpha)), text);
        }
    }
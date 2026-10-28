TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = MyMenu

MyMenu_FILES = Tweak.mm Menu.mm ESP.mm Loc.mm \
			   esp/Core/AutoFire.mm \
               esp/Core/GhostMode.mm \
               esp/Core/PlayerModes.mm \
               esp/Core/SilentAim.mm \
               esp/Core/SilentAimExternal.mm \
               esp/Core/_0xGL2972_.mm \
               esp/Core/_0xPDFFFF27.mm \
               esp/Core/_0xUNT2872_.mm \
               esp/drawing_view/FloatingFeatureControl.mm \
               esp/drawing_view/_0xE298S9_.mm \
               esp/drawing_view/_0xEDR2862_.mm \
               esp/drawing_view/_0xEPR2872_.mm \
               esp/drawing_view/_0xIC2872_.mm \
               esp/drawing_view/_0xMU2872_.mm

MyMenu_CFLAGS = -fobjc-arc -I$(THEOS_PROJECT_DIR)/sources
MyMenu_CCFLAGS = -std=c++17
MyMenu_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/library.mk
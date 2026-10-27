TARGET := iphone:clang:latest:14.0
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = MyMenu

MyMenu_FILES = Tweak.mm Menu.mm ESP.mm Loc.mm
MyMenu_CFLAGS = -fobjc-arc
MyMenu_CCFLAGS = -std=c++17
MyMenu_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/library.mk

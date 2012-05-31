include /opt/theos/makefiles/common.mk

TWEAK_NAME = LibDisplay
LibDisplay_FILES = Tweak.xm LibDisplay.m
LibDisplay_FRAMEWORKS = Foundation UIKit QuartzCore
LibDisplay_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

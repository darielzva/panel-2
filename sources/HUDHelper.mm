#import "HUDHelper.h"

BOOL IsHUDEnabled(void) { return NO; }
BOOL StartHUD(NSError **error) { return NO; }
void StopHUD(void) {}
void StopHUDWithMessage(NSString *message) {}
NSString *HUDLastStatusMessage(void) { return @""; }
void HUDMarkStarting(void) {}
void HUDMarkReady(void) {}
void HUDRecordFrame(double milliseconds, int players, NSString *aimState) {}
void RequestExitHUDWithMessage(NSString *message) {}
void _0xFFFADK2(BOOL isEnabled) {}
void RequestExitHUD(void) {}

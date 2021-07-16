#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(PJAMMBackgroundPlugin, "PJAMMBackground",
            CAP_PLUGIN_METHOD(enableBackgroundFetch, CAPPluginReturnNone);
            CAP_PLUGIN_METHOD(disableBackgroundFetch, CAPPluginReturnNone);
            CAP_PLUGIN_METHOD(sendBackgroundExitData, CAPPluginReturnPromise);
)

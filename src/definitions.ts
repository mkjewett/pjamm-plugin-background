declare module '@capacitor/core' {
  interface PluginRegistry {
    PJAMMBackground: PJAMMBackgroundPlugin;
  }
}

export interface PJAMMBackgroundPlugin {
  enableBackgroundFetch():void;
  disableBackgroundFetch():void;
  sendBackgroundExitData():void;
}

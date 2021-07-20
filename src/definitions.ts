import { WebPlugin } from "@capacitor/core";

export interface PJAMMBackgroundPlugin extends WebPlugin {
  enableBackgroundFetch():void;
  disableBackgroundFetch():void;
  sendBackgroundExitData():Promise<any>
  sendBatteryData():Promise<any>
}

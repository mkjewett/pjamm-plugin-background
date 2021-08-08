import { WebPlugin } from "@capacitor/core";

export interface PJAMMBackgroundPlugin extends WebPlugin {
  taskBeforeExit():Promise<any>;
  taskFinish(options: FinishOptions): void;
  enableBackgroundFetch():void;
  enableBackgroundFetch():void;
  disableBackgroundFetch():void;
  sendBackgroundExitData():Promise<any>
  sendBatteryData():Promise<any>
}

export interface FinishOptions {
  taskId: string
}

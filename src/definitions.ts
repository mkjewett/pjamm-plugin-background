import { WebPlugin } from "@capacitor/core";

export type CallBackID = string;

export interface PJAMMBackgroundPlugin extends WebPlugin {
  taskBeforeExit(cb: ()=>void):Promise<CallBackID>;
  taskFinish(options: FinishOptions): void;
  enableBackgroundFetch():void;
  enableBackgroundFetch():void;
  disableBackgroundFetch():void;
  sendBackgroundExitData():Promise<any>
  sendBatteryData():Promise<any>
}

export interface FinishOptions {
  taskId: CallBackID
}

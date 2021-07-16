export interface PJAMMBackgroundPlugin {
  enableBackgroundFetch():void;
  disableBackgroundFetch():void;
  sendBackgroundExitData():Promise<any>
}

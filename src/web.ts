import { WebPlugin } from '@capacitor/core';

import type { CallBackID, FinishOptions, PJAMMBackgroundPlugin } from './definitions';

export class PJAMMBackgroundWeb extends WebPlugin implements PJAMMBackgroundPlugin {
  taskBeforeExit(_cb: ()=>void):Promise<CallBackID> {
    throw this.unimplemented('Not implemented on web.');
  }

  taskFinish(_options: FinishOptions) {
    throw this.unimplemented('Not implemented on web.');
  }
  
  enableBackgroundFetch() {
    //Do Nothing
    return;
  }

  disableBackgroundFetch() {
    //Do Nothing
    return;
  }

  sendBackgroundExitData():Promise<any> {
    return Promise.resolve(null);
  }

  sendBatteryData():Promise<any> {
    return Promise.resolve(null);
  }
}

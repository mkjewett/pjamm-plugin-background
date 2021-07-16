import { WebPlugin } from '@capacitor/core';

import type { PJAMMBackgroundPlugin } from './definitions';

export class PJAMMBackgroundWeb extends WebPlugin implements PJAMMBackgroundPlugin {
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
}

import { WebPlugin } from '@capacitor/core';
import { PJAMMBackgroundPlugin } from './definitions';

export class PJAMMBackgroundWeb extends WebPlugin implements PJAMMBackgroundPlugin {
  constructor() {
    super({
      name: 'PJAMMBackground',
      platforms: ['web'],
    });
  }

  enableBackgroundFetch() {
    //Do Nothing
    return;
  }

  disableBackgroundFetch() {
    //Do Nothing
    return;
  }

  sendBackgroundExitData() {
    //Do Nothing
    return;
  }
}

const PJAMMBackground = new PJAMMBackgroundWeb();

export { PJAMMBackground };

import { registerWebPlugin } from '@capacitor/core';
registerWebPlugin(PJAMMBackground);

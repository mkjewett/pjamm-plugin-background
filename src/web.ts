import { WebPlugin } from '@capacitor/core';
import { PJAMMBackgroundPlugin } from './definitions';

export class PJAMMBackgroundWeb extends WebPlugin implements PJAMMBackgroundPlugin {
  constructor() {
    super({
      name: 'PJAMMBackground',
      platforms: ['web'],
    });
  }

  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}

const PJAMMBackground = new PJAMMBackgroundWeb();

export { PJAMMBackground };

import { registerWebPlugin } from '@capacitor/core';
registerWebPlugin(PJAMMBackground);

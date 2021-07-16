import { registerPlugin } from '@capacitor/core';

import type { PJAMMBackgroundPlugin } from './definitions';

const PJAMMBackground = registerPlugin<PJAMMBackgroundPlugin>('PJAMMBackground', {
  web: () => import('./web').then(m => new m.PJAMMBackgroundWeb()),
});

export * from './definitions';
export { PJAMMBackground };

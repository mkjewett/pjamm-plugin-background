declare module '@capacitor/core' {
  interface PluginRegistry {
    PJAMMBackground: PJAMMBackgroundPlugin;
  }
}

export interface PJAMMBackgroundPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}

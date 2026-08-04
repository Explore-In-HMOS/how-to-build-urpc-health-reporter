export interface UrpcServerConfig {
  ip: string;
  port: number;
}

export class UrpcConfigStore {
  private static serverIp: string = 'xxx.xxx.x.xx';
  private static serverPort: number = 9000;

  public static getConfig(): UrpcServerConfig {
    return {
      ip: UrpcConfigStore.serverIp,
      port: UrpcConfigStore.serverPort
    };
  }

  public static saveConfig(ip: string, port: number): void {
    UrpcConfigStore.serverIp = ip.trim();
    UrpcConfigStore.serverPort = port;
  }
}
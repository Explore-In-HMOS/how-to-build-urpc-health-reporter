import {
  UrpcConfigStore, UrpcServerConfig
} from '../model/UrpcConfig';

@Component
export struct ServerSettingsPage {
  @State private serverIp: string = '';
  @State private serverPort: string = '';
  @State private statusText: string =
    'Enter the URPC server endpoint';
  @State private hasError: boolean = false;
  private pageStack: NavPathStack = new NavPathStack();

  private loadCurrentConfig(): void {
    const config: UrpcServerConfig =
      UrpcConfigStore.getConfig();

    this.serverIp = config.ip;
    this.serverPort = config.port.toString();
  }

  private validatePort(portText: string): number {
    const normalizedPort: string = portText.trim();

    if (normalizedPort.length === 0) {
      return -1;
    }

    const port: number = Number(normalizedPort);

    if (!Number.isInteger(port)) {
      return -1;
    }

    if (port < 1 || port > 65535) {
      return -1;
    }

    return port;
  }

  private saveSettings(): void {
    const normalizedIp: string =
      this.serverIp.trim();

    if (normalizedIp.length === 0) {
      this.hasError = true;
      this.statusText = 'Server IP cannot be empty';
      return;
    }

    const validatedPort: number =
      this.validatePort(this.serverPort);

    if (validatedPort < 0) {
      this.hasError = true;
      this.statusText =
        'Port must be between 1 and 65535';
      return;
    }

    UrpcConfigStore.saveConfig(
      normalizedIp,
      validatedPort
    );

    this.hasError = false;
    this.statusText = 'Server configuration saved';

    this.pageStack.pop();
  }

  private cancel(): void {
    this.pageStack.pop();
  }

  @Builder
  private InputLabel(label: string) {
    Text(label)
      .width('100%')
      .fontSize(10)
      .fontWeight(FontWeight.Medium)
      .fontColor('#8E98AA')
      .letterSpacing(0.7)
      .textAlign(TextAlign.Start);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 12 }) {
          Column({ space: 3 }) {
            Text('URPC Server')
              .fontSize(19)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF');

            Text('Remote analytics endpoint')
              .fontSize(10)
              .fontColor('#77808F');
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start);

          Column({ space: 8 }) {
            this.InputLabel('SERVER IP');

            TextInput({
              text: this.serverIp,
              placeholder: 'xxx.xxx.x.xxx'
            })
              .width('100%')
              .height(42)
              .fontSize(13)
              .fontColor('#FFFFFF')
              .placeholderColor('#626C7C')
              .backgroundColor('#1B2130')
              .borderRadius(12)
              .padding({
                left: 12,
                right: 12
              })
              .maxLength(64)
              .onChange((value: string): void => {
                this.serverIp = value;
              });

            this.InputLabel('SERVER PORT');

            TextInput({
              text: this.serverPort,
              placeholder: '9000'
            })
              .width('100%')
              .height(42)
              .type(InputType.Number)
              .fontSize(13)
              .fontColor('#FFFFFF')
              .placeholderColor('#626C7C')
              .backgroundColor('#1B2130')
              .borderRadius(12)
              .padding({
                left: 12,
                right: 12
              })
              .maxLength(5)
              .onChange((value: string): void => {
                this.serverPort = value;
              });
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#121722')
          .borderRadius(18);

          Row({ space: 7 }) {
            Circle()
              .width(7)
              .height(7)
              .fill(
                this.hasError
                  ? '#FF7186'
                  : '#F0B35A'
              );

            Text(this.statusText)
              .fontSize(10)
              .fontColor(
                this.hasError
                  ? '#FF8A9B'
                  : '#AEB7C7'
              )
              .maxLines(2)
              .textOverflow({
                overflow: TextOverflow.Ellipsis
              });
          }
          .width('100%')
          .justifyContent(FlexAlign.Center);

          Button(
            'Save Server',
            {
              type: ButtonType.Capsule
            }
          )
            .width('100%')
            .height(46)
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#07120D')
            .backgroundColor('#42D392')
            .onClick((): void => {
              this.saveSettings();
            });

          Button(
            'Cancel',
            {
              type: ButtonType.Capsule
            }
          )
            .width('100%')
            .height(42)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#222938')
            .onClick((): void => {
              this.cancel();
            });

          Text(
            'The server must support the URPC/EAT protocol. A normal HTTP endpoint cannot receive this request directly.'
          )
            .width('100%')
            .fontSize(9)
            .fontColor('#667080')
            .textAlign(TextAlign.Center)
            .padding({
              left: 8,
              right: 8
            });
        }
        .width('100%')
        .padding({
          left: 12,
          right: 12,
          top: 10,
          bottom: 20
        });
      }
      .padding({ top: 55, bottom: 25 })
      .width('100%')
      .height('100%')
      .backgroundColor('#080B12')
      .scrollBar(BarState.Off);
    }
    .hideTitleBar(true)
    .onReady((context: NavDestinationContext): void => {
      this.pageStack = context.pathStack;
      this.loadCurrentConfig();
    });
  }
}
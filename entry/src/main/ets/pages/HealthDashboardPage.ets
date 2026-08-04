import { abilityAccessCtrl, common, Permissions, PermissionRequestResult } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HealthSensorService } from '../service/HealthSensorService';
import { HealthSnapshot } from '../model/HealthSnapshot';

const HEALTH_PERMISSION: Permissions =
  'ohos.permission.READ_HEALTH_DATA';

const MOTION_PERMISSION: Permissions =
  'ohos.permission.ACTIVITY_MOTION';

@Component
export struct HealthDashboardPage {
  pageStack: NavPathStack = new NavPathStack();
  @State private heartRate: number = 0;
  @State private steps: number = 0;
  @State private isCollecting: boolean = false;
  @State private statusText: string = 'Ready';
  @State private lastUpdatedText: string = '--:--';
  private readonly sensorService: HealthSensorService =
    new HealthSensorService();

  aboutToDisappear(): void {
    this.sensorService.stop();
  }

  private async requestPermissions(): Promise<boolean> {
    const hostContext =
      this.getUIContext().getHostContext();

    if (hostContext === undefined) {
      this.statusText = 'Unable to obtain UIAbility context';
      return false;
    }

    const context: common.UIAbilityContext =
      hostContext as common.UIAbilityContext;

    const atManager: abilityAccessCtrl.AtManager =
      abilityAccessCtrl.createAtManager();

    try {
      const result: PermissionRequestResult =
        await atManager.requestPermissionsFromUser(
          context,
          [
            HEALTH_PERMISSION,
            MOTION_PERMISSION
          ]
        );

      if (result.authResults.length !== 2) {
        this.statusText =
          'Unexpected permission result';
        return false;
      }

      const healthPermissionGranted: boolean =
        result.authResults[0] ===
        abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;

      const motionPermissionGranted: boolean =
        result.authResults[1] ===
        abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;

      return healthPermissionGranted &&
        motionPermissionGranted;
    } catch (error) {
      const businessError: BusinessError =
        error as BusinessError;

      this.statusText =
        `Permission error: ${businessError.code}`;

      return false;
    }
  }

  private async startCollection(): Promise<void> {
    this.statusText = 'Requesting permission...';

    const permissionsGranted: boolean =
      await this.requestPermissions();

    if (!permissionsGranted) {
      this.statusText = 'Sensor permission denied';
      this.isCollecting = false;
      return;
    }

    const started: boolean = this.sensorService.start(
      (heartRate: number): void => {
        this.heartRate = heartRate;
        this.updateLastUpdatedTime();
      },
      (steps: number): void => {
        this.steps = steps;
        this.updateLastUpdatedTime();
      },
      (message: string): void => {
        this.statusText = message;
      }
    );

    if (!started) {
      this.statusText = 'No supported sensor was started';
      this.isCollecting = false;
      return;
    }

    this.isCollecting = true;
    this.statusText = 'Live monitoring';
  }

  private stopCollection(): void {
    this.sensorService.stop();

    this.isCollecting = false;
    this.statusText = 'Monitoring stopped';
  }

  private toggleCollection(): void {
    if (this.isCollecting) {
      this.stopCollection();
      return;
    }

    this.startCollection().catch((): void => {
      this.statusText = 'Unable to start monitoring';
      this.isCollecting = false;
    });
  }

  private openSendDataPage(): void {
    if (this.heartRate <= 0) {
      this.statusText =
        'Wait for a heart rate measurement';
      return;
    }

    const snapshot: HealthSnapshot = {
      timestamp: Date.now(),
      heartRate: this.heartRate,
      steps: this.steps
    };

    this.sensorService.stop();

    this.isCollecting = false;
    this.statusText = 'Snapshot captured';

    this.pageStack.pushPath({
      name: 'SendDataPage',
      param: snapshot
    });
  }

  private updateLastUpdatedTime(): void {
    const currentDate: Date = new Date();

    const hours: string =
      currentDate.getHours()
        .toString()
        .padStart(2, '0');

    const minutes: string =
      currentDate.getMinutes()
        .toString()
        .padStart(2, '0');

    const seconds: string =
      currentDate.getSeconds()
        .toString()
        .padStart(2, '0');

    this.lastUpdatedText =
      `${hours}:${minutes}:${seconds}`;
  }

  @Builder
  private StatusIndicator() {
    Row({ space: 6 }) {
      Circle()
        .width(7)
        .height(7)
        .fill(
          this.isCollecting
            ? '#42D392'
            : '#77808F'
        );

      Text(this.statusText)
        .fontSize(11)
        .fontColor('#AEB7C7')
        .maxLines(1)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        });
    }
    .padding({
      left: 10,
      right: 10,
      top: 6,
      bottom: 6
    })
    .backgroundColor('#151A24')
    .borderRadius(16);
  }

  @Builder
  private HeartRateCard() {
    Column({ space: 3 }) {
      Text('HEART RATE')
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor('#8E98AA')
        .letterSpacing(1);

      Row({ space: 6 }) {
        Text(
          this.heartRate > 0
            ? this.heartRate.toString()
            : '--'
        )
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF');

        Text('BPM')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FF6B81')
          .alignSelf(ItemAlign.End)
          .margin({ bottom: 9 });
      };

      Text(
        this.isCollecting
          ? 'Reading from watch sensor'
          : 'Start monitoring to collect data'
      )
        .fontSize(10)
        .fontColor('#77808F');
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#121722')
    .borderRadius(22)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  private StepsCard() {
    Row() {
      Column({ space: 4 }) {
        Text('TODAY’S STEPS')
          .fontSize(10)
          .fontWeight(FontWeight.Medium)
          .fontColor('#8E98AA')
          .letterSpacing(0.7);

        Text(this.steps.toString())
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF');
      }
      .alignItems(HorizontalAlign.Start);

      Blank();

      Column({ space: 3 }) {
        Text('UPDATED')
          .fontSize(9)
          .fontColor('#77808F');

        Text(this.lastUpdatedText)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#53C8FF');
      }
      .alignItems(HorizontalAlign.End);
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#121722')
    .borderRadius(20);
  }

  build() {
    Scroll() {
      Column({ space: 12 }) {
        Row() {
          Column({ space: 2 }) {
            Text('Health RPC')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF');

            Text('Wearable telemetry')
              .fontSize(10)
              .fontColor('#77808F');
          }
          .alignItems(HorizontalAlign.Start);

          Blank();

          this.StatusIndicator();
        }
        .width('100%');

        this.HeartRateCard();

        this.StepsCard();

        Button(
          this.isCollecting
            ? 'Stop Monitoring'
            : 'Start Monitoring',
          {
            type: ButtonType.Capsule
          }
        )
          .width('100%')
          .height(46)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(
            this.isCollecting
              ? '#FF7186'
              : '#07120D'
          )
          .backgroundColor(
            this.isCollecting
              ? '#2A1820'
              : '#42D392'
          )
          .onClick((): void => {
            this.toggleCollection();
          });

        Button(
          'Review Snapshot',
          {
            type: ButtonType.Capsule
          }
        )
          .width('100%')
          .height(44)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(
            this.heartRate > 0
              ? '#FFFFFF'
              : '#5F6877'
          )
          .backgroundColor(
            this.heartRate > 0
              ? '#2563EB'
              : '#181D27'
          )
          .enabled(this.heartRate > 0)
          .onClick((): void => {
            this.openSendDataPage();
          });

        Text(
          'A snapshot must contain a valid heart rate measurement.'
        )
          .fontSize(9)
          .fontColor('#667080')
          .textAlign(TextAlign.Center)
          .padding({
            left: 10,
            right: 10
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
}
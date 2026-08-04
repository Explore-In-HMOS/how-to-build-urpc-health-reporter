import { HealthSnapshot } from '../model/HealthSnapshot';

import { UrpcConfigStore, UrpcServerConfig } from '../model/UrpcConfig';

import { HealthTrendResult, UrpcClientService } from '../service/UrpcClientService';

import { DemoHealthAnalysisService } from '../service/DemoHealthAnalysisService';

import {HealthMetricCard,RequestStatusView,SendDataActionPanel,SnapshotPreviewCard,UrpcServerCard} from './SendDataComponents';

interface TrendAnalysisNavigationParams { snapshot: HealthSnapshot;result: HealthTrendResult;source: string; }

@Component
export struct SendDataPage {
  @State private heartRate: number = 0;
  @State private steps: number = 0;
  @State private timestamp: number = 0;
  @State private serverIp: string = '';
  @State private serverPort: number = 0;
  @State private requestStatus: string =
    'Snapshot received';
  @State private payloadPreview: string =
    'Preparing snapshot...';
  @State private isSending: boolean = false;
  @State private statusLevel: number = 0;
  private pageStack: NavPathStack =
    new NavPathStack();
  private readonly urpcClientService:
    UrpcClientService =
    new UrpcClientService();
  private readonly demoAnalysisService:
    DemoHealthAnalysisService =
    new DemoHealthAnalysisService();

  aboutToAppear(): void {
    this.refreshServerConfig();
  }

  aboutToDisappear(): void {
    this.urpcClientService.destroy();
  }

  private refreshServerConfig(): void {
    const config: UrpcServerConfig =
      UrpcConfigStore.getConfig();

    this.serverIp = config.ip;
    this.serverPort = config.port;
  }

  private createCurrentSnapshot():
    HealthSnapshot {
    return {
      heartRate: this.heartRate,
      steps: this.steps,
      timestamp: this.timestamp
    };
  }

  private updatePayloadPreview(
    snapshot: HealthSnapshot
  ): void {
    this.payloadPreview =
      `heartRate=${snapshot.heartRate}, ` +
        `steps=${snapshot.steps}, ` +
        `timestamp=${snapshot.timestamp}`;
  }

  private validateSnapshot(): boolean {
    if (this.heartRate > 0) {
      return true;
    }

    this.requestStatus =
      'Heart rate value is invalid';

    this.statusLevel = 3;
    return false;
  }

  private validateServerConfig(): boolean {
    const hasServerIp: boolean =
      this.serverIp.trim().length > 0;

    const hasValidPort: boolean =
      this.serverPort > 0;

    if (hasServerIp && hasValidPort) {
      return true;
    }

    this.requestStatus =
      'Configure the URPC server first';

    this.statusLevel = 3;
    return false;
  }

  private openServerSettings(): void {
    if (this.isSending) {
      return;
    }

    this.pageStack.pushPath({
      name: 'ServerSettingsPage'
    });
  }

  private openTrendAnalysis(
    snapshot: HealthSnapshot,
    result: HealthTrendResult,
    source: string
  ): void {
    const params:
      TrendAnalysisNavigationParams = {
      snapshot: snapshot,
      result: result,
      source: source
    };

    this.pageStack.pushPath({
      name: 'TrendAnalysisPage',
      param: params
    });
  }

  private handleUnexpectedError(
    message: string
  ): void {
    this.isSending = false;
    this.statusLevel = 3;
    this.requestStatus = message;
  }

  private async sendRequest():
    Promise<void> {
    if (this.isSending) {
      return;
    }

    if (!this.validateSnapshot()) {
      return;
    }

    if (!this.validateServerConfig()) {
      return;
    }

    const snapshot: HealthSnapshot =
      this.createCurrentSnapshot();

    this.isSending = true;
    this.statusLevel = 1;

    this.requestStatus =
      `Connecting to ` +
        `${this.serverIp}:${this.serverPort}`;

    this.updatePayloadPreview(snapshot);

    const result: HealthTrendResult =
      await this.urpcClientService
        .sendHealthSnapshot(snapshot);

    this.isSending = false;

    if (!result.success) {
      this.statusLevel = 3;
      this.requestStatus = result.message;
      return;
    }

    this.statusLevel = 2;
    this.requestStatus =
      'URPC analysis received';

    this.openTrendAnalysis(
      snapshot,
      result,
      'URPC'
    );
  }

  private runDemoAnalysis(): void {
    if (this.isSending) {
      return;
    }

    if (!this.validateSnapshot()) {
      return;
    }

    const snapshot: HealthSnapshot =
      this.createCurrentSnapshot();

    this.statusLevel = 1;
    this.requestStatus =
      'Running local demo analysis...';

    const result: HealthTrendResult =
      this.demoAnalysisService
        .analyze(snapshot);

    if (!result.success) {
      this.statusLevel = 3;
      this.requestStatus = result.message;
      return;
    }

    this.statusLevel = 2;
    this.requestStatus =
      'Demo analysis completed';

    this.openTrendAnalysis(
      snapshot,
      result,
      'DEMO'
    );
  }

  private async runUrpcDemo():
    Promise<void> {
    if (this.isSending) {
      return;
    }

    if (!this.validateSnapshot()) {
      return;
    }

    const snapshot: HealthSnapshot =
      this.createCurrentSnapshot();

    this.isSending = true;
    this.statusLevel = 1;

    this.requestStatus =
      'Starting real URPC connection attempt...';

    this.updatePayloadPreview(snapshot);

    const urpcResult: HealthTrendResult =
      await this.urpcClientService
        .sendHealthSnapshot(snapshot);

    if (urpcResult.success) {
      this.isSending = false;
      this.statusLevel = 2;

      this.requestStatus =
        'URPC response received';

      this.openTrendAnalysis(
        snapshot,
        urpcResult,
        'URPC'
      );
      return;
    }

    const localResult: HealthTrendResult =
      this.demoAnalysisService
        .analyze(snapshot);

    if (!localResult.success) {
      this.isSending = false;
      this.statusLevel = 3;
      this.requestStatus =
        localResult.message;
      return;
    }

    const fallbackResult:
      HealthTrendResult = {
      success: true,
      message:
      `Real URPC attempt failed: ` +
        `${urpcResult.message}. ` +
        `The displayed analysis was ` +
        `generated locally as a fallback.`,
      callingId: urpcResult.callingId,
      analysisStatus:
      localResult.analysisStatus,
      trendScore:
      localResult.trendScore,
      recommendation:
      localResult.recommendation
    };

    this.isSending = false;
    this.statusLevel = 2;

    this.requestStatus =
      'URPC attempted · ' +
        'Local fallback displayed';

    this.openTrendAnalysis(
      snapshot,
      fallbackResult,
      'URPC_FALLBACK'
    );
  }

  private cancelRequest(): void {
    const cancellationRequested: boolean =
      this.urpcClientService
        .cancelCurrentCall();

    if (cancellationRequested) {
      this.requestStatus =
        'URPC cancellation requested';
    } else {
      this.requestStatus =
        'No active URPC request';
    }

    this.statusLevel = 0;
  }

  private initializePage(
    context: NavDestinationContext
  ): void {
    this.pageStack = context.pathStack;

    if (context.pathInfo.param === undefined) {
      this.statusLevel = 3;
      this.requestStatus =
        'Health snapshot data is missing';
      return;
    }

    const snapshot: HealthSnapshot =
      context.pathInfo.param as HealthSnapshot;

    this.heartRate = snapshot.heartRate;
    this.steps = snapshot.steps;
    this.timestamp = snapshot.timestamp;

    this.updatePayloadPreview(snapshot);
    this.refreshServerConfig();
  }

  @Builder
  private PageHeader() {
    Column({ space: 3 }) {
      Text('Health Snapshot')
        .fontSize(19)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF');

      Text('Choose an analysis mode')
        .fontSize(10)
        .fontColor('#77808F');
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start);
  }

  @Builder
  private MetricsSection() {
    Row({ space: 8 }) {
      HealthMetricCard({
        label: 'HEART RATE',
        value: this.heartRate.toString(),
        unit: 'BPM'
      });

      HealthMetricCard({
        label: 'STEPS',
        value: this.steps.toString(),
        unit: 'TOTAL'
      });
    }
    .width('100%');
  }

  @Builder
  private PageContent() {
    Column({ space: 12 }) {
      this.PageHeader();

      this.MetricsSection();

      UrpcServerCard({
        serverIp: this.serverIp,
        serverPort: this.serverPort,
        disabled: this.isSending,
        onEdit: (): void => {
          this.openServerSettings();
        }
      });

      SnapshotPreviewCard({
        timestamp: this.timestamp,
        payloadPreview:
        this.payloadPreview
      });

      RequestStatusView({
        statusLevel: this.statusLevel,
        requestStatus:
        this.requestStatus
      });

      SendDataActionPanel({
        isSending: this.isSending,

        onCancel: (): void => {
          this.cancelRequest();
        },

        onSendViaUrpc: (): void => {
          this.sendRequest()
            .catch((): void => {
              this.handleUnexpectedError(
                'Unexpected URPC client error'
              );
            });
        },

        onRunDemo: (): void => {
          this.runUrpcDemo()
            .catch((): void => {
              this.handleUnexpectedError(
                'Unexpected URPC demo error'
              );
            });
        },

        onOpenSettings: (): void => {
          this.openServerSettings();
        },

        onBack: (): void => {
          this.pageStack.pop();
        }
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

  build() {
    NavDestination() {
      Scroll() {
        this.PageContent();
      }
      .padding({
        top: 55,
        bottom: 25
      })
      .width('100%')
      .height('100%')
      .backgroundColor('#080B12')
      .scrollBar(BarState.Off);
    }
    .hideTitleBar(true)
    .onReady(
      (
        context: NavDestinationContext
      ): void => {
        this.initializePage(context);
      }
    );
  }
}
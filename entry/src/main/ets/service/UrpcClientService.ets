import { urpc } from '@kit.RemoteCommunicationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { HealthSnapshot } from '../model/HealthSnapshot';
import {
  UrpcConfigStore, UrpcServerConfig
} from '../model/UrpcConfig';

const DOMAIN: number = 0x0001;
const TAG: string = '[UrpcClientService]';

const ANALYZE_HEALTH_FUNCTION: string =
  'analyzeHealthSnapshot';

class HealthAnalyticsRequest {
  heartRate: urpc.FlowbufElement<number>;
  steps: urpc.FlowbufElement<number>;
  timestamp: urpc.FlowbufElement<number>;

  constructor(snapshot: HealthSnapshot) {
    this.heartRate = {
      type: 'INT32',
      value: snapshot.heartRate,
      name: 'heartRate'
    };

    this.steps = {
      type: 'INT32',
      value: snapshot.steps,
      name: 'steps'
    };

    this.timestamp = {
      type: 'INT64',
      value: snapshot.timestamp,
      name: 'timestamp'
    };
  }
}

class HealthAnalyticsResponse {
  analysisStatus: urpc.FlowbufElement<string>;
  trendScore: urpc.FlowbufElement<number>;
  recommendation: urpc.FlowbufElement<string>;

  constructor() {
    this.analysisStatus = {
      type: 'STRING',
      value: '',
      name: 'analysisStatus'
    };

    this.trendScore = {
      type: 'INT32',
      value: 0,
      name: 'trendScore'
    };

    this.recommendation = {
      type: 'STRING',
      value: '',
      name: 'recommendation'
    };
  }
}

export interface HealthTrendResult {
  success: boolean;
  message: string;
  callingId: number;
  analysisStatus: string;
  trendScore: number;
  recommendation: string;
}

export class UrpcClientService {
  private stub: urpc.UrpcStub | null = null;
  private activeCallingId: number = -1;
  private endpointKey: string = '';

  public async sendHealthSnapshot(
    snapshot: HealthSnapshot
  ): Promise<HealthTrendResult> {
    if (snapshot.heartRate <= 0) {
      return this.createFailureResult(
        'Heart rate must be greater than zero.'
      );
    }

    const serverConfig: UrpcServerConfig =
      UrpcConfigStore.getConfig();

    if (
      serverConfig.ip.trim().length === 0 ||
        serverConfig.port <= 0
    ) {
      return this.createFailureResult(
        'URPC server configuration is invalid.'
      );
    }

    let callingId: number = -1;

    try {
      const currentStub: urpc.UrpcStub =
        await this.getOrCreateStub(serverConfig);

      hilog.info(
        DOMAIN,
        TAG,
        `Stub creation completed. ID: ${currentStub.id}`
      );

      const request: HealthAnalyticsRequest =
        new HealthAnalyticsRequest(snapshot);

      const response: HealthAnalyticsResponse =
        new HealthAnalyticsResponse();

      hilog.info(
        DOMAIN,
        TAG,
        `Calling remote function: ${ANALYZE_HEALTH_FUNCTION}`
      );

      const callResult: urpc.UrpcPromise =
        currentStub.call(
          ANALYZE_HEALTH_FUNCTION,
          request,
          response
        );

      hilog.info(
        DOMAIN,
        TAG,
        `URPC call accepted. Calling ID: ${callResult.callingId}`
      );

      callingId = callResult.callingId;
      this.activeCallingId = callingId;

      hilog.info(
        DOMAIN,
        TAG,
        `URPC call started. Calling ID: ${callingId}`
      );

      await callResult.promise;

      hilog.info(
        DOMAIN,
        TAG,
        `URPC response received. Calling ID: ${callingId}`
      );

      const responseStatus: string =
        response.analysisStatus.value.length > 0
          ? response.analysisStatus.value
          : 'Analysis completed';

      return {
        success: true,
        message: 'URPC response received.',
        callingId: callingId,
        analysisStatus: responseStatus,
        trendScore: response.trendScore.value,
        recommendation: response.recommendation.value
      };
    } catch (error) {
      const businessError: BusinessError =
        error as BusinessError;

      const errorCode: number =
        businessError.code !== undefined
          ? businessError.code
          : -1;

      const errorMessage: string =
        businessError.message !== undefined &&
          businessError.message.length > 0
          ? businessError.message
          : 'No message returned by URPC runtime';

      hilog.error(
        DOMAIN,
        TAG,
        `URPC operation failed. ` +
          `Code: ${errorCode}, ` +
          `message: ${errorMessage}`
      );

      return {
        success: false,
        message: `URPC failed (${errorCode}): ${errorMessage}`,
        callingId: callingId,
        analysisStatus: '',
        trendScore: 0,
        recommendation: ''
      };
    } finally {
      if (this.activeCallingId === callingId) {
        this.activeCallingId = -1;
      }
    }
  }

  public cancelCurrentCall(): boolean {
    if (
      this.stub === null ||
        this.activeCallingId < 0
    ) {
      return false;
    }

    try {
      const callingId: number =
        this.activeCallingId;

      this.stub.cancel(callingId);
      this.activeCallingId = -1;

      hilog.info(
        DOMAIN,
        TAG,
        `URPC cancellation requested. Calling ID: ${callingId}`
      );

      return true;
    } catch (error) {
      const businessError: BusinessError =
        error as BusinessError;

      hilog.error(
        DOMAIN,
        TAG,
        `URPC cancellation failed. Code: ${businessError.code}`
      );

      return false;
    }
  }

  public destroy(): void {
    if (this.stub === null) {
      return;
    }

    if (this.activeCallingId >= 0) {
      try {
        this.stub.cancel(this.activeCallingId);
      } catch (error) {
        const businessError: BusinessError =
          error as BusinessError;

        hilog.warn(
          DOMAIN,
          TAG,
          `Active call could not be cancelled: ` +
            `${businessError.code}`
        );
      }
    }

    try {
      this.stub.destroy();

      hilog.info(
        DOMAIN,
        TAG,
        'URPC stub destroyed.'
      );
    } catch (error) {
      const businessError: BusinessError =
        error as BusinessError;

      hilog.error(
        DOMAIN,
        TAG,
        `URPC stub destroy failed. Code: ` +
          `${businessError.code}`
      );
    }

    this.stub = null;
    this.activeCallingId = -1;
    this.endpointKey = '';
  }

  private async getOrCreateStub(
    serverConfig: UrpcServerConfig
  ): Promise<urpc.UrpcStub> {
    const normalizedIp: string =
      serverConfig.ip.trim();

    const requestedEndpointKey: string =
      `${normalizedIp}:${serverConfig.port}`;

    if (
      this.stub !== null &&
        this.endpointKey === requestedEndpointKey
    ) {
      return this.stub;
    }

    this.destroy();

    const node: urpc.IpAndPort = {
      ip: normalizedIp,
      port: serverConfig.port
    };

    // Resmî örnekteki minimum bağlantı yapılandırması.
    const connectConfiguration:
      urpc.UrpcConnectConfiguration = {
      node: node,
      protocol: 'eat'
    };

    const initConfiguration:
      urpc.UrpcInitConfiguration = {
      timeout: 3000,
      mode: 'client',
      connect: connectConfiguration
    };

    hilog.info(
      DOMAIN,
      TAG,
      `Creating URPC stub. ` +
        `IP: ${normalizedIp}, ` +
        `port: ${serverConfig.port}, ` +
        `protocol: eat`
    );

    const createdStub: urpc.UrpcStub =
      await urpc.urpcStubCreate(
        initConfiguration,
        ANALYZE_HEALTH_FUNCTION
      );

    hilog.info(
      DOMAIN,
      TAG,
      `URPC stub created successfully. ` +
        `Stub ID: ${createdStub.id}`
    );

    this.stub = createdStub;
    this.endpointKey = requestedEndpointKey;

    return createdStub;
  }

  private createFailureResult(
    message: string
  ): HealthTrendResult {
    return {
      success: false,
      message: message,
      callingId: -1,
      analysisStatus: '',
      trendScore: 0,
      recommendation: ''
    };
  }
}
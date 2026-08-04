import { sensor } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0001;
const TAG: string = '[HealthSensorService]';

export type HeartRateListener = (heartRate: number) => void;

export type StepListener = (steps: number) => void;

export type SensorErrorListener = (message: string) => void;

export class HealthSensorService {
  private isRunning: boolean = false;
  private heartRateListener: HeartRateListener | null = null;
  private stepListener: StepListener | null = null;
  private errorListener: SensorErrorListener | null = null;
  private readonly heartRateCallback =
    (data: sensor.HeartRateResponse): void => {
      const heartRate: number = Math.round(data.heartRate);

      hilog.info(
        DOMAIN,
        TAG,
        `Heart rate received: ${heartRate}`
      );

      if (this.heartRateListener !== null) {
        this.heartRateListener(heartRate);
      }
    };
  private readonly pedometerCallback =
    (data: sensor.PedometerResponse): void => {
      const steps: number = Math.round(data.steps);

      hilog.info(
        DOMAIN,
        TAG,
        `Step count received: ${steps}`
      );

      if (this.stepListener !== null) {
        this.stepListener(steps);
      }
    };

  public start(
    heartRateListener: HeartRateListener,
    stepListener: StepListener,
    errorListener: SensorErrorListener
  ): boolean {
    if (this.isRunning) {
      return true;
    }

    this.heartRateListener = heartRateListener;
    this.stepListener = stepListener;
    this.errorListener = errorListener;

    let heartRateStarted: boolean = false;
    let pedometerStarted: boolean = false;

    try {
      sensor.on(
        sensor.SensorId.HEART_RATE,
        this.heartRateCallback,
        {
          interval: 1_000_000_000
        }
      );

      heartRateStarted = true;
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;

      hilog.error(
        DOMAIN,
        TAG,
        `Heart rate sensor error: ${businessError.code}, ${businessError.message}`
      );

      this.reportError(
        `Heart rate sensor could not be started (${businessError.code}).`
      );
    }

    try {
      sensor.on(
        sensor.SensorId.PEDOMETER,
        this.pedometerCallback,
        {
          interval: 1_000_000_000
        }
      );

      pedometerStarted = true;
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;

      hilog.error(
        DOMAIN,
        TAG,
        `Pedometer sensor error: ${businessError.code}, ${businessError.message}`
      );

      this.reportError(
        `Pedometer sensor could not be started (${businessError.code}).`
      );
    }

    this.isRunning = heartRateStarted || pedometerStarted;
    return this.isRunning;
  }

  public stop(): void {
    if (!this.isRunning) {
      return;
    }

    try {
      sensor.off(
        sensor.SensorId.HEART_RATE,
        this.heartRateCallback
      );
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;

      hilog.warn(
        DOMAIN,
        TAG,
        `Heart rate sensor could not be stopped: ${businessError.code}`
      );
    }

    try {
      sensor.off(
        sensor.SensorId.PEDOMETER,
        this.pedometerCallback
      );
    } catch (error) {
      const businessError: BusinessError = error as BusinessError;

      hilog.warn(
        DOMAIN,
        TAG,
        `Pedometer sensor could not be stopped: ${businessError.code}`
      );
    }

    this.isRunning = false;
    this.heartRateListener = null;
    this.stepListener = null;
    this.errorListener = null;

    hilog.info(DOMAIN, TAG, 'Sensor collection stopped.');
  }

  public getRunningState(): boolean {
    return this.isRunning;
  }

  private reportError(message: string): void {
    if (this.errorListener !== null) {
      this.errorListener(message);
    }
  }
}
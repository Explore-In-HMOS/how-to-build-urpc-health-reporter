import { HealthSnapshot } from '../model/HealthSnapshot';
import { HealthTrendResult } from './UrpcClientService';

export class DemoHealthAnalysisService {
  public analyze(
    snapshot: HealthSnapshot
  ): HealthTrendResult {
    if (snapshot.heartRate <= 0) {
      return {
        success: false,
        message: 'A valid heart rate value is required.',
        callingId: -1,
        analysisStatus: '',
        trendScore: 0,
        recommendation: ''
      };
    }

    const heartRateScore: number =
      this.calculateHeartRateSampleScore(
        snapshot.heartRate
      );

    const activityScore: number =
      this.calculateActivitySampleScore(
        snapshot.steps
      );

    const trendScore: number =
      Math.round(
        heartRateScore * 0.6 +
          activityScore * 0.4
      );

    return {
      success: true,
      message: 'Demo analysis completed locally.',
      callingId: -1,
      analysisStatus:
      this.createAnalysisStatus(trendScore),
      trendScore: trendScore,
      recommendation:
      this.createRecommendation(
        trendScore,
        snapshot.steps
      )
    };
  }

  private calculateHeartRateSampleScore(
    heartRate: number
  ): number {
    const referenceValue: number = 75;

    const difference: number =
      Math.abs(heartRate - referenceValue);

    const calculatedScore: number =
      100 - difference * 2;

    return Math.max(
      0,
      Math.min(100, calculatedScore)
    );
  }

  private calculateActivitySampleScore(
    steps: number
  ): number {
    if (steps <= 0) {
      return 0;
    }

    const calculatedScore: number =
      steps / 100;

    return Math.max(
      0,
      Math.min(100, calculatedScore)
    );
  }

  private createAnalysisStatus(
    trendScore: number
  ): string {
    if (trendScore >= 80) {
      return 'High sample score';
    }

    if (trendScore >= 50) {
      return 'Moderate sample score';
    }

    return 'Limited sample score';
  }

  private createRecommendation(
    trendScore: number,
    steps: number
  ): string {
    if (steps <= 0) {
      return 'Collect additional movement data before comparing activity trends.';
    }

    if (trendScore >= 80) {
      return 'Continue collecting snapshots to build a longer-term sample trend.';
    }

    if (trendScore >= 50) {
      return 'Collect more samples at different times of the day for comparison.';
    }

    return 'More sensor samples are required before a meaningful trend can be demonstrated.';
  }
}
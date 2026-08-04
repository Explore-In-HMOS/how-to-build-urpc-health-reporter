import { HealthSnapshot } from '../model/HealthSnapshot';
import { HealthTrendResult } from '../service/UrpcClientService';

interface TrendAnalysisNavigationParams {
  snapshot: HealthSnapshot;
  result: HealthTrendResult;
  source: string;
}

@Component
export struct TrendAnalysisPage {
  @State private heartRate: number = 0;
  @State private steps: number = 0;
  @State private timestamp: number = 0;
  @State private analysisSource: string = '';
  @State private analysisStatus: string = '';
  @State private trendScore: number = 0;
  @State private recommendation: string = '';
  @State private resultMessage: string = '';
  @State private callingId: number = -1;
  private pageStack: NavPathStack =
    new NavPathStack();

  private formatTimestamp(
    timestamp: number
  ): string {
    if (timestamp <= 0) {
      return '--:--:--';
    }

    const date: Date = new Date(timestamp);

    const hours: string =
      date.getHours()
        .toString()
        .padStart(2, '0');

    const minutes: string =
      date.getMinutes()
        .toString()
        .padStart(2, '0');

    const seconds: string =
      date.getSeconds()
        .toString()
        .padStart(2, '0');

    return `${hours}:${minutes}:${seconds}`;
  }

  private getScoreLabel(): string {
    if (this.trendScore >= 80) {
      return 'HIGH';
    }

    if (this.trendScore >= 50) {
      return 'MODERATE';
    }

    return 'LIMITED';
  }

  private getScoreColor(): string {
    if (this.trendScore >= 80) {
      return '#42D392';
    }

    if (this.trendScore >= 50) {
      return '#F0B35A';
    }

    return '#FF7186';
  }

  @Builder
  private SourceBadge() {
    Row({ space: 6 }) {
      Circle()
        .width(7)
        .height(7)
        .fill(
          this.analysisSource === 'URPC'
            ? '#42D392'
            : '#F0B35A'
        );

      Text(this.getSourceLabel())
        .fontSize(9)
        .fontWeight(FontWeight.Medium)
        .fontColor('#C1C8D4')
        .letterSpacing(0.6);
    }
    .padding({
      left: 10,
      right: 10,
      top: 6,
      bottom: 6
    })
    .backgroundColor('#181E2A')
    .borderRadius(14);
  }

  private getSourceLabel(): string {
    if (this.analysisSource === 'URPC') {
      return 'URPC SERVER';
    }

    if (
      this.analysisSource ===
        'URPC_FALLBACK'
    ) {
      return 'URPC + FALLBACK';
    }

    return 'LOCAL DEMO';
  }

  @Builder
  private ScoreCard() {
    Column({ space: 7 }) {
      Text('TREND SCORE')
        .fontSize(10)
        .fontColor('#808A9B')
        .letterSpacing(0.8);

      Text(this.trendScore.toString())
        .fontSize(56)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getScoreColor());

      Text(this.getScoreLabel())
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.getScoreColor())
        .letterSpacing(1);

      Text(this.analysisStatus)
        .fontSize(11)
        .fontColor('#C1C8D4')
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        });
    }
    .width('100%')
    .padding({
      left: 16,
      right: 16,
      top: 18,
      bottom: 18
    })
    .backgroundColor('#121722')
    .borderRadius(22)
    .alignItems(HorizontalAlign.Center);
  }

  @Builder
  private SnapshotCard() {
    Column({ space: 9 }) {
      Text('ANALYZED SNAPSHOT')
        .width('100%')
        .fontSize(9)
        .fontColor('#808A9B')
        .letterSpacing(0.7)
        .textAlign(TextAlign.Start);

      Row() {
        Text('Heart rate')
          .fontSize(10)
          .fontColor('#8E98AA');

        Blank();

        Text(`${this.heartRate} BPM`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF');
      }
      .width('100%');

      Row() {
        Text('Steps')
          .fontSize(10)
          .fontColor('#8E98AA');

        Blank();

        Text(this.steps.toString())
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF');
      }
      .width('100%');

      Row() {
        Text('Captured at')
          .fontSize(10)
          .fontColor('#8E98AA');

        Blank();

        Text(this.formatTimestamp(this.timestamp))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#53C8FF');
      }
      .width('100%');
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#121722')
    .borderRadius(18);
  }

  @Builder
  private RecommendationCard() {
    Column({ space: 8 }) {
      Text('ANALYSIS RESULT')
        .width('100%')
        .fontSize(9)
        .fontColor('#808A9B')
        .letterSpacing(0.7)
        .textAlign(TextAlign.Start);

      Text(this.recommendation)
        .width('100%')
        .fontSize(11)
        .fontColor('#D2D8E2')
        .textAlign(TextAlign.Start)
        .maxLines(5)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        });

      Divider()
        .color('#252B38');

      Text(this.resultMessage)
        .width('100%')
        .fontSize(9)
        .fontColor('#77808F')
        .textAlign(TextAlign.Start);

      if (this.callingId >= 0) {
        Text(`Calling ID: ${this.callingId}`)
          .width('100%')
          .fontSize(8)
          .fontColor('#667080')
          .textAlign(TextAlign.End);
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#121722')
    .borderRadius(18);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column({ space: 12 }) {
          Row() {
            Column({ space: 3 }) {
              Text('Trend Analysis')
                .fontSize(19)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF');

              Text('Health telemetry result')
                .fontSize(10)
                .fontColor('#77808F');
            }
            .alignItems(HorizontalAlign.Start);

            Blank();

            this.SourceBadge();
          }
          .width('100%');

          this.ScoreCard();

          this.SnapshotCard();

          this.RecommendationCard();

          if (this.analysisSource !== 'URPC') {
            Text(
              'A real URPC connection was attempted. Because no compatible server response was received, the displayed result was generated locally and must not be interpreted as medical advice.'
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

          Button(
            'Back to Snapshot',
            {
              type: ButtonType.Capsule
            }
          )
            .width('100%')
            .height(44)
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#222938')
            .onClick((): void => {
              this.pageStack.pop();
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

      const params: TrendAnalysisNavigationParams =
        context.pathInfo.param as TrendAnalysisNavigationParams;

      this.heartRate =
        params.snapshot.heartRate;

      this.steps =
        params.snapshot.steps;

      this.timestamp =
        params.snapshot.timestamp;

      this.analysisSource =
        params.source;

      this.analysisStatus =
        params.result.analysisStatus;

      this.trendScore =
        params.result.trendScore;

      this.recommendation =
        params.result.recommendation;

      this.resultMessage =
        params.result.message;

      this.callingId =
        params.result.callingId;
    });
  }
}
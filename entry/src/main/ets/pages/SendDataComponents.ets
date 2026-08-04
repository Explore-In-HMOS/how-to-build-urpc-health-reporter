@Component
export struct HealthMetricCard {
  @Prop label: string = '';
  @Prop value: string = '';
  @Prop unit: string = '';

  build() {
    Column({ space: 5 }) {
      Text(this.label)
        .fontSize(9)
        .fontColor('#808A9B')
        .letterSpacing(0.6);

      Row({ space: 4 }) {
        Text(this.value)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF');

        Text(this.unit)
          .fontSize(10)
          .fontColor('#53C8FF')
          .alignSelf(ItemAlign.End)
          .margin({ bottom: 5 });
      };
    }
    .layoutWeight(1)
    .height(86)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#121722')
    .borderRadius(18);
  }
}

@Component
export struct UrpcServerCard {
  @Prop serverIp: string = '';
  @Prop serverPort: number = 0;
  @Prop disabled: boolean = false;
  onEdit: () => void = (): void => {
  };

  build() {
    Column({ space: 7 }) {
      Row() {
        Text('URPC SERVER')
          .fontSize(9)
          .fontColor('#808A9B')
          .letterSpacing(0.6);

        Blank();

        Text('EDIT')
          .fontSize(9)
          .fontWeight(FontWeight.Medium)
          .fontColor(
            this.disabled
              ? '#667080'
              : '#53C8FF'
          );
      }
      .width('100%');

      Text(
        `${this.serverIp}:${this.serverPort}`
      )
        .width('100%')
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Start);

      Text('Protocol: EAT · Demo endpoint')
        .width('100%')
        .fontSize(9)
        .fontColor('#77808F')
        .textAlign(TextAlign.Start);
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#121722')
    .borderRadius(18)
    .opacity(this.disabled ? 0.6 : 1.0)
    .onClick((): void => {
      if (this.disabled) {
        return;
      }

      this.onEdit();
    });
  }
}

@Component
export struct SnapshotPreviewCard {
  @Prop timestamp: number = 0;
  @Prop payloadPreview: string = '';

  private formatTimestamp(
    timestamp: number
  ): string {
    if (timestamp <= 0) {
      return '--:--:--';
    }

    const date: Date =
      new Date(timestamp);

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

  build() {
    Column({ space: 6 }) {
      Row() {
        Text('CAPTURED AT')
          .fontSize(9)
          .fontColor('#808A9B');

        Blank();

        Text(
          this.formatTimestamp(
            this.timestamp
          )
        )
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#42D392');
      }
      .width('100%');

      Divider()
        .color('#252B38');

      Text('REQUEST PREVIEW')
        .fontSize(9)
        .fontColor('#808A9B')
        .width('100%')
        .textAlign(TextAlign.Start);

      Text(this.payloadPreview)
        .fontSize(10)
        .fontColor('#C1C8D4')
        .width('100%')
        .maxLines(4)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        });
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#121722')
    .borderRadius(18);
  }
}

@Component
export struct RequestStatusView {
  @Prop statusLevel: number = 0;
  @Prop requestStatus: string = '';

  private getStatusColor(): string {
    if (this.statusLevel === 1) {
      return '#F0B35A';
    }

    if (this.statusLevel === 2) {
      return '#42D392';
    }

    if (this.statusLevel === 3) {
      return '#FF7186';
    }

    return '#77808F';
  }

  build() {
    Row({ space: 6 }) {
      Circle()
        .width(7)
        .height(7)
        .fill(this.getStatusColor());

      Text(this.requestStatus)
        .fontSize(10)
        .fontColor('#AEB7C7')
        .maxLines(3)
        .textOverflow({
          overflow: TextOverflow.Ellipsis
        });
    }
    .width('100%')
    .justifyContent(FlexAlign.Center);
  }
}

@Component
export struct SendDataActionPanel {
  @Prop isSending: boolean = false;
  onCancel: () => void = (): void => {
  };
  onSendViaUrpc: () => void =
    (): void => {
    };
  onRunDemo: () => void =
    (): void => {
    };
  onOpenSettings: () => void =
    (): void => {
    };
  onBack: () => void = (): void => {
  };

  build() {
    Column({ space: 12 }) {
      if (this.isSending) {
        Button(
          'Cancel Request',
          {
            type: ButtonType.Capsule
          }
        )
          .width('100%')
          .height(46)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('#9F3448')
          .onClick((): void => {
            this.onCancel();
          });
      } else {
        Button(
          'Send via URPC',
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
            this.onSendViaUrpc();
          });

        Button(
          'Run URPC Demo',
          {
            type: ButtonType.Capsule
          }
        )
          .width('100%')
          .height(44)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .backgroundColor('#805AD5')
          .onClick((): void => {
            this.onRunDemo();
          });
      }

      Button(
        'Server Settings',
        {
          type: ButtonType.Capsule
        }
      )
        .width('100%')
        .height(42)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .backgroundColor('#2563EB')
        .enabled(!this.isSending)
        .onClick((): void => {
          this.onOpenSettings();
        });

      Button(
        'Back to Live Data',
        {
          type: ButtonType.Capsule
        }
      )
        .width('100%')
        .height(42)
        .fontSize(12)
        .fontColor('#FFFFFF')
        .backgroundColor('#222938')
        .enabled(!this.isSending)
        .onClick((): void => {
          this.onBack();
        });
    }
    .width('100%');
  }
}
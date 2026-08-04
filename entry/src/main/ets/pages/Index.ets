import { HealthDashboardPage } from './HealthDashboardPage';
import { SendDataPage } from './SendDataPage';
import { ServerSettingsPage } from './ServerSettingsPage';
import { TrendAnalysisPage } from './TrendAnalysisPage';

@Entry
@Component
struct Index {
  private pageStack: NavPathStack =
    new NavPathStack();

  @Builder
  private PageMap(name: string) {
    if (name === 'SendDataPage') {
      SendDataPage();
    } else if (name === 'ServerSettingsPage') {
      ServerSettingsPage();
    } else if (name === 'TrendAnalysisPage') {
      TrendAnalysisPage();
    }
  }

  build() {
    Navigation(this.pageStack) {
      HealthDashboardPage({
        pageStack: this.pageStack
      });
    }
    .navDestination(this.PageMap)
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .backgroundColor('#080B12');
  }
}
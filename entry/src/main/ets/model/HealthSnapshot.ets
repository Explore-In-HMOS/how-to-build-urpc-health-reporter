export interface HealthSnapshot {
  timestamp: number;
  heartRate: number;
  steps: number;
}

export function createEmptyHealthSnapshot(): HealthSnapshot {
  return {
    timestamp: Date.now(),
    heartRate: 0,
    steps: 0
  };
}
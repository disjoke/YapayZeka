import Foundation
import Combine

@MainActor
final class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()

    @Published var snapshot: AnalyticsSnapshot
    @Published var isLoadingInsight = false
    @Published var aiInsight = ""

    private init() {
        snapshot = AnalyticsSnapshot(
            impressions: 128_400,
            clicks: 9_820,
            engagementRate: 4.7,
            adSpend: 24_500,
            conversions: 312,
            aiInsight: ""
        )
    }

    func syncFromBackend() async {
        guard BackendConfig.useBackend else { return }
        do {
            snapshot = try await APIClient.shared.fetchAnalytics()
            aiInsight = snapshot.aiInsight
        } catch { /* yerel */ }
    }

    func refreshInsight() async {
        isLoadingInsight = true
        defer { isLoadingInsight = false }

        let metrics = """
        Gösterim: \(snapshot.impressions)
        Tıklama: \(snapshot.clicks)
        Etkileşim: %\(snapshot.engagementRate)
        Harcama: \(snapshot.adSpend) TL
        Dönüşüm: \(snapshot.conversions)
        """

        do {
            if BackendConfig.useBackend {
                aiInsight = try await APIClient.shared.aiAnalyticsInsight(metrics: metrics)
            } else {
                aiInsight = try await AIService.shared.generateAnalyticsInsight(metrics: metrics)
            }
            snapshot.aiInsight = aiInsight
        } catch {
            do {
                aiInsight = try await AIService.shared.generateAnalyticsInsight(metrics: metrics)
            } catch {
                aiInsight = error.localizedDescription
            }
        }
    }
}

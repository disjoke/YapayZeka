import Foundation
import Combine

@MainActor
final class AIAdManager: ObservableObject {
    static let shared = AIAdManager()

    @Published var isLoading = false
    @Published var lastResult = ""
    @Published var lastError: String?

    private init() {}

    func generateAdText(product: String, platform: String, tone: String) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            if BackendConfig.useBackend {
                lastResult = try await APIClient.shared.aiAdCopy(product: product, platform: platform, tone: tone)
            } else {
                lastResult = try await AIService.shared.generateAdCopy(product: product, platform: platform, tone: tone)
            }
        } catch {
            do {
                lastResult = try await AIService.shared.generateAdCopy(product: product, platform: platform, tone: tone)
            } catch {
                lastError = error.localizedDescription
                lastResult = ""
            }
        }
    }

    func planCampaign(budget: Double, audience: String, goal: String) async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        do {
            if BackendConfig.useBackend {
                lastResult = try await APIClient.shared.aiCampaignPlan(budget: budget, audience: audience, goal: goal)
            } else {
                lastResult = try await AIService.shared.generateCampaignPlan(budget: budget, audience: audience, goal: goal)
            }
        } catch {
            do {
                lastResult = try await AIService.shared.generateCampaignPlan(budget: budget, audience: audience, goal: goal)
            } catch {
                lastError = error.localizedDescription
                lastResult = ""
            }
        }
    }
}

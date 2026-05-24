import Foundation
import Combine

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var isLoggedIn = false
    @Published var errorMessage: String?
    @Published var currentUsername: String = ""
    @Published var isLoading = false
    @Published var backendOnline = false

    private let usernameKey = "ekinciler.session.username"

    init() {
        BackendConfig.migrateToCloudIfNeeded()
        if let token = KeychainService.loadSessionToken(), !token.isEmpty {
            isLoggedIn = true
            currentUsername = UserDefaults.standard.string(forKey: usernameKey) ?? "Kullanıcı"
        }
        Task { await checkBackend() }
    }

    func checkBackend() async {
        guard BackendConfig.useBackend else {
            backendOnline = false
            return
        }
        do {
            _ = try await APIClient.shared.health()
            backendOnline = true
        } catch {
            backendOnline = false
        }
    }

    func login(username: String, password: String) async {
        let user = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let pass = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !user.isEmpty, !pass.isEmpty else {
            errorMessage = "Kullanıcı adı ve parola zorunludur."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        if BackendConfig.useBackend {
            do {
                let response = try await APIClient.shared.login(username: user, password: pass)
                guard KeychainService.saveSessionToken(response.token) else {
                    errorMessage = "Oturum kaydedilemedi."
                    return
                }
                UserDefaults.standard.set(response.user.username, forKey: usernameKey)
                currentUsername = response.user.username
                isLoggedIn = true
                backendOnline = true
                await syncAllData()
                return
            } catch {
                if !backendOnline {
                    #if DEBUG
                    loginLocal(user: user, pass: pass)
                    #else
                    errorMessage = AppConfig.cloudUnavailableMessage
                    #endif
                    return
                }
                errorMessage = error.localizedDescription
                return
            }
        }

        #if DEBUG
        loginLocal(user: user, pass: pass)
        #else
        errorMessage = AppConfig.cloudUnavailableMessage
        #endif
    }

    func register(username: String, password: String, email: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIClient.shared.register(username: username, password: password, email: email)
            guard KeychainService.saveSessionToken(response.token) else {
                errorMessage = "Kayıt tamamlandı ancak oturum kaydedilemedi."
                return
            }
            UserDefaults.standard.set(response.user.username, forKey: usernameKey)
            currentUsername = response.user.username
            isLoggedIn = true
            await syncAllData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    #if DEBUG
    private func loginLocal(user: String, pass: String) {
        guard user == "admin" && pass == "1234" else {
            errorMessage = "Kullanıcı adı veya parola geçersiz."
            return
        }
        let token = UUID().uuidString
        guard KeychainService.saveSessionToken(token) else {
            errorMessage = "Oturum kaydedilemedi."
            return
        }
        UserDefaults.standard.set(user, forKey: usernameKey)
        currentUsername = user
        isLoggedIn = true
        errorMessage = nil
    }
    #endif

    func logout() {
        KeychainService.deleteSessionToken()
        UserDefaults.standard.removeObject(forKey: usernameKey)
        isLoggedIn = false
        currentUsername = ""
        errorMessage = nil
    }

    private func syncAllData() async {
        await CustomerManager.shared.syncFromBackend()
        await SchedulingManager.shared.syncFromBackend()
        await BrandManager.shared.syncFromBackend()
        await AnalyticsManager.shared.syncFromBackend()
        await SocialMediaManager.shared.syncFromBackend()
    }
}

import AuthenticationServices
import Combine
import Foundation
import UIKit

@MainActor
final class MetaOAuthService: NSObject, ObservableObject {
    static let shared = MetaOAuthService()

    @Published var isAuthenticating = false
    @Published var lastMessage: String?

    private var session: ASWebAuthenticationSession?
    private static weak var cachedKeyWindow: UIWindow?

    private override init() {
        super.init()
    }

    static func refreshPresentationWindow() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
        guard let scene else { return }
        cachedKeyWindow = scene.keyWindow
            ?? scene.windows.first(where: \.isKeyWindow)
            ?? scene.windows.first
    }

    private static func presentationWindow() -> UIWindow {
        refreshPresentationWindow()
        if let cachedKeyWindow { return cachedKeyWindow }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else {
            fatalError("Aktif UIWindowScene bulunamadı")
        }
        let window = UIWindow(windowScene: scene)
        cachedKeyWindow = window
        return window
    }

    func startOAuth() async {
        guard BackendConfig.useBackend else {
            lastMessage = "Meta OAuth için backend aktif olmalı"
            return
        }

        isAuthenticating = true
        defer { isAuthenticating = false }

        do {
            let url = try await APIClient.shared.startMetaOAuth()
            await presentOAuth(url: url)
        } catch {
            lastMessage = error.localizedDescription
        }
    }

    func handleCallback(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let params = components.queryItems ?? []

        if let error = params.first(where: { $0.name == "error" })?.value {
            lastMessage = "OAuth hatası: \(error)"
            return
        }

        if params.contains(where: { $0.name == "success" && $0.value == "1" }) {
            let username = params.first(where: { $0.name == "username" })?.value?
                .removingPercentEncoding ?? ""
            lastMessage = username.isEmpty
                ? "Facebook ve Instagram başarıyla bağlandı!"
                : "Bağlandı: \(username)"
            Task { await SocialMediaManager.shared.syncFromBackend() }
        }
    }

    private func presentOAuth(url: URL) async {
        Self.refreshPresentationWindow()
        await withCheckedContinuation { continuation in
            session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "ekinciler"
            ) { [weak self] callbackURL, error in
                if let callbackURL {
                    self?.handleCallback(url: callbackURL)
                } else if let error = error as? ASWebAuthenticationSessionError,
                          error.code != .canceledLogin {
                    self?.lastMessage = error.localizedDescription
                }
                continuation.resume()
            }
            session?.presentationContextProvider = self
            session?.prefersEphemeralWebBrowserSession = false
            session?.start()
        }
    }
}

extension MetaOAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> UIWindow {
        MetaOAuthService.presentationWindow()
    }
}

import SwiftUI

@main
struct EkincilerApp: App {
    @StateObject private var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(session)
            .onAppear {
                BackendConfig.migrateToCloudIfNeeded()
                MetaOAuthService.refreshPresentationWindow()
                Task { await session.checkBackend() }
            }
            .onOpenURL { url in
                MetaOAuthService.shared.handleCallback(url: url)
            }
        }
    }
}

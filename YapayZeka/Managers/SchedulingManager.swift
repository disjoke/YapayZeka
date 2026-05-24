import Foundation
import Combine

@MainActor
final class SchedulingManager: ObservableObject {
    static let shared = SchedulingManager()

    @Published var posts: [ScheduledPost] = []

    private let storageKey = "ekinciler.scheduled.posts"

    private init() { load() }

    func syncFromBackend() async {
        guard BackendConfig.useBackend else { return }
        do {
            posts = try await APIClient.shared.fetchPosts()
            save()
        } catch { /* yerel */ }
    }

    func schedule(platform: String, content: String, date: Date, isStory: Bool) async {
        if BackendConfig.useBackend {
            do {
                let iso = ISO8601DateFormatter().string(from: date)
                let created: ScheduledPost = try await APIClient.shared.createPost([
                    "platform": platform,
                    "content": content,
                    "scheduledAt": iso,
                    "isStory": isStory,
                ])
                posts.append(created)
                posts.sort { $0.scheduledAt < $1.scheduledAt }
                save()
                return
            } catch { /* yerel */ }
        }

        let post = ScheduledPost(platform: platform, content: content, scheduledAt: date, isStory: isStory)
        posts.append(post)
        posts.sort { $0.scheduledAt < $1.scheduledAt }
        save()
    }

    func markPublished(_ post: ScheduledPost) {
        guard let index = posts.firstIndex(where: { $0.id == post.id }) else { return }
        posts[index].status = .published
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ScheduledPost].self, from: data) else { return }
        posts = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(posts) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

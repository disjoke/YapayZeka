import Foundation
import Combine

@MainActor
final class CustomerManager: ObservableObject {
    static let shared = CustomerManager()

    @Published var customers: [Customer] = []

    private let storageKey = "ekinciler.customers"

    private init() { load() }

    func syncFromBackend() async {
        guard BackendConfig.useBackend else { return }
        do {
            customers = try await APIClient.shared.fetchCustomers()
            save()
        } catch { /* yerel veri kalır */ }
    }

    func add(name: String, phone: String, email: String, notes: String) async {
        if BackendConfig.useBackend {
            do {
                let created = try await APIClient.shared.createCustomer([
                    "name": name, "phone": phone, "email": email, "notes": notes
                ])
                customers.insert(created, at: 0)
                save()
                return
            } catch { /* yerel kayda düş */ }
        }

        let customer = Customer(name: name, phone: phone, email: email, notes: notes)
        customers.insert(customer, at: 0)
        save()
    }

    func delete(_ customer: Customer) async {
        if BackendConfig.useBackend {
            try? await APIClient.shared.deleteCustomer(id: customer.id)
        }
        customers.removeAll { $0.id == customer.id }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Customer].self, from: data) else { return }
        customers = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(customers) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

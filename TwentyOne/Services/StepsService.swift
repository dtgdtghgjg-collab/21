import Foundation
import HealthKit

final class StepsService {
    static let shared = StepsService()
    private let store = HKHealthStore()
    private init() {}
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    func fetchTodaySteps(completion: @escaping (Int?) -> Void) {
        guard isAvailable, let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { completion(nil); return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
            let steps = stats?.sumQuantity()?.doubleValue(for: .count())
            DispatchQueue.main.async { completion(steps.map { Int($0) }) }
        }
        store.execute(query)
    }
    func requestAndFetch(completion: @escaping (Int?) -> Void) {
        guard isAvailable, let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { completion(nil); return }
        store.requestAuthorization(toShare: [], read: [type]) { [weak self] granted, _ in
            guard granted else { DispatchQueue.main.async { completion(nil) }; return }
            self?.fetchTodaySteps(completion: completion)
        }
    }
}

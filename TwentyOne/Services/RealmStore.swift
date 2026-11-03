import Foundation
import RealmSwift

enum RealmStore {
    static func write(_ block: (Realm) -> Void) {
        guard let realm = try? Realm() else { return }
        if realm.isInWriteTransaction { block(realm); return }
        try? realm.write { block(realm) }
    }
    static func user(in realm: Realm) -> User? { realm.objects(User.self).first }
    static func settings(in realm: Realm) -> AppSettings? { realm.objects(AppSettings.self).first }
    static func live<T: Object>(_ object: T, in realm: Realm) -> T? {
        guard let property = object.objectSchema.primaryKeyProperty, let key = object.value(forKey: property.name) else { return nil }
        return realm.object(ofType: T.self, forPrimaryKey: key)
    }
    static func mutate<T: Object>(_ object: T, _ block: (T) -> Void) {
        write { realm in if let live = live(object, in: realm) { block(live) } }
    }
}

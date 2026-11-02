import XCTest
@testable import TwentyOne

final class BalanceTests: XCTestCase {
    func testXpForNextLevel() {
        XCTAssertEqual(User.xpForNextLevel(1), 80)
        XCTAssertEqual(User.xpForNextLevel(2), 211)
        XCTAssertEqual(User.xpForNextLevel(10), 2009)
    }
    func testBasePrices() {
        XCTAssertEqual(rankBasePrices["F"], 4000)
        XCTAssertEqual(rankBasePrices["D"], 15000)
        XCTAssertEqual(rankBasePrices["R"], 2000000)
    }
    func testCatalogPrice() {
        let cheap = CatalogItem(id: "t1", name: "T", rank: "F", desc: "", slot: "Аксессуар", statName: "Логика", statPoints: 1)
        XCTAssertEqual(cheap.pricePesetas, 4000)
        var expensive = cheap
        expensive.priceMultiplier = 3.0
        XCTAssertEqual(expensive.pricePesetas, 12000)
        var pinpoon = cheap
        pinpoon.isPinpoon = true
        XCTAssertEqual(pinpoon.pricePesetas, 16000)
    }
}

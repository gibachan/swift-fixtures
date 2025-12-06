import Foundation
import Fixtures

@Fixture
struct Vehicle {
    let name: String
    let maker: String
}

@Fixture
struct User {
    let name: String
    var age: Int
    var isRich: Bool

    var vehicle: Vehicle

    @Fixture
    struct Money {
        var yen: Int
    }
    var money: Money

    @Fixture
    enum Rank {
        case bronze, silver, gold
    }
    var rank: Rank

    var points: [Int]
}

@Fixture
enum AccountType {
    case normal, premium
    case administrator
}

@Fixture
class Room {
    let name: String

    init(name: String) {
        self.name = name
    }

    init(fixtureName: String) {  // ⚠️ nameプロパティを初期化していない！
        self.name = fixtureName  // ❌ コンパイルエラーの可能性
    }

    init() {
        self.name = "demo"
    }
}

func test() {
    let user: User = .fixture
    print("fixture user = \(user)")

    let accountType: AccountType = .fixture
    print("fixture accountType = \(accountType)")

    let room: Room = .fixture
    print("fixture room = \(room)")
}

test()

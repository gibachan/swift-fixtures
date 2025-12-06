import Fixtures
import Foundation

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

func test() {
  print("=== Basic Fixture Usage ===")
  let user: User = .fixture
  print("fixture user = \(user)")

  let accountType: AccountType = .fixture
  print("fixture accountType = \(accountType)")

  print("\n=== Using closure with direct property access ===")
  // Closure-based approach with direct property access
  let customUser = User.fixture {
    $0.age = 25
    $0.isRich = true
  }
  print("custom user with closure = \(customUser)")

  // Another example with different values
  let anotherUser = User.fixture {
    $0.age = 30
    $0.isRich = false
  }
  print("user with closure = \(anotherUser)")

  print("\n=== Customizing specific properties ===")
  // Customize only specific properties
  let vehicle1 = Vehicle.fixture {
    $0.name = "Tesla Model 3"
  }
  print("vehicle with custom name = \(vehicle1)")

  let vehicle2 = Vehicle.fixture {
    $0.name = "BMW X5"
    $0.maker = "BMW"
  }
  print("vehicle with custom name and maker = \(vehicle2)")

  // Customize user properties
  let user1 = User.fixture {
    $0.name = "Charlie"
    $0.age = 30
  }
  print("user with custom name and age = \(user1)")

  // Customize with nested fixtures
  let customVehicle = Vehicle.fixture {
    $0.name = "Audi A4"
    $0.maker = "Audi"
  }
  let user2 = User.fixture {
    $0.name = "Diana"
    $0.vehicle = customVehicle
    $0.money = User.Money.fixture { $0.yen = 10000 }
  }
  print("user with custom vehicle and money = \(user2)")

  print("\n=== More examples ===")
  // Customize multiple properties
  let user3 = User.fixture {
    $0.name = "Eve"
    $0.age = 28
    $0.isRich = true
  }
  print("user with multiple custom properties = \(user3)")

  // Complex nested structures
  let complexUser = User.fixture {
    $0.name = "Frank"
    $0.age = 35
    $0.isRich = false
    $0.vehicle = Vehicle.fixture {
      $0.name = "Toyota Camry"
      $0.maker = "Toyota"
    }
    $0.money = User.Money.fixture { $0.yen = 50000 }
  }
  print("complex user with closure = \(complexUser)")
}

test()

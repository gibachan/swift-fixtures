import Fixtures
import Foundation
import XCTest

@Fixture
struct Item {
  let id: Int
  let name: String
}

@Fixture
struct Team {
  let name: String
  let members: [Item]
}

@Fixture
struct Product {
  let price: Double
  let weight: Float
  let stock: UInt
  let category: UInt8
}

@Fixture
struct Event {
  let name: String
  let date: Date
  let website: URL
  let id: UUID
  let attachment: Data
}

@Fixture
struct Config {
  var timeout: Int = 30
  var retryCount: Int = 3
  let serviceName: String
}

@Fixture
struct Person {
  let name: String
  var age: Int
  var email: String
}

final class FixturesTests: XCTestCase {
  func testFixtureInt() {
    XCTAssertEqual(Int.fixture, 1)
  }

  func testFixtureString() {
    XCTAssertEqual(String.fixture, "a")
  }

  func testFixtureBool() {
    XCTAssertEqual(Bool.fixture, true)
  }

  func testFixtureArray() {
    XCTAssertEqual(Array<Int>.fixture, [1, 1, 1])
    XCTAssertEqual(Array<Bool>.fixture, [true, true, true])
    XCTAssertEqual(Array<String>.fixture, ["a", "a", "a"])
  }

  func testFixtureOptional() {
    XCTAssertNil(String?.fixture)
    XCTAssertNil(Int?.fixture)
    XCTAssertNil(Bool?.fixture)
  }

  func testFixtureDictionary() {
    let stringIntDict = [String: Int].fixture
    XCTAssertEqual(stringIntDict, ["a": 1])

    let intStringDict = [Int: String].fixture
    XCTAssertEqual(intStringDict, [1: "a"])

    let stringBoolDict = [String: Bool].fixture
    XCTAssertEqual(stringBoolDict, ["a": true])
  }

  func testFixtureCustomDictionary() {
    let itemDict = [String: Item].fixture
    XCTAssertEqual(itemDict.count, 1)
    XCTAssertEqual(itemDict["a"]?.id, 1)
    XCTAssertEqual(itemDict["a"]?.name, "a")
  }

  func testFixtureCustomArray() {
    let fixtureItems = [Item].fixture
    XCTAssertEqual(fixtureItems.count, 3)
    XCTAssertEqual(fixtureItems[0].id, 1)
    XCTAssertEqual(fixtureItems[0].name, "a")
  }

  func testFixtureStructWithCustomArray() {
    let fixtureTeam = Team.fixture
    XCTAssertEqual(fixtureTeam.name, "a")
    XCTAssertEqual(fixtureTeam.members.count, 3)
    XCTAssertEqual(fixtureTeam.members[0].id, 1)
    XCTAssertEqual(fixtureTeam.members[0].name, "a")
  }

  func testFixtureNumericTypes() {
    XCTAssertEqual(Double.fixture, 1.0)
    XCTAssertEqual(Float.fixture, 1.0)
    XCTAssertEqual(UInt.fixture, 1)
    XCTAssertEqual(UInt8.fixture, 1)
  }

  func testFixtureFoundationTypes() {
    XCTAssertEqual(Date.fixture, Date(timeIntervalSince1970: 0))
    XCTAssertEqual(URL.fixture, URL(string: "https://example.com")!)
    XCTAssertEqual(UUID.fixture, UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    XCTAssertEqual(Data.fixture, Data())
  }

  func testFixtureStructWithNumericTypes() {
    let fixtureProduct = Product.fixture
    XCTAssertEqual(fixtureProduct.price, 1.0)
    XCTAssertEqual(fixtureProduct.weight, 1.0)
    XCTAssertEqual(fixtureProduct.stock, 1)
    XCTAssertEqual(fixtureProduct.category, 1)
  }

  func testFixtureStructWithFoundationTypes() {
    let fixtureEvent = Event.fixture
    XCTAssertEqual(fixtureEvent.name, "a")
    XCTAssertEqual(fixtureEvent.date, Date(timeIntervalSince1970: 0))
    XCTAssertEqual(fixtureEvent.website, URL(string: "https://example.com")!)
    XCTAssertEqual(fixtureEvent.id, UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    XCTAssertEqual(fixtureEvent.attachment, Data())
  }

  func testFixtureStructWithDefaultValues() {
    let fixtureConfig = Config.fixture
    XCTAssertEqual(fixtureConfig.timeout, 1)
    XCTAssertEqual(fixtureConfig.retryCount, 1)
    XCTAssertEqual(fixtureConfig.serviceName, "a")

    let customConfig = Config(
      fixturetimeout: 60, fixtureretryCount: 5, fixtureserviceName: "custom")
    XCTAssertEqual(customConfig.timeout, 60)
    XCTAssertEqual(customConfig.retryCount, 5)
    XCTAssertEqual(customConfig.serviceName, "custom")
  }

  func testFixtureWithClosure() {
    let customItem = Item.fixture {
      $0.id = 100
      $0.name = "Custom Item"
    }
    XCTAssertEqual(customItem.id, 100)
    XCTAssertEqual(customItem.name, "Custom Item")

    let partialItem = Item.fixture {
      $0.name = "Partial"
    }
    XCTAssertEqual(partialItem.id, 1)
    XCTAssertEqual(partialItem.name, "Partial")
  }

  func testFixtureWithClosureForLetProperties() {
    let person = Person.fixture {
      $0.name = "Alice"
    }
    XCTAssertEqual(person.name, "Alice")
    XCTAssertEqual(person.age, 1)
    XCTAssertEqual(person.email, "a")

    let customPerson = Person.fixture {
      $0.name = "Bob"
      $0.age = 30
      $0.email = "bob@example.com"
    }
    XCTAssertEqual(customPerson.name, "Bob")
    XCTAssertEqual(customPerson.age, 30)
    XCTAssertEqual(customPerson.email, "bob@example.com")
  }
}
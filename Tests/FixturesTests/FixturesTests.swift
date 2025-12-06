import Foundation
import Fixtures
import Testing

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

@MainActor
struct FixtureTests {
  @Test
  func fixtureInt() {
    #expect(Int.fixture == 1)
  }
  @Test
  func fixtureString() {
    #expect(String.fixture == "a")
  }
  @Test
  func fixtureBool() {
    #expect(Bool.fixture == true)
  }
  @Test
  func fixtureArray() {
    #expect(Array<Int>.fixture == [1, 1, 1])
    #expect(Array<Bool>.fixture == [true, true, true])
    #expect(Array<String>.fixture == ["a", "a", "a"])
  }
  @Test
  func fixtureOptional() {
    #expect(String?.fixture == nil)
    #expect(Int?.fixture == nil)
    #expect(Bool?.fixture == nil)
  }
  @Test
  func fixtureCustomArray() {
    let fixtureItems = [Item].fixture
    #expect(fixtureItems.count == 3)
    #expect(fixtureItems[0].id == 1)
    #expect(fixtureItems[0].name == "a")
  }
  @Test
  func fixtureStructWithCustomArray() {
    let fixtureTeam = Team.fixture
    #expect(fixtureTeam.name == "a")
    #expect(fixtureTeam.members.count == 3)
    #expect(fixtureTeam.members[0].id == 1)
    #expect(fixtureTeam.members[0].name == "a")
  }
  @Test
  func fixtureNumericTypes() {
    #expect(Double.fixture == 1.0)
    #expect(Float.fixture == 1.0)
    #expect(UInt.fixture == 1)
    #expect(UInt8.fixture == 1)
  }
  @Test
  func fixtureFoundationTypes() {
    #expect(Date.fixture == Date(timeIntervalSince1970: 0))
    #expect(URL.fixture == URL(string: "https://example.com")!)
    #expect(UUID.fixture == UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    #expect(Data.fixture == Data())
  }
  @Test
  func fixtureStructWithNumericTypes() {
    let fixtureProduct = Product.fixture
    #expect(fixtureProduct.price == 1.0)
    #expect(fixtureProduct.weight == 1.0)
    #expect(fixtureProduct.stock == 1)
    #expect(fixtureProduct.category == 1)
  }
  @Test
  func fixtureStructWithFoundationTypes() {
    let fixtureEvent = Event.fixture
    #expect(fixtureEvent.name == "a")
    #expect(fixtureEvent.date == Date(timeIntervalSince1970: 0))
    #expect(fixtureEvent.website == URL(string: "https://example.com")!)
    #expect(fixtureEvent.id == UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    #expect(fixtureEvent.attachment == Data())
  }
  @Test
  func fixtureStructWithDefaultValues() {
    // Test that properties with default values use .fixture
    let fixtureConfig = Config.fixture
    #expect(fixtureConfig.timeout == 1) // Uses .fixture (Int.fixture = 1)
    #expect(fixtureConfig.retryCount == 1) // Uses .fixture (Int.fixture = 1)
    #expect(fixtureConfig.serviceName == "a") // Required parameter

    // Test that we can also create with custom values for properties with defaults
    let customConfig = Config(fixturetimeout: 60, fixtureretryCount: 5, fixtureserviceName: "custom")
    #expect(customConfig.timeout == 60)
    #expect(customConfig.retryCount == 5)
    #expect(customConfig.serviceName == "custom")
  }
}

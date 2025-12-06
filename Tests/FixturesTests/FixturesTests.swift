import Fixtures
import Foundation
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

@Fixture
struct Person {
  let name: String
  var age: Int
  var email: String
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
    #expect(fixtureConfig.timeout == 1)  // Uses .fixture (Int.fixture = 1)
    #expect(fixtureConfig.retryCount == 1)  // Uses .fixture (Int.fixture = 1)
    #expect(fixtureConfig.serviceName == "a")  // Required parameter

    // Test that we can also create with custom values for properties with defaults
    let customConfig = Config(
      fixturetimeout: 60, fixtureretryCount: 5, fixtureserviceName: "custom")
    #expect(customConfig.timeout == 60)
    #expect(customConfig.retryCount == 5)
    #expect(customConfig.serviceName == "custom")
  }

  @Test
  func fixtureWithClosure() {
    // Test with custom struct using closure-based API
    let customItem = Item.fixture {
      $0.id = 100
      $0.name = "Custom Item"
    }
    #expect(customItem.id == 100)
    #expect(customItem.name == "Custom Item")

    // Test customizing only one property
    let partialItem = Item.fixture {
      $0.name = "Partial"
    }
    #expect(partialItem.id == 1)  // Default fixture value
    #expect(partialItem.name == "Partial")
  }

  @Test
  func fixtureWithClosureForLetProperties() {
    // Test closure-based API for struct with let properties
    let person = Person.fixture {
      $0.name = "Alice"
    }
    #expect(person.name == "Alice")
    #expect(person.age == 1)  // Default fixture value
    #expect(person.email == "a")  // Default fixture value

    // Test modifying multiple properties including let
    let customPerson = Person.fixture {
      $0.name = "Bob"
      $0.age = 30
      $0.email = "bob@example.com"
    }
    #expect(customPerson.name == "Bob")
    #expect(customPerson.age == 30)
    #expect(customPerson.email == "bob@example.com")

    // Test customizing only var properties
    let anotherPerson = Person.fixture {
      $0.name = "Charlie"
      $0.age = 25
    }
    #expect(anotherPerson.name == "Charlie")
    #expect(anotherPerson.age == 25)
    #expect(anotherPerson.email == "a")
  }

  @Test
  func fixtureClosureVariations() {
    // Test closure with single property override
    let item1 = Item.fixture {
      $0.name = "Custom Item"
    }
    #expect(item1.id == 1)  // Default fixture value
    #expect(item1.name == "Custom Item")

    // Test closure with multiple property overrides
    let item2 = Item.fixture {
      $0.id = 999
      $0.name = "Special Item"
    }
    #expect(item2.id == 999)
    #expect(item2.name == "Special Item")

    // Test with no customization - use default .fixture
    let item3 = Item.fixture
    #expect(item3.id == 1)
    #expect(item3.name == "a")

    // Test with var properties
    let person1 = Person.fixture {
      $0.name = "Dave"
    }
    #expect(person1.name == "Dave")
    #expect(person1.age == 1)
    #expect(person1.email == "a")

    // Test with struct containing array
    let team = Team.fixture {
      $0.name = "Dream Team"
    }
    #expect(team.name == "Dream Team")
    #expect(team.members.count == 3)  // Default fixture array
  }

  @Test
  func fixtureClosurePattern() {
    // Test closure pattern - customize only specific properties
    let item1 = Item.fixture {
      $0.name = "Custom Item"
    }
    #expect(item1.id == 1)  // Default
    #expect(item1.name == "Custom Item")

    // Test closure pattern - customize multiple properties
    let item2 = Item.fixture {
      $0.id = 999
      $0.name = "Special Item"
    }
    #expect(item2.id == 999)
    #expect(item2.name == "Special Item")

    // Test with let properties
    let item4 = Item.fixture {
      $0.id = 42
    }
    #expect(item4.id == 42)
    #expect(item4.name == "a")  // Default

    // Test closure with nested struct
    let team = Team.fixture {
      $0.name = "Dream Team"
      $0.members = [
        Item.fixture {
          $0.id = 1
          $0.name = "Alice"
        },
        Item.fixture {
          $0.id = 2
          $0.name = "Bob"
        },
      ]
    }
    #expect(team.name == "Dream Team")
    #expect(team.members.count == 2)
    #expect(team.members[0].id == 1)
    #expect(team.members[0].name == "Alice")
    #expect(team.members[1].id == 2)
    #expect(team.members[1].name == "Bob")
  }
}

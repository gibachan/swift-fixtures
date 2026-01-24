import Fixtures
import Foundation

@Fixture
struct User {
  let id: String
  let name: String
  var age: Int

  @Fixture
  enum Role {
    case guest
    case user(String)
    case admin(String, permissions: [String])
  }
  var role: Role
}

#if DEBUG
// Generate fixture with default values
let user: User = .fixture
// User(id: "a", name: "a", age: 1, role: .guest)

// Customize specific properties
let bob = User.fixture {
  $0.name = "Bob"
  $0.age = 30
  $0.role = .admin("admin123", permissions: ["read", "write"])
}
// User(id: "a", name: "Bob", age: 30, role: .admin("admin123", permissions: ["read", "write"]))

print(user)
print(bob)
#else
print("Fixtures are only available in DEBUG builds")
#endif

import Foundation
import SwiftData

@Model
final class Tag {
    @Attribute(.unique) var name: String

    init(name: String) {
        self.name = name
    }
}

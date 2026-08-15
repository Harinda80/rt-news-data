import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var colorHex: String
    var parent: Category?

    init(name: String, colorHex: String, parent: Category? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.parent = parent
    }
}

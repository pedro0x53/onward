import Onward

class TextValidadtor {
    func validate(_ text: String) -> Bool {
        return !text.isEmpty
    }
}

extension OnwardContainer {
    @Inward var validator: TextValidadtor = .init()
}

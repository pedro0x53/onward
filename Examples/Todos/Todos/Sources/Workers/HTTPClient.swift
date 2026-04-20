import Onward

class HTTPClient {
    func request() async -> [ToDo] {
        try? await Task.sleep(for: .seconds(1))
        return [ToDo(title: "Mock", description: "Mock desc.")]
    }
}

extension OnwardContainer {
    @Inward var httpClient: HTTPClient = .init()
}

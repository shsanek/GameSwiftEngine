final class LazyReques<Input: Hashable, Output> {
    private var results: [Input: Output] = [:]
    private let getter: (Input) -> Output

    init(_ getter: @escaping (Input) -> Output) {
        self.getter = getter
    }

    func fetch(with input: Input) -> Output {
        let result = results[input] ?? getter(input)
        results[input] = result
        return result
    }
}

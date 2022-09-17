public struct AnimationFunction {
    let function: (Float) -> Float
}

extension AnimationFunction {
    public static var `default`: Self {
        .init(function: { $0 })
    }

    public static var loop: Self {
        .init(function: {
            if $0 < 0.5 {
                return $0 * 2
            } else {
                return 1 - ($0 - 0.5) * 2
            }
        })
    }
}

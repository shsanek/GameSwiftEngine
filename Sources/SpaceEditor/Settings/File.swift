import SwiftUI

//protocol SettingController {
//    var view: AnyView { get }
//}
//
//struct SliderSettingProvider: SettingController {
//    @State var value: Float
//    let range: ClosedRange<Float>
//    let name: String
//
//    init(
//        name: String,
//        value: Float,
//        range: ClosedRange<Float>,
//
//    ) {
//        self.value = value
//        self.range = range
//        self.name = name
//    }
//
//    var view: AnyView {
//        return AnyView(
//            HStack {
//                Slider(
//                    value: $value
//                    in: range
//                )
//                Text("Value: \(value)")
//            }
//        )
//    }
//}

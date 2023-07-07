import SwiftUI

struct TrigerView: View {
    let updateState: (CGPoint?) -> Void
    @State private var offset = CGSize.zero
    @State private var isDragging = false

    var body: some View {
        // a drag gesture that updates offset and isDragging as it moves around
        let dragGesture = DragGesture()
            .onChanged {
                value in offset = value.translation
                updateState(.init(x: offset.width / 120, y: offset.height / 120))
            }
            .onEnded { _ in
                withAnimation {
                    updateState(nil)
                    offset = .zero
                    isDragging = false
                }
            }

        // a long press gesture that enables isDragging
        let pressGesture = LongPressGesture(minimumDuration: 0.01)
            .onEnded { value in
                withAnimation {
                    isDragging = true
                }
            }

        // a combined gesture that forces the user to long press then drag
        let combined = pressGesture.sequenced(before: dragGesture)

        // a 64x64 circle that scales up when it's dragged, sets its offset to whatever we had back from the drag gesture, and uses our combined gesture
        HStack {
            Spacer()
            VStack {
                Spacer()
                Circle()
                    .fill(.red)
                    .frame(width: 40, height: 40)
                    .scaleEffect(isDragging ? 0.8 : 1)
                    .offset(offset)
                    .gesture(combined)
                Spacer()
            }.frame(height: 120)
            Spacer()
        }.frame(width: 120)
    }
}

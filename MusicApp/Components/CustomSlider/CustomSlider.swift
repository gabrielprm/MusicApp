import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    
    var range: ClosedRange<Double> = 0...1
    var onEditingChanged: (Bool) -> Void = { _ in }

    var trackHeight: CGFloat = 6
    var thumbSize: CGFloat = 18

    @State private var isDragging = false

    var body: some View {
        GeometryReader { geometry in
            let dragGesture = DragGesture(minimumDistance: 0)
                .onChanged { gestureValue in
                    if !isDragging {
                        isDragging = true
                        onEditingChanged(true)
                    }
                    
                    let totalWidth = geometry.size.width
                    let percentage = max(0, min(1, gestureValue.location.x / totalWidth))
                    let newValue = range.lowerBound + percentage * (range.upperBound - range.lowerBound)
                    
                    self.value = newValue
                }
                .onEnded { _ in
                    isDragging = false
                    onEditingChanged(false)
                }

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: geometry.size.width, height: trackHeight)

                Capsule()
                    .fill(Color.white)
                    .frame(width: calculateFilledWidth(totalWidth: geometry.size.width), height: trackHeight)

                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: calculateThumbOffsetX(totalWidth: geometry.size.width))
                    .gesture(dragGesture)
            }
            .frame(height: thumbSize)
        }
        .frame(height: thumbSize)
    }

    private func calculateFilledWidth(totalWidth: CGFloat) -> CGFloat {
        let percentage = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        return totalWidth * CGFloat(percentage)
    }

    private func calculateThumbOffsetX(totalWidth: CGFloat) -> CGFloat {
        return calculateFilledWidth(totalWidth: totalWidth) - (thumbSize / 2)
    }
}

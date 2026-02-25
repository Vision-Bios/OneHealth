import SwiftUI

struct HealthArtBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.18),
                    Color(red: 0.10, green: 0.12, blue: 0.30),
                    Color(red: 0.08, green: 0.04, blue: 0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color(red: 0.98, green: 0.47, blue: 0.47, opacity: 0.60),
                    Color(red: 0.30, green: 0.74, blue: 0.94, opacity: 0.05)
                ],
                center: .top,
                startRadius: 20,
                endRadius: 300
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [
                    Color(red: 0.24, green: 0.95, blue: 0.86, opacity: 0.30),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 10,
                endRadius: 260
            )
            .blendMode(.plusLighter)
        }
        .ignoresSafeArea()
    }
}

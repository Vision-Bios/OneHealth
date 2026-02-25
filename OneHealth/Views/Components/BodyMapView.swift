import SwiftUI

struct BodyMapView: View {
    let selectedRegion: BodyRegion
    let onSelect: (BodyRegion) -> Void
    let profile: BodyProfile

    private let spots: [BodySpot] = [
        BodySpot(region: .head, x: 0.50, y: 0.12),
        BodySpot(region: .chest, x: 0.50, y: 0.30),
        BodySpot(region: .abdomen, x: 0.50, y: 0.46),
        BodySpot(region: .pelvis, x: 0.50, y: 0.62),
        BodySpot(region: .leftArm, x: 0.28, y: 0.34),
        BodySpot(region: .rightArm, x: 0.72, y: 0.34),
        BodySpot(region: .leftLeg, x: 0.44, y: 0.80),
        BodySpot(region: .rightLeg, x: 0.56, y: 0.80)
    ]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                if profile == .realistic {
                    Image(profile.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: size.width * 0.78)
                        .opacity(0.95)
                        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)
                } else {
                    BodySilhouetteShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.62, green: 0.48, blue: 0.98, opacity: 0.65),
                                    Color(red: 0.25, green: 0.65, blue: 0.95, opacity: 0.30),
                                    Color(red: 0.95, green: 0.45, blue: 0.60, opacity: 0.20)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            BodySilhouetteShape()
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.20), radius: 18, x: 0, y: 12)
                }

                ForEach(spots) { spot in
                    BodyHotspot(
                        region: spot.region,
                        isSelected: spot.region == selectedRegion,
                        onSelect: onSelect
                    )
                    .position(
                        x: size.width * spot.x,
                        y: size.height * spot.y
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 320)
    }
}

private struct BodySpot: Identifiable {
    let id = UUID()
    let region: BodyRegion
    let x: CGFloat
    let y: CGFloat
}

private struct BodyHotspot: View {
    let region: BodyRegion
    let isSelected: Bool
    let onSelect: (BodyRegion) -> Void

    var body: some View {
        Button {
            onSelect(region)
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(isSelected ? 0.30 : 0.12))
                    .frame(width: isSelected ? 42 : 20, height: isSelected ? 42 : 20)
                    .shadow(color: Color(red: 0.36, green: 0.75, blue: 0.98, opacity: 0.70), radius: 16, x: 0, y: 8)

                Circle()
                    .stroke(Color.white.opacity(isSelected ? 0.95 : 0.35), lineWidth: isSelected ? 2 : 1)
                    .frame(width: isSelected ? 24 : 12, height: isSelected ? 24 : 12)

                if isSelected {
                    Text(region.displayName)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.35))
                        )
                        .offset(y: 28)
                }
            }
            .frame(width: 80, height: 80)
        }
        .buttonStyle(.plain)
    }
}

private struct BodySilhouetteShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Head
        let head = CGRect(x: w * 0.40, y: h * 0.02, width: w * 0.20, height: h * 0.16)
        path.addEllipse(in: head)

        // Neck + shoulders + torso as a single curved silhouette
        path.move(to: CGPoint(x: w * 0.50, y: h * 0.16))
        path.addCurve(
            to: CGPoint(x: w * 0.18, y: h * 0.30),
            control1: CGPoint(x: w * 0.42, y: h * 0.18),
            control2: CGPoint(x: w * 0.26, y: h * 0.22)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.26, y: h * 0.58),
            control1: CGPoint(x: w * 0.12, y: h * 0.40),
            control2: CGPoint(x: w * 0.16, y: h * 0.50)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.38, y: h * 0.70),
            control1: CGPoint(x: w * 0.30, y: h * 0.64),
            control2: CGPoint(x: w * 0.34, y: h * 0.68)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.42, y: h * 0.98),
            control1: CGPoint(x: w * 0.34, y: h * 0.82),
            control2: CGPoint(x: w * 0.36, y: h * 0.92)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.58, y: h * 0.98),
            control1: CGPoint(x: w * 0.46, y: h * 1.00),
            control2: CGPoint(x: w * 0.54, y: h * 1.00)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.62, y: h * 0.70),
            control1: CGPoint(x: w * 0.64, y: h * 0.92),
            control2: CGPoint(x: w * 0.66, y: h * 0.82)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.74, y: h * 0.58),
            control1: CGPoint(x: w * 0.66, y: h * 0.68),
            control2: CGPoint(x: w * 0.70, y: h * 0.64)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.82, y: h * 0.30),
            control1: CGPoint(x: w * 0.84, y: h * 0.50),
            control2: CGPoint(x: w * 0.88, y: h * 0.40)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.50, y: h * 0.16),
            control1: CGPoint(x: w * 0.74, y: h * 0.22),
            control2: CGPoint(x: w * 0.58, y: h * 0.18)
        )
        path.closeSubpath()

        return path
    }
}


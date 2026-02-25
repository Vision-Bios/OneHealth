import SwiftUI

struct HeaderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

struct RegionFilterRow: View {
    let selectedRegion: BodyRegion
    let onSelect: (BodyRegion) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(BodyRegion.allCases) { region in
                    Button {
                        onSelect(region)
                    } label: {
                        Text(region.displayName)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedRegion == region ? Color.white.opacity(0.24) : Color.white.opacity(0.10))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

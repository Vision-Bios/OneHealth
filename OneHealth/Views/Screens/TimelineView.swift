import SwiftUI

struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                HealthArtBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HeaderView(
                            title: "Timeline",
                            subtitle: "Every record you add lights up your life-long story."
                        )

                        ProgressCard(
                            progress: viewModel.progress,
                            label: viewModel.progressLabel
                        )

                        RewardsCard(rewards: viewModel.rewards, nextReward: viewModel.nextRewardLabel)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Records")
                                .font(.headline)
                                .foregroundColor(.white)

                            ForEach(viewModel.items) { item in
                                TimelineRow(item: item)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .onAppear {
            viewModel.load()
        }
    }
}

private struct ExportButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                Text("Export Data")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.16))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ImportButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                Text("Import Data")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.16))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct PasteButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard")
                Text("Paste CSV")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.16))
            )
        }
        .buttonStyle(.plain)
    }
}

private struct ProgressCard: View {
    let progress: Double
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress")
                .font(.headline)
                .foregroundColor(.white)

            ProgressView(value: progress)
                .tint(Color(red: 0.30, green: 0.74, blue: 0.94))

            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

private struct RewardsCard: View {
    let rewards: [Reward]
    let nextReward: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rewards")
                .font(.headline)
                .foregroundColor(.white)

            Text(nextReward)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.75))

            VStack(spacing: 10) {
                ForEach(rewards) { reward in
                    HStack {
                        Image(systemName: reward.isUnlocked ? "sparkles" : "lock")
                            .foregroundColor(reward.isUnlocked ? Color(red: 0.45, green: 0.85, blue: 0.98) : .white.opacity(0.5))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reward.title)
                                .foregroundColor(.white)
                                .font(.subheadline.weight(.semibold))
                            Text(reward.message)
                                .foregroundColor(.white.opacity(0.75))
                                .font(.caption)
                        }
                        Spacer()
                        Text("\(reward.threshold)")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }
}

private struct TimelineRow: View {
    let item: TimelineItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(kindColor)
                .frame(width: 12, height: 12)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(HealthDateFormatter.shortDate.string(from: item.date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))

                Label(item.region.displayName, systemImage: item.region.systemImage)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
    }

    private var kindColor: Color {
        switch item.kind {
        case .vaccine:
            return Color(red: 0.30, green: 0.74, blue: 0.94)
        case .diagnostic:
            return Color(red: 0.98, green: 0.47, blue: 0.47)
        case .medication:
            return Color(red: 0.60, green: 0.42, blue: 0.95)
        }
    }
}

#Preview {
    TimelineView()
}

import SwiftUI

struct MoreView: View {
    @StateObject private var timelineViewModel = TimelineViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                HealthArtBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HeaderView(
                            title: "More",
                            subtitle: "Explore your timeline and data tools."
                        )

                        RewardsSummaryCard(
                            progressLabel: timelineViewModel.progressLabel,
                            nextReward: timelineViewModel.nextRewardLabel,
                            unlockedCount: timelineViewModel.rewards.filter(\.isUnlocked).count
                        )

                        VStack(spacing: 12) {
                            NavigationLink {
                                TimelineView()
                            } label: {
                                MoreActionCard(
                                    title: "Timeline",
                                    subtitle: "See your full record history.",
                                    systemImage: "clock.arrow.circlepath"
                                )
                            }

                            NavigationLink {
                                DataHandlingView()
                            } label: {
                                MoreActionCard(
                                    title: "Data Handling",
                                    subtitle: "Export, import, and backup.",
                                    systemImage: "tray.full"
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
        }
        .onAppear {
            timelineViewModel.load()
        }
    }
}

private struct RewardsSummaryCard: View {
    let progressLabel: String
    let nextReward: String
    let unlockedCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Rewards")
                .font(.headline)
                .foregroundColor(.white)
            Text(progressLabel)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Text(nextReward)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text("\(unlockedCount) unlocked")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
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

private struct MoreActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white.opacity(0.18)))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.headline)
                Text(subtitle)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
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

#Preview {
    MoreView()
}

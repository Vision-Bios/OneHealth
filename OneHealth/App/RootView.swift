import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            VaccinesView()
                .tabItem {
                    Label("Vaccines", systemImage: "shield.lefthalf.filled")
                }

            DiagnosticsView()
                .tabItem {
                    Label("Diagnostics", systemImage: "waveform.path.ecg")
                }

            MedicationsView()
                .tabItem {
                    Label("Meds", systemImage: "pills")
                }

            HealthAssistantView()
                .tabItem {
                    Label("Assistant", systemImage: "mic.fill")
                }

            MoreView()
                .tabItem {
                    Label("More", systemImage: "square.grid.2x2")
                }
        }
    }
}

#Preview {
    RootView()
}

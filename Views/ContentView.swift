//
//  ContentView.swift
//  voice-gmail-assistant
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DemoRoot()
    }
}

private struct DemoRoot: View {
    #if DEBUG
    @State private var route: DemoRoute = .main
    #endif

    var body: some View {
        #if DEBUG
        ZStack(alignment: .topTrailing) {
            Group {
                switch route {
                case .main:
                    MainPageView()
                case .settings:
                    SettingsView()
                case .voice:
                    VoiceChatView2()
                }
            }
            DevSwitcher(route: $route)
        }
        #else
        // Release/TestFlight: always show the mock main page
        MainPageView()
        #endif
    }
}

#if DEBUG
private enum DemoRoute: String, CaseIterable, Identifiable {
    case main = "MainPageView"
    case settings = "SettingsView"
    case voice = "VoiceChatView2"
    var id: String { rawValue }
}

private struct DevSwitcher: View {
    @Binding var route: DemoRoute

    var body: some View {
        Menu {
            Picker("Mock screen", selection: $route) {
                ForEach(DemoRoute.allCases) { r in
                    Text(r.rawValue).tag(r)
                }
            }
        } label: {
            Image(systemName: "ladybug.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(10)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(12)
    }
}
#endif

#Preview {
    ContentView()
}

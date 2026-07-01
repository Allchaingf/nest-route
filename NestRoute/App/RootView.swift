//
//  RootView.swift
//  NestRoute
//
//  Drives the strict entry flow:
//      Splash  →  (first launch only) Onboarding  →  Main App
//  No auth, no welcome, no sign-in gates.
//

import SwiftUI

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                LaunchView(isActive: $showSplash)
                    .transition(.opacity)
            } else if !hasCompletedOnboarding {
                OnboardingView(onFinish: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        hasCompletedOnboarding = true
                    }
                })
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
    }
}

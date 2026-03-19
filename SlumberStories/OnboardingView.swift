//
//  OnboardingView.swift
//  SlumberStories
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "🌙",
            title: "Welcome to\nSlumber Stories",
            subtitle: "Magical bedtime adventures, made just for your child every single night",
            gradient: [Color(red: 0.24, green: 0.10, blue: 0.43), Color(red: 0.05, green: 0.04, blue: 0.10)]
        ),
        OnboardingPage(
            emoji: "✨",
            title: "Unique Stories\nEvery Night",
            subtitle: "AI creates a brand new personalised adventure with your child as the hero",
            gradient: [Color(red: 0.05, green: 0.17, blue: 0.35), Color(red: 0.05, green: 0.04, blue: 0.10)]
        ),
        OnboardingPage(
            emoji: "🎵",
            title: "Built for\nDeep Sleep",
            subtitle: "Theta wave frequencies and ambient sounds guide your child into restful sleep",
            gradient: [Color(red: 0.10, green: 0.05, blue: 0.30), Color(red: 0.05, green: 0.04, blue: 0.10)]
        ),
        OnboardingPage(
            emoji: "🔥",
            title: "Build a Bedtime\nRoutine They Love",
            subtitle: "Track streaks, save favourites, and make story time the best part of their day",
            gradient: [Color(red: 0.25, green: 0.08, blue: 0.08), Color(red: 0.05, green: 0.04, blue: 0.10)]
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: pages[currentPage].gradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: currentPage)

            // Stars background
            StarsBackground()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: onComplete) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                }
                .padding(.top, 16)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 460)

                Spacer()

                // Dots indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentPage ? 10 : 7, height: index == currentPage ? 10 : 7)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Next / Get Started button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onComplete()
                    }
                }) {
                    Text(currentPage == pages.count - 1 ? "✨ Get Started" : "Next →")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(18)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.58, green: 0.20, blue: 0.92), Color(red: 0.75, green: 0.15, blue: 0.82)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: Color(red: 0.58, green: 0.20, blue: 0.92).opacity(0.5), radius: 12)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

struct OnboardingPage {
    let emoji: String
    let title: String
    let subtitle: String
    let gradient: [Color]
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            // Big emoji with glow
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 160, height: 160)
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 200, height: 200)
                Text(page.emoji)
                    .font(.system(size: 90))
                    .scaleEffect(appeared ? 1.0 : 0.5)
                    .opacity(appeared ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: appeared)
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.15), value: appeared)

                Text(page.subtitle)
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                    .offset(y: appeared ? 0 : 20)
                    .opacity(appeared ? 1 : 0)
                    .animation(.spring(response: 0.5).delay(0.25), value: appeared)
            }
        }
        .padding(.horizontal, 24)
        .onAppear {
            appeared = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appeared = true
            }
        }
        .onDisappear { appeared = false }
    }
}

struct StarsBackground: View {
    let stars: [(x: CGFloat, y: CGFloat, size: CGFloat, opacity: Double)] = (0..<60).map { _ in
        (
            x: CGFloat.random(in: 0...1),
            y: CGFloat.random(in: 0...1),
            size: CGFloat.random(in: 1...3),
            opacity: Double.random(in: 0.1...0.6)
        )
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<stars.count, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(stars[i].opacity))
                    .frame(width: stars[i].size, height: stars[i].size)
                    .position(
                        x: stars[i].x * geo.size.width,
                        y: stars[i].y * geo.size.height
                    )
            }
        }
        .ignoresSafeArea()
    }
}//
//  OnboardingView.swift
//  SlumberStories
//
//  Created by Armani Wattie on 3/15/26.
//


//
//  VoiceChatView3.swift
//  voice-gmail-assistant
//
//  Ultra-minimal voice interface designed for runners/walkers - no visual interaction required
//

import SwiftUI

struct VoiceChatView3: View {
    @State private var isListening = true
    @State private var isAISpeaking = false
    @State private var voiceMinutesRemaining = 23
    @State private var animationPhase = 0.0
    @State private var currentStatus = "Ready to help"
    @State private var isPaused = false
    
    var body: some View {
        ZStack {
            AppBackground()
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // MARK: Top Status Bar - Ultra Minimal
                topStatusBar
                
                Spacer()
                
                // MARK: Giant Voice Indicator - Primary Focus
                giantVoiceIndicator
                
                Spacer()
                
                // MARK: Simple Status Text
                statusText
                
                Spacer()
            }
        }
        .onAppear {
            startExerciseMode()
        }
    }
    
    // MARK: - Top Status Bar
    private var topStatusBar: some View {
        HStack {
            // Connection indicator
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .scaleEffect(isListening ? 1.0 + sin(animationPhase) * 0.2 : 1.0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animationPhase)
            
            Spacer()
            
            // Voice minutes - large and clear
            Text("\(voiceMinutesRemaining)m")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Giant Voice Indicator
    private var giantVoiceIndicator: some View {
        ZStack {
            // Outer pulse rings - visible from distance
            if isListening || isAISpeaking {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: ringColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: CGFloat(240 + index * 30), height: CGFloat(240 + index * 30))
                        .scaleEffect(1.0 + sin(animationPhase + Double(index) * 0.8) * 0.15)
                        .opacity(0.8 - Double(index) * 0.15)
                        .animation(
                            .easeInOut(duration: 2.0 + Double(index) * 0.4)
                            .repeatForever(autoreverses: true),
                            value: animationPhase
                        )
                }
            }
            
            // Main circle - massive and clear
            Circle()
                .fill(.regularMaterial)
                .frame(width: 200, height: 200)
                .overlay(
                    Circle()
                        .strokeBorder(.white.opacity(0.3), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
            
            // Central icon - huge and bold
            Image(systemName: currentIcon)
                .font(.system(size: 80, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: iconColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isListening || isAISpeaking ? 1.1 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isListening || isAISpeaking)
        }
        .onAppear {
            animationPhase = 1.0
        }
    }
    
    // MARK: - Status Text
    private var statusText: some View {
        VStack(spacing: 20) {
            // Main status - large and readable from distance
            Text(currentStatus)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .lineLimit(2)
            
            // Voice commands hint
            Text("Say 'pause' to stop")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.bottom, 60)
    }
    
    // MARK: - Computed Properties
    private var currentIcon: String {
        if isPaused {
            return "pause.circle.fill"
        } else if isAISpeaking {
            return "speaker.wave.3.fill"
        } else if isListening {
            return "mic.circle.fill"
        } else {
            return "waveform.circle.fill"
        }
    }
    
    private var iconColors: [Color] {
        if isPaused {
            return [.gray, .white.opacity(0.7)]
        } else if isAISpeaking {
            return [.green, .mint, .cyan]
        } else if isListening {
            return [.blue, .purple, .indigo]
        } else {
            return [.white, .gray]
        }
    }
    
    private var ringColors: [Color] {
        if isAISpeaking {
            return [.green.opacity(0.8), .mint.opacity(0.6), .cyan.opacity(0.4)]
        } else {
            return [.blue.opacity(0.8), .purple.opacity(0.6), .indigo.opacity(0.4)]
        }
    }
    
    // MARK: - Voice Actions
    private func startExerciseMode() {
        isListening = true
        currentStatus = "Ready for email help"
        
        // Start exercise-paced conversation
        simulateExerciseConversation()
    }
    
    private func simulateExerciseConversation() {
        // Natural exercise conversation timing - 20-45 seconds between interactions
        let delay = Double.random(in: 20...45)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if isListening && !isAISpeaking && !isPaused {
                simulateRunnerRequest()
            }
            simulateExerciseConversation() // Continue cycle
        }
    }
    
    private func simulateRunnerRequest() {
        let requests = [
            "Anything urgent?",
            "Check my email",
            "What's my next meeting?",
            "Tell my team I'm running late",
            "Any calls I missed?",
            "Schedule lunch with Sarah"
        ]
        
        let request = requests.randomElement() ?? requests[0]
        processRunnerCommand(request)
    }
    
    private func processRunnerCommand(_ command: String) {
        withAnimation(.easeInOut(duration: 0.4)) {
            isAISpeaking = true
        }
        
        let response = getRunnerResponse(for: command)
        currentStatus = response
        
        // AI responds for 4-7 seconds (natural speaking pace)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 4...7)) {
            withAnimation(.easeInOut(duration: 0.4)) {
                isAISpeaking = false
                currentStatus = "Listening for commands"
            }
            
            // Deduct voice minutes
            if voiceMinutesRemaining > 0 {
                voiceMinutesRemaining -= 1
            }
        }
    }
    
    private func getRunnerResponse(for command: String) -> String {
        if command.lowercased().contains("urgent") {
            return "2 urgent emails. Client wants meeting moved. HR needs form by 5pm."
            
        } else if command.lowercased().contains("email") || command.lowercased().contains("check") {
            return "7 new emails. Nothing urgent. Team meeting reminder at 3pm."
            
        } else if command.lowercased().contains("meeting") || command.lowercased().contains("next") {
            return "Next meeting: Team standup at 2pm. Then free until 4pm."
            
        } else if command.lowercased().contains("late") || command.lowercased().contains("team") {
            return "Told your team you're running 15 minutes late. They'll start without you."
            
        } else if command.lowercased().contains("calls") || command.lowercased().contains("missed") {
            return "1 missed call from Mike. He said no rush, will email instead."
            
        } else if command.lowercased().contains("lunch") || command.lowercased().contains("schedule") {
            return "Scheduled lunch with Sarah for Wednesday 12:30pm. Sent calendar invite."
            
        } else {
            return "Ready to help with emails and calendar"
        }
    }
}

#Preview {
    VoiceChatView3()
}

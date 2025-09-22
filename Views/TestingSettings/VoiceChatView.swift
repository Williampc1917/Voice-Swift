//
//  VoiceChatView.swift
//  voice-gmail-assistant
//
//  Always-listening voice AI interface with chat history
//

import SwiftUI

struct VoiceChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var isListening = true // Always listening by default
    @State private var isAISpeaking = false
    @State private var voiceMinutesRemaining = 23
    @State private var showingSettings = false
    @State private var animationPhase = 0.0
    @State private var currentTranscript = ""
    @State private var conversationActive = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // MARK: Header
                    headerSection
                    
                    // MARK: Chat Messages
                    chatSection
                    
                    // MARK: Voice Status Bar
                    voiceStatusSection
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                startConstantListening()
                loadInitialMessage()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                // Always listening indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .scaleEffect(isListening ? 1.0 + sin(animationPhase) * 0.3 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animationPhase)
                    
                    Text("Listening")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Voice Minutes
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(voiceMinutesRemaining)m")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Settings
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            
            // Title
            Text("Voice Assistant")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Divider()
                .background(Color.white.opacity(0.15))
                .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Chat Section
    private var chatSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatBubbleView(message: message)
                    }
                    
                    // Live transcript while user is speaking
                    if !currentTranscript.isEmpty {
                        ChatBubbleView(message: ChatMessage(
                            content: currentTranscript,
                            isUser: true,
                            timestamp: Date(),
                            isTranscribing: true
                        ))
                    }
                    
                    Color.clear.frame(height: 80) // Space for status bar
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .onChange(of: messages.count) { _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.5)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: currentTranscript) { _ in
                // Auto-scroll when transcript updates
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo("transcript-area", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Voice Status Bar (Bottom)
    private var voiceStatusSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.15))
            
            HStack(spacing: 20) {
                // Voice Activity Indicator
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(isAISpeaking ? Color.blue : Color.green.opacity(0.3))
                            .frame(width: 40, height: 40)
                        
                        if isAISpeaking {
                            // AI speaking animation
                            Image(systemName: "waveform")
                                .font(.title3)
                                .foregroundColor(.white)
                                .scaleEffect(1.0 + sin(animationPhase) * 0.15)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animationPhase)
                        } else {
                            // Listening microphone
                            Image(systemName: "mic.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isAISpeaking ? "AI Speaking" : "Listening")
                            .font(.callout.weight(.medium))
                            .foregroundColor(.white)
                        
                        Text(isAISpeaking ? "Tap anywhere to interrupt" : "Start speaking anytime")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                
                Spacer()
                
                // Pause/Resume Button
                Button {
                    toggleListening()
                } label: {
                    Image(systemName: isListening ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.black.opacity(0.3))
        }
        .onTapGesture {
            if isAISpeaking {
                stopAISpeaking()
            }
        }
    }
    
    // MARK: - Actions
    private func startConstantListening() {
        isListening = true
        animationPhase = 1.0
        
        // Simulate voice detection
        simulateVoiceDetection()
    }
    
    private func simulateVoiceDetection() {
        // Simulate random user speech every 8-15 seconds
        let delay = Double.random(in: 8...15)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if isListening && !isAISpeaking {
                simulateUserSpeech()
            }
            simulateVoiceDetection() // Continue listening
        }
    }
    
    private func simulateUserSpeech() {
        let userInputs = [
            "Check my emails",
            "What's urgent today?",
            "Schedule my meeting with Sarah",
            "Draft a reply to John",
            "What's on my calendar tomorrow?",
            "Any important messages?",
            "Help me prioritize my tasks"
        ]
        
        let selectedInput = userInputs.randomElement() ?? userInputs[0]
        
        // Simulate live transcription
        currentTranscript = ""
        for (index, character) in selectedInput.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.08) {
                currentTranscript += String(character)
            }
        }
        
        // Process after transcription completes
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(selectedInput.count) * 0.08 + 0.5) {
            processUserMessage(selectedInput)
            currentTranscript = ""
        }
    }
    
    private func processUserMessage(_ text: String) {
        // Add user message
        let userMessage = ChatMessage(
            content: text,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // AI responds immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isAISpeaking = true
            }
            
            // Add AI response
            let aiResponse = getAIResponse(for: text)
            let aiMessage = ChatMessage(
                content: aiResponse,
                isUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)
            
            // AI speaks for 3-5 seconds
            let speakingDuration = Double.random(in: 3...5)
            DispatchQueue.main.asyncAfter(deadline: .now() + speakingDuration) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAISpeaking = false
                }
                
                // Deduct minutes
                if voiceMinutesRemaining > 0 {
                    voiceMinutesRemaining -= 1
                }
            }
        }
    }
    
    private func toggleListening() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isListening.toggle()
        }
        
        if isListening {
            simulateVoiceDetection()
        }
    }
    
    private func stopAISpeaking() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isAISpeaking = false
        }
    }
    
    private func getAIResponse(for userText: String) -> String {
        if userText.lowercased().contains("email") {
            return "I found 3 unread emails. Two are from your team about the project deadline, and one is from a client requesting a meeting. Should I prioritize the client email?"
        } else if userText.lowercased().contains("urgent") {
            return "You have 2 urgent items: a budget review due today and a client call that needs rescheduling. Which would you like to handle first?"
        } else if userText.lowercased().contains("schedule") || userText.lowercased().contains("meeting") {
            return "I can help you schedule that. What time works best, and should I send a calendar invite to the attendees?"
        } else if userText.lowercased().contains("calendar") || userText.lowercased().contains("tomorrow") {
            return "Tomorrow you have a team standup at 9 AM and a client presentation at 2 PM. Your morning is free for focused work."
        } else if userText.lowercased().contains("draft") || userText.lowercased().contains("reply") {
            return "I'll draft a professional response. Should I keep the tone formal or make it more conversational?"
        } else {
            return "I'm here to help with your emails and calendar. What would you like me to focus on right now?"
        }
    }
    
    private func loadInitialMessage() {
        let welcomeMessage = ChatMessage(
            content: "Hi! I'm ready to help manage your emails and calendar. I'm always listening - just start speaking whenever you need assistance.",
            isUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
}

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID().uuidString
    let content: String
    let isUser: Bool
    let timestamp: Date
    var isTranscribing: Bool = false
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(message.isTranscribing ? Color.blue.opacity(0.7) : Color.blue)
                        )
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.trailing, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 8)
                }
                
                Spacer(minLength: 50)
            }
        }
        .id(message.isTranscribing ? "transcript-area" : message.id)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VoiceChatView()
}

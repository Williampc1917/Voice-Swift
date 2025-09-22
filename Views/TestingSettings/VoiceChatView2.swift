//
//  VoiceChatView2.swift
//  voice-gmail-assistant
//
//  ChatGPT-style voice interface with email drafting capabilities
//

import SwiftUI

struct VoiceChatView2: View {
    @State private var messages: [ChatMessage2] = []
    @State private var isUserSpeaking = false
    @State private var isAISpeaking = false
    @State private var voiceMinutesRemaining = 23
    @State private var showingSettings = false
    @State private var animationPhase = 0.0
    @State private var currentTranscript = ""
    @State private var showingDraftEmail: DraftEmail?
    
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
                    
                    // MARK: Central Voice Indicator
                    centralVoiceSection
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $showingDraftEmail) { draft in
                EmailDraftView(draft: draft) { action in
                    handleDraftAction(action, for: draft)
                }
            }
            .onAppear {
                loadInitialMessage()
                startConversationFlow()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            // Voice status
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                    .scaleEffect(isUserSpeaking || isAISpeaking ? 1.5 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isUserSpeaking || isAISpeaking)
                
                Text("Voice Active")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Minutes remaining
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
        .padding(.bottom, 12)
    }
    
    // MARK: - Chat Section
    private var chatSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatBubbleView2(message: message) { draftEmail in
                            showingDraftEmail = draftEmail
                        }
                    }
                    
                    // Live transcript
                    if isUserSpeaking && !currentTranscript.isEmpty {
                        ChatBubbleView2(message: ChatMessage2(
                            content: currentTranscript,
                            isUser: true,
                            timestamp: Date(),
                            isTranscribing: true
                        )) { _ in }
                    }
                    
                    Color.clear.frame(height: 200) // Space for central indicator
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
        }
    }
    
    // MARK: - Central Voice Indicator
    private var centralVoiceSection: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Main voice indicator
            ZStack {
                // Background circle
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                // Animated outer ring
                if isUserSpeaking || isAISpeaking {
                    Circle()
                        .stroke(isUserSpeaking ? Color.blue : Color.green, lineWidth: 3)
                        .frame(width: 140, height: 140)
                        .scaleEffect(1.0 + sin(animationPhase) * 0.1)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: animationPhase)
                }
                
                // Central logo/icon
                Image(systemName: currentVoiceIcon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(currentIconColor)
                    .scaleEffect(isUserSpeaking || isAISpeaking ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isUserSpeaking || isAISpeaking)
            }
            
            // Status text
            Text(currentStatusText)
                .font(.callout.weight(.medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Interrupt hint when AI is speaking
            if isAISpeaking {
                Text("Start speaking to interrupt")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.1))
                    )
            }
            
            Spacer()
        }
        .padding(.bottom, 50)
        .onAppear {
            animationPhase = 1.0
        }
    }
    
    // MARK: - Computed Properties
    private var currentVoiceIcon: String {
        if isUserSpeaking {
            return "mic.circle.fill"
        } else if isAISpeaking {
            return "brain.head.profile"
        } else {
            return "waveform.circle"
        }
    }
    
    private var currentIconColor: Color {
        if isUserSpeaking {
            return .blue
        } else if isAISpeaking {
            return .green
        } else {
            return .white.opacity(0.7)
        }
    }
    
    private var currentStatusText: String {
        if isUserSpeaking {
            return "Listening to you..."
        } else if isAISpeaking {
            return "AI is responding..."
        } else {
            return "Ready to help"
        }
    }
    
    // MARK: - Voice Flow
    private func startConversationFlow() {
        // Simulate continuous conversation
        simulateConversationCycle()
    }
    
    private func simulateConversationCycle() {
        // Wait for user to speak
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3...8)) {
            if !isAISpeaking {
                simulateUserSpeaking()
            }
            simulateConversationCycle() // Continue cycle
        }
    }
    
    private func simulateUserSpeaking() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isUserSpeaking = true
        }
        
        let userInputs = [
            "Draft an email to my team about the project update",
            "Check if I have any urgent messages",
            "Help me respond to Sarah's email",
            "Schedule a meeting with the marketing team",
            "What's my calendar looking like tomorrow?",
            "Draft a follow-up email to our client"
        ]
        
        let selectedInput = userInputs.randomElement() ?? userInputs[0]
        
        // Live transcription
        currentTranscript = ""
        for (index, character) in selectedInput.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.06) {
                if isUserSpeaking {
                    currentTranscript += String(character)
                }
            }
        }
        
        // End user speaking
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(selectedInput.count) * 0.06 + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isUserSpeaking = false
            }
            
            processUserMessage(selectedInput)
            currentTranscript = ""
        }
    }
    
    private func processUserMessage(_ text: String) {
        // Add user message
        let userMessage = ChatMessage2(
            content: text,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        // AI responds
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isAISpeaking = true
            }
            
            let (response, hasDraft) = getAIResponse(for: text)
            let aiMessage = ChatMessage2(
                content: response,
                isUser: false,
                timestamp: Date(),
                hasDraftEmail: hasDraft
            )
            messages.append(aiMessage)
            
            // AI speaking duration
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...4)) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAISpeaking = false
                }
                
                // Auto-show draft if applicable
                if hasDraft {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingDraftEmail = createMockDraft(for: text)
                    }
                }
                
                // Deduct minutes
                if voiceMinutesRemaining > 0 {
                    voiceMinutesRemaining -= 1
                }
            }
        }
    }
    
    private func getAIResponse(for userText: String) -> (String, Bool) {
        if userText.lowercased().contains("draft") {
            return ("I've drafted an email for you. Let me show you the preview so you can review, edit, or confirm it.", true)
        } else if userText.lowercased().contains("urgent") || userText.lowercased().contains("check") {
            return ("I found 2 urgent emails: one from your client about the project deadline and another from HR about benefits enrollment. Should I help you respond to either?", false)
        } else if userText.lowercased().contains("respond") || userText.lowercased().contains("reply") {
            return ("I'll help you craft a response. Based on the original email, I suggest keeping it professional but friendly. Would you like me to draft a reply?", false)
        } else if userText.lowercased().contains("schedule") || userText.lowercased().contains("meeting") {
            return ("I can schedule that meeting. I found availability next Tuesday at 2 PM or Wednesday at 10 AM. Which works better for you?", false)
        } else if userText.lowercased().contains("calendar") || userText.lowercased().contains("tomorrow") {
            return ("Tomorrow you have a light schedule: team standup at 9 AM and one client call at 3 PM. Perfect for focused work in between.", false)
        } else {
            return ("I'm here to help with your emails and calendar. What would you like me to assist you with?", false)
        }
    }
    
    private func createMockDraft(for userText: String) -> DraftEmail {
        if userText.lowercased().contains("team") && userText.lowercased().contains("project") {
            return DraftEmail(
                to: "team@company.com",
                subject: "Project Update - Week of [Date]",
                body: """
Hi Team,

I wanted to share a quick update on our current project status:

✅ Phase 1 completed on schedule
🔄 Phase 2 in progress (75% complete)
📅 On track for final delivery next Friday

Key achievements this week:
• Successfully integrated the new API
• Completed user testing with positive feedback
• Resolved the performance issues from last sprint

Next steps:
• Final QA testing
• Documentation review
• Deployment preparation

Please let me know if you have any questions or concerns.

Best regards,
[Your name]
""",
                isDraft: true
            )
        } else {
            return DraftEmail(
                to: "client@example.com",
                subject: "Follow-up on Our Discussion",
                body: """
Hi [Name],

Thank you for taking the time to discuss the project requirements with me yesterday. I wanted to follow up on a few key points we covered:

• Timeline: We can accommodate the requested delivery date
• Budget: The proposal aligns with your requirements
• Next steps: I'll send over the detailed project plan by Friday

I'm excited about the opportunity to work together on this project. Please let me know if you have any additional questions.

Best regards,
[Your name]
""",
                isDraft: true
            )
        }
    }
    
    private func handleDraftAction(_ action: EmailDraftAction, for draft: DraftEmail) {
        switch action {
        case .send:
            let confirmMessage = ChatMessage2(
                content: "Email sent successfully to \(draft.to)!",
                isUser: false,
                timestamp: Date()
            )
            messages.append(confirmMessage)
            
        case .edit:
            let editMessage = ChatMessage2(
                content: "I've saved your edits. Would you like me to send the updated email or make additional changes?",
                isUser: false,
                timestamp: Date()
            )
            messages.append(editMessage)
            
        case .cancel:
            let cancelMessage = ChatMessage2(
                content: "Email draft discarded. Is there anything else I can help you with?",
                isUser: false,
                timestamp: Date()
            )
            messages.append(cancelMessage)
        }
    }
    
    private func loadInitialMessage() {
        let welcomeMessage = ChatMessage2(
            content: "Hi! I'm your voice assistant. I'm always listening and ready to help with your emails and calendar. Just start speaking whenever you need assistance.",
            isUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
}

// MARK: - Models
struct ChatMessage2: Identifiable {
    let id = UUID().uuidString
    let content: String
    let isUser: Bool
    let timestamp: Date
    var isTranscribing: Bool = false
    var hasDraftEmail: Bool = false
}

struct DraftEmail: Identifiable {
    let id = UUID()
    let to: String
    let subject: String
    let body: String
    let isDraft: Bool
}

enum EmailDraftAction {
    case send
    case edit
    case cancel
}

// MARK: - Enhanced Chat Bubble with Draft Support
struct ChatBubbleView2: View {
    let message: ChatMessage2
    let onDraftTap: (DraftEmail) -> Void
    
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
                    
                    // Draft email indicator
                    if message.hasDraftEmail {
                        Button {
                            // Trigger draft view
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.badge")
                                    .foregroundColor(.blue)
                                Text("View Draft Email")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .padding(.leading, 8)
                    }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.leading, 8)
                }
                
                Spacer(minLength: 50)
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Email Draft View
struct EmailDraftView: View {
    let draft: DraftEmail
    let onAction: (EmailDraftAction) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var editedBody: String
    @State private var editedSubject: String
    
    init(draft: DraftEmail, onAction: @escaping (EmailDraftAction) -> Void) {
        self.draft = draft
        self.onAction = onAction
        self._editedBody = State(initialValue: draft.body)
        self._editedSubject = State(initialValue: draft.subject)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Email preview
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Draft Email")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("To:")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(draft.to)
                                        .font(.subheadline)
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Subject:")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    TextField("Subject", text: $editedSubject)
                                        .textFieldStyle(.plain)
                                        .foregroundColor(.white)
                                        .appInputStyle()
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Message:")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    TextEditor(text: $editedBody)
                                        .font(.callout)
                                        .foregroundColor(.white)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .frame(minHeight: 200)
                                        .appInputStyle()
                                }
                            }
                            .appCardStyle()
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            Button {
                                onAction(.send)
                                dismiss()
                            } label: {
                                Label("Send Email", systemImage: "paperplane.fill")
                                    .font(.callout.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                            }
                            .appButtonStyle()
                            
                            HStack(spacing: 12) {
                                Button {
                                    onAction(.edit)
                                    dismiss()
                                } label: {
                                    Label("Save Changes", systemImage: "square.and.pencil")
                                        .font(.callout.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                }
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                
                                Button {
                                    onAction(.cancel)
                                    dismiss()
                                } label: {
                                    Label("Discard", systemImage: "trash")
                                        .font(.callout.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                }
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        Color.clear.frame(height: 44)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Email Draft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .presentationBackground(.clear)
    }
}

#Preview {
    VoiceChatView2()
}

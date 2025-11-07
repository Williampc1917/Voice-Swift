import SwiftUI

// =====================================================
// MARK: - ClaroAI Theme (Logo Coral + Dark Gradient)
// =====================================================
enum UITheme {
    // Text
    static let textPrimary   = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.68)

    // Background gradient stops (washed black/gray that pairs with coral)
    static let bgTop     = Color(hex: "#0B0D11") // charcoal black
    static let bgMid     = Color(hex: "#10141A") // deep gray-blue
    static let bgBottom  = Color(hex: "#171B22") // smoky navy
    static let coralGlow = Color(hex: "#EA8467") // logo coral glow source

    // For compatibility with existing references
    static let backgroundDeep  = Color(hex: "#10141A")
    static let surfaceElevated = Color(hex: "#14171F")
    static let stroke          = Color.white.opacity(0.15)

    // Chat Bubbles — Option A (Frosted Coral vs Slate)
    // AI: warm charcoal with coral edge
    // User: cool slate with soft white edge
    static let bubbleUser = Color(hex: "#232A35")
    static let bubbleAI   = Color(hex: "#1A1719")

    // Brand (from logo)
    static let brandCoral = Color(hex: "#EA8467")
    static let brandCoralLight = Color(hex: "#F39A83")
    static let brandNavy  = Color(hex: "#1E2230")
    static let brandMint = Color.mint // Matches MainPage brand mint; replace with custom hex if needed

    // Accent (kept for compatibility; not used for AI ring anymore)
    static let accentBlue = Color(hex: "#4DA3FF")

    // Status
    static let success   = Color(hex: "#3DD598")
    static let dangerRed = Color(hex: "#FF5F6D")

    // Gradients
    static let gradientCoral = LinearGradient(
        colors: [UITheme.brandCoral, UITheme.brandCoralLight],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let gradientNavy = LinearGradient(
        colors: [Color(hex: "#1E2230"), Color(hex: "#2C3144")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // Subtle strokes for bubbles (gives glassy edge)
    static let bubbleStrokeUser = LinearGradient(
        colors: [Color.white.opacity(0.12), Color.white.opacity(0.02)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let bubbleStrokeAI = LinearGradient(
        colors: [UITheme.brandCoral.opacity(0.18), UITheme.brandCoralLight.opacity(0.06)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// HEX helper
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8)  & 0xFF) / 255,
            blue:  Double(rgb & 0xFF) / 255
        )
    }
}

// =====================================================
// MARK: - Root View
// =====================================================
struct VoiceChatView2: View {
    @State private var messages: [ChatMessage2] = []
    @State private var isUserSpeaking = false
    @State private var isAISpeaking = false
    @State private var voiceMinutesRemaining = 23
    @State private var showingSettings = false
    @State private var animationPhase = 0.0
    @State private var currentTranscript = ""
    @State private var showingDraftEmail: DraftEmail?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ChatBackground().ignoresSafeArea(.all)

                VStack(spacing: 0) {
                    headerSection
                    chatSection
                    centralVoiceSection
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) { SettingsView1() }
            .sheet(item: $showingDraftEmail) { draft in
                EmailDraftView(draft: draft) { action in
                    handleDraftAction(action, for: draft)
                }
            }
            .onAppear {
                runUrgentDemoFlow() // scripted landing demo
            }
        }
    }

    // MARK: Header
    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Button { dismiss() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.backward")
                            .font(.caption.weight(.semibold))
                        Text("Home")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(UITheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(UITheme.surfaceElevated)
                            .overlay(Capsule().stroke(UITheme.stroke, lineWidth: 1))
                    )
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundColor(UITheme.textSecondary.opacity(0.9))
                    Text("\(voiceMinutesRemaining)m")
                        .font(.caption.weight(.medium))
                        .foregroundColor(UITheme.textSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(UITheme.surfaceElevated)
                        .overlay(Capsule().stroke(UITheme.stroke, lineWidth: 1))
                )
            }

            Spacer()

            Button { showingSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundColor(UITheme.textSecondary)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(UITheme.surfaceElevated)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(UITheme.stroke, lineWidth: 1)
                            )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    // MARK: Chat Section
    private var chatSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        ChatBubbleView2(message: message) { draftEmail in
                            showingDraftEmail = draftEmail
                        }
                    }

                    if isUserSpeaking && !currentTranscript.isEmpty {
                        ChatBubbleView2(message: ChatMessage2(
                            content: currentTranscript,
                            isUser: true,
                            timestamp: Date(),
                            isTranscribing: true
                        )) { _ in }
                    }

                    Color.clear.frame(height: 200)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    withAnimation(.easeOut(duration: 0.5)) { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    // MARK: Central Voice Indicator
    private var centralVoiceSection: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(UITheme.surfaceElevated)
                    .frame(width: 120, height: 120)
                    .overlay(Circle().stroke(UITheme.stroke, lineWidth: 1))

                // Speaking pulse ring
                if isUserSpeaking || isAISpeaking {
                    Circle()
                        .stroke(
                            isUserSpeaking ? UITheme.brandMint : UITheme.brandCoral,
                            lineWidth: 3
                        )
                        .frame(width: 140, height: 140)
                        .shadow(
                            color: (isUserSpeaking ? UITheme.brandMint : UITheme.brandCoral).opacity(0.45),
                            radius: 20
                        )
                        .scaleEffect(1.0 + sin(animationPhase) * 0.08)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animationPhase)
                        .overlay(
                            Circle()
                                .stroke(
                                    (isUserSpeaking ? UITheme.brandMint : UITheme.brandCoral).opacity(0.25),
                                    lineWidth: 10
                                )
                                .blur(radius: 16)
                        )
                }

                Image(systemName: currentVoiceIcon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        isUserSpeaking ? UITheme.brandMint : (isAISpeaking ? UITheme.brandCoral : UITheme.textSecondary)
                    )
                    .scaleEffect(isUserSpeaking || isAISpeaking ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isUserSpeaking || isAISpeaking)
            }

            Text(currentStatusText)
                .font(.callout.weight(.medium))
                .foregroundColor(UITheme.textSecondary)
                .multilineTextAlignment(.center)

            if isAISpeaking {
                Text("Start speaking to interrupt")
                    .font(.caption)
                    .foregroundColor(UITheme.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(UITheme.bubbleUser.opacity(0.7))
                    )
            }

            Spacer()
        }
        .padding(.bottom, 50)
        .onAppear { animationPhase = 1.0 }
    }

    // MARK: Computed
    private var currentVoiceIcon: String {
        if isUserSpeaking { return "mic.circle.fill" }
        if isAISpeaking   { return "bolt.horizontal.circle.fill" }
        return "waveform.circle"
    }

    private var currentStatusText: String {
        if isUserSpeaking { return "Listening to you..." }
        if isAISpeaking   { return "AI is responding..." }
        return "Ready to help"
    }

    // =====================================================
    // MARK: - Scripted Landing Demo Flow ("What's urgent?")
    // =====================================================
    private func runUrgentDemoFlow() {
        // Reset for a clean demo
        messages.removeAll()
        isUserSpeaking = false
        isAISpeaking = false
        currentTranscript = ""

        // Step 2 — User: “What’s urgent?”
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.25)) { isUserSpeaking = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            messages.append(ChatMessage2(content: "What’s urgent?", isUser: true, timestamp: Date()))
            withAnimation(.easeInOut(duration: 0.25)) { isUserSpeaking = false }
        }

        // Step 3 — AI: concise urgency summary
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeInOut(duration: 0.25)) { isAISpeaking = true }
            let summary = """
            Three things might need your attention, Emily:
            • Sarah Lopez — waiting on your reply for 2 days. She asked if you could confirm next steps on the partnership proposal.
            • Alex Wong — you promised a follow-up next week about the product roadmap discussion from Friday.
            • Jennifer Miller — budget review in 3 hours; she sent a quick note this morning confirming the agenda.

            Would you like to reply to Sarah first?
            """
            messages.append(ChatMessage2(content: summary, isUser: false, timestamp: Date()))
        }

        // Step 4 — User intent + closure
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.2) {
            withAnimation(.easeInOut(duration: 0.25)) {
                isAISpeaking = false
                isUserSpeaking = true
            }
            messages.append(ChatMessage2(
                content: "Tell her I’m happy to move forward and I’ll share the final details tomorrow. Thank her for her patience.",
                isUser: true,
                timestamp: Date()
            ))
        }

        // Step 5 — AI drafts + shows sheet
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.6) {
            withAnimation(.easeInOut(duration: 0.25)) {
                isUserSpeaking = false
                isAISpeaking = true
            }
            messages.append(ChatMessage2(
                content: "Got it — drafted a short, professional follow-up in your usual tone with Sarah.",
                isUser: false,
                timestamp: Date(),
                hasDraftEmail: true
            ))

            // Present draft
            let draft = createSarahDraft(userName: "Emily")
            showingDraftEmail = draft

            // Emily reads a moment, then says "Send" → auto send + close
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                handleDraftAction(.send, for: draft)   // appends “Sent…” message
                showingDraftEmail = nil                // closes the sheet

                // Step 7 — Transition mention of Alex (stop here)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    messages.append(ChatMessage2(
                        content: "Next up is Alex Wong — your follow-up for next week about the product roadmap.",
                        isUser: false,
                        timestamp: Date()
                    ))
                    withAnimation(.easeInOut(duration: 0.25)) { isAISpeaking = false }
                }
            }
        }
    }

    // Deterministic Sarah draft for the demo
    private func createSarahDraft(userName: String) -> DraftEmail {
        DraftEmail(
            to: "Sarah Lopez",
            subject: "Partnership Proposal — Next Steps",
            body: """
Hi Sarah,

Thanks for your patience! I’m happy to move forward — I’ll share the final details tomorrow once everything’s wrapped up.

Appreciate you checking in.

Best,
\(userName)
""",
            isDraft: true
        )
    }

    // =====================================================
    // (Legacy mock flow kept for reference but unused in demo)
    // =====================================================
    private func startConversationFlow() { simulateConversationCycle() }

    private func simulateConversationCycle() {
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 3...8)) {
            if !isAISpeaking { simulateUserSpeaking() }
            simulateConversationCycle()
        }
    }

    private func simulateUserSpeaking() {
        withAnimation(.easeInOut(duration: 0.3)) { isUserSpeaking = true }
        let userInputs = [
            "Draft an email to my team about the project update",
            "Check if I have any urgent messages",
            "Help me respond to Sarah's email",
            "Schedule a meeting with the marketing team",
            "What's my calendar looking like tomorrow?",
            "Draft a follow-up email to our client"
        ]
        let text = userInputs.randomElement() ?? userInputs[0]
        currentTranscript = ""
        for (i, ch) in text.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.06) {
                if isUserSpeaking { currentTranscript += String(ch) }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(text.count) * 0.06 + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) { isUserSpeaking = false }
            processUserMessage(text)
            currentTranscript = ""
        }
    }

    private func processUserMessage(_ text: String) {
        messages.append(ChatMessage2(content: text, isUser: true, timestamp: Date()))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) { isAISpeaking = true }
            let (response, hasDraft) = getAIResponse(for: text)
            messages.append(ChatMessage2(content: response, isUser: false, timestamp: Date(), hasDraftEmail: hasDraft))
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 2...4)) {
                withAnimation(.easeInOut(duration: 0.3)) { isAISpeaking = false }
                if hasDraft {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showingDraftEmail = createMockDraft(for: text)
                    }
                }
                if voiceMinutesRemaining > 0 { voiceMinutesRemaining -= 1 }
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
            if draft.to.lowercased().contains("sarah") {
                messages.append(ChatMessage2(content: "Sent the reply to Sarah. I’ll remind you tomorrow to confirm she responded.", isUser: false, timestamp: Date()))
            } else {
                messages.append(ChatMessage2(content: "Email sent successfully to \(draft.to)!", isUser: false, timestamp: Date()))
            }
        case .save:
            messages.append(ChatMessage2(content: "Saved your email draft.", isUser: false, timestamp: Date()))
        case .delete:
            messages.append(ChatMessage2(content: "Email draft deleted.", isUser: false, timestamp: Date()))
        }
    }

    private func loadInitialMessage() {
        messages.append(ChatMessage2(
            content: "Hi! I'm your voice assistant. I'm always listening and ready to help with your emails and calendar. Just start speaking whenever you need assistance.",
            isUser: false, timestamp: Date()
        ))
    }
}

// =====================================================
// MARK: - Models
// =====================================================
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

enum EmailDraftAction { case send, save, delete }

// =====================================================
// MARK: - Chat Bubbles
// =====================================================
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
                        .foregroundColor(UITheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(message.isTranscribing ? UITheme.bubbleAI : UITheme.bubbleUser)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(UITheme.bubbleStrokeUser, lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 6)
                        )
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(UITheme.textSecondary)
                        .padding(.trailing, 8)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(.callout)
                        .foregroundColor(UITheme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(UITheme.bubbleAI)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(UITheme.bubbleStrokeUser, lineWidth: 1)
                                )
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 5)
                        )

                    if message.hasDraftEmail {
                        Button { /* main flow auto-presents */ } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "envelope.open.fill")
                                    .foregroundColor(UITheme.brandCoral)
                                Text("View Draft Email")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(UITheme.brandCoral)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(UITheme.surfaceElevated)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(UITheme.brandCoral.opacity(0.4), lineWidth: 1)
                                    )
                                    .shadow(color: UITheme.brandCoral.opacity(0.18), radius: 6, x: 0, y: 2)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 8)
                    }

                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(UITheme.textSecondary)
                        .padding(.leading, 8)
                }
                Spacer(minLength: 50)
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}

// =====================================================
// MARK: - Email Draft View (3 buttons only)
// =====================================================
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
                ChatBackground().ignoresSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Draft Email")
                                .font(.title2.bold())
                                .foregroundColor(UITheme.textPrimary)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("To:")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(UITheme.textSecondary)
                                    Text(draft.to)
                                        .font(.subheadline)
                                        .foregroundColor(UITheme.textPrimary)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Subject:")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(UITheme.textSecondary)
                                    TextField("Subject", text: $editedSubject)
                                        .textFieldStyle(.plain)
                                        .foregroundColor(UITheme.textPrimary)
                                        .appInputStyle()
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Message:")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(UITheme.textSecondary)
                                    TextEditor(text: $editedBody)
                                        .font(.callout)
                                        .foregroundColor(UITheme.textPrimary)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .frame(minHeight: 200)
                                        .appInputStyle()
                                }
                            }
                            .appCardStyle()
                        }

                        // === Only 3 actions: Send, Save, Delete ===
                        VStack(spacing: 12) {
                            Button {
                                onAction(.send); dismiss()
                            } label: {
                                Label("Send Email", systemImage: "paperplane.fill")
                                    .font(.callout.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 14)
                                    .background(UITheme.brandCoral)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .shadow(color: UITheme.brandCoral.opacity(0.3), radius: 12, y: 6)
                            }

                            HStack(spacing: 12) {
                                Button {
                                    onAction(.save); dismiss()
                                } label: {
                                    Label("Save Email", systemImage: "square.and.arrow.down")
                                        .font(.callout.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                }
                                .foregroundColor(UITheme.textPrimary)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(UITheme.stroke, lineWidth: 1)
                                )

                                Button {
                                    onAction(.delete); dismiss()
                                } label: {
                                    Label("Delete", systemImage: "trash.fill")
                                        .font(.callout.weight(.medium))
                                        .frame(maxWidth: .infinity)
                                }
                                .foregroundColor(UITheme.dangerRed)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(UITheme.dangerRed.opacity(0.35), lineWidth: 1)
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
                    Button("Close") { dismiss() }
                        .foregroundColor(UITheme.textPrimary)
                }
            }
        }
        .presentationBackground(.clear)
    }
}

// =====================================================
// MARK: - Background + Modifiers + Placeholders
// =====================================================
struct ChatBackground: View {
    var body: some View {
        ZStack {
            // Washed black/gray base gradient
            LinearGradient(
                colors: [UITheme.bgTop, UITheme.bgMid, UITheme.bgBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Soft coral bloom near center (ties to logo coral)
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: UITheme.coralGlow.opacity(0.10), location: 0.0),
                    .init(color: .clear,                        location: 1.0)
                ]),
                center: .center,
                startRadius: 0,
                endRadius: 480
            )

            // Secondary subtle bloom from bottom-right for depth
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: UITheme.coralGlow.opacity(0.06), location: 0.0),
                    .init(color: .clear,                          location: 1.0)
                ]),
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 520
            )

            // Gentle vignette for readability (MainPage tone)
            LinearGradient(
                colors: [.black.opacity(0.22), .clear, .black.opacity(0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.multiply)
        }
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(UITheme.surfaceElevated)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(UITheme.stroke, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 10)
    }
}

struct InputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(UITheme.bubbleUser.opacity(0.45))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(UITheme.stroke, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension View {
    func appCardStyle2() -> some View { modifier(CardStyle()) }
    func appInputStyle2() -> some View { modifier(InputStyle()) }
}

// Simple placeholder
struct SettingsView1: View {
    var body: some View {
        ZStack {
            ChatBackground().ignoresSafeArea()
            Text("Settings")
                .foregroundColor(UITheme.textPrimary)
        }
    }
}

// =====================================================
// MARK: - Preview
// =====================================================
#Preview { VoiceChatView2() }


//
//  OnboardingEmailStyleView.swift
//  voice-gmail-assistant
//
//  REDESIGNED: Single custom style flow with 3 email examples + quick topic suggestions
//

import SwiftUI

struct OnboardingEmailStyleView: View {
    @EnvironmentObject var onboarding: OnboardingManager
    @State private var emailExamples = ["", "", ""]
    @State private var emailSubjects = ["", "", ""]
    @State private var emailBodies = ["", "", ""]
    @State private var currentStep = 0
    @State private var isProcessing = false
    @State private var extractionResult: CustomEmailStyleResponse?
    @State private var showResult = false
    @State private var animationPhase = 0.0
    
    let emailTypes = ["Professional", "Casual", "Friendly"]
    let descriptions = [
        "Enter a formal business email you'd send to a client or executive",
        "Enter a standard work email to a colleague or team member",
        "Enter a warm, informal email to someone you know well"
    ]
    let icons = ["briefcase.fill", "person.2.fill", "heart.fill"]
    let colors: [Color] = [.blue, .purple, .pink]
    
    private var canProceed: Bool {
        !emailSubjects[currentStep].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        sentenceCount(in: emailBodies[currentStep]) >= 3
    }
    
    private func sentenceCount(in text: String) -> Int {
        text.split { ".!?".contains($0) }.count
    }
    
    var body: some View {
        ZStack {
            AppBackground()
            
            ScrollView {
                VStack(spacing: 36) {
                    Spacer().frame(height: 20)
                    
                    // HEADER
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.blue)
                            .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
                        
                        Text("Train Your Email Style")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text("Provide 3 different email examples so we can learn your unique writing style.")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // MAIN CONTENT
                    if showResult, let result = extractionResult {
                        // RESULT VIEW
                        CustomStyleResultView(
                            result: result,
                            onContinue: {
                                Task {
                                    await completeOnboarding()
                                }
                            },
                            onRetry: {
                                showResult = false
                                extractionResult = nil
                                emailExamples = ["", "", ""]
                                emailSubjects = ["", "", ""]
                                emailBodies = ["", "", ""]
                                currentStep = 0
                            }
                        )
                        .padding(.horizontal, 24)
                        
                    } else if isProcessing {
                        // PROCESSING VIEW
                        ProcessingView(animationPhase: $animationPhase)
                            .padding(.horizontal, 24)
                        
                    } else {
                        // INPUT FORM
                        VStack(spacing: 24) {
                            // Progress Indicator
                            ProgressIndicatorView(
                                currentStep: currentStep,
                                totalSteps: 3,
                                hasCompleted: hasCompleted
                            )
                            
                            // Current Email Type Card
                            EmailTypeHeader(
                                type: emailTypes[currentStep],
                                description: descriptions[currentStep],
                                icon: icons[currentStep],
                                color: colors[currentStep]
                            )
                            
                            // Quick Topic Suggestions
                            QuickTopicSuggestions(
                                currentStep: currentStep,
                                onSelectTopic: { topic in
                                    fillExampleEmail(topic: topic)
                                }
                            )
                            
                            // Subject Input
                            SubjectInputView(
                                subject: $emailSubjects[currentStep]
                            )
                            
                            // Body Input
                            BodyInputView(
                                text: $emailBodies[currentStep],
                                example: getExample()
                            )
                            
                            // Tip
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow.opacity(0.8))
                                
                                Text("Provide 3 different emails with at least 3 sentences each to help us learn your style")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.yellow.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .strokeBorder(Color.yellow.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            
                            // Navigation Buttons
                            NavigationButtons(
                                currentStep: currentStep,
                                canProceed: canProceed,
                                onPrevious: {
                                    withAnimation { currentStep -= 1 }
                                },
                                onNext: {
                                    if currentStep == 2 {
                                        submitCustomStyle()
                                    } else {
                                        withAnimation { currentStep += 1 }
                                    }
                                }
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer().frame(height: 44)
                }
            }
            .scrollIndicators(.hidden)
        }
    }
    
    // MARK: - Helpers
    
    private func hasCompleted(_ i: Int) -> Bool {
        !emailSubjects[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        sentenceCount(in: emailBodies[i]) >= 3
    }
    
    private func getExample() -> String {
        [
            "Dear Ms. Johnson, I wanted to follow up on our quarterly review meeting. Could you please send me the finalized budget report by end of week? I appreciate your attention to this matter. Best regards, John",
            "Hey team, thanks for the quick turnaround on those designs. I've reviewed everything and left some comments in Figma. Let me know if you have questions. Cheers, John",
            "Hi Sarah! Hope you're doing well! Just wanted to check in about Friday's lunch. Are we still on for noon? Would love to catch up! Talk soon, John"
        ][currentStep]
    }
    
    private func fillExampleEmail(topic: EmailTopic) {
        emailSubjects[currentStep] = topic.subject
        emailBodies[currentStep] = topic.body
    }
    
    private func submitCustomStyle() {
        for i in 0..<3 {
            emailExamples[i] = "Subject: \(emailSubjects[i])\n\n\(emailBodies[i])"
        }
        
        isProcessing = true
        
        Task {
            let validExamples = emailExamples.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            let result = await onboarding.createCustomStyle(emailExamples: validExamples)
            
            isProcessing = false
            
            if let result = result {
                extractionResult = result
                showResult = true
            }
        }
    }
    
    private func completeOnboarding() async {
        await onboarding.refreshStatus()
    }
}

// MARK: - Email Topic Model
struct EmailTopic: Identifiable {
    let id = UUID()
    let title: String
    let subject: String
    let body: String
    let icon: String
}

// MARK: - Quick Topic Suggestions
struct QuickTopicSuggestions: View {
    let currentStep: Int
    let onSelectTopic: (EmailTopic) -> Void
    
    private var topics: [EmailTopic] {
        switch currentStep {
        case 0: // Professional
            return [
                EmailTopic(
                    title: "Meeting Follow-up",
                    subject: "Follow-up: Q4 Strategy Meeting",
                    body: "Dear Ms. Rodriguez, Thank you for taking the time to meet with me yesterday regarding our Q4 strategy. I wanted to follow up on the action items we discussed. Could you please send me the updated timeline and budget allocations by Friday? I believe this will help us move forward efficiently. Please let me know if you need any additional information from my end. Best regards,",
                    icon: "calendar.badge.clock"
                ),
                EmailTopic(
                    title: "Project Update",
                    subject: "Project Status Update - Week 12",
                    body: "Dear Team, I wanted to provide you with an update on the current project status. We have successfully completed the initial phase and are now moving into implementation. The deliverables are on track for the end of month deadline. Please review the attached documentation and let me know if you have any concerns. I appreciate your continued dedication to this project. Respectfully,",
                    icon: "chart.line.uptrend.xyaxis"
                ),
                EmailTopic(
                    title: "Client Proposal",
                    subject: "Proposal for Marketing Campaign Services",
                    body: "Dear Mr. Thompson, I hope this email finds you well. Following our conversation last week, I am pleased to present our proposal for the comprehensive marketing campaign. Our team has developed a strategic approach that aligns with your business objectives. The proposal includes detailed timelines, deliverables, and pricing structure. I would appreciate the opportunity to discuss this further at your earliest convenience. Looking forward to your response.",
                    icon: "doc.text"
                )
            ]
        case 1: // Casual
            return [
                EmailTopic(
                    title: "Team Check-in",
                    subject: "Quick Check-in on Design Progress",
                    body: "Hey everyone, Just wanted to touch base on where we're at with the design mockups. I saw the latest versions in Figma and they're looking great! Can we schedule a quick call this week to go over the final details? Let me know what works for your schedule. Also, if anyone has feedback on the color scheme, now's the time to speak up. Thanks for all the hard work on this!",
                    icon: "person.2.wave.2"
                ),
                EmailTopic(
                    title: "Task Update",
                    subject: "Update: API Integration Status",
                    body: "Hi team, Quick update on the API integration work. I've completed the authentication module and it's ready for testing. The documentation is in the shared drive under the 'Development' folder. I ran into a small issue with rate limiting but found a workaround. Can someone review the code when you get a chance? Let me know if you have any questions or spot anything that needs adjustment. Cheers,",
                    icon: "checkmark.circle"
                ),
                EmailTopic(
                    title: "Resource Request",
                    subject: "Need Access to Analytics Dashboard",
                    body: "Hey Sarah, Hope you're having a good week! I'm working on the quarterly report and realized I need access to the analytics dashboard. Would you be able to grant me view permissions? I just need to pull some metrics for the presentation. No rush on this, but would be great to have it by Thursday if possible. Let me know if you need any additional info from me. Thanks a bunch!",
                    icon: "key"
                )
            ]
        case 2: // Friendly
            return [
                EmailTopic(
                    title: "Lunch Plans",
                    subject: "Coffee catch-up next week?",
                    body: "Hey! Hope you're doing well! It's been way too long since we last caught up. I was thinking we could grab coffee or lunch next week if you're free? I'd love to hear how the new job is going and just chat about life in general. I'm pretty flexible on timing, so just let me know what works for you! Maybe that café we went to last time? Looking forward to it!",
                    icon: "cup.and.saucer"
                ),
                EmailTopic(
                    title: "Weekend Plans",
                    subject: "Beach trip this Saturday?",
                    body: "Hi there! So I know this is kind of last minute, but a bunch of us are planning a beach trip this Saturday and I immediately thought of you! We're leaving around 9am and will probably spend the whole day there. Bring sunscreen and maybe some snacks to share. It's supposed to be beautiful weather! Let me know if you can make it. No worries if not, but it would be awesome to have you there! Talk soon!",
                    icon: "sun.max"
                ),
                EmailTopic(
                    title: "Thank You Note",
                    subject: "Thanks for your help!",
                    body: "Hey! I just wanted to send you a quick note to say thank you so much for helping me out last week. I really appreciate you taking the time to walk me through everything. You made what seemed super complicated actually make sense! I definitely owe you lunch or coffee. Seriously, just let me know when you're free and it's on me. You're the best! Hope you have an amazing rest of your week!",
                    icon: "heart"
                )
            ]
        default:
            return []
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text("Quick Ideas")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Text("Tap to use")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(topics) { topic in
                        QuickTopicCard(topic: topic) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                onSelectTopic(topic)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Quick Topic Card
struct QuickTopicCard: View {
    let topic: EmailTopic
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: topic.icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.15))
                    )
                
                Text(topic.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(topic.subject)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(width: 140)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Indicator
struct ProgressIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int
    let hasCompleted: (Int) -> Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                ForEach(0..<totalSteps, id: \.self) { i in
                    Circle()
                        .fill(i == currentStep ? Color.blue : (hasCompleted(i) ? Color.green : Color.white.opacity(0.3)))
                        .frame(width: 12, height: 12)
                    
                    if i < totalSteps - 1 {
                        Rectangle()
                            .fill(i < currentStep ? Color.blue : Color.white.opacity(0.3))
                            .frame(height: 2)
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Text("Email \(currentStep + 1) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Email Type Header
struct EmailTypeHeader: View {
    let type: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Circle()
                    .strokeBorder(color.opacity(0.4), lineWidth: 2)
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(color)
            }
            .shadow(color: color.opacity(0.3), radius: 10, y: 4)
            
            VStack(spacing: 8) {
                Text(type + " Email")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(color.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: - Subject Input
struct SubjectInputView: View {
    @Binding var subject: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Subject Line")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Text("\(subject.count)/100")
                    .font(.caption)
                    .foregroundColor(subject.count > 100 ? .red : .white.opacity(0.6))
            }
            
            TextField("Enter subject line", text: $subject)
                .textFieldStyle(.plain)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .onChange(of: subject) { _, newValue in
                    if newValue.count > 100 {
                        subject = String(newValue.prefix(100))
                    }
                }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Body Input
struct BodyInputView: View {
    @Binding var text: String
    let example: String
    
    private var sentenceCount: Int {
        text.split { ".!?".contains($0) }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Email Body")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: sentenceCount >= 3 ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundColor(sentenceCount >= 3 ? .green : .white.opacity(0.4))
                    Text("\(sentenceCount)/3 sentences")
                        .font(.caption)
                        .foregroundColor(sentenceCount >= 3 ? .green : .white.opacity(0.6))
                }
            }
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text("Paste or type your email here...")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                
                TextEditor(text: $text)
                    .font(.callout)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 160)
                    .padding(12)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            
            if text.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Example:")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(example)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                        .italic()
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.02))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.03))
        )
    }
}

// MARK: - Navigation Buttons
struct NavigationButtons: View {
    let currentStep: Int
    let canProceed: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button(action: onPrevious) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Previous")
                    }
                    .font(.callout.weight(.medium))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1.5)
                    )
                }
            }
            
            Button(action: onNext) {
                HStack {
                    Text(currentStep == 2 ? "Analyze My Style" : "Next")
                    if currentStep < 2 {
                        Image(systemName: "chevron.right")
                    } else {
                        Image(systemName: "sparkles")
                    }
                }
                .font(.callout.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(canProceed ? Color.blue : Color.white.opacity(0.2))
                )
            }
            .disabled(!canProceed)
        }
    }
}

// MARK: - Processing View
struct ProcessingView: View {
    @Binding var animationPhase: Double
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(animationPhase * 360))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animationPhase)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(.blue)
                        .scaleEffect(1.0 + sin(animationPhase * .pi * 2) * 0.1)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationPhase)
                }
                .shadow(color: Color.blue.opacity(0.3), radius: 20, y: 8)
                .onAppear { animationPhase = 1.0 }
                
                VStack(spacing: 12) {
                    Text("Analyzing Your Writing Style")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text("Our AI is reading your emails to understand your unique voice")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Text("This usually takes 10-30 seconds")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
            
            Spacer()
        }
    }
}

// MARK: - Result View
struct CustomStyleResultView: View {
    let result: CustomEmailStyleResponse
    let onContinue: () -> Void
    let onRetry: () -> Void
    @EnvironmentObject var onboarding: OnboardingManager
    
    var body: some View {
        VStack(spacing: 24) {
            if result.success {
                // SUCCESS
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)
                    }
                    .shadow(color: Color.green.opacity(0.3), radius: 20, y: 8)
                    
                    VStack(spacing: 12) {
                        Text("Style Captured Successfully!")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        if let gradeDisplay = result.gradeDisplay {
                            Text(gradeDisplay)
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        
                        Text("Your assistant will now write emails that sound just like you.")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(Color.green.opacity(0.3), lineWidth: 2)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                
                Button(action: onContinue) {
                    HStack {
                        Text("Continue to App")
                        Image(systemName: "arrow.right")
                    }
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green)
                    )
                }
                
            } else {
                // ERROR
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: result.isRateLimitError ? "clock.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.orange)
                    }
                    .shadow(color: Color.orange.opacity(0.3), radius: 20, y: 8)
                    
                    VStack(spacing: 12) {
                        Text(result.isRateLimitError ? "Daily Limit Reached" : "Analysis Failed")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text(result.friendlyError)
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                        
                        if let rateLimitInfo = result.rateLimitInfo {
                            Text("Resets at midnight UTC (\(formatResetTime(rateLimitInfo.resetTime)))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(Color.orange.opacity(0.3), lineWidth: 2)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
                
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text(result.isRateLimitError ? "Back to Start" : "Try Different Examples")
                    }
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.orange)
                    )
                }
            }
        }
    }
    
    private func formatResetTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return "soon"
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: date)
    }
}

// MARK: - Previews

#Preview("1. Step 1 - Professional") {
    OnboardingEmailStyleView()
        .environmentObject(OnboardingManager())
}

#Preview("2. Step 2 - Casual") {
    OnboardingEmailStyleView()
        .environmentObject({
            let mgr = OnboardingManager()
            return mgr
        }())
        .onAppear {
            // Simulate being on step 2
        }
}

#Preview("3. Processing") {
    ZStack {
        AppBackground()
        ProcessingView(animationPhase: .constant(0.5))
            .padding(24)
    }
}

#Preview("4. Success Result") {
    ZStack {
        AppBackground()
        CustomStyleResultView(
            result: CustomEmailStyleResponse(
                success: true,
                styleProfile: nil,
                extractionGrade: "A",
                errorMessage: nil,
                rateLimitInfo: nil,
                nextStep: nil
            ),
            onContinue: {},
            onRetry: {}
        )
        .environmentObject(OnboardingManager())
        .padding(24)
    }
}

#Preview("5. Error Result") {
    ZStack {
        AppBackground()
        CustomStyleResultView(
            result: CustomEmailStyleResponse(
                success: false,
                styleProfile: nil,
                extractionGrade: nil,
                errorMessage: "Unable to extract a consistent writing style. Please provide more varied examples.",
                rateLimitInfo: nil,
                nextStep: nil
            ),
            onContinue: {},
            onRetry: {}
        )
        .environmentObject(OnboardingManager())
        .padding(24)
    }
}

#Preview("6. Quick Topics - Professional") {
    ZStack {
        AppBackground()
        
        ScrollView {
            VStack(spacing: 24) {
                EmailTypeHeader(
                    type: "Professional",
                    description: "Enter a formal business email you'd send to a client or executive",
                    icon: "briefcase.fill",
                    color: .blue
                )
                
                QuickTopicSuggestions(
                    currentStep: 0,
                    onSelectTopic: { topic in
                        print("Selected: \(topic.title)")
                    }
                )
            }
            .padding(24)
        }
    }
}

#Preview("7. Quick Topics - Casual") {
    ZStack {
        AppBackground()
        
        ScrollView {
            VStack(spacing: 24) {
                EmailTypeHeader(
                    type: "Casual",
                    description: "Enter a standard work email to a colleague or team member",
                    icon: "person.2.fill",
                    color: .purple
                )
                
                QuickTopicSuggestions(
                    currentStep: 1,
                    onSelectTopic: { topic in
                        print("Selected: \(topic.title)")
                    }
                )
            }
            .padding(24)
        }
    }
}

#Preview("8. Quick Topics - Friendly") {
    ZStack {
        AppBackground()
        
        ScrollView {
            VStack(spacing: 24) {
                EmailTypeHeader(
                    type: "Friendly",
                    description: "Enter a warm, informal email to someone you know well",
                    icon: "heart.fill",
                    color: .pink
                )
                
                QuickTopicSuggestions(
                    currentStep: 2,
                    onSelectTopic: { topic in
                        print("Selected: \(topic.title)")
                    }
                )
            }
            .padding(24)
        }
    }
}

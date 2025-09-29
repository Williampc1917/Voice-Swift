//
//  OnboardingEmailStyleView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/29/25.
//

import SwiftUI

struct OnboardingEmailStyleView: View {
    @EnvironmentObject var onboarding: OnboardingManager
    @State private var showCustomStyleSetup = false
    @State private var selectedStyleName: String?
    
    var body: some View {
        ZStack {
            AppBackground() // Design system background
            
            ScrollView {
                VStack(spacing: 36) {
                    Spacer().frame(height: 20)
                    
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "text.bubble")
                            .font(.system(size: 48, weight: .semibold))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.blue)
                            .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
                        
                        Text("Choose Your Email Style")
                            .font(.title.bold())
                            .foregroundColor(.white)
                        
                        Text("Select how your voice assistant should write emails for you. You can always change this later.")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Loading state
                    if onboarding.isLoading && onboarding.availableEmailStyles.isEmpty {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.blue)
                            
                            Text("Loading email styles...")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .appCardStyle()
                        .padding(.horizontal, 24)
                    }
                    // Success state (style already selected)
                    else if onboarding.emailStyleSelected {
                        SuccessStateView()
                    }
                    // Main content (style options)
                    else if !onboarding.availableEmailStyles.isEmpty {
                        VStack(spacing: 16) {
                            ForEach(onboarding.availableEmailStyles) { option in
                                EmailStyleOptionCard(
                                    option: option,
                                    isSelected: selectedStyleName == option.name,
                                    onSelect: {
                                        handleStyleSelection(option)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    // Error state
                    else if let error = onboarding.errorMessage {
                        ErrorStateView(error: error)
                    }
                    
                    Spacer().frame(height: 44)
                }
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showCustomStyleSetup) {
            CustomStyleSetupSheet()
        }
        .task {
            // Load options when view appears
            if onboarding.availableEmailStyles.isEmpty && !onboarding.emailStyleSelected {
                await onboarding.loadEmailStyleOptions()
            }
        }
    }
    
    // MARK: - Style Selection Handler
    private func handleStyleSelection(_ option: EmailStyleOption) {
        selectedStyleName = option.name
        
        Task {
            switch option.name.lowercased() {
            case "casual":
                await onboarding.selectPredefinedStyle(.casual)
                
            case "professional":
                await onboarding.selectPredefinedStyle(.professional)
                
            case "custom":
                // Check if available (not rate limited)
                if option.available {
                    showCustomStyleSetup = true
                } else {
                    // Show rate limit error
                    onboarding.errorMessage = option.rateLimitDisplay ?? "Custom style temporarily unavailable"
                }
                
            default:
                break
            }
        }
    }
}

// MARK: - Email Style Option Card
struct EmailStyleOptionCard: View {
    let option: EmailStyleOption
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and name
                HStack {
                    Image(systemName: option.iconName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(option.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 24))
                    }
                }
                
                // Example preview
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Preview:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Greeting:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text(option.example.greeting)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack {
                            Text("Closing:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text(option.example.closing)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack {
                            Text("Tone:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                            Text(option.example.tone)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    )
                }
                
                // Rate limit info for custom option
                if option.name.lowercased() == "custom", let rateLimitInfo = option.rateLimitInfo {
                    HStack {
                        Image(systemName: rateLimitInfo.canExtract ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundColor(rateLimitInfo.canExtract ? .green : .orange)
                            .font(.caption)
                        
                        if rateLimitInfo.canExtract {
                            Text("\(rateLimitInfo.dailyLimit - rateLimitInfo.usedToday) custom style\(rateLimitInfo.dailyLimit - rateLimitInfo.usedToday == 1 ? "" : "s") remaining today")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Text("Daily limit reached • Resets in \(rateLimitInfo.resetCountdown)")
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.9))
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                }
                
                // Unavailable overlay
                if !option.available {
                    Text("Try Casual or Professional instead")
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.9))
                        .padding(.top, 4)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                isSelected ? Color.blue : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
            .opacity(option.available ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Success State View
struct SuccessStateView: View {
    @EnvironmentObject var onboarding: OnboardingManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Success message
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                    .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
                
                Text("Email Style Selected!")
                    .font(.headline)
                    .foregroundColor(.green)
                
                if let styleName = onboarding.currentEmailStyle {
                    Text("You've chosen the \(styleName.capitalized) style")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                
                Text("Your assistant will now write emails in your preferred style.")
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .appCardStyle()
            .padding(.horizontal, 24)
            
            // Continue button
            Button {
                // Onboarding is automatically marked complete by the manager
                // The app will transition to the main view
            } label: {
                Label("Continue to App", systemImage: "arrow.right")
            }
            .appButtonStyle(disabled: onboarding.isLoading)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: String
    @EnvironmentObject var onboarding: OnboardingManager
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                    .shadow(color: Color.orange.opacity(0.3), radius: 8, y: 4)
                
                Text("Unable to Load Styles")
                    .font(.headline)
                    .foregroundColor(.orange)
                
                Text(error)
                    .font(.callout)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
            .appCardStyle()
            .padding(.horizontal, 24)
            
            // Retry button
            Button {
                Task {
                    await onboarding.loadEmailStyleOptions()
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .appButtonStyle(disabled: onboarding.isLoading)
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Custom Style Setup Sheet
struct CustomStyleSetupSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var onboarding: OnboardingManager
    
    @State private var emailExamples = ["", "", ""]
    @State private var currentExampleIndex = 0
    @State private var isProcessing = false
    @State private var extractionResult: CustomEmailStyleResponse?
    @State private var showResult = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundColor(.blue)
                                .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
                            
                            VStack(spacing: 8) {
                                Text("Train Your Custom Style")
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                                
                                Text("Provide 3 email examples so we can learn your unique writing style.")
                                    .font(.callout)
                                    .foregroundColor(.white.opacity(0.85))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Show result if extraction is complete
                        if showResult, let result = extractionResult {
                            CustomStyleResultView(result: result, onDismiss: {
                                dismiss()
                            })
                        }
                        // Show input form
                        else {
                            CustomStyleInputForm(
                                emailExamples: $emailExamples,
                                currentExampleIndex: $currentExampleIndex,
                                isProcessing: $isProcessing,
                                onSubmit: {
                                    await submitCustomStyle()
                                }
                            )
                        }
                        
                        Spacer().frame(height: 44)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .disabled(isProcessing)
                }
            }
        }
    }
    
    private func submitCustomStyle() async {
        isProcessing = true
        
        // Filter out empty examples
        let validExamples = emailExamples.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let result = await onboarding.createCustomStyle(emailExamples: validExamples)
        
        isProcessing = false
        
        if let result = result {
            extractionResult = result
            showResult = true
            
            // Auto-dismiss on success after a delay
            if result.success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Custom Style Input Form
struct CustomStyleInputForm: View {
    @Binding var emailExamples: [String]
    @Binding var currentExampleIndex: Int
    @Binding var isProcessing: Bool
    let onSubmit: () async -> Void
    
    @State private var emailSubjects = ["", "", ""]
    @State private var emailBodies = ["", "", ""]
    @State private var currentStep = 0
    
    let sampleTitles = [
        "Professional Email",
        "Follow-up Email",
        "Casual Email"
    ]
    
    let sampleDescriptions = [
        "Paste a formal business email you've written, or use the example for inspiration.",
        "Provide a reply or follow-up email, or draft one using the scenario below.",
        "Include a casual or internal team email — real or roleplay."
    ]
    
    private var canProceed: Bool {
        let subject = emailSubjects[currentStep].trimmingCharacters(in: .whitespacesAndNewlines)
        let body = emailBodies[currentStep]
        return !subject.isEmpty && sentenceCount(in: body) >= 3
    }
    
    private var canSubmit: Bool {
        // Check if all 3 emails have both subject and body with at least 3 sentences
        for i in 0..<3 {
            let subject = emailSubjects[i].trimmingCharacters(in: .whitespacesAndNewlines)
            let body = emailBodies[i]
            if subject.isEmpty || sentenceCount(in: body) < 3 {
                return false
            }
        }
        return true
    }
    
    private func sentenceCount(in text: String) -> Int {
        let sentences = text.split { ".!?".contains($0) }
        return sentences.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress indicator with connected lines
            VStack(spacing: 12) {
                HStack {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(index == currentStep ? Color.blue : (hasCompletedStep(index) ? Color.blue : Color.white.opacity(0.3)))
                            .frame(width: 12, height: 12)
                        
                        if index < 2 {
                            Rectangle()
                                .fill(index < currentStep ? Color.blue : Color.white.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Text("Sample \(currentStep + 1) of 3")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Current sample info
            VStack(spacing: 8) {
                Text(sampleTitles[currentStep])
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(sampleDescriptions[currentStep])
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            // Subject input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Subject")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                    
                    Spacer()
                    
                    Text("\(emailSubjects[currentStep].count)/100")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                TextField("Enter subject line", text: $emailSubjects[currentStep])
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                    .foregroundColor(.white)
            }
            .appCardStyle()
            
            // Body input
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Body")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                    
                    Spacer()
                    
                    Text("\(emailBodies[currentStep].count)/500")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                TextEditor(text: $emailBodies[currentStep])
                    .font(.callout)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: 140)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                
                if emailBodies[currentStep].isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Example:")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(getPlaceholderBody())
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                            .italic()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .appCardStyle()
            
            // Guidance tip
            Text("Tip: Minimum 3 sentences per body for best results.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Navigation buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button("Previous") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep -= 1
                        }
                    }
                    .font(.callout.weight(.medium))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                
                Button(currentStep == 2 ? "Analyze My Style" : "Next") {
                    if currentStep == 2 {
                        // Combine subject + body for each email
                        for i in 0..<3 {
                            emailExamples[i] = "Subject: \(emailSubjects[i])\n\n\(emailBodies[i])"
                        }
                        
                        Task {
                            await onSubmit()
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep += 1
                        }
                    }
                }
                .font(.callout.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(canProceed ? Color.blue : Color.white.opacity(0.2))
                )
                .disabled(!canProceed || isProcessing)
                .animation(.easeInOut(duration: 0.2), value: canProceed)
            }
        }
    }
    
    private func hasCompletedStep(_ index: Int) -> Bool {
        let subject = emailSubjects[index].trimmingCharacters(in: .whitespacesAndNewlines)
        let body = emailBodies[index]
        return !subject.isEmpty && sentenceCount(in: body) >= 3
    }
    
    private func getPlaceholderBody() -> String {
        switch currentStep {
        case 0:
            return "Hi Sarah,\n\nI wanted to follow up on the project timeline we discussed. Could you please send me the updated requirements by Friday?\n\nBest regards,\nJohn"
        case 1:
            return "Thanks for the quick response! I've reviewed the document and have a few questions. Would you be available for a brief call tomorrow?\n\nThanks,\nJohn"
        case 2:
            return "Hey team!\n\nGreat work on the launch today. Pizza's on me for the celebration. See you all tomorrow!\n\nCheers,\nJohn"
        default:
            return ""
        }
    }
}

// MARK: - Custom Style Result View
struct CustomStyleResultView: View {
    let result: CustomEmailStyleResponse
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            if result.success {
                // Success
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Style Captured!")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    if let gradeDisplay = result.gradeDisplay {
                        Text(gradeDisplay)
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                }
                .appCardStyle()
            } else {
                // Error
                VStack(spacing: 16) {
                    Image(systemName: result.isRateLimitError ? "clock.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    Text(result.isRateLimitError ? "Daily Limit Reached" : "Unable to Analyze")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text(result.friendlyError)
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .appCardStyle()
                
                // Dismiss button for errors
                Button {
                    onDismiss()
                } label: {
                    Text("OK")
                }
                .appButtonStyle()
            }
        }
    }
}

#Preview("Initial State") {
    OnboardingEmailStyleView()
        .environmentObject({
            let mgr = OnboardingManager()
            mgr.availableEmailStyles = []
            mgr.emailStyleSelected = false
            return mgr
        }())
}

#Preview("With Options") {
    OnboardingEmailStyleView()
        .environmentObject({
            let mgr = OnboardingManager()
            mgr.availableEmailStyles = [
                EmailStyleOption(
                    name: "Casual",
                    description: "Friendly, informal communication style",
                    example: EmailStyleExample(greeting: "Hey [name]!", closing: "Thanks!", tone: "Friendly and direct"),
                    available: true,
                    rateLimitInfo: nil
                ),
                EmailStyleOption(
                    name: "Professional",
                    description: "Formal, business-appropriate style",
                    example: EmailStyleExample(greeting: "Dear [name],", closing: "Best regards,", tone: "Formal and polite"),
                    available: true,
                    rateLimitInfo: nil
                ),
                EmailStyleOption(
                    name: "Custom",
                    description: "Personalized style learned from your emails",
                    example: EmailStyleExample(greeting: "Based on your writing", closing: "Matches your preferences", tone: "Uniquely yours"),
                    available: true,
                    rateLimitInfo: RateLimitInfo(canExtract: true, usedToday: 0, dailyLimit: 2, hoursUntilReset: 18.5)
                )
            ]
            return mgr
        }())
}

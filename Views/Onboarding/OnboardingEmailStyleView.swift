//
//  OnboardingEmailStyleView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/29/25.
//  FINAL: Simple, clean flow with clear button states
//

import SwiftUI

struct OnboardingEmailStyleView: View {
    @EnvironmentObject var onboarding: OnboardingManager
    @State private var showCustomStyleSetup = false
    @State private var selectedStyleName: String?
    @State private var showContinueButton = false
     
    var body: some View {
        ZStack {
            AppBackground()
            
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
                        
                        // Continue button (appears after selection)
                        if showContinueButton {
                            Button {
                                completeOnboarding()
                            } label: {
                                if onboarding.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Label("Continue to App", systemImage: "arrow.right")
                                }
                            }
                            .appButtonStyle(disabled: onboarding.isLoading)
                            .padding(.horizontal, 24)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.3), value: showContinueButton)
                        }
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
            CustomStyleSetupSheet(onComplete: {
                // After custom style completes successfully
                selectedStyleName = "Custom"
                showContinueButton = true
            })
        }
        .task {
            if onboarding.availableEmailStyles.isEmpty {
                await onboarding.loadEmailStyleOptions()
            }
        }
    }
    
    // MARK: - Style Selection Handler
    private func handleStyleSelection(_ option: EmailStyleOption) {
        selectedStyleName = option.name
        
        switch option.name.lowercased() {
        case "casual":
            Task {
                await onboarding.selectPredefinedStyle(.casual)
                showContinueButton = true
            }
            
        case "professional":
            Task {
                await onboarding.selectPredefinedStyle(.professional)
                showContinueButton = true
            }
            
        case "custom":
            if option.available {
                showCustomStyleSetup = true
            } else {
                onboarding.errorMessage = option.rateLimitDisplay ?? "Custom style temporarily unavailable"
            }
            
        default:
            break
        }
    }
    
    // MARK: - Complete Onboarding
    private func completeOnboarding() {
        onboarding.needsOnboarding = false
        onboarding.step = .completed
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
                HStack(alignment: .top) {
                    Image(systemName: option.iconName)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(option.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(option.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 0)
                    
                    // Fixed-size checkmark that doesn't affect layout
                    ZStack {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 24))
                        }
                    }
                    .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Preview:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(alignment: .top) {
                            Text("Greeting:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 60, alignment: .leading)
                            Text(option.example.greeting)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        HStack(alignment: .top) {
                            Text("Closing:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 60, alignment: .leading)
                            Text(option.example.closing)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        HStack(alignment: .top) {
                            Text("Tone:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 60, alignment: .leading)
                            Text(option.example.tone)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.03))
                    )
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
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
            
            Button {
                Task { await onboarding.loadEmailStyleOptions() }
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
    let onComplete: () -> Void
    
    @State private var emailExamples = ["", "", ""]
    @State private var isProcessing = false
    @State private var extractionResult: CustomEmailStyleResponse?
    @State private var showResult = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
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
                        
                        if showResult, let result = extractionResult {
                            CustomStyleResultView(
                                result: result,
                                onContinue: {
                                    dismiss()
                                    onComplete()
                                },
                                onRetry: {
                                    // Reset to step 1
                                    showResult = false
                                    extractionResult = nil
                                    emailExamples = ["", "", ""]
                                }
                            )
                        } else {
                            CustomStyleInputForm(
                                emailExamples: $emailExamples,
                                isProcessing: $isProcessing,
                                onSubmit: { await submitCustomStyle() }
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
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.85))
                        .disabled(isProcessing)  // ← Disable cancel during AI processing
                }
            }
        }
    }
    
    private func submitCustomStyle() async {
        isProcessing = true
        let validExamples = emailExamples.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let result = await onboarding.createCustomStyle(emailExamples: validExamples)
        isProcessing = false
        
        if let result = result {
            extractionResult = result
            showResult = true
        }
    }
}

// MARK: - Custom Style Input Form
struct CustomStyleInputForm: View {
    @Binding var emailExamples: [String]
    @Binding var isProcessing: Bool
    let onSubmit: () async -> Void
    
    @State private var emailSubjects = ["", "", ""]
    @State private var emailBodies = ["", "", ""]
    @State private var currentStep = 0
    @State private var animationPhase = 0.0
    
    let titles = ["Professional Email", "Follow-up Email", "Casual Email"]
    let descriptions = [
        "Enter a formal business email",
        "Enter a reply or follow-up email",
        "Enter a casual or internal team email"
    ]
    
    private var canProceed: Bool {
        !emailSubjects[currentStep].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        sentenceCount(in: emailBodies[currentStep]) >= 3
    }
    
    private func sentenceCount(in text: String) -> Int {
        text.split { ".!?".contains($0) }.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // 🔄 SHOW LOADING STATE WHILE PROCESSING
            if isProcessing {
                Spacer()
                
                VStack(spacing: 24) {
                    // Animated brain icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 64, weight: .semibold))
                        .foregroundColor(.blue)
                        .scaleEffect(1.0 + sin(animationPhase) * 0.1)
                        .shadow(color: Color.blue.opacity(0.3), radius: 12, y: 6)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationPhase)
                        .onAppear { animationPhase = 1.0 }
                    
                    // Progress spinner
                    ProgressView()
                        .scaleEffect(1.3)
                        .tint(.blue)
                    
                    VStack(spacing: 8) {
                        Text("Analyzing Your Writing Style...")
                            .font(.title3.bold())
                            .foregroundColor(.white)
                        
                        Text("This usually takes 10-30 seconds")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Our AI is reading your emails to learn your unique style")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 4)
                    }
                }
                .appCardStyle()
                
                Spacer()
            } else {
                // 📝 SHOW WIZARD FORM WHEN NOT PROCESSING
                // 📝 SHOW WIZARD FORM WHEN NOT PROCESSING
                // Progress indicator
                VStack(spacing: 12) {
                    HStack {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(i == currentStep ? Color.blue : (hasCompleted(i) ? Color.blue : Color.white.opacity(0.3)))
                                .frame(width: 12, height: 12)
                            if i < 2 {
                                Rectangle()
                                    .fill(i < currentStep ? Color.blue : Color.white.opacity(0.3))
                                    .frame(height: 2)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Text("Email \(currentStep + 1) of 3")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                VStack(spacing: 8) {
                    Text(titles[currentStep])
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(descriptions[currentStep])
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
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.05)))
                        .foregroundColor(.white)
                }
                .appCardStyle()
                
                // Body input
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Body (minimum 3 sentences)")
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
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                        )
                    
                    if emailBodies[currentStep].isEmpty {
                        Text("Example: \(getExample())")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .appCardStyle()
                
                Text("💡 Provide exactly 3 different emails with at least 3 sentences each")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                
                // Navigation buttons
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Previous") {
                            withAnimation { currentStep -= 1 }
                        }
                        .font(.callout.weight(.medium))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    
                    Button(currentStep == 2 ? "Analyze My Style" : "Next") {
                        if currentStep == 2 {
                            // Combine subject + body
                            for i in 0..<3 {
                                emailExamples[i] = "Subject: \(emailSubjects[i])\n\n\(emailBodies[i])"
                            }
                            Task { await onSubmit() }
                        } else {
                            withAnimation { currentStep += 1 }
                        }
                    }
                    .font(.callout.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(canProceed ? Color.blue : Color.white.opacity(0.2)))
                    .disabled(!canProceed || isProcessing)
                }
            }
        }
    }
    
    private func hasCompleted(_ i: Int) -> Bool {
        !emailSubjects[i].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        sentenceCount(in: emailBodies[i]) >= 3
    }
    
    private func getExample() -> String {
        ["Hi Sarah, I wanted to follow up on the project timeline. Could you send me the updated requirements by Friday? Best regards, John",
         "Thanks for the quick response! I've reviewed the document. Would you be available for a brief call tomorrow? Thanks, John",
         "Hey team! Great work on the launch today. Pizza's on me for the celebration. See you all tomorrow! Cheers, John"][currentStep]
    }
}

// MARK: - Custom Style Result View
struct CustomStyleResultView: View {
    let result: CustomEmailStyleResponse
    let onContinue: () -> Void
    let onRetry: () -> Void
    @EnvironmentObject var onboarding: OnboardingManager
    
    var body: some View {
        VStack(spacing: 20) {
            if result.success {
                // SUCCESS STATE
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                        .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
                    
                    Text("Style Captured!")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    if let gradeDisplay = result.gradeDisplay {
                        Text(gradeDisplay)
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                    
                    Text("Your assistant will now write emails in your personal style.")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .appCardStyle()
                
                Button {
                    onContinue()
                } label: {
                    Label("Continue to App", systemImage: "arrow.right")
                }
                .appButtonStyle()
                
            } else {
                // ERROR STATE
                VStack(spacing: 16) {
                    Image(systemName: result.isRateLimitError ? "clock.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                        .shadow(color: Color.orange.opacity(0.3), radius: 8, y: 4)
                    
                    Text(result.isRateLimitError ? "Daily Limit Reached" : "Unable to Analyze")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text(result.friendlyError)
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                    
                    if result.isRateLimitError {
                        Text("Try selecting Casual or Professional style instead, or come back tomorrow.")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                .appCardStyle()
                
                Button {
                    onRetry()
                } label: {
                    Text(result.isRateLimitError ? "Choose Different Style" : "Try Different Examples")
                }
                .appButtonStyle()
            }
        }
    }
}

// MARK: - Previews

#Preview("1. Choose Email Style") {
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
                    rateLimitInfo: nil
                )
            ]
            return mgr
        }())
}

#Preview("2. Custom Style Wizard - Step 1") {
    NavigationStack {
        ZStack {
            AppBackground().ignoresSafeArea()
            CustomStyleInputForm(
                emailExamples: .constant(["", "", ""]),
                isProcessing: .constant(false),
                onSubmit: {}
            )
            .padding()
        }
    }
}

#Preview("2b. AI Processing - Loading State 🔄") {
    NavigationStack {
        ZStack {
            AppBackground().ignoresSafeArea()
            CustomStyleInputForm(
                emailExamples: .constant(["", "", ""]),
                isProcessing: .constant(true),  // ← Shows loading state
                onSubmit: {}
            )
            .padding()
        }
    }
}

#Preview("3. Custom Style - Success") {
    NavigationStack {
        ZStack {
            AppBackground().ignoresSafeArea()
            CustomStyleResultView(
                result: CustomEmailStyleResponse(
                    success: true,
                    styleProfile: StyleProfile(
                        greeting: GreetingStyle(style: "casual", warmth: "high"),
                        closing: ClosingStyle(styles: ["Thanks", "Cheers"], includesName: true),
                        tone: ToneStyle(formality: 2, directness: 4, enthusiasm: 4, politeness: 3)
                    ),
                    extractionGrade: "A",
                    errorMessage: nil,
                    rateLimitInfo: nil,
                    nextStep: "completed"
                ),
                onContinue: {},
                onRetry: {}
            )
            .environmentObject(OnboardingManager())
            .padding()
        }
    }
}

#Preview("4. Custom Style - Error") {
    NavigationStack {
        ZStack {
            AppBackground().ignoresSafeArea()
            CustomStyleResultView(
                result: CustomEmailStyleResponse(
                    success: false,
                    styleProfile: nil,
                    extractionGrade: "C",
                    errorMessage: "Unable to extract a consistent writing style. Please provide more varied emails.",
                    rateLimitInfo: nil,
                    nextStep: nil
                ),
                onContinue: {},
                onRetry: {}
            )
            .environmentObject(OnboardingManager())
            .padding()
        }
    }
}

//
//  CustomDraftingSetupView.swift
//  voice-gmail-assistant
//
//  Created by William Pineda on 9/21/25.
import SwiftUI

struct CustomDraftingSetupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var emailSubjects = ["", "", ""]
    @State private var emailBodies = ["", "", ""]
    @State private var currentStep = 0
    @Binding var isConfigured: Bool
    
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // MARK: - Sticky Header
                    headerSection
                    
                    // MARK: - Scrollable Content
                    ScrollView {
                        VStack(spacing: 32) {
                            
                            // Header Icon & Title
                            VStack(spacing: 16) {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 48, weight: .semibold))
                                    .foregroundColor(.blue)
                                    .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
                                
                                VStack(spacing: 8) {
                                    Text("Train Your Style")
                                        .font(.title.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("Provide 3 email samples so your assistant can capture your writing style. You can paste real emails, or write new ones using the examples.")
                                        .font(.callout)
                                        .foregroundColor(.white.opacity(0.85))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                }
                            }
                            .padding(.top, 20)
                            
                            // Progress
                            VStack(spacing: 12) {
                                HStack {
                                    ForEach(0..<3, id: \.self) { index in
                                        Circle()
                                            .fill(index == currentStep ? Color.blue : Color.white.opacity(0.3))
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
                            
                            // Current Sample
                            VStack(spacing: 16) {
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
                                        .padding(10)
                                        .background(Color.white.opacity(0.08))
                                        .cornerRadius(8)
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
                                        .appInputStyle()
                                    
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
                                
                                // Guidance banner
                                Text("Tip: Minimum 3 sentences per body for best results.")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 4)
                            }
                            
                            // Navigation
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
                                
                                Button(currentStep == 2 ? "Complete Setup" : "Next") {
                                    if currentStep == 2 {
                                        isConfigured = true
                                        dismiss()
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
                                .disabled(!canProceed)
                                .animation(.easeInOut(duration: 0.2), value: canProceed)
                            }
                            .padding(.horizontal, 24)
                            
                            Color.clear.frame(height: 44)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .presentationBackground(.clear)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            // Cancel button
            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.callout)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Title
            Text("")
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer to balance layout
            Text("Cancel")
                .font(.callout)
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    // MARK: - Validation
    private var canProceed: Bool {
        let subject = emailSubjects[currentStep].trimmingCharacters(in: .whitespacesAndNewlines)
        let body = emailBodies[currentStep]
        return !subject.isEmpty && sentenceCount(in: body) >= 3
    }
    
    private func sentenceCount(in text: String) -> Int {
        let sentences = text.split { ".!?".contains($0) }
        return sentences.count
    }
    
    // MARK: - Placeholders
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

#Preview {
    @State var isConfigured = false
    return CustomDraftingSetupView(isConfigured: $isConfigured)
}

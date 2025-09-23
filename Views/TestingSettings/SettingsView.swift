//
//  SettingsView.swift
//  voice-gmail-assistant
//
//  Complete settings view with custom drafting setup and document library
//

import SwiftUI

private struct SettingsSafeTopKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    // State
    @State private var userName = "Jane Doe"
    @State private var draftingStyle = "Professional"
    @State private var voiceModel = "Assistant Voice"
    @State private var subscriptionType = "Free"
    @State private var gmailConnected = true
    @State private var calendarConnected = false
    @State private var isEditingName = false
    @State private var voiceMinutesRemaining = 5 // Mock minutes remaining

    // Custom drafting style states
    @State private var customStyleConfigured = false
    @State private var showingCustomSetup = false

    // Document Library states
    @State private var connectedFiles: [ConnectedFile] = []
    @State private var showingFilePicker = false
    @State private var isLoadingFiles = false

    @State private var safeTop: CGFloat = 0
    
    // Mock connected files data
    let mockFiles: [ConnectedFile] = [
        ConnectedFile(
            id: "1",
            name: "Annual Report 2024.pdf",
            type: .pdf,
            lastModified: "2 days ago",
            hasAccess: true,
            isRecentlyUsed: true
        ),
        ConnectedFile(
            id: "2",
            name: "Q3 Budget Analysis.xlsx",
            type: .excel,
            lastModified: "1 week ago",
            hasAccess: false,
            isRecentlyUsed: false
        ),
        ConnectedFile(
            id: "3",
            name: "Contract Template.docx",
            type: .word,
            lastModified: "3 days ago",
            hasAccess: true,
            isRecentlyUsed: true
        ),
        ConnectedFile(
            id: "4",
            name: "Marketing Presentation.pptx",
            type: .powerpoint,
            lastModified: "5 days ago",
            hasAccess: true,
            isRecentlyUsed: false
        )
    ]

    let draftingOptions = ["Professional", "Casual", "Custom"]
    let voiceOptions = ["Assistant Voice", "Companion Voice"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground().ignoresSafeArea()

                GeometryReader { proxy in
                    Color.clear.preference(key: SettingsSafeTopKey.self, value: proxy.safeAreaInsets.top)
                }
                .frame(height: 0)
                .onPreferenceChange(SettingsSafeTopKey.self) { safeTop = $0 }

                ScrollView {
                    VStack(spacing: 32) {
                        // MARK: Hero Header
                        VStack(spacing: 8) {
                            HStack {
                                Button("Done") { dismiss() }
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 8)
                                    .contentShape(Rectangle())
                                Spacer()
                            }

                            VStack(spacing: 4) {
                                Text("Settings")
                                    .font(.system(size: 34, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Text("Customize your experience")
                                    .font(.footnote)
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.top, 12)

                            Divider()
                                .background(Color.white.opacity(0.15))
                                .padding(.top, 8)
                        }
                        .padding(.top, safeTop + 8)

                        // MARK: Sections
                        profileSection
                        voiceUsageSection
                        draftingStyleSection
                        voiceSection
                        subscriptionSection
                        documentLibrarySection
                        connectionStatusSection
                        Color.clear.frame(height: 44)
                    }
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingCustomSetup) {
                CustomDraftingSetupView(isConfigured: $customStyleConfigured)
                    .onDisappear {
                        if customStyleConfigured {
                            draftingStyle = "Custom"
                        }
                    }
            }
            .sheet(isPresented: $showingFilePicker) {
                GoogleDriveFilePickerView(selectedFiles: $connectedFiles)
            }
        }
        .onAppear {
            connectedFiles = mockFiles
        }
    }

    // MARK: - Sections
    private var profileSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "person.circle").foregroundColor(.blue).font(.headline)
                Text("Profile").font(.headline).foregroundColor(.white)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Name").font(.subheadline.weight(.medium)).foregroundColor(.white.opacity(0.85))
                    Spacer()
                    if isEditingName {
                        Button("Save") { isEditingName = false }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.blue)
                    } else {
                        Button("Edit") { isEditingName = true }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                if isEditingName {
                    TextField("Enter your name", text: $userName)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .appInputStyle()
                } else {
                    Text(userName)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .appInputStyle()
                }
            }
            .appCardStyle()
        }
    }

    private var voiceUsageSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "timer").foregroundColor(.blue).font(.headline)
                Text("Voice Usage").font(.headline).foregroundColor(.white)
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Minutes remaining display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Minutes Remaining")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white.opacity(0.85))
                        
                        HStack(spacing: 8) {
                            Text("\(voiceMinutesRemaining)")
                                .font(.title2.bold())
                                .foregroundColor(voiceMinutesRemaining > 10 ? .white : .orange)
                            
                            Text("min")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // Visual indicator
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 50, height: 50)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(voiceMinutesRemaining) / 100.0) // Assuming 100 is max
                            .stroke(
                                voiceMinutesRemaining > 10 ? Color.green : Color.orange,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int((CGFloat(voiceMinutesRemaining) / 100.0) * 100))%")
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Usage info
                VStack(spacing: 8) {
                    HStack {
                        Text("Plan Limit:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Spacer()
                        Text(subscriptionType == "Pro" ? "Unlimited" : "100 min/month")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if subscriptionType == "Free" && voiceMinutesRemaining <= 10 {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text("Running low on minutes")
                                .font(.caption)
                                .foregroundColor(.orange)
                            
                            Spacer()
                            
                            Button("Upgrade") {
                                subscriptionType = "Pro"
                                voiceMinutesRemaining = 999 // Mock unlimited
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(4)
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .appCardStyle()
        }
    }

    private var draftingStyleSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "pencil.and.outline").foregroundColor(.blue).font(.headline)
                Text("Drafting Style").font(.headline).foregroundColor(.white)
                Spacer()
            }
            VStack(spacing: 12) {
                ForEach(draftingOptions, id: \.self) { option in
                    Button {
                        if option == "Custom" && !customStyleConfigured {
                            showingCustomSetup = true
                        } else {
                            draftingStyle = option
                        }
                    } label: {
                        HStack {
                            Circle()
                                .fill(draftingStyle == option ? Color.blue : Color.clear)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 2))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option).foregroundColor(.white)
                                
                                if option == "Custom" {
                                    Text(customStyleConfigured ? "Configured ✓" : "Setup Required")
                                        .font(.caption)
                                        .foregroundColor(customStyleConfigured ? .green.opacity(0.8) : .orange.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            if option == "Custom" && customStyleConfigured {
                                Button("Edit") {
                                    showingCustomSetup = true
                                }
                                .font(.caption.weight(.medium))
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.vertical, option == "Custom" ? 12 : 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .appCardStyle()
        }
    }

    private var voiceSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "waveform").foregroundColor(.blue).font(.headline)
                Text("Voice").font(.headline).foregroundColor(.white)
                Spacer()
            }
            VStack(spacing: 12) {
                ForEach(voiceOptions, id: \.self) { option in
                    Button { voiceModel = option } label: {
                        HStack {
                            Circle()
                                .fill(voiceModel == option ? Color.blue : Color.clear)
                                .frame(width: 16, height: 16)
                                .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 2))
                            Text(option).foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .appCardStyle()
        }
    }

    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "crown").foregroundColor(.blue).font(.headline)
                Text("Subscription").font(.headline).foregroundColor(.white)
                Spacer()
            }
            HStack {
                Text("Plan:").foregroundColor(.white.opacity(0.85))
                Text(subscriptionType)
                    .foregroundColor(subscriptionType == "Pro" ? .yellow : .white)
                    .fontWeight(.semibold)
                if subscriptionType == "Pro" {
                    Image(systemName: "crown.fill").foregroundColor(.yellow).font(.caption)
                }
                Spacer()
                if subscriptionType == "Free" {
                    Button("Upgrade") {
                        subscriptionType = "Pro"
                        voiceMinutesRemaining = 999 // Mock unlimited minutes
                    }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(6)
                }
            }
            .appCardStyle()
        }
    }

    private var documentLibrarySection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "doc.on.clipboard").foregroundColor(.blue).font(.headline)
                Text("Document Library").font(.headline).foregroundColor(.white)
                Spacer()
            }
            
            if connectedFiles.isEmpty {
                // Empty State
                VStack(spacing: 16) {
                    VStack(spacing: 12) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                    .frame(width: 80, height: 80)
                            )
                        
                        VStack(spacing: 4) {
                            Text("No documents connected")
                                .font(.callout.weight(.medium))
                                .foregroundColor(.white.opacity(0.85))
                            
                            Text("Connect Google Drive files so your AI can reference and attach them")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Connect Google Drive Files", systemImage: "plus")
                            .font(.callout.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .appButtonStyle()
                    .padding(.horizontal, 8)
                }
                .appCardStyle()
            } else {
                // Files Connected State
                VStack(spacing: 16) {
                    // Header with file count
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(connectedFiles.count) files connected")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.85))
                            
                            Text("AI can reference and attach these files")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button {
                            showingFilePicker = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                    
                    // Files List
                    VStack(spacing: 12) {
                        ForEach(connectedFiles) { file in
                            FileRowView(file: file) { action in
                                handleFileAction(action, for: file)
                            }
                        }
                    }
                    
                    // Bulk Actions
                    HStack(spacing: 12) {
                        Button {
                            // Refresh all permissions
                            isLoadingFiles = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isLoadingFiles = false
                                // Update file access status
                                connectedFiles = connectedFiles.map { file in
                                    var updatedFile = file
                                    updatedFile.hasAccess = true
                                    return updatedFile
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                if isLoadingFiles {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.clockwise")
                                }
                                Text("Refresh All")
                            }
                            .font(.caption.weight(.medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .disabled(isLoadingFiles)
                        
                        Button {
                            connectedFiles.removeAll()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Remove All")
                            }
                            .font(.caption.weight(.medium))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .appCardStyle()
            }
        }
    }

    private var connectionStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "link").foregroundColor(.blue).font(.headline)
                Text("Connection Status").font(.headline).foregroundColor(.white)
                Spacer()
            }
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "envelope").foregroundColor(.white.opacity(0.6)).frame(width: 20)
                    Text("Gmail").foregroundColor(.white)
                    Spacer()
                    Circle().fill(gmailConnected ? Color.green : Color.red).frame(width: 8, height: 8)
                    Text(gmailConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(gmailConnected ? .green : .red.opacity(0.8))
                }
                HStack {
                    Image(systemName: "calendar").foregroundColor(.white.opacity(0.6)).frame(width: 20)
                    Text("Calendar").foregroundColor(.white)
                    Spacer()
                    Circle().fill(calendarConnected ? Color.green : Color.red).frame(width: 8, height: 8)
                    Text(calendarConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(calendarConnected ? .green : .red.opacity(0.8))
                    if !calendarConnected {
                        Button("Connect") { calendarConnected = true }
                            .font(.caption.weight(.medium))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .appCardStyle()
        }
    }
    
    // MARK: - File Actions
    private func handleFileAction(_ action: FileAction, for file: ConnectedFile) {
        switch action {
        case .view:
            // Open file preview or external app
            print("Viewing file: \(file.name)")
        case .useInEmail:
            // Navigate to email composer with file attached
            print("Using file in email: \(file.name)")
        case .remove:
            // Remove file access
            connectedFiles.removeAll { $0.id == file.id }
        case .refreshAccess:
            // Refresh file permissions
            if let index = connectedFiles.firstIndex(where: { $0.id == file.id }) {
                connectedFiles[index].hasAccess = true
            }
        }
    }
}

// MARK: - Supporting Models and Views

struct ConnectedFile: Identifiable, Equatable {
    let id: String
    let name: String
    let type: FileType
    let lastModified: String
    var hasAccess: Bool
    let isRecentlyUsed: Bool
}

enum FileType {
    case pdf, word, excel, powerpoint, text, image
    
    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .word: return "doc.text"
        case .excel: return "tablecells"
        case .powerpoint: return "rectangle.on.rectangle"
        case .text: return "doc.plaintext"
        case .image: return "photo"
        }
    }
    
    var color: Color {
        switch self {
        case .pdf: return .red
        case .word: return .blue
        case .excel: return .green
        case .powerpoint: return .orange
        case .text: return .gray
        case .image: return .purple
        }
    }
}

enum FileAction {
    case view, useInEmail, remove, refreshAccess
}

struct FileRowView: View {
    let file: ConnectedFile
    let onAction: (FileAction) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // File type icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(file.type.color.opacity(0.2))
                    .frame(width: 36, height: 36)
                
                Image(systemName: file.type.icon)
                    .foregroundColor(file.type.color)
                    .font(.system(size: 16, weight: .medium))
            }
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(file.name)
                        .font(.callout)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if file.isRecentlyUsed {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Text(file.lastModified)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    if file.hasAccess {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("AI can access")
                                .font(.caption)
                                .foregroundColor(.green.opacity(0.8))
                        }
                    } else {
                        HStack(spacing: 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Access expired")
                                .font(.caption)
                                .foregroundColor(.orange.opacity(0.8))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onAction(.view)
            } label: {
                Label("View File", systemImage: "eye")
            }
            
            if file.hasAccess {
                Button {
                    onAction(.useInEmail)
                } label: {
                    Label("Use in Email", systemImage: "envelope")
                }
            } else {
                Button {
                    onAction(.refreshAccess)
                } label: {
                    Label("Refresh Access", systemImage: "arrow.clockwise")
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                onAction(.remove)
            } label: {
                Label("Remove Access", systemImage: "trash")
            }
        }
    }
}

struct GoogleDriveFilePickerView: View {
    @Binding var selectedFiles: [ConnectedFile]
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "externaldrive.badge.plus")
                            .font(.system(size: 48, weight: .semibold))
                            .foregroundColor(.blue)
                            .shadow(color: Color.blue.opacity(0.25), radius: 10, y: 4)
                        
                        VStack(spacing: 8) {
                            Text("Connect Google Drive")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Select files for your AI assistant to access")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }
                    .padding(.top, 20)
                    
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.blue)
                            
                            Text("Connecting to Google Drive...")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .appCardStyle()
                        .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 16) {
                            Text("🔐 Secure Connection")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                FeatureRow(icon: "checkmark.shield", text: "Read-only access to selected files")
                                FeatureRow(icon: "eye.slash", text: "No access to your entire drive")
                                FeatureRow(icon: "lock", text: "Encrypted file references only")
                                FeatureRow(icon: "person.badge.key", text: "Revoke access anytime")
                            }
                        }
                        .appCardStyle()
                        .padding(.horizontal, 24)
                    }
                    
                    Spacer()
                    
                    // Connect button
                    if !isLoading {
                        Button {
                            isLoading = true
                            // Mock Google Drive connection
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                // Mock adding some files
                                let newFiles = [
                                    ConnectedFile(id: UUID().uuidString, name: "New Document.pdf", type: .pdf, lastModified: "Just now", hasAccess: true, isRecentlyUsed: false),
                                    ConnectedFile(id: UUID().uuidString, name: "Meeting Notes.docx", type: .word, lastModified: "Just now", hasAccess: true, isRecentlyUsed: false)
                                ]
                                selectedFiles.append(contentsOf: newFiles)
                                dismiss()
                            }
                        } label: {
                            Label("Connect to Google Drive", systemImage: "arrow.right")
                        }
                        .appButtonStyle()
                        .padding(.horizontal, 24)
                        .padding(.bottom, 44)
                    }
                }
            }
            .navigationTitle("Google Drive")
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

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.callout)
                .frame(width: 20)
            
            Text(text)
                .font(.callout)
                .foregroundColor(.white.opacity(0.85))
            
            Spacer()
        }
    }
}

#Preview { SettingsView() }

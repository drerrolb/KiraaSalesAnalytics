import SwiftUI
import Foundation

#if os(macOS)
import AppKit
#endif

// MARK: - Model Definition
struct Instance: Identifiable, Codable {
    let _id: Int
    var id: Int { _id }
    
    let INSTANCE_COMPLETION_ENDPOINT: String
    let INSTANCE_AUDIO_ENDPOINT: String
    let INSTANCE_STORAGE_BUCKET: String
    let processMonth: Int
    let INSTANCE_STATYS: String   // Spelling kept to match JSON key
    let processYear: Int
    let INSTANCE_IMAGE_ENDPOINT: String
    let bucketStep04target: String
    let INSTANCE_API_ENDPOINT: String
    let INSTANCE_PDF_ENDPOINT: String
    let INSTANCE_VIDEO_ENDPOINT: String
    let INSTANCE_PINECONE_INDEX: String
    let details: String
    let apiEndpoint: String
    let bucketStorage: String?
    let INSTANCE_DESCRIPTION: String
    let mongoDatabase: String
    let INSTANCE_MEET_ENDPOINT: String
    let INSTANCE_STORAGE_REGION: String
    let INSTANCE_FISCAL_OFFSET: Int?
    let name: String
    let INSTANCE_MAP_ENDPOINT: String
    let INSTANCE_NAME: String
    let pageNames: [String]
    let financialOffset: Int
    let mongoUri: String
    let INSTANCE_DOCUMENT_ENDPOINT: String
    let INSTANCE_PROCESS_YEAR: Int
    let INSTANCE_SPREADSHEET_ENDPOINT: String
    let INSTANCE_MONGO_DATABASE: String
    let regionStep04target: String
    let INSTANCE_CHAT_ENDPOINT: String
    let INSTANCE_STATUS: String?
    let INSTANCE_PRESENTATION_ENDPOINT: String
    let INSTANCE_PROCESS_MONTH: Int
}

// MARK: - Main View
struct DownloadDocumentsView: View {
    @State private var status: String = ""
    @State private var instance: Instance? = nil
    
    // For iOS dismissal if used in a sheet.
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Top bar with a Close button aligned to the right.
            HStack {
                Spacer()
                Button("Close") {
                    #if os(macOS)
                    // Terminate the entire app so the window does not reopen.
                    NSApplication.shared.terminate(nil)
                    #else
                    dismiss()
                    #endif
                }
                .padding(8)
            }
            
            // Title
            Text("Download Documents")
                .font(.headline)
                .padding(.top, 10)
            
            // Action Buttons
            HStack(spacing: 20) {
                Button("Download") {
                    performDownload()
                }
                Button("Load Instance") {
                    loadInstance()
                }
            }
            
            // Status Message
            Text(status)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider()
            
            // Instance Details (if loaded)
            if let instance = instance {
                ScrollView {
                    InstanceDetailsView(instance: instance)
                }
                .padding(.horizontal)
            } else {
                Text("No instance loaded.")
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 20)
        }
        .padding()
        // Set a reasonable minimum size so the window won't be too small.
        .frame(minWidth: 700, minHeight: 500)
    }
    
    // MARK: - Download Functionality
    private func performDownload() {
        print("Starting performDownload()")
        let fileManager = FileManager.default
        
        // Adjust the path for your environment.
        let destinationURL = URL(fileURLWithPath: "/Users/e2mq173/Documents/kiraaanalytics/", isDirectory: true)
        
        // Create the directory if it doesn't exist.
        if !fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.createDirectory(at: destinationURL,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
                print("Created directory at \(destinationURL.path)")
            } catch {
                status = "Failed to create directory: \(error.localizedDescription)"
                return
            }
        }
        
        Task {
            do {
                let jsonString = try MongoDownloader.downloadDocuments()
                print("Downloaded JSON: \(jsonString)")
                
                let fileURL = destinationURL.appendingPathComponent("instance.json")
                try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
                
                await MainActor.run {
                    status = "Download successful. File saved to \(fileURL.path)"
                }
            } catch {
                await MainActor.run {
                    status = "Download failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Load Instance Functionality
    private func loadInstance() {
        let fileManager = FileManager.default
        
        let directoryURL = URL(fileURLWithPath: "/Users/e2mq173/Documents/kiraaanalytics/", isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent("instance.json")
        
        do {
            let data = try Data(contentsOf: fileURL)
            let instances = try JSONDecoder().decode([Instance].self, from: data)
            if let first = instances.first {
                instance = first
                status = "Loaded instance: \(first.name)"
            } else {
                status = "No instance data available in JSON."
            }
        } catch {
            status = "Error loading instance: \(error.localizedDescription)"
        }
    }
}

// MARK: - Instance Details View
struct InstanceDetailsView: View {
    let instance: Instance
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            // Basic Info Section
            SectionBlock(title: "Basic Info") {
                detailRow("ID", "\(instance._id)")
                detailRow("Name", instance.name)
                detailRow("Description", instance.INSTANCE_DESCRIPTION)
            }
            
            // Endpoints Section
            SectionBlock(title: "Endpoints") {
                detailRow("Completion", instance.INSTANCE_COMPLETION_ENDPOINT)
                detailRow("Audio", instance.INSTANCE_AUDIO_ENDPOINT)
                detailRow("Image", instance.INSTANCE_IMAGE_ENDPOINT)
                detailRow("PDF", instance.INSTANCE_PDF_ENDPOINT)
                detailRow("Video", instance.INSTANCE_VIDEO_ENDPOINT)
                detailRow("API", instance.INSTANCE_API_ENDPOINT)
                detailRow("Document", instance.INSTANCE_DOCUMENT_ENDPOINT)
                detailRow("Spreadsheet", instance.INSTANCE_SPREADSHEET_ENDPOINT)
                detailRow("Meet", instance.INSTANCE_MEET_ENDPOINT)
                detailRow("Chat", instance.INSTANCE_CHAT_ENDPOINT)
                detailRow("Presentation", instance.INSTANCE_PRESENTATION_ENDPOINT)
                detailRow("Map", instance.INSTANCE_MAP_ENDPOINT)
            }
            
            // Other Info Section
            SectionBlock(title: "Other Info") {
                detailRow("Process Month", "\(instance.processMonth)")
                detailRow("Process Year", "\(instance.processYear)")
                detailRow("Status (Typo)", instance.INSTANCE_STATYS)
                detailRow("Status", instance.INSTANCE_STATUS ?? "N/A")
                detailRow("Mongo Database", instance.mongoDatabase)
                detailRow("Mongo URI", instance.mongoUri)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
    
    // Helper to create a labeled row with multiline text.
    @ViewBuilder
    private func detailRow(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
    }
}

// MARK: - Reusable Section Block
struct SectionBlock<Content: View>: View {
    let title: String
    let content: () -> Content
    
    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3)
                .bold()
            content()
        }
    }
}

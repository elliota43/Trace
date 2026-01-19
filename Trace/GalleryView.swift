import SwiftUI
import SwiftData

struct GalleryView: View {
    @State private var searchText = ""
    @State private var selectedItem: ScreenshotItem?
    
    var body: some View {
        NavigationSplitView {
            ScreenshotListView(searchText: searchText, selection: $selectedItem)
                .id(searchText)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            if let item = selectedItem {
                ScreenshotDetailView(item: item, highlightTerm: searchText)
                    .id(item.id)
            } else {
                Text("Select a screenshot")
                    .foregroundStyle(.secondary)
            }
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search text or apps...")
    }
}

struct ScreenshotListView: View {
    let searchText: String
    @Binding var selection: ScreenshotItem?
    @Query var items: [ScreenshotItem]
    
    init(searchText: String, selection: Binding<ScreenshotItem?>) {
        self.searchText = searchText
        self._selection = selection
        
        if searchText.isEmpty {
            _items = Query(sort: \ScreenshotItem.timestamp, order: .reverse)
        } else {
            _items = Query(
                filter: #Predicate {
                    $0.recognizedText.localizedStandardContains(searchText) ||
                    $0.appName.localizedStandardContains(searchText) ||
                    $0.smartTitle.localizedStandardContains(searchText)
                },
                sort: \ScreenshotItem.timestamp,
                order: .reverse
            )
        }
    }
    
    var body: some View {
        List(items, id: \.id, selection: $selection) { item in
            HStack {
                if let data = item.imageData, let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 40)
                        .cornerRadius(4)
                }
                
                VStack(alignment: .leading) {
                    Text(item.smartTitle)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack {
                        if item.smartTitle != item.appName {
                            Text(item.appName)
                                .fontWeight(.medium)
                        }
                        Text(item.timestamp, style: .time)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
            .tag(item) // Critical for selection to work
            .onDrag {
                guard let data = item.imageData else { return NSItemProvider() }
                
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(item.smartTitle.replacingOccurrences(of: "/", with: "-"))
                    .appendingPathExtension("png")
                
                try? data.write(to: tempURL)
                return NSItemProvider(contentsOf: tempURL) ?? NSItemProvider()
            }
        }
    }
}

struct ScreenshotDetailView: View {
    let item: ScreenshotItem
    let highlightTerm: String
    
    var body: some View {
        HSplitView {
            if let data = item.imageData, let nsImage = NSImage(data: data) {
                // Assumes you have ImageWithHighlights in a separate file
                ImageWithHighlights(nsImage: nsImage, highlightTerm: highlightTerm)
                    .background(Color(nsColor: .windowBackgroundColor))
            } else {
                Text("Image Missing")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            VStack(alignment: .leading) {
                if let urlString = item.url, let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "safari")
                                .font(.system(size: 14))
                            
                            VStack(alignment: .leading) {
                                Text("Open in Browser")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                
                                Text(url.host() ?? urlString)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding([.top, .horizontal])
                }
                
                Text("DETECTED TEXT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding([.top, .horizontal])
                
                ScrollView {
                    Text(generateHighlightedText(source: item.recognizedText, term: highlightTerm))
                        .textSelection(.enabled)
                        .font(.body)
                        .padding()
                }
            }
            .frame(minWidth: 200, maxWidth: 400)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
    
    private func generateHighlightedText(source: String, term: String) -> AttributedString {
        var attributed = AttributedString(source)
        
        guard !term.isEmpty else { return attributed }
        
        var searchStartIndex = source.startIndex
        
        while let range = source.range(of: term, options: .caseInsensitive, range: searchStartIndex..<source.endIndex) {
            if let attrRange = Range(range, in: attributed) {
                attributed[attrRange].backgroundColor = .yellow.opacity(0.5)
                attributed[attrRange].font = .body.bold()
                attributed[attrRange].foregroundColor = .black
            }
            searchStartIndex = range.upperBound
        }
        
        return attributed
    }
}

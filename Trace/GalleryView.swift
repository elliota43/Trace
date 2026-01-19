//
//  GalleryView.swift
//  Trace
//
//  Created by Elliot Anderson on 1/19/26.
//

import SwiftUI
import SwiftData

struct GalleryView: View {
    @State private var searchText = ""
    
    var body: some View {
        NavigationSplitView {
            ScreenshotListView(searchText: searchText)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        } detail: {
            // empty state
            Text("Select a screenshot")
                .foregroundStyle(.secondary)
        }
        .searchable(text: $searchText, placement: .sidebar, prompt: "Search text or apps...")
    }
}

// Subview -- so the query updates when searchText changes
struct ScreenshotListView: View {
    @Query var items: [ScreenshotItem]
    
    init(searchText: String) {
        if searchText.isEmpty {
            _items = Query(sort: \ScreenshotItem.timestamp, order: .reverse)
        } else {
            _items = Query(
                filter: #Predicate {
                    $0.recognizedText.localizedStandardContains(searchText) ||
                    $0.appName.localizedStandardContains(searchText)
                },
                sort: \ScreenshotItem.timestamp,
                order: .reverse
            )
        }
    }
    
    var body: some View {
        List(items, id: \.id) { item in
            NavigationLink {
                // RIGHT
                ScreenshotDetailView(item: item)
            } label: {
                // List Row (Left)
                HStack {
                    if let data = item.imageData, let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 40)
                            .cornerRadius(4)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(item.appName)
                            .font(.headline)
                        Text(item.timestamp, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct ScreenshotDetailView: View {
    let item: ScreenshotItem
    
    var body: some View {
        HSplitView {
            // Left: The Image
            if let data = item.imageData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .windowBackgroundColor))
            } else {
                Text("Image Missing")
            }
            
            // Right: Extracted Text
            VStack(alignment: .leading) {
                
                if let urlString = item.url, let url = URL(string: urlString) {
                    Link(destination: url) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Open Original Page")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(0)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                }
                
                
                Text("DETECTED TEXT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .padding(.top)
                
                ScrollView {
                    Text(item.recognizedText)
                        .textSelection(.enabled)
                        .font(.body)
                        .padding()
                }
            }
            .frame(minWidth: 200, maxWidth: 400)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
}

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SmartFolder: Identifiable {
    let id: String
    let name: String
    let icon: String
    let color: Color
    let filter: (ScreenshotItem) -> Bool
}

struct GalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @State private var selectedItem: ScreenshotItem?
    @State private var currentFolder: SmartFolder?
    @State private var hoveredItem: UUID?

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(red: 0.07, green: 0.09, blue: 0.15),
                    Color(red: 0.25, green: 0.1, blue: 0.35),
                    Color(red: 0.07, green: 0.09, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            HStack(spacing: 0) {
                // Sidebar
                SidebarView(
                    searchText: $searchText,
                    currentFolder: $currentFolder,
                    modelContext: modelContext
                )
                .frame(width: 256)

                // Main Content
                MainGridView(
                    searchText: searchText,
                    currentFolder: $currentFolder,
                    selectedItem: $selectedItem,
                    hoveredItem: $hoveredItem
                )
            }

            // Detail Modal
            if let item = selectedItem {
                DetailModalView(
                    item: item,
                    highlightTerm: searchText,
                    modelContext: modelContext,
                    onClose: {
                        selectedItem = nil
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @Binding var searchText: String
    @Binding var currentFolder: SmartFolder?
    let modelContext: ModelContext
    @Query var allItems: [ScreenshotItem]

    init(searchText: Binding<String>, currentFolder: Binding<SmartFolder?>, modelContext: ModelContext) {
        self._searchText = searchText
        self._currentFolder = currentFolder
        self.modelContext = modelContext
        _allItems = Query(sort: \ScreenshotItem.timestamp, order: .reverse)
    }

    private var smartFolders: [SmartFolder] {
        [
            SmartFolder(
                id: "all",
                name: "All Screenshots",
                icon: "photo.stack",
                color: .blue,
                filter: { _ in true }
            ),
            SmartFolder(
                id: "recent",
                name: "Recent",
                icon: "clock",
                color: .orange,
                filter: { item in
                    Calendar.current.isDateInToday(item.timestamp) ||
                    Calendar.current.isDateInYesterday(item.timestamp)
                }
            ),
            SmartFolder(
                id: "receipts",
                name: "Receipts & Invoices",
                icon: "doc.text",
                color: .green,
                filter: { item in
                    item.recognizedText.localizedStandardContains("invoice") ||
                    item.recognizedText.localizedStandardContains("receipt") ||
                    item.recognizedText.localizedStandardContains("payment") ||
                    item.recognizedText.localizedStandardContains("total") ||
                    item.recognizedText.localizedStandardContains("$") ||
                    item.appName.localizedStandardContains("stripe") ||
                    item.appName.localizedStandardContains("paypal")
                }
            ),
            SmartFolder(
                id: "code",
                name: "Code Snippets",
                icon: "curlybraces",
                color: .purple,
                filter: { item in
                    item.appName.localizedStandardContains("code") ||
                    item.appName.localizedStandardContains("terminal") ||
                    item.appName.localizedStandardContains("xcode") ||
                    item.recognizedText.contains("{") ||
                    item.recognizedText.contains("function") ||
                    item.recognizedText.contains("const ") ||
                    item.recognizedText.contains("def ")
                }
            ),
            SmartFolder(
                id: "design",
                name: "Design Inspiration",
                icon: "paintbrush",
                color: .pink,
                filter: { item in
                    item.appName.localizedStandardContains("figma") ||
                    item.appName.localizedStandardContains("sketch") ||
                    item.appName.localizedStandardContains("adobe") ||
                    item.appName.localizedStandardContains("canva")
                }
            )
        ]
    }

    private func count(for folder: SmartFolder) -> Int {
        allItems.filter(folder.filter).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search Box
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.4))
                        .font(.system(size: 14))

                    TextField("Search by content...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .cornerRadius(8)
            }
            .padding(16)

            // Quick Actions
            VStack(alignment: .leading, spacing: 4) {
                Text("QUICK ACTIONS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                SidebarButton(icon: "sparkles", title: "Open Canvas")
                SidebarButton(icon: "calendar", title: "Review & Cleanup")
            }
            .padding(.bottom, 16)

            // Smart Folders
            VStack(alignment: .leading, spacing: 4) {
                Text("SMART FOLDERS")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)

                ForEach(smartFolders) { folder in
                    FolderButton(
                        icon: folder.icon,
                        color: folder.color,
                        title: folder.name,
                        count: count(for: folder),
                        isSelected: currentFolder?.id == folder.id,
                        action: {
                            if currentFolder?.id == folder.id {
                                currentFolder = nil
                            } else {
                                currentFolder = folder
                            }
                        }
                    )
                }
            }
            .padding(.bottom, 16)

            Spacer()
        }
        .background(
            Color.black.opacity(0.2)
                .background(.ultraThinMaterial.opacity(0.5))
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

struct SidebarButton: View {
    let icon: String
    let title: String

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct FolderButton: View {
    let icon: String
    let color: Color
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 13))
                Spacer()
                Text("\(count)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white.opacity(0.15) : Color.clear)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Grid
struct MainGridView: View {
    let searchText: String
    @Binding var currentFolder: SmartFolder?
    @Binding var selectedItem: ScreenshotItem?
    @Binding var hoveredItem: UUID?
    @Query var items: [ScreenshotItem]

    init(searchText: String, currentFolder: Binding<SmartFolder?>, selectedItem: Binding<ScreenshotItem?>, hoveredItem: Binding<UUID?>) {
        self.searchText = searchText
        self._currentFolder = currentFolder
        self._selectedItem = selectedItem
        self._hoveredItem = hoveredItem

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

    private var smartFolders: [SmartFolder] {
        [
            SmartFolder(
                id: "all",
                name: "All Screenshots",
                icon: "photo.stack",
                color: .blue,
                filter: { _ in true }
            ),
            SmartFolder(
                id: "recent",
                name: "Recent",
                icon: "clock",
                color: .orange,
                filter: { item in
                    Calendar.current.isDateInToday(item.timestamp) ||
                    Calendar.current.isDateInYesterday(item.timestamp)
                }
            ),
            SmartFolder(
                id: "receipts",
                name: "Receipts & Invoices",
                icon: "doc.text",
                color: .green,
                filter: { item in
                    item.recognizedText.localizedStandardContains("invoice") ||
                    item.recognizedText.localizedStandardContains("receipt") ||
                    item.recognizedText.localizedStandardContains("payment") ||
                    item.recognizedText.localizedStandardContains("total") ||
                    item.recognizedText.localizedStandardContains("$") ||
                    item.appName.localizedStandardContains("stripe") ||
                    item.appName.localizedStandardContains("paypal")
                }
            ),
            SmartFolder(
                id: "code",
                name: "Code Snippets",
                icon: "curlybraces",
                color: .purple,
                filter: { item in
                    item.appName.localizedStandardContains("code") ||
                    item.appName.localizedStandardContains("terminal") ||
                    item.appName.localizedStandardContains("xcode") ||
                    item.recognizedText.contains("{") ||
                    item.recognizedText.contains("function") ||
                    item.recognizedText.contains("const ") ||
                    item.recognizedText.contains("def ")
                }
            ),
            SmartFolder(
                id: "design",
                name: "Design Inspiration",
                icon: "paintbrush",
                color: .pink,
                filter: { item in
                    item.appName.localizedStandardContains("figma") ||
                    item.appName.localizedStandardContains("sketch") ||
                    item.appName.localizedStandardContains("adobe") ||
                    item.appName.localizedStandardContains("canva")
                }
            )
        ]
    }

    private var filteredItems: [ScreenshotItem] {
        guard let folder = currentFolder else { return [] }
        return items.filter(folder.filter)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with Breadcrumb
                VStack(alignment: .leading, spacing: 8) {
                    if let folder = currentFolder {
                        // Breadcrumb
                        HStack(spacing: 8) {
                            Button(action: { currentFolder = nil }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: folder.icon)
                                .font(.system(size: 24))
                                .foregroundColor(folder.color)
                            Text(folder.name)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        Text("\(filteredItems.count) items")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text("Smart Folders")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.white)
                        Text("\(items.count) total screenshots")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Content: Search Results, Folders, or Screenshots
                if !searchText.isEmpty {
                    // Show search results
                    searchResultsGrid
                } else if currentFolder == nil {
                    // Show folders in desktop style
                    foldersView
                } else {
                    // Show screenshots grid
                    screenshotsGrid
                }
            }
        }
    }

    private var foldersView: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 120, maximum: 140), spacing: 24)
            ],
            alignment: .leading,
            spacing: 32
        ) {
            ForEach(smartFolders) { folder in
                FolderIcon(
                    folder: folder,
                    count: items.filter(folder.filter).count,
                    onTap: {
                        currentFolder = folder
                    }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private var screenshotsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(filteredItems) { item in
                ScreenshotCard(
                    item: item,
                    searchTerm: "",
                    isHovered: hoveredItem == item.id,
                    onHover: { isHovered in
                        hoveredItem = isHovered ? item.id : nil
                    },
                    onTap: {
                        selectedItem = item
                    }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private var searchResultsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(items) { item in
                ScreenshotCard(
                    item: item,
                    searchTerm: searchText,
                    isHovered: hoveredItem == item.id,
                    onHover: { isHovered in
                        hoveredItem = isHovered ? item.id : nil
                    },
                    onTap: {
                        selectedItem = item
                    }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }
}

// MARK: - Folder Icon
struct FolderIcon: View {
    let folder: SmartFolder
    let count: Int
    let onTap: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Folder Icon
                ZStack {
                    // Folder background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    folder.color.opacity(0.8),
                                    folder.color.opacity(0.6)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(folder.color.opacity(0.5), lineWidth: 2)
                        )
                        .shadow(color: folder.color.opacity(0.3), radius: isHovered ? 12 : 6)

                    // Folder tab
                    VStack {
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(folder.color.opacity(0.9))
                                .frame(width: 40, height: 8)
                                .offset(y: -4)
                            Spacer()
                        }
                        Spacer()
                    }
                    .frame(width: 100, height: 80)

                    // Icon
                    Image(systemName: folder.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    // Count badge
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(count)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(10)
                                .offset(x: 8, y: -8)
                        }
                        Spacer()
                    }
                    .frame(width: 100, height: 80)
                }
                .scaleEffect(isHovered ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)

                // Folder name
                Text(folder.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 120)
            }
            .frame(width: 120)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct ScreenshotCard: View {
    let item: ScreenshotItem
    let searchTerm: String
    let isHovered: Bool
    let onHover: (Bool) -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    // Image
                    if let data = item.imageData, let nsImage = NSImage(data: data) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()

                        // Text highlighting overlays
                        if !searchTerm.isEmpty {
                            textHighlightOverlay(imageSize: CGSize(
                                width: nsImage.size.width,
                                height: nsImage.size.height
                            ), cardSize: geometry.size)
                        }
                    } else {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                    }

                    // Hover Overlay
                    if isHovered {
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.8),
                                Color.black.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .transition(.opacity)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.smartTitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(item.timestamp, style: .relative)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                    }

                    // Source Badge
                    if item.url != nil && isHovered {
                        VStack {
                            HStack {
                                Spacer()
                                Circle()
                                    .fill(Color.purple.opacity(0.8))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: "folder")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white)
                                    )
                                    .padding(8)
                            }
                            Spacer()
                        }
                        .transition(.opacity)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .aspectRatio(16/9, contentMode: .fit)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isHovered ? Color.purple.opacity(0.5) : Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .cornerRadius(12)
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(
                color: isHovered ? Color.purple.opacity(0.2) : Color.clear,
                radius: isHovered ? 20 : 0
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            onHover(hovering)
        }
        .onDrag {
            guard let data = item.imageData else { return NSItemProvider() }

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(item.smartTitle.replacingOccurrences(of: "/", with: "-"))
                .appendingPathExtension("png")

            try? data.write(to: tempURL)
            return NSItemProvider(contentsOf: tempURL) ?? NSItemProvider()
        }
    }

    @ViewBuilder
    private func textHighlightOverlay(imageSize: CGSize, cardSize: CGSize) -> some View {
        let textBounds = item.textBounds
        let matchingBounds = textBounds.filter { bound in
            bound.text.localizedStandardContains(searchTerm)
        }

        if !matchingBounds.isEmpty {
            // Calculate scale factor (card is smaller than actual image)
            let scaleX = cardSize.width / imageSize.width
            let scaleY = cardSize.height / imageSize.height

            ForEach(Array(matchingBounds.enumerated()), id: \.offset) { _, bound in
                Rectangle()
                    .fill(Color.yellow.opacity(0.4))
                    .frame(
                        width: bound.width * scaleX,
                        height: bound.height * scaleY
                    )
                    .position(
                        x: (bound.x + bound.width / 2) * scaleX,
                        y: (bound.y + bound.height / 2) * scaleY
                    )
            }
        }
    }
}

// MARK: - Detail Modal
struct DetailModalView: View {
    let item: ScreenshotItem
    let highlightTerm: String
    let modelContext: ModelContext
    let onClose: () -> Void

    @State private var isRedactionEnabled = true

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }

            // Modal Content
            modalContent
        }
    }

    private var modalContent: some View {
        HStack(spacing: 0) {
            imagePreview
            detailsSidebar
        }
        .frame(maxWidth: 1200, maxHeight: 800)
        .background(
            Color.black.opacity(0.4)
                .background(.ultraThinMaterial.opacity(0.5))
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.3), radius: 30)
    }

    private var imagePreview: some View {
        ZStack {
            Color.black.opacity(0.2)

            if let data = item.imageData, let nsImage = NSImage(data: data) {
                ImageWithHighlights(
                    nsImage: nsImage,
                    highlightTerm: highlightTerm,
                    isRedactionEnabled: isRedactionEnabled
                )
                .padding(32)

                // Social Ready Badge
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("Social Ready")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.8))
                        .cornerRadius(12)
                        .padding(16)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var detailsSidebar: some View {
        VStack(spacing: 0) {
            sidebarHeader
            sidebarContent
            actionFooter
        }
        .frame(width: 384)
        .background(Color.black.opacity(0.3))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1),
            alignment: .leading
        )
    }

    private var sidebarHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.smartTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Text(item.timestamp, style: .relative)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .background(Color.white.opacity(0.05))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var sidebarContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sourceSection
                metadataSection
                redactionToggle
                ocrSection
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private var sourceSection: some View {
        if let urlString = item.url, let url = URL(string: urlString) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14))
                        .foregroundColor(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Original Source")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Text(url.host() ?? urlString)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }

                Link(destination: url) {
                    Text("Open Source")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.purple)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.2),
                        Color.pink.opacity(0.2)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Basic Context
            VStack(alignment: .leading, spacing: 12) {
                Text("BASIC INFO")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)

                MetadataRow(
                    icon: "globe",
                    label: "Application",
                    value: item.appName
                )

                MetadataRow(
                    icon: "clock",
                    label: "Captured",
                    value: item.timestamp.formatted(date: .abbreviated, time: .shortened)
                )

                if let timeOfDay = item.timeOfDay {
                    MetadataRow(
                        icon: "sun.max",
                        label: "Time of Day",
                        value: timeOfDay.capitalized
                    )
                }
            }

            // Git Context
            if item.gitBranch != nil || item.gitRepo != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("GIT CONTEXT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)

                    if let branch = item.gitBranch {
                        MetadataRow(
                            icon: "arrow.branch",
                            label: "Branch",
                            value: branch
                        )
                    }

                    if let commit = item.gitCommit {
                        MetadataRow(
                            icon: "number",
                            label: "Commit",
                            value: commit
                        )
                    }

                    if let status = item.gitStatus {
                        MetadataRow(
                            icon: status == "clean" ? "checkmark.circle" : "exclamationmark.triangle",
                            label: "Status",
                            value: status.capitalized
                        )
                    }
                }
            }

            // IDE Context
            if item.activeFile != nil || item.activeProject != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("IDE CONTEXT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)

                    if let project = item.activeProject {
                        MetadataRow(
                            icon: "folder",
                            label: "Project",
                            value: project
                        )
                    }

                    if let file = item.activeFile {
                        MetadataRow(
                            icon: "doc.text",
                            label: "Active File",
                            value: URL(fileURLWithPath: file).lastPathComponent
                        )
                    }
                }
            }

            // Browser Context
            if item.pageTitle != nil || item.domain != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("BROWSER CONTEXT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)

                    if let title = item.pageTitle {
                        MetadataRow(
                            icon: "doc.text",
                            label: "Page Title",
                            value: title
                        )
                    }

                    if let domain = item.domain {
                        MetadataRow(
                            icon: "network",
                            label: "Domain",
                            value: domain
                        )
                    }
                }
            }

            // Development Context
            if let portsJSON = item.localhostPorts, let data = portsJSON.data(using: .utf8),
               let ports = try? JSONDecoder().decode([String].self, from: data), !ports.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("DEVELOPMENT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)

                    MetadataRow(
                        icon: "network",
                        label: "Localhost Ports",
                        value: ports.joined(separator: ", ")
                    )
                }
            }

            // Design Context
            if item.figmaFileId != nil || item.figmaFileName != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("DESIGN CONTEXT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)

                    if let fileName = item.figmaFileName {
                        MetadataRow(
                            icon: "paintbrush",
                            label: "Figma File",
                            value: fileName
                        )
                    }
                }
            }

            // Communication Context
            if item.slackChannel != nil || item.emailSubject != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("COMMUNICATION")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)

                    if let channel = item.slackChannel {
                        MetadataRow(
                            icon: "message",
                            label: "Slack Channel",
                            value: channel
                        )
                    }

                    if let subject = item.emailSubject {
                        MetadataRow(
                            icon: "envelope",
                            label: "Email Subject",
                            value: subject
                        )
                    }
                }
            }

            // Media Context
            if item.spotifyTrack != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("MEDIA")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(1)

                    if let track = item.spotifyTrack, let artist = item.spotifyArtist {
                        MetadataRow(
                            icon: "music.note",
                            label: "Playing",
                            value: "\(track) - \(artist)"
                        )
                    }
                }
            }
        }
    }

    private var redactionToggle: some View {
        HStack {
            Image(systemName: isRedactionEnabled ? "eye.slash.fill" : "eye.fill")
                .foregroundColor(isRedactionEnabled ? .green : .white.opacity(0.6))
            Text("Smart Redaction")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Toggle("", isOn: $isRedactionEnabled)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    @ViewBuilder
    private var ocrSection: some View {
        if !item.recognizedText.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("DETECTED TEXT")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(1)

                Text(generateHighlightedText(source: item.recognizedText, term: highlightTerm))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .cornerRadius(8)

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(item.recognizedText, forType: .string)
                }) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                        Text("Copy Text")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionFooter: some View {
        VStack(spacing: 8) {
            Button(action: exportScreenshot) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 12))
                    Text("Export")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.purple)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Button(action: copyScreenshot) {
                    HStack {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 12))
                        Text("Copy")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button(action: deleteScreenshot) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                        Text("Delete")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.05))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }

    private func exportScreenshot() {
        guard let data = item.imageData else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = item.smartTitle.replacingOccurrences(of: "/", with: "-") + ".png"
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false

        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            try? data.write(to: url)
        }
    }

    private func copyScreenshot() {
        guard let data = item.imageData else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setData(data, forType: .png)
    }

    private func deleteScreenshot() {
        modelContext.delete(item)
        try? modelContext.save()
        onClose()
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

struct MetadataRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
        }
    }
}


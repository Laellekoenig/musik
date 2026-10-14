import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        List(selection: $selection) {
            Section("Apple Music") {
                ForEach(SidebarItem.appleMusic, id: \.self, content: row)
            }

            Section("Library") {
                ForEach(SidebarItem.library, id: \.self, content: row)
            }

            PlaylistsSidebarSection()
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 300)
    }

    private func row(_ item: SidebarItem) -> some View {
        Label(item.title, systemImage: item.systemImage)
            .tag(item)
    }
}

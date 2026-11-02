import SwiftUI

private struct Placeholder: View { let title: String; let text: String; var body: some View { NavigationStack { ContentUnavailableView(title, systemImage: "hammer", description: Text(text)).navigationTitle(title) } } }


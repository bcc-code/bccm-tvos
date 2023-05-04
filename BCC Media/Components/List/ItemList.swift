//
// Created by Fredrik Vedvik on 16/03/2023.
//

import SwiftUI

struct ItemListView<T, IView: View>: View {
    var title: String?
    var items: [T]
    var emptyListText: Text?

    var view: (T) -> IView

    var body: some View {
        VStack {
            if let t = title {
                Text(t).font(.title3).frame(maxWidth: .infinity, alignment: .leading)
            }
            ScrollView(.horizontal) {
                LazyHStack(spacing: 20) {
                    if items.count > 0 {
                        ForEach(items.indices, id: \.self) { index in
                            view(items[index])
                        }
                    } else if let s = emptyListText {
                        s
                    }
                }
                .lineLimit(2).padding(100)
            }
            .padding(-100)
        }
    }
}

struct ItemView<Destination: View>: View {
    var title: String
    var image: String?
    var destination: Destination

    init(_ title: String, _ image: String?, destination: Destination) {
        self.title = title
        self.image = image
        self.destination = destination
    }

    var body: some View {
        VStack {
            NavigationLink {
                destination
            } label: {
                ItemImage(image).frame(width: 400, height: 225)
            }
            .buttonStyle(.card)
            .padding(.zero)
            Text(title).padding(.zero).font(.caption)
        }
        .frame(width: 400)
    }
}

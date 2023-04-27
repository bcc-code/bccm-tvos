//
//  PosterSection.swift
//  BCC Media
//
//  Created by Fredrik Vedvik on 17/04/2023.
//

import SwiftUI

struct CardSection: View {
    var title: String?
    var items: [Item]

    init(_ title: String?, _ items: [Item]) {
        self.title = title
        self.items = items
    }

    var body: some View {
        VStack {
            if let t = title {
                Text(t).font(.title3).frame(maxWidth: .infinity, alignment: .leading)
            }
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 20) {
                    ForEach(items) { item in
                        if let img = item.image {
                            VStack(alignment: .leading, spacing: 20) {
                                NavigationLink {
                                    item
                                } label: {
                                    VStack(alignment: .leading) {
                                        ItemImage(img)
                                            .frame(width: 400, height: 225).cornerRadius(10)
                                        VStack(alignment: .leading) {
                                            Text(item.title)
                                            Text(item.description).font(.caption2).foregroundColor(.gray)
                                        }.padding(.horizontal, 20).padding(.bottom, 10)
                                        Spacer()
                                    }.frame(width: 400).cornerRadius(10)
                                }.buttonStyle(.card)
                            }.frame(width: 400)
                        }
                    }
                }.padding(100)
            }.padding(-100)
        }
    }
}

struct CardSection_Previews: PreviewProvider {
    static var previews: some View {
        CardSection(nil, previewItems)
    }
}
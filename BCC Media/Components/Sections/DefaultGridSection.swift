//
//  DefaultGridSection.swift
//  BCC Media
//
//  Created by Fredrik Vedvik on 17/04/2023.
//

import SwiftUI

struct DefaultGridSection: View {
    var title: String?
    var items: [Item]
    var clickItem: (Item) -> Void

    init(_ title: String?, _ items: [Item], clickItem: @escaping (Item) -> Void) {
        self.title = title
        self.items = items
        self.clickItem = clickItem
    }

    var columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack {
            if let t = title {
                Text(t).font(.title3).frame(maxWidth: .infinity, alignment: .leading)
            }
            ScrollView(.vertical) {
                LazyVGrid(columns: columns, spacing: 40) {
                    ForEach(items) { item in
                        if let img = item.image {
                            VStack(alignment: .leading, spacing: 20) {
                                Button {
                                    clickItem(item)
                                } label: {
                                    ItemImage(img)
                                        .frame(width: 400, height: 225).cornerRadius(10).overlay(
                                            LockView(locked: item.locked)
                                        )
                                }.buttonStyle(.card)
                                ItemTitle(item)
                            }.frame(width: 400)
                        }
                    }
                }.padding(100)
            }.padding(-100)
        }
    }
}

struct DefaultGridSection_Previews: PreviewProvider {
    static var previews: some View {
        DefaultGridSection("", previewItems) { item in
            print(item.title)
        }
    }
}

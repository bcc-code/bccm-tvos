//
//  PosterSection.swift
//  BCC Media
//
//  Created by Fredrik Vedvik on 17/04/2023.
//

import SwiftUI

struct IconSection: View {
    var title: String?
    var items: [Item]
    
    var body: some View {
        VStack {
            if let t = title {
                Text(t).font(.title3).frame(maxWidth: .infinity, alignment: .leading)
            }
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 20) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 20) {
                            NavigationLink {
                                item
                            } label: {
                                ItemImage(item.image)
                                    .frame(width: 200, height: 200)
                                    .background(Color.init(red: 29/256, green: 40/256, blue: 56/256))
                                    .cornerRadius(10)
                            }.buttonStyle(.card)
                            VStack(alignment: .leading) {
                                Text(item.title)
                            }
                        }.frame(width: 200)
                    }
                }.padding(100)
            }.padding(-100)
        }
    }
}

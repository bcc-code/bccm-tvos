//
//  SectionItemButtom.swift
//  BCC Media
//
//  Created by Fredrik Vedvik on 16/05/2023.
//

import SwiftUI

struct SectionItemButton: ButtonStyle {
    let focused: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.zero)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white, lineWidth: configuration.isPressed || focused ? 4 : 0))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 1.05 : focused ? 1.02 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed || focused)
    }
}

struct SectionItemCard: View {
    var item: Item
    var onClick: () -> Void
    
    init(_ item: Item, onClick: @escaping () -> Void) {
        self.item = item
        self.onClick = onClick
    }
    
    @FocusState var isFocused: Bool
    
    var body: some View {
        GeometryReader { reader in
            if let image = item.image {
                VStack(alignment: .leading, spacing: 20) {
                    Button {
                        onClick()
                    } label: {
                        ItemImage(image)
                            .frame(width: reader.size.width, height: reader.size.height)
                            .cornerRadius(10)
                            .overlay(
                                LockView(locked: item.locked),
                                alignment: .top
                            )
                            .overlay(
                                ProgressBar(item: item),
                                alignment: .bottom)
                    }
                    .buttonStyle(SectionItemButton(focused: isFocused))
                    .focused($isFocused)
                    ItemTitle(item)
                }.frame(width: reader.size.width)
            }
        }
    }
}

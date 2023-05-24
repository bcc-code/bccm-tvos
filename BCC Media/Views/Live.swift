//
// Created by Fredrik Vedvik on 16/03/2023.
//

import AVKit
import Foundation
import SwiftUI

struct LiveResponse: Codable {
    var url: String

    enum CodingKeys: String, CodingKey {
        case url
    }
}

struct LivePlayer: View {
    @State var url: URL?

    func load() {
        Task {
            let token = await authenticationProvider.getAccessToken()
            if token != nil {
                var req = URLRequest(url: URL(string: "https://livestreamfunctions.brunstad.tv/api/urls/live")!)
                req.setValue("Bearer " + token!, forHTTPHeaderField: "Authorization")

                let (data, _) = try await URLSession.shared.data(for: req)
                let resp = try JSONDecoder().decode(LiveResponse.self, from: data)
                url = URL(string: resp.url)!
            }
        }
    }

    var body: some View {
        VStack {
            if let url = url {
                PlayerViewController(url, .init(isLive: true)).ignoresSafeArea()
            } else {
                ProgressView()
            }
        }.onAppear {
            load()
        }.ignoresSafeArea()
    }
}

extension LivePlayer: Hashable {
    static func == (_: LivePlayer, _: LivePlayer) -> Bool {
        true
    }

    func hash(into _: inout Hasher) {}
}

struct LiveView: View {
    var play: () -> Void

    init(_ play: @escaping () -> Void) {
        self.play = play
    }

    private var columns = [GridItem(.flexible()), GridItem(.flexible())]

    @FocusState var imageFocused

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                Image(uiImage: UIImage(named: "Live.png")!)
                    .focusable()
                    .focused($imageFocused)
                    .scaleEffect(imageFocused ? 1.02 : 1)
                    .animation(.easeOut(duration: 0.1), value: imageFocused)
                    .onTapGesture {
                        play()
                    }
                VStack {
                    Text("common_live").font(.title).bold()
                }
                Spacer()
            }
            CalendarDay()
        }
    }
}

struct LiveView_Previews: PreviewProvider {
    static var previews: some View {
        LiveView {}
    }
}

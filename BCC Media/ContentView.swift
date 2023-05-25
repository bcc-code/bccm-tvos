//
//  ContentView.swift
//  appletv
//
//  Created by Fredrik Vedvik on 09/03/2023.
//
//

import SwiftUI

var backgroundColor: Color {
    Color(red: 13 / 256, green: 22 / 256, blue: 35 / 256)
}

var cardBackgroundColor: Color {
    Color(red: 29 / 256, green: 40 / 256, blue: 56 / 256)
}

// This is a struct to distinguish the first page component from any subpages.
struct FrontPage: View {
    var page: API.GetPageQuery.Data.Page?
    var clickItem: ClickItem

    init(page: API.GetPageQuery.Data.Page?, clickItem: @escaping ClickItem) {
        self.page = page
        self.clickItem = clickItem
    }

    var body: some View {
        ZStack {
            if let page = page {
                PageView(page, clickItem: clickItem)
            }
        }
    }
}

enum StaticDestination: Hashable {
    case live
    case aboutUs
    case signIn
}

enum TabType: Hashable {
    case pages
    case live
    case search
    case settings
}

struct ContentView: View {
    @State var authenticated = authenticationProvider.isAuthenticated()
    @State var frontPage: API.GetPageQuery.Data.Page? = nil
    @State var bccMember = false

    @State var loaded = false

    @State var loading = false

    func load() async {
        await AppOptions.load()
        if let pageId = AppOptions.app.pageId {
            frontPage = nil
            // Assure that the cache is cleared. It's done asynchronously
            try? await Task.sleep(nanoseconds: 1_000_000)
            frontPage = await getPage(pageId)
            print("FETCHED FRONTPAGE")
            bccMember = AppOptions.user.bccMember == true
        }
        authenticationProvider.registerErrorCallback {
            startSignIn()
        }
        withAnimation {
            loaded = true
        }
    }

    private func viewCallback(_ id: String) async {
        await loadEpisode(id)
    }

    private func getPathsFromUrl(_ url: URL) async -> [any Hashable] {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        let parts = components.path.split(separator: "/")
        if parts.count == 0 {
            return []
        }

        var path: [any Hashable] = []

        if parts[0] == "episode" {
            if parts[1] != "" {
                let str = parts[1]
                guard let data = await apolloClient.getAsync(query: API.GetEpisodeQuery(id: String(str))) else {
                    return []
                }
                path.append(data.episode)
                if let queryItems = components.queryItems {
                    for q in queryItems {
                        if q.name == "play" {
                            if let playerUrl = getPlayerUrl(streams: data.episode.streams) {
                                path.append(EpisodePlayer(episode: data.episode, playerUrl: playerUrl, startFrom: data.episode.progress ?? 0))
                            }
                        }
                    }
                }
            }
        }

        return path
    }

    func reload() async {
        authenticationProvider.clearUserInfoCache()
        await load()
    }

    func authStateUpdate() {
        apolloClient.clearCache(callbackQueue: .main) { _ in
            print("CLEARED APOLLO CACHE")
            authenticated = authenticationProvider.isAuthenticated()
            loading = false
            path.removeLast(path.count)
            Task {
                await reload()
            }
        }
    }

    func logout() {
        loading = true
        Task {
            _ = await authenticationProvider.logout()
            authStateUpdate()
        }
    }

    @State var cancelLogin: (() -> Void)? = nil
    func startSignIn() {
        let task = Task {
            do {
                try await authenticationProvider.login { code in
                    path.append(
                        SignInView(
                            cancel: {
                                cancelLogin?()
                            },
                            verificationUri: code.verificationUri,
                            verificationUriComplete: code.verificationUriComplete,
                            code: code.userCode
                        )
                    )
                }
                authStateUpdate()
            } catch {
                print(error)
            }
        }
        cancelLogin = task.cancel
    }

    func playCallback(_ player: EpisodePlayer) {
        path.append(player)
    }

    func loadEpisode(_ id: String) async {
        guard let data = await apolloClient.getAsync(query: API.GetEpisodeQuery(id: id)) else {
            return
        }
        path.append(data.episode)
    }

    func loadShow(_ id: String) async {
        guard let data = await apolloClient.getAsync(query: API.GetDefaultEpisodeIdForShowQuery(id: id)) else {
            return
        }
        await loadEpisode(data.show.defaultEpisode.id)
    }

    func loadSeason(_ id: String) async {
        guard let data = await apolloClient.getAsync(query: API.GetDefaultEpisodeIdForSeasonQuery(id: id)) else {
            return
        }
        await loadEpisode(data.season.defaultEpisode.id)
    }

    func loadTopic(_ id: String) async {
        guard let data = await apolloClient.getAsync(query: API.GetDefaultEpisodeIdForStudyTopicQuery(id: id)),
              let episodeId = data.studyTopic.defaultLesson.defaultEpisode?.id
        else {
            return
        }
        await loadEpisode(episodeId)
    }

    func loadPage(_ id: String) async {
        guard let data = await apolloClient.getAsync(query: API.GetPageQuery(id: id)) else {
            return
        }
        path.append(data.page)
    }

    func getPage(_ id: String) async -> API.GetPageQuery.Data.Page {
        let data = await apolloClient.getAsync(query: API.GetPageQuery(id: id))
        return data!.page
    }

    func clickItem(item: Item) async {
        if item.locked {
            print("Item was locked. Ignoring click")
            return
        }

        print("LOADING: \(item.type) \(item.id)")

        switch item.type {
        case .episode:
            await loadEpisode(item.id)
        case .show:
            await loadShow(item.id)
        case .page:
            await loadPage(item.id)
        case .topic:
            await loadTopic(item.id)
        case .season:
            await loadSeason(item.id)
        }
    }

    @State var searchQuery = ""

    @State var path: NavigationPath = .init()
    @State var tab: TabType = .pages

    @State var onboarded = authenticationProvider.isAuthenticated()

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            if loaded {
                NavigationStack(path: $path) {
                    ZStack {
                        TabView(selection: $tab) {
                            FrontPage(page: frontPage, clickItem: clickItem)
                                .tabItem {
                                    Label("tab_home", systemImage: "house.fill")
                                }.tag(TabType.pages)
                            if authenticated && bccMember {
                                LiveView {
                                    path.append(StaticDestination.live)
                                }.tabItem {
                                    Label("tab_live", systemImage: "video")
                                }.tag(TabType.live)
                            }
                            SearchView(queryString: $searchQuery, clickItem: clickItem, playCallback: playCallback).tabItem {
                                Label("tab_search", systemImage: "magnifyingglass")
                            }.tag(TabType.search)
                            SettingsView(path: $path, authenticated: authenticated, onSave: {
                                authenticated = authenticationProvider.isAuthenticated()
                                Task {
                                    await load()
                                }
                            }) {
                                startSignIn()
                            } logout: {
                                logout()
                            }.tabItem {
                                Label("tab_settings", systemImage: "gearshape.fill")
                            }.tag(TabType.settings)
                        }.disabled(!authenticated && !onboarded)
                        if !authenticated && !onboarded {
                            Image(uiImage: UIImage(named: "OnboardBackground")!).resizable().ignoresSafeArea()
                            ZStack {
                                HStack {
                                    Image(uiImage: UIImage(named: "OnboardArt")!)
                                    VStack {
                                        Spacer()
                                        VStack(alignment: .leading) {
                                            Text("onboard_title").font(.title2)
                                            Text("onboard_description").foregroundColor(.gray)
                                        }
                                        Spacer()
                                        Button("onboard_login") {
                                            withAnimation {
                                                startSignIn()
                                                onboarded.toggle()
                                            }
                                        }.tint(.blue)
                                        Button("onboard_explorePublic") {
                                            withAnimation {
                                                onboarded.toggle()
                                            }
                                        }
                                        Spacer()
                                    }.padding(50)
                                }
                            }.transition(.move(edge: .bottom)).zIndex(2)
                        }
                    }
                    .navigationDestination(for: API.GetEpisodeQuery.Data.Episode.self) { i in
                        EpisodeViewer(episode: i, viewCallback: viewCallback, playCallback: playCallback)
                    }
                    .navigationDestination(for: API.GetPageQuery.Data.Page.self) { page in
                        PageView(page, clickItem: clickItem)
                    }
                    .navigationDestination(for: EpisodePlayer.self) { player in
                        player.ignoresSafeArea()
                    }
                    .navigationDestination(for: SignInView.self) { view in
                        view
                    }
                    .navigationDestination(for: AboutUsView.self) { view in
                        view
                    }
                    .navigationDestination(for: StaticDestination.self) { dest in
                        switch dest {
                        case .live:
                            LivePlayer()
                        case .aboutUs:
                            AboutUsView()
                        default:
                            EmptyView()
                        }
                    }
                }.transition(.opacity)
            }
        }.preferredColorScheme(.dark)
            .task {
                await load()
            }
            .onOpenURL(perform: { url in
                loading = true
                Task {
                    let paths = await getPathsFromUrl(url)
                    for p in paths {
                        path.append(p)
                    }
                    onboarded = true
                    loading = false
                }
            })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

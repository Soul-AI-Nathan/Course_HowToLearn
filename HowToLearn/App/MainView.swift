//
//  MainView.swift
//  HowToLearn
//
//  Created by How on 6/6/24.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var selectedTab = 0
    @State private var selectedItemID: String?
    @State private var navigateToDetail = false
    @State private var selectedViewType: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                BlogView()
                    .background(
                        NavigationLink(
                            destination: detailView(),
                            isActive: $navigateToDetail,
                            label: { EmptyView() }
                        )
                        .hidden()
                    )
            }
            .tabItem {
                Image(systemName: "newspaper")
                Text("Blog")
            }
            .tag(0)

            NavigationView {
                VideoView()
                    .background(
                        NavigationLink(
                            destination: detailView(),
                            isActive: $navigateToDetail,
                            label: { EmptyView() }
                        )
                        .hidden()
                    )
            }
            .tabItem {
                Image(systemName: "play.rectangle")
                Text("Video")
            }
            .tag(1)

            NavigationView {
                BookView()
                    .background(
                        NavigationLink(
                            destination: detailView(),
                            isActive: $navigateToDetail,
                            label: { EmptyView() }
                        )
                        .hidden()
                    )
            }
            .tabItem {
                Image(systemName: "book")
                Text("Book")
            }
            .tag(2)

            NavigationView {
                PodcastView()
                    .background(
                        NavigationLink(
                            destination: detailView(),
                            isActive: $navigateToDetail,
                            label: { EmptyView() }
                        )
                        .hidden()
                    )
            }
            .tabItem {
                Image(systemName: "headphones")
                Text("Podcast")
            }
            .tag(3)

            NavigationView {
                CourseView()
                    .background(
                        NavigationLink(
                            destination: detailView(),
                            isActive: $navigateToDetail,
                            label: { EmptyView() }
                        )
                        .hidden()
                    )
            }
            .tabItem {
                Image(systemName: "desktopcomputer")
                Text("Course")
            }
            .tag(4)
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: .didReceiveDeepLink, object: nil, queue: .main) { notification in
                if let url = notification.object as? URL {
                    handleDeepLink(url: url)
                }
            }
        }
    }

    private func handleDeepLink(url: URL) {
        if let host = url.host, let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems, let id = queryItems.first(where: { $0.name == "id" })?.value {
            selectedItemID = id
            selectedViewType = host

            switch host {
            case "article":
                selectedTab = 0
            case "video":
                selectedTab = 1
            case "book":
                selectedTab = 2
            case "podcast":
                selectedTab = 3
            case "course":
                selectedTab = 4
            default:
                break
            }

            DispatchQueue.main.async {
                navigateToDetail = true
            }
        }
    }

    @ViewBuilder
    private func detailView() -> some View {
        if let id = selectedItemID, let viewType = selectedViewType {
            switch viewType {
            case "article":
                if let article = firestoreManager.articles.first(where: { $0.id == id }) {
                    ArticleDetailView(article: article)
                }
            case "video":
                if let video = firestoreManager.videos.first(where: { $0.id == id }) {
                    VideoDetailView(video: video)
                }
            case "book":
                if let book = firestoreManager.books.first(where: { $0.id == id }) {
                    BookDetailView(book: book)
                }
            case "podcast":
                if let podcast = firestoreManager.podcasts.first(where: { $0.id == id }) {
                    PodcastDetailView(podcast: podcast)
                }
            case "course":
                if let course = firestoreManager.courses.first(where: { $0.id == id }) {
                    CourseDetailView(course: course)
                }
            default:
                EmptyView()
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    MainView()
}



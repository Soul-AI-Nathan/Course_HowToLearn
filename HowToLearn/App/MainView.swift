//
//  MainView.swift
//  HowToLearn
//
//  Created by How on 6/6/24.
//

// MainView.swift
// HowToLearn
//
// Created by How on 6/6/24.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var selectedTab = 0
    @State private var selectedItemID: String?
    @State private var navigateToDetail = false
    @State private var selectedSegment = 0

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
                VStack {
                    if selectedSegment == 0 {
                        VideoView()
                    } else if selectedSegment == 1 {
                        BookView()
                    } else {
                        PodcastView()
                    }
                }
                .background(
                    NavigationLink(
                        destination: detailView(),
                        isActive: $navigateToDetail,
                        label: { EmptyView() }
                    )
                    .hidden()
                )
                .overlay(
                    VStack {
                        Spacer()
                        Picker("Select Category", selection: $selectedSegment) {
                            Text("Video").tag(0)
                            Text("Book").tag(1)
                            Text("Podcast").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.bottom))
                    }
                )
            }
            .tabItem {
                Image(systemName: "play.rectangle")
                Text("Media")
            }
            .tag(1)

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
            .tag(2)

            NavigationView {
                ProjectView()
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
                Image(systemName: "folder")
                Text("Project")
            }
            .tag(3)

            NavigationView {
                ChatView()
            }
            .tabItem {
                Image(systemName: "message")
                Text("Chat")
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

            switch host {
            case "article":
                selectedTab = 0
            case "video":
                selectedTab = 1
                selectedSegment = 0
            case "book":
                selectedTab = 1
                selectedSegment = 1
            case "podcast":
                selectedTab = 1
                selectedSegment = 2
            case "course":
                selectedTab = 2
            case "project":
                selectedTab = 3
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
        if let id = selectedItemID {
            switch selectedSegment {
            case 0:
                if let video = firestoreManager.videos.first(where: { $0.id == id }) {
                    VideoDetailView(video: video)
                }
            case 1:
                if let book = firestoreManager.books.first(where: { $0.id == id }) {
                    BookDetailView(book: book)
                }
            case 2:
                if let podcast = firestoreManager.podcasts.first(where: { $0.id == id }) {
                    PodcastDetailView(podcast: podcast)
                }
            default:
                EmptyView()
            }

            if let course = firestoreManager.courses.first(where: { $0.id == id }) {
                CourseDetailView(course: course)
            } else if let project = firestoreManager.projects.first(where: { $0.id == id }) {
                ProjectDetailView(project: project)
            }
        } else {
            EmptyView()
        }
    }
}

#Preview {
    MainView()
        .environmentObject(TimerManager())
}


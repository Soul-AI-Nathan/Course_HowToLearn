//
//  VideoView.swift
//  HowToLearn
//
//  Created by How on 6/6/24.
//

import SwiftUI

struct VideoView: View {
    @ObservedObject var firestoreManager = FirestoreManager()
    @State private var selectedVideo: Video?
    @State private var showAddVideoAlert = false
    @State private var newVideoURL = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupVideosByDate(), id: \.key) { date, videos in
                    Section(header: Text(formatDate(date))) {
                        ForEach(videos) { video in
                            NavigationLink(value: video) {
                                VideoListView(video: video)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteVideo(video: video)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 50) // Add padding at the bottom to keep it above the tab bar
            .navigationTitle("Video")
            .navigationBarItems(trailing: Button(action: {
                withAnimation {
                    showAddVideoAlert.toggle()
                }
            }) {
                Image(systemName: "plus")
            })
            .navigationDestination(for: Video.self) { video in
                VideoDetailView(video: video)
            }
            .overlay(
                Group {
                    if showAddVideoAlert {
                        AddVideoAlertView(isPresented: $showAddVideoAlert, videoURL: $newVideoURL) {
                            addNewVideo(url: newVideoURL)
                            newVideoURL = ""
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                        .transition(.opacity)
                        .animation(.easeInOut, value: showAddVideoAlert)
                    }
                }
            )
        }
        .withTimer() // Apply the timer
    }

    private func addNewVideo(url: String) {
        let newVideo = Video(id: UUID().uuidString, title: "", headline: "", video_url: url, timestamp: Date())
        firestoreManager.addVideo(newVideo)
    }

    private func deleteVideo(video: Video) {
        firestoreManager.deleteVideo(video: video)
    }

    private func groupVideosByDate() -> [(key: Date, value: [Video])] {
        let groupedDict = Dictionary(grouping: firestoreManager.videos) { (video: Video) -> Date in
            // Truncate time components from the date for grouping by day
            Calendar.current.startOfDay(for: video.timestamp)
        }
        return groupedDict.sorted { $0.key > $1.key }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd"
        return formatter.string(from: date)
    }
}

#Preview {
    VideoView()
        .environmentObject(TimerManager()) // Inject the TimerManager environment object
}



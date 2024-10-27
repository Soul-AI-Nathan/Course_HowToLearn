//
//  ProjectView.swift
//  HowToLearn
//
//  Created by How on 6/6/24.
//

import SwiftUI

struct PodcastView: View {
    @ObservedObject var firestoreManager = FirestoreManager()
    @State private var selectedPodcast: Podcast?
    @State private var showAddPodcastAlert = false
    @State private var newPodcastURL = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupPodcastsByDate(), id: \.key) { date, podcasts in
                    Section(header: Text(formatDate(date))) {
                        ForEach(podcasts) { podcast in
                            NavigationLink(value: podcast) {
                                PodcastListView(podcast: podcast)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deletePodcast(podcast: podcast)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 50) // Add padding at the bottom to keep it above the tab bar
            .navigationTitle("Podcast")
            .navigationBarItems(trailing: Button(action: {
                withAnimation {
                    showAddPodcastAlert.toggle()
                }
            }) {
                Image(systemName: "plus")
            })
            .navigationDestination(for: Podcast.self) { podcast in
                PodcastDetailView(podcast: podcast)
            }
            .overlay(
                Group {
                    if showAddPodcastAlert {
                        AddPodcastAlertView(isPresented: $showAddPodcastAlert, podcastURL: $newPodcastURL) {
                            addNewPodcast(url: newPodcastURL)
                            newPodcastURL = ""
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                        .transition(.opacity)
                        .animation(.easeInOut, value: showAddPodcastAlert)
                    }
                }
            )
        }
        .withTimer() // Apply the timer
    }

    private func addNewPodcast(url: String) {
        let newPodcast = Podcast(id: UUID().uuidString, title: "", description: "", image_url: "", podcast_url: url, audio_url: "", timestamp: Date())
        firestoreManager.addPodcast(newPodcast)
    }

    private func deletePodcast(podcast: Podcast) {
        firestoreManager.deletePodcast(podcast: podcast)
    }

    private func groupPodcastsByDate() -> [(key: Date, value: [Podcast])] {
        let groupedDict = Dictionary(grouping: firestoreManager.podcasts) { (podcast: Podcast) -> Date in
            // Truncate time components from the date for grouping by day
            Calendar.current.startOfDay(for: podcast.timestamp)
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
    PodcastView()
        .environmentObject(TimerManager()) // Inject the TimerManager environment object
}


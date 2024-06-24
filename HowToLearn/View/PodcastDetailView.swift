//
//  PodcastDetailView.swift
//  HowToLearn
//
//  Created by How on 6/9/24.
//

import SwiftUI
import FirebaseFirestore

struct PodcastDetailView: View {
    let podcast: Podcast
    @State private var newTakeawayText = ""
    @State private var showAddTakeawayAlert = false
    @State private var takeaways: [String]
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var isShareSheetPresented = false
    @State private var screenshotImage: UIImage?

    init(podcast: Podcast) {
        self.podcast = podcast
        _takeaways = State(initialValue: podcast.takeaways ?? [])
    }

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    if let url = URL(string: podcast.image_url) {
                        Link(destination: URL(string: podcast.podcast_url)!) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 300)
                        }
                    }

                    Text("点击图片收听")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(podcast.title.uppercased())
                        .font(.title3)
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .foregroundColor(.primary)
                        .background(
                            Color.accentColor
                                .frame(height: 6)
                                .offset(y: 40)
                        )

                    Text(podcast.description)
                        .font(.body)
                        .lineSpacing(9)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black)
                        .padding(.horizontal)

                    // TAKEAWAY VIEW
                    if !takeaways.isEmpty {
                        VStack(alignment: .center, spacing: 5) {
                            Text("How老师的Takeaways")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.top)
                            TakeawayView(itemID: podcast.id ?? "", contentType: .podcast, takeaways: $takeaways)
                                .environmentObject(firestoreManager)
                        }
                    }

                    // COMMENTS
                    CommentPodcastView(podcastID: podcast.id ?? "")
                        .padding(.bottom, 10) // Add padding at the bottom to keep it above the tab bar
                }
                .navigationBarTitle("Listen to \(podcast.title)", displayMode: .inline)
                .navigationBarItems(trailing: HStack {
                    Button(action: {
                        withAnimation {
                            showAddTakeawayAlert.toggle()
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                    Button(action: {
                        takeScreenshot()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                })
            }

            if showAddTakeawayAlert {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                AddTakeawayAlertView(isPresented: $showAddTakeawayAlert, takeawayText: $newTakeawayText) {
                    addNewTakeaway(takeaway: newTakeawayText)
                    newTakeawayText = ""
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showAddTakeawayAlert)
            }
        }
        .onChange(of: showAddTakeawayAlert) { _ in
            if !showAddTakeawayAlert {
                reloadPodcastData()
            }
        }
        .sheet(isPresented: $isShareSheetPresented, content: {
            if let screenshotImage = screenshotImage {
                ShareSheet(activityItems: [screenshotImage])
            }
        })
    }

    private func takeScreenshot() {
        let keyWindow = UIApplication.shared.connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }

        if let keyWindow = keyWindow {
            let renderer = UIGraphicsImageRenderer(size: keyWindow.bounds.size)
            let image = renderer.image { ctx in
                keyWindow.drawHierarchy(in: keyWindow.bounds, afterScreenUpdates: true)
            }
            screenshotImage = image
            isShareSheetPresented = true
        }
    }

    private func addNewTakeaway(takeaway: String) {
        guard let podcastID = podcast.id else { return }
        firestoreManager.addTakeawayToPodcast(podcastID: podcastID, takeaway: takeaway)
        takeaways.append(takeaway)
    }

    private func reloadPodcastData() {
        let db = Firestore.firestore()
        if let podcastID = podcast.id {
            let document = db.collection("podcasts").document(podcastID)
            document.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    if let updatedPodcast = try? snapshot.data(as: Podcast.self) {
                        self.takeaways = updatedPodcast.takeaways ?? []
                    } else {
                        print("Failed to parse updated podcast")
                    }
                } else {
                    print("Document does not exist or error: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
}

#Preview {
    PodcastDetailView(podcast: Podcast(id: "1", title: "Sample Title", description: "Sample description for the podcast.", image_url: "https://via.placeholder.com/150", podcast_url: "https://www.xiaoyuzhoufm.com/episode/665faf066488b5dec3b8b28d", timestamp: Date(), takeaways: ["This is a sample takeaway.", "Another takeaway."]))
        .environmentObject(FirestoreManager())
}


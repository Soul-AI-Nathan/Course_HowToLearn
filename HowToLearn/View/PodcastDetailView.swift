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

    @State private var showAddTakeawayAlert = false
    @State private var newTakeawayText = ""
    @State private var takeaways: [String]
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var isShareSheetPresented = false
    @State private var screenshotImage: IdentifiableImage?
    @State private var showAIResponse = false // State to show/hide the AI response pop-up
    @StateObject private var audioModel = AudioModel() // Use AudioModel instead of AudioRecorderManager

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
                    
                    if !podcast.audio_url.isEmpty {
                        if let audioURL = URL(string: podcast.audio_url) {
                            AudioPlayerView(audioURL: audioURL)
                                .padding(.horizontal)
                        } else {
                            Text("Invalid audio URL")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Text(podcast.title.uppercased())
                        .font(.title3)
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .foregroundColor(.primary)
                        .background(
                            Color.accentColor
                                .frame(height: 6)
                                .offset(y: 30)
                        )
                    
                    Text(podcast.description)
                        .font(.headline)
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
                        }
                    }

                    // COMMENTS
                    CommentPodcastView(podcastID: podcast.id ?? "")
                        .padding(.bottom, 40) // Add padding at the bottom to keep it above the tab bar
                } //: VSTACK
                .navigationBarTitle("Listen to \(podcast.title)", displayMode: .inline)
                .navigationBarItems(trailing: HStack {
//                    Button(action: {
//                        withAnimation {
//                            showAddTakeawayAlert.toggle()
//                        }
//                    }) {
//                        Image(systemName: "plus")
//                    }
                    Button(action: {
                        takeScreenshot()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: {
                        showAIAudioView()
                    }) {
                        Image(systemName: "brain.head.profile")
                    }
                })
            } //: SCROLL

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
        .sheet(item: $screenshotImage, onDismiss: {
            screenshotImage = nil
        }, content: { item in
            ShareSheet(activityItems: [item.image])
        })
        .sheet(isPresented: $showAIResponse) {
            AIAudioView(am: audioModel)
        }
    }

    private func takeScreenshot() {
        print("Attempting to take screenshot...")

        guard let window = UIApplication.shared.windows.first else {
            print("No key window found.")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("Starting renderer...")

            if let image = window.snapshot {
                print("Renderer completed...")
                DispatchQueue.main.async {
                    self.screenshotImage = IdentifiableImage(image: image)
                    print("Screenshot taken, presenting share sheet.")
                }
            } else {
                print("Snapshot failed.")
            }
        }
    }

    private func showAIAudioView() {
        guard let window = UIApplication.shared.windows.first else {
            print("No key window found.")
            return
        }

        if let image = window.snapshot {
            audioModel.processingImageTask = audioModel.processImageTask(image: image)
            showAIResponse = true
        } else {
            print("Snapshot failed.")
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


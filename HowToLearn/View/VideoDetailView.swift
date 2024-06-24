//
//  VideoDetailView.swift
//  HowToLearn
//
//  Created by How on 6/8/24.
//

import SwiftUI
import YouTubePlayerKit
import FirebaseFirestore

struct VideoDetailView: View {
    let video: Video

    @StateObject
    var youTubePlayer: YouTubePlayer = .init()

    @State private var showAddTakeawayAlert = false
    @State private var newTakeawayText = ""
    @State private var updatedVideo: Video?
    @State private var takeaways: [String]
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var isShareSheetPresented = false
    @State private var screenshotImage: UIImage?

    init(video: Video) {
        self.video = video
        _takeaways = State(initialValue: video.takeaways ?? [])
    }

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    YouTubePlayerView(self.youTubePlayer)
                        .frame(height: 300)
                        .onAppear {
                            youTubePlayer.load(source: .url(video.video_url))
                        }
                    
                    Text(video.title.uppercased())
                        .font(.title3)
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .foregroundColor(.primary)
                        .background(
                            Color.accentColor
                                .frame(height: 6)
                                .offset(y: 24)
                        )
                    
                    Text(video.headline)
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
                            TakeawayView(itemID: video.id ?? "", contentType: .video, takeaways: $takeaways)
                        }
                    }

                    // COMMENTS
                    CommentVideoView(videoID: video.id ?? "")
                        .padding(.bottom, 10) // Add padding at the bottom to keep it above the tab bar
                } //: VSTACK
                .navigationBarTitle("Watch about \(video.title)", displayMode: .inline)
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
                reloadVideoData()
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
        guard let videoID = video.id else { return }
        firestoreManager.addTakeawayToVideo(videoID: videoID, takeaway: takeaway)
        takeaways.append(takeaway)
    }

    private func reloadVideoData() {
        let db = Firestore.firestore()
        if let videoID = video.id {
            let document = db.collection("videos").document(videoID)
            document.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    if let updatedVideo = try? snapshot.data(as: Video.self) {
                        self.updatedVideo = updatedVideo
                        self.takeaways = updatedVideo.takeaways ?? []
                    } else {
                        print("Failed to parse updated video")
                    }
                } else {
                    print("Document does not exist or error: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
}

#Preview {
    VideoDetailView(video: Video(id: "1", title: "Sample Title", headline: "Sample headline for the video.", video_url: "https://www.youtube.com/embed/VIDEO_ID", timestamp: Date(), takeaways: ["This is a sample takeaway.", "Another takeaway."]))
        .environmentObject(FirestoreManager())
}

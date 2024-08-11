import SwiftUI
import FirebaseFirestore
import AVFoundation

struct ArticleDetailView: View {
    let article: BlogArticle
    @State private var imageUrl: String? = nil
    @State private var isLoadingImage = false
    @State private var showAddTakeawayAlert = false
    @State private var newTakeawayText = ""
    @State private var updatedArticle: BlogArticle?
    @State private var takeaways: [String]
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var isShareSheetPresented = false
    @State private var screenshotImage: IdentifiableImage?
    @State private var showAIResponse = false // State to show/hide the AI response pop-up
    @StateObject private var audioModel = AudioModel() // Use AudioModel instead of AudioRecorderManager

    init(article: BlogArticle) {
        self.article = article
        _takeaways = State(initialValue: article.takeaways ?? [])
    }

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    // HERO IMAGE
                    if let imageUrl = imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                            case .failure:
                                Image(systemName: "photo")
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        ProgressView()
                            .onAppear {
                                loadImage()
                            }
                    }

                    // TITLE
                    Text(article.title.uppercased())
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

                    // CONTENT
                    Text(article.content.replacingOccurrences(of: "\\n", with: "\n"))
                        .font(.body)
                        .lineSpacing(9)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                        .lineLimit(nil) // Allow text to span multiple lines
                        .fixedSize(horizontal: false, vertical: true) // Make sure the Text view can grow vertically

                    // TAKEAWAY VIEW
                    if !takeaways.isEmpty {
                        VStack(alignment: .center, spacing: 5) {
                            Text("How老师的Takeaways")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.top)
                            TakeawayView(itemID: article.id ?? "", contentType: .article, takeaways: $takeaways)
                        }
                    }

                    // COMMENTS
                    CommentArticleView(articleID: article.id ?? "")
                        .padding(.bottom, 10) // Add padding at the bottom to keep it above the tab bar
                } //: VSTACK
                .navigationBarTitle("Read about \(article.title)", displayMode: .inline)
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
            if (!showAddTakeawayAlert) {
                reloadArticleData()
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
        guard let articleID = article.id else { return }
        firestoreManager.addTakeawayToArticle(articleID: articleID, takeaway: takeaway)
        takeaways.append(takeaway)
    }

    private func reloadArticleData() {
        let db = Firestore.firestore()
        if let articleID = article.id {
            let document = db.collection("articles").document(articleID)
            document.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    if let updatedArticle = try? snapshot.data(as: BlogArticle.self) {
                        self.updatedArticle = updatedArticle
                        self.takeaways = updatedArticle.takeaways ?? []
                    } else {
                        print("Failed to parse updated article")
                    }
                } else {
                    print("Document does not exist or error: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }

    private func loadImage() {
        isLoadingImage = true
        let db = Firestore.firestore()
        if let articleID = article.id {
            let document = db.collection("articles").document(articleID)
            document.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    if let url = snapshot.data()?["imageUrl"] as? String {
                        imageUrl = url
                        isLoadingImage = false
                    } else {
                        // Generate image if not available
                        sendArticleToOpenAIAPI(article: article) { prompt in
                            guard let prompt = prompt else {
                                isLoadingImage = false
                                return
                            }
                            generateImageWithDALLE(prompt: prompt, for: article) { url in
                                imageUrl = url
                                isLoadingImage = false
                            }
                        }
                    }
                } else {
                    isLoadingImage = false
                    print("Document does not exist or error: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }

}

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

import SwiftUI
import FirebaseFirestore
import AVFoundation
import PhotosUI
import FirebaseStorage

struct ArticleDetailView: View {
    let article: BlogArticle
    @State private var imageUrls: [String] = []
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
    
    @State private var selectedImages: [UIImage] = []  // To store selected images
    @State private var isImagePickerPresented = false  // To control the presentation of the image picker

    init(article: BlogArticle) {
        self.article = article
        _takeaways = State(initialValue: article.takeaways ?? [])
    }

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    // HERO IMAGE
                    if !imageUrls.isEmpty {
                        TabView {
                            ForEach(imageUrls, id: \.self) { url in
                                CustomAsyncImage(
                                    url: URL(string: url),
                                    isUserUrl: urlIsUserUrl(url),  // Determine if the URL is from userUrl
                                    deleteAction: {
                                        deleteImageUrl(url: url)
                                    }
                                )
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle())
                        .frame(height: 300)  // Adjust the height based on calculated value
                        .padding(.horizontal, 0)
                    } else {
                        VStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
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
//                    Button(action: {
//                        isImagePickerPresented = true  // Present the image picker
//                    }) {
//                        Image(systemName: "photo")
//                    }
                })
                .sheet(isPresented: $isImagePickerPresented) {
                    PhotoPicker(selectedImages: $selectedImages)  // Present the custom PhotoPicker
                        .onDisappear {
                            uploadSelectedImages {
                                loadImage()  // Refresh the images after upload
                            }
                        }
                }
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
    
    private func urlIsUserUrl(_ url: String) -> Bool {
        // Assuming the first URL in imageUrls is always the main imageUrl and others are userUrls
        return imageUrls.firstIndex(of: url) != 0
    }
    
    private func deleteImageUrl(url: String) {
        guard let articleID = article.id else { return }

        let db = Firestore.firestore()
        let document = db.collection("articles").document(articleID)

        // Remove the URL from the userUrl array in Firestore
        document.updateData(["userUrl": FieldValue.arrayRemove([url])]) { error in
            if let error = error {
                print("Error removing URL: \(error.localizedDescription)")
            } else {
                print("URL successfully removed from Firestore")
                // Remove the URL from the local imageUrls array
                if let index = imageUrls.firstIndex(of: url) {
                    imageUrls.remove(at: index)
                }
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
    
    private func uploadSelectedImages(completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        guard let articleID = article.id else { return }

        var uploadedImageUrls: [String] = []

        let dispatchGroup = DispatchGroup() // To manage multiple async tasks

        for image in selectedImages {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                dispatchGroup.enter() // Enter the dispatch group before starting the upload

                uploadImageToFirebaseStorage(imageData: imageData, for: article) { firebaseImageUrl in
                    if let firebaseImageUrl = firebaseImageUrl {
                        print("Image uploaded with URL: \(firebaseImageUrl)")
                        if !uploadedImageUrls.contains(firebaseImageUrl) {
                            uploadedImageUrls.append(firebaseImageUrl)
                        } else {
                            print("Duplicate URL detected: \(firebaseImageUrl)")
                        }
                    } else {
                        print("Failed to upload image.")
                    }

                    dispatchGroup.leave() // Leave the dispatch group after finishing the upload
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            print("All uploads finished. Uploading the following URLs to Firestore: \(uploadedImageUrls)")
            // Update the Firestore document with the array of image URLs in the `userUrl` field
            let document = db.collection("articles").document(articleID)
            document.updateData(["userUrl": FieldValue.arrayUnion(uploadedImageUrls)]) { error in
                if let error = error {
                    print("Error updating document: \(error.localizedDescription)")
                } else {
                    print("Document successfully updated with image URLs in userUrl")
                }
                completion()  // Call the completion handler after updating Firestore
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
                    var combinedUrls: [String] = []
                    
                    if let url = snapshot.data()?["imageUrl"] as? String {
                        combinedUrls.append(url)
                    }
                    if let userUrls = snapshot.data()?["userUrl"] as? [String] {
                        combinedUrls.append(contentsOf: userUrls)
                    }
                    
                    // Debug log to verify loaded URLs
                    print("Combined URLs from Firestore: \(combinedUrls)")

                    self.imageUrls = combinedUrls
                    isLoadingImage = false
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

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0  // Allow multiple selections

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.selectedImages = []  // Clear the previous selections

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                        } else if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self?.parent.selectedImages.append(image)
                            }
                        }
                    }
                }
            }

            picker.dismiss(animated: true)
        }
    }
}

struct CustomAsyncImage: View {
    let url: URL?
    let isUserUrl: Bool  // To differentiate between imageUrl and userUrl
    let deleteAction: () -> Void  // Closure for deleting the image

    var body: some View {
        GeometryReader { geometry in
            if let url = url {
                AsyncImage(url: url, transaction: Transaction(animation: .default)) { phase in
                    switch phase {
                    case .empty:
                        VStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width) // Ensure the image takes up the full screen width
                            .transition(.opacity)
                            .contextMenu {
                                if isUserUrl {
                                    Button(action: {
                                        deleteAction()  // Trigger delete action
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width)
                    @unknown default:
                        EmptyView()
                    }
                }
                .transition(.opacity) // Add transition to ensure cache doesn't affect display
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometry.size.width)
            }
        }
    }
}



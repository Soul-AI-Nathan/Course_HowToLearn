//
//  BookDetailView.swift
//  HowToLearn
//
//  Created by How on 6/8/24.
//

import SwiftUI
import FirebaseFirestore

struct BookDetailView: View {
    let book: Book

    @State private var showAddTakeawayAlert = false
    @State private var newTakeawayText = ""
    @State private var takeaways: [String]
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var isShareSheetPresented = false
    @State private var screenshotImage: IdentifiableImage?
    @State private var showAIResponse = false // State to show/hide the AI response pop-up
    @StateObject private var audioModel = AudioModel() // Use AudioModel instead of AudioRecorderManager

    init(book: Book) {
        self.book = book
        _takeaways = State(initialValue: book.takeaways ?? [])
    }

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    if let url = URL(string: book.image_url) {
                        Link(destination: URL(string: book.book_url)!) {
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
                    
                    Text(book.title.uppercased())
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
                    
                    Text(book.description)
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
                            TakeawayView(itemID: book.id ?? "", contentType: .book, takeaways: $takeaways)
                        }
                    }

                    // COMMENTS
                    CommentBookView(bookID: book.id ?? "")
                        .padding(.bottom, 40) // Add padding at the bottom to keep it above the tab bar
                } //: VSTACK
                .navigationBarTitle("Read about \(book.title)", displayMode: .inline)
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
            if !showAddTakeawayAlert {
                reloadBookData()
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
        guard let bookID = book.id else { return }
        firestoreManager.addTakeawayToBook(bookID: bookID, takeaway: takeaway)
        takeaways.append(takeaway)
    }

    private func reloadBookData() {
        let db = Firestore.firestore()
        if let bookID = book.id {
            let document = db.collection("books").document(bookID)
            document.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    if let updatedBook = try? snapshot.data(as: Book.self) {
                        self.takeaways = updatedBook.takeaways ?? []
                    } else {
                        print("Failed to parse updated book")
                    }
                } else {
                    print("Document does not exist or error: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
}


#Preview {
    BookDetailView(book: Book(id: "1", title: "Sample Title", description: "Sample description for the book.", image_url: "https://example.com/image.jpg", book_url: "https://example.com/book", timestamp: Date(), takeaways: ["This is a sample takeaway.", "Another takeaway."]))
        .environmentObject(FirestoreManager())
}

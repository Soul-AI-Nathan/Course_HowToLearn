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
    @State private var screenshotImage: UIImage?

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
                        .padding(.bottom, 10) // Add padding at the bottom to keep it above the tab bar
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

//
//  BookListView.swift
//  HowToLearn
//
//  Created by How on 6/8/24.
//

import SwiftUI
import SwiftSoup
import FirebaseFirestore

struct BookListView: View {
    let book: Book
    @State private var isLoading = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if isLoading {
                ProgressView()
                    .frame(width: 134, height: 195)
            } else {
                if let url = URL(string: book.image_url) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 134, height: 195)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 134, height: 195)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundColor(.accentColor)

                Text(book.description)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .padding(.trailing, 8)
            }
        }
        .onAppear {
            if book.title.isEmpty || book.description.isEmpty || book.image_url.isEmpty {
                fetchAndUpdateBookDetails()
            }
        }
    }

    private func fetchAndUpdateBookDetails() {
        fetchBookDetails { title, description, imageUrl in
            if let title = title, let description = description, let imageUrl = imageUrl {
                updateBookInDatabase(title: title, description: description, imageUrl: imageUrl)
            }
        }
    }

    private func fetchBookDetails(completion: @escaping (String?, String?, String?) -> Void) {
        guard let url = URL(string: book.book_url) else {
            completion(nil, nil, nil)
            return
        }

        isLoading = true

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                completion(nil, nil, nil)
                return
            }

            if let html = String(data: data, encoding: .utf8) {
                parseHTML(html, completion: completion)
            } else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                completion(nil, nil, nil)
            }
        }.resume()
    }

    private func parseHTML(_ html: String, completion: @escaping (String?, String?, String?) -> Void) {
        do {
            let document = try SwiftSoup.parse(html)

            let imgUrl = try document.select("img.wr_bookCover_img").first()?.attr("src")
            let title = try document.select("meta[property=og:title]").first()?.attr("content")
            let description = try document.select("meta[name=description]").first()?.attr("content")

            let extractedTitle = extractTitleUpToFirstSymbol(from: title ?? "")

            DispatchQueue.main.async {
                completion(extractedTitle, description, imgUrl)
                isLoading = false
            }
        } catch {
            print("Error parsing HTML: \(error)")
            DispatchQueue.main.async {
                isLoading = false
            }
            completion(nil, nil, nil)
        }
    }

    private func extractTitleUpToFirstSymbol(from title: String) -> String {
        let pattern = "^[^：:：]+"
        if let range = title.range(of: pattern, options: .regularExpression) {
            return String(title[range])
        }
        return title
    }

    private func updateBookInDatabase(title: String, description: String, imageUrl: String) {
        let db = Firestore.firestore()
        guard let bookID = book.id else {
            print("Book ID is nil")
            return
        }

        let document = db.collection("books").document(bookID)
        document.updateData([
            "title": title,
            "description": description,
            "image_url": imageUrl,
            "timestamp": book.timestamp
        ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Document successfully updated with book details")
            }
        }
    }

    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

#Preview {
    BookListView(book: Book(id: "1", title: "", description: "", image_url: "", book_url: "https://weread.qq.com/web/bookDetail/67532750716e85116752328", timestamp: Date()))
}

//
//  BookView.swift
//  HowToLearn
//
//  Created by How on 6/6/24.
//

import SwiftUI

struct BookView: View {
    @ObservedObject var firestoreManager = FirestoreManager()
    @State private var selectedBook: Book?
    @State private var showAddBookAlert = false
    @State private var newBookURL = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupBooksByDate(), id: \.key) { date, books in
                    Section(header: Text(formatDate(date))) {
                        ForEach(books) { book in
                            NavigationLink(value: book) {
                                BookListView(book: book)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteBook(book: book)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 50) // Add padding at the bottom to keep it above the tab bar
            .navigationTitle("Book")
            .navigationBarItems(trailing: Button(action: {
                withAnimation {
                    showAddBookAlert.toggle()
                }
            }) {
                Image(systemName: "plus")
            })
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
            .overlay(
                Group {
                    if showAddBookAlert {
                        AddBookAlertView(isPresented: $showAddBookAlert, bookURL: $newBookURL) {
                            addNewBook(url: newBookURL)
                            newBookURL = ""
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                        .transition(.opacity)
                        .animation(.easeInOut, value: showAddBookAlert)
                    }
                }
            )
        }
        .withTimer() // Apply the timer
    }

    private func addNewBook(url: String) {
        let newBook = Book(id: UUID().uuidString, title: "", description: "", image_url: "", book_url: url, timestamp: Date())
        firestoreManager.addBook(newBook)
    }

    private func deleteBook(book: Book) {
        firestoreManager.deleteBook(book: book)
    }

    private func groupBooksByDate() -> [(key: Date, value: [Book])] {
        let groupedDict = Dictionary(grouping: firestoreManager.books) { (book: Book) -> Date in
            // Truncate time components from the date for grouping by day
            Calendar.current.startOfDay(for: book.timestamp)
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
    BookView()
}



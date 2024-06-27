//
//  BlogView.swift
//  HowToLearn
//
//  Created by How on 6/6/24.
//

import SwiftUI

struct BlogView: View {
    @ObservedObject var firestoreManager = FirestoreManager()
    @State private var selectedArticle: BlogArticle?
    @State private var showAddArticleAlert = false
    @State private var newArticleTitle = ""
    @State private var newArticleContent = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupArticlesByDate(), id: \.key) { date, articles in
                    Section(header: Text(formatDate(date))) {
                        ForEach(articles) { article in
                            NavigationLink(value: article) {
                                ArticleListView(article: article)
                            }
//                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                                Button(role: .destructive) {
//                                    deleteArticle(article: article)
//                                } label: {
//                                    Label("Delete", systemImage: "trash")
//                                }
//                            }
                        }
                    }
                }
            }
            .navigationTitle("Blog")
//            .navigationBarItems(trailing: Button(action: {
//                withAnimation {
//                    showAddArticleAlert.toggle()
//                }
//            }) {
//                Image(systemName: "plus")
//            })
            .navigationDestination(for: BlogArticle.self) { article in
                ArticleDetailView(article: article)
            }
//            .overlay(
//                Group {
//                    if showAddArticleAlert {
//                        AddArticleAlertView(isPresented: $showAddArticleAlert, articleTitle: $newArticleTitle, articleContent: $newArticleContent) {
//                            addNewArticle(title: newArticleTitle, content: newArticleContent)
//                            newArticleTitle = ""
//                            newArticleContent = ""
//                        }
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
//                        .transition(.opacity)
//                        .animation(.easeInOut, value: showAddArticleAlert)
//                    }
//                }
//            )
        }
    }

    private func addNewArticle(title: String, content: String) {
        let newArticle = BlogArticle(id: UUID().uuidString, title: title, content: content, timestamp: Date())
        firestoreManager.addArticle(newArticle)
    }

    private func deleteArticle(article: BlogArticle) {
        firestoreManager.deleteArticle(article: article)
    }

    private func groupArticlesByDate() -> [(key: Date, value: [BlogArticle])] {
        let groupedDict = Dictionary(grouping: firestoreManager.articles) { (article: BlogArticle) -> Date in
            // Truncate time components from the date for grouping by day
            Calendar.current.startOfDay(for: article.timestamp)
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
    BlogView()
}

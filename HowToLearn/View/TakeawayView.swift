//
//  TakeawayView.swift
//  HowToLearn
//
//  Created by How on 6/19/24.
//

import SwiftUI

enum ContentType {
    case article
    case video
    case book
    case podcast
    case course
}

struct TakeawayView: View {
    let itemID: String
    let contentType: ContentType
    @Binding var takeaways: [String]
    @EnvironmentObject var firestoreManager: FirestoreManager

    var body: some View {
        GroupBox {
            TabView {
                ForEach(takeaways, id: \.self) { takeaway in
                    Text(takeaway)
                        .font(.body)
                        .foregroundColor(.black)
                        .padding()
                        .cornerRadius(10)
                        .padding(.horizontal, 10)
                        .contextMenu {
                            Button(action: {
                                deleteTakeaway(takeaway)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .tabViewStyle(PageTabViewStyle())
            .frame(minHeight: 148, idealHeight: 168, maxHeight: 180)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .onAppear {
            setupPageControlAppearance()
        }
    }

    private func setupPageControlAppearance() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.red
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray
    }

    private func deleteTakeaway(_ takeaway: String) {
        if let index = takeaways.firstIndex(of: takeaway) {
            takeaways.remove(at: index)
            switch contentType {
            case .article:
                firestoreManager.removeTakeawayFromArticle(articleID: itemID, takeaway: takeaway)
            case .video:
                firestoreManager.removeTakeawayFromVideo(videoID: itemID, takeaway: takeaway)
            case .book:
                firestoreManager.removeTakeawayFromBook(bookID: itemID, takeaway: takeaway)
            case .podcast:
                firestoreManager.removeTakeawayFromPodcast(podcastID: itemID, takeaway: takeaway)
            case .course:
                firestoreManager.removeTakeawayFromCourse(courseID: itemID, takeaway: takeaway)
            }
        }
    }
}

#Preview {
    TakeawayView(itemID: "1", contentType: .article, takeaways: .constant(["This is a sample takeaway.", "Another takeaway."]))
        .environmentObject(FirestoreManager())
}




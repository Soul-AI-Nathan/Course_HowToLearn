//
//  CommentVideoView.swift
//  HowToLearn
//
//  Created by How on 6/15/24.
//

import SwiftUI
import FirebaseFirestore

struct CommentVideoView: View {
    @State private var newComment = ""
    @State private var comments = [CommentVideo]()
    let videoID: String
    private var db = Firestore.firestore()

    // Explicit initializer
    init(videoID: String) {
        self.videoID = videoID
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Comments")
                .font(.headline)
                .padding(.top)
            
            HStack {
                TextField("Enter your comment", text: $newComment)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.vertical, 8)

                Button(action: addComment) {
                    Text("Post")
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            ForEach(comments) { comment in
                VStack(alignment: .leading, spacing: 4) {
                    Text(comment.text)
                        .padding(.vertical, 4)
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Text(formatTimestamp(comment.timestamp))
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.bottom, 4)
                }
            }
        }
        .padding([.horizontal, .bottom]) // Add padding at the bottom
        .onAppear(perform: fetchComments)
    }

    private func fetchComments() {
        db.collection("commentsVideo").whereField("videoID", isEqualTo: videoID)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error getting comments: \(error.localizedDescription)")
                } else {
                    comments = querySnapshot?.documents.compactMap { document -> CommentVideo? in
                        try? document.data(as: CommentVideo.self)
                    } ?? []
                }
            }
    }

    private func addComment() {
        guard !newComment.isEmpty else { return }
        let comment = CommentVideo(videoID: videoID, text: newComment, timestamp: Date())
        do {
            _ = try db.collection("commentsVideo").addDocument(from: comment)
            newComment = ""
            hideKeyboard() // Hide the keyboard
        } catch {
            print("Error adding comment: \(error.localizedDescription)")
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

#Preview {
    CommentVideoView(videoID: "sampleVideoID")
}

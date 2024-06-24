//
//  CommentVideo.swift
//  HowToLearn
//
//  Created by How on 6/15/24.
//

import Foundation
import FirebaseFirestoreSwift

struct CommentVideo: Identifiable, Codable {
    @DocumentID var id: String?
    var videoID: String
    var text: String
    var timestamp: Date
}

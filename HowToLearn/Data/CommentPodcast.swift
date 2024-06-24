//
//  CommentPodcast.swift
//  HowToLearn
//
//  Created by How on 6/15/24.
//

import Foundation
import FirebaseFirestoreSwift

struct CommentPodcast: Identifiable, Codable {
    @DocumentID var id: String?
    var podcastID: String
    var text: String
    var timestamp: Date
}


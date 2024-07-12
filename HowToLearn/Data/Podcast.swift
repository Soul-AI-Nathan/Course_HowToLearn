//
//  Podcast.swift
//  HowToLearn
//
//  Created by How on 6/9/24.
//

import Foundation
import FirebaseFirestoreSwift

struct Podcast: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var image_url: String
    var podcast_url: String
    var audio_url: String
    var timestamp: Date
    var takeaways: [String]?
}

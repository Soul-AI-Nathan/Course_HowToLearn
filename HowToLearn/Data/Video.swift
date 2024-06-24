//
//  Video.swift
//  HowToLearn
//
//  Created by How on 6/8/24.
//

import Foundation
import FirebaseFirestoreSwift

struct Video: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var headline: String
    var video_url: String
    var timestamp: Date
    var takeaways: [String]?
}

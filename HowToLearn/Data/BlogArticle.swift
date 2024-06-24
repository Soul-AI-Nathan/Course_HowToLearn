//
//  BlogArticle.swift
//  HowToLearn
//
//  Created by How on 6/8/24.
//

// BlogArticle.swift

import Foundation
import FirebaseFirestoreSwift

struct BlogArticle: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var content: String
    var timestamp: Date
    var takeaways: [String]?
}


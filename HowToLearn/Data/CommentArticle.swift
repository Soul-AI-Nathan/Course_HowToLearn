//
//  CommnetArticle.swift
//  HowToLearn
//
//  Created by How on 6/14/24.
//

import Foundation
import FirebaseFirestoreSwift

struct CommentArticle: Identifiable, Codable {
    @DocumentID var id: String?
    var articleID: String
    var text: String
    var timestamp: Date
}


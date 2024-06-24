//
//  CommnetBook.swift
//  HowToLearn
//
//  Created by How on 6/15/24.
//

import Foundation
import FirebaseFirestoreSwift

struct CommentBook: Identifiable, Codable {
    @DocumentID var id: String?
    var bookID: String
    var text: String
    var timestamp: Date
}

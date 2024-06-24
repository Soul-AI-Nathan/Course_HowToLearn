//
//  CommentCourse.swift
//  HowToLearn
//
//  Created by How on 6/15/24.
//

import Foundation
import FirebaseFirestoreSwift

struct CommentCourse: Identifiable, Codable {
    @DocumentID var id: String?
    var courseID: String
    var text: String
    var timestamp: Date
}

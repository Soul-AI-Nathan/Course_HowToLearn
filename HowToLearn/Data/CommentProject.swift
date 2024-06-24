//
//  CommentProject.swift
//  HowToLearn
//
//  Created by How on 6/24/24.
//

import Foundation
import FirebaseFirestoreSwift

struct CommentProject: Identifiable, Codable {
    @DocumentID var id: String?
    var projectID: String
    var text: String
    var timestamp: Date
}

//
//  Project.swift
//  HowToLearn
//
//  Created by How on 6/24/24.
//

import Foundation
import FirebaseFirestoreSwift

struct Project: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var image_url: String
    var project_url: String
    var timestamp: Date
    var takeaways: [String]?
}

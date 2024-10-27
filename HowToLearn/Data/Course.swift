//
//  Course.swift
//  HowToLearn
//
//  Created by How on 6/11/24.
//

import Foundation
import FirebaseFirestoreSwift

struct Course: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var image_url: String
    var course_url: String
    var timestamp: Date
    var takeaways: [String]?
}

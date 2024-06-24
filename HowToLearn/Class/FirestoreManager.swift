//
//  FirestoreManager.swift
//  HowToLearn
//
//  Created by How on 6/15/24.
//

import SwiftUI
import FirebaseFirestore
import Combine
import UserNotifications

class FirestoreManager: ObservableObject {
    @Published var articles = [BlogArticle]()
    @Published var videos = [Video]()
    @Published var books = [Book]()
    @Published var podcasts = [Podcast]()
    @Published var courses = [Course]()
    @Published var projects = [Project]()
    private var db = Firestore.firestore()
    private let defaults = UserDefaults.standard

    init() {
        requestNotificationPermission()
        fetchArticles()
        fetchVideos()
        fetchBooks()
        fetchPodcasts()
        fetchCourses()
        fetchProjects()
    }

    // Request notification permission
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }

    // Fetch articles with a snapshot listener for real-time updates
    func fetchArticles() {
        db.collection("articles").order(by: "timestamp", descending: true).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                let newArticles = querySnapshot?.documents.compactMap { document -> BlogArticle? in
                    try? document.data(as: BlogArticle.self)
                } ?? []
                
                let newArticleIDs = Set(newArticles.compactMap { $0.id })
                self.checkForNewItems(oldIDsKey: "lastKnownArticleIDs", newItems: newArticles, newIDs: newArticleIDs, type: "Article")
                self.articles = newArticles
            }
        }
    }

    func addArticle(_ article: BlogArticle) {
        var newArticle = article
        newArticle.timestamp = Date() // Set the current date and time as the timestamp
        
        do {
            let _ = try db.collection("articles").addDocument(from: newArticle)
        } catch {
            print("Error adding article: \(error)")
        }
    }

    func deleteArticle(article: BlogArticle) {
        guard let articleID = article.id else { return }
        db.collection("articles").document(articleID).delete { error in
            if let error = error {
                print("Error deleting article: \(error.localizedDescription)")
            } else {
                print("Article successfully deleted")
            }
        }
    }

    func addTakeawayToArticle(articleID: String, takeaway: String) {
        let document = db.collection("articles").document(articleID)
        document.updateData([
            "takeaways": FieldValue.arrayUnion([takeaway])
        ]) { error in
            if let error = error {
                print("Error adding takeaway to article: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully added to article")
            }
        }
    }
    
    func removeTakeawayFromArticle(articleID: String, takeaway: String) {
        let document = db.collection("articles").document(articleID)
        document.updateData([
            "takeaways": FieldValue.arrayRemove([takeaway])
        ]) { error in
            if let error = error {
                print("Error removing takeaway: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully removed")
            }
        }
    }

    // Fetch videos with a snapshot listener for real-time updates
    func fetchVideos() {
        db.collection("videos").order(by: "timestamp", descending: true).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                let newVideos = querySnapshot?.documents.compactMap { document -> Video? in
                    try? document.data(as: Video.self)
                } ?? []
                
                let newVideoIDs = Set(newVideos.compactMap { $0.id })
                self.checkForNewItems(oldIDsKey: "lastKnownVideoIDs", newItems: newVideos, newIDs: newVideoIDs, type: "Video")
                self.videos = newVideos
            }
        }
    }
    
    func addVideo(_ video: Video) {
        do {
            _ = try db.collection("videos").addDocument(from: video)
        } catch {
            print("Error adding video: \(error.localizedDescription)")
        }
    }

    func updateVideo(video: Video) {
        guard let videoID = video.id else {
            print("Video ID is nil")
            return
        }

        let document = db.collection("videos").document(videoID)
        document.setData([
            "video_url": video.video_url,
            "title": video.title,
            "headline": video.headline,
            "timestamp": video.timestamp
        ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func deleteVideo(video: Video) {
        guard let videoID = video.id else { return }
        db.collection("videos").document(videoID).delete { error in
            if let error = error {
                print("Error deleting video: \(error.localizedDescription)")
            } else {
                print("Video successfully deleted")
            }
        }
    }

    func addTakeawayToVideo(videoID: String, takeaway: String) {
        let document = db.collection("videos").document(videoID)
        document.updateData([
            "takeaways": FieldValue.arrayUnion([takeaway])
        ]) { error in
            if let error = error {
                print("Error adding takeaway to video: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully added to video")
            }
        }
    }
    
    func removeTakeawayFromVideo(videoID: String, takeaway: String) {
        let document = db.collection("videos").document(videoID)
        document.updateData([
            "takeaways": FieldValue.arrayRemove([takeaway])
        ]) { error in
            if let error = error {
                print("Error removing takeaway: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully removed")
            }
        }
    }

    // Fetch books with a snapshot listener for real-time updates
    func fetchBooks() {
        db.collection("books").order(by: "timestamp", descending: true).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                let newBooks = querySnapshot?.documents.compactMap { document -> Book? in
                    try? document.data(as: Book.self)
                } ?? []
                
                let newBookIDs = Set(newBooks.compactMap { $0.id })
                self.checkForNewItems(oldIDsKey: "lastKnownBookIDs", newItems: newBooks, newIDs: newBookIDs, type: "Book")
                self.books = newBooks
            }
        }
    }

    func addBook(_ book: Book) {
        do {
            _ = try db.collection("books").addDocument(from: book)
        } catch {
            print("Error adding book: \(error.localizedDescription)")
        }
    }

    func updateBook(book: Book) {
        guard let bookID = book.id else {
            print("Book ID is nil")
            return
        }

        let document = db.collection("books").document(bookID)
        document.setData([
            "title": book.title,
            "description": book.description,
            "image_url": book.image_url,
            "book_url": book.book_url,
            "timestamp": book.timestamp
        ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Document successfully updated")
            }
        }
    }
    
    func deleteBook(book: Book) {
        guard let bookID = book.id else { return }
        db.collection("books").document(bookID).delete { error in
            if let error = error {
                print("Error deleting book: \(error.localizedDescription)")
            } else {
                print("Book successfully deleted")
            }
        }
    }

    func addTakeawayToBook(bookID: String, takeaway: String) {
        let document = db.collection("books").document(bookID)
        document.updateData([
            "takeaways": FieldValue.arrayUnion([takeaway])
        ]) { error in
            if let error = error {
                print("Error adding takeaway to book: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully added to book")
            }
        }
    }
    
    func removeTakeawayFromBook(bookID: String, takeaway: String) {
        let document = db.collection("books").document(bookID)
        document.updateData([
            "takeaways": FieldValue.arrayRemove([takeaway])
        ]) { error in
            if let error = error {
                print("Error removing takeaway: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully removed")
            }
        }
    }

    // Fetch podcasts with a snapshot listener for real-time updates
    func fetchPodcasts() {
        db.collection("podcasts").order(by: "timestamp", descending: true).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                let newPodcasts = querySnapshot?.documents.compactMap { document -> Podcast? in
                    try? document.data(as: Podcast.self)
                } ?? []
                
                let newPodcastIDs = Set(newPodcasts.compactMap { $0.id })
                self.checkForNewItems(oldIDsKey: "lastKnownPodcastIDs", newItems: newPodcasts, newIDs: newPodcastIDs, type: "Podcast")
                self.podcasts = newPodcasts
            }
        }
    }
    
    func addPodcast(_ podcast: Podcast) {
        do {
            let _ = try db.collection("podcasts").addDocument(from: podcast)
        } catch {
            print("Error adding podcast: \(error)")
        }
    }

    func updatePodcast(podcast: Podcast) {
        guard let podcastID = podcast.id else {
            print("Podcast ID is nil")
            return
        }

        let document = db.collection("podcasts").document(podcastID)
        document.setData([
            "title": podcast.title,
            "description": podcast.description,
            "image_url": podcast.image_url,
            "podcast_url": podcast.podcast_url,
            "timestamp": podcast.timestamp
        ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Document successfully updated")
            }
        }
    }

    func deletePodcast(podcast: Podcast) {
        guard let podcastID = podcast.id else { return }
        db.collection("podcasts").document(podcastID).delete { error in
            if let error = error {
                print("Error deleting podcast: \(error.localizedDescription)")
            } else {
                print("Podcast successfully deleted")
            }
        }
    }

    func addTakeawayToPodcast(podcastID: String, takeaway: String) {
        let document = db.collection("podcasts").document(podcastID)
        document.updateData([
            "takeaways": FieldValue.arrayUnion([takeaway])
        ]) { error in
            if let error = error {
                print("Error adding takeaway to podcast: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully added to podcast")
            }
        }
    }
    
    func removeTakeawayFromPodcast(podcastID: String, takeaway: String) {
        let document = db.collection("podcasts").document(podcastID)
        document.updateData([
            "takeaways": FieldValue.arrayRemove([takeaway])
        ]) { error in
            if let error = error {
                print("Error removing takeaway: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully removed")
            }
        }
    }

    // Fetch courses with a snapshot listener for real-time updates
    func fetchCourses() {
        db.collection("courses").order(by: "timestamp", descending: true).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                let newCourses = querySnapshot?.documents.compactMap { document -> Course? in
                    try? document.data(as: Course.self)
                } ?? []
                
                let newCourseIDs = Set(newCourses.compactMap { $0.id })
                self.checkForNewItems(oldIDsKey: "lastKnownCourseIDs", newItems: newCourses, newIDs: newCourseIDs, type: "Course")
                self.courses = newCourses
            }
        }
    }

    func addCourse(_ course: Course) {
        do {
            let _ = try db.collection("courses").addDocument(from: course)
        } catch {
            print("Error adding course: \(error)")
        }
    }

    func updateCourse(course: Course) {
        guard let courseID = course.id else {
            print("Course ID is nil")
            return
        }

        let document = db.collection("courses").document(courseID)
        document.setData([
            "title": course.title,
            "description": course.description,
            "image_url": course.image_url,
            "course_url": course.course_url,
            "timestamp": course.timestamp
        ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Document successfully updated")
            }
        }
    }

    func deleteCourse(course: Course) {
        guard let courseID = course.id else { return }
        db.collection("courses").document(courseID).delete { error in
            if let error = error {
                print("Error deleting course: \(error.localizedDescription)")
            } else {
                print("Course successfully deleted")
            }
        }
    }

    func addTakeawayToCourse(courseID: String, takeaway: String) {
        let document = db.collection("courses").document(courseID)
        document.updateData([
            "takeaways": FieldValue.arrayUnion([takeaway])
        ]) { error in
            if let error = error {
                print("Error adding takeaway to course: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully added to course")
            }
        }
    }
    
    func removeTakeawayFromCourse(courseID: String, takeaway: String) {
        let document = db.collection("courses").document(courseID)
        document.updateData([
            "takeaways": FieldValue.arrayRemove([takeaway])
        ]) { error in
            if let error = error {
                print("Error removing takeaway: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully removed")
            }
        }
    }
    
    // Fetch projects with a snapshot listener for real-time updates
    func fetchProjects() {
        db.collection("projects").order(by: "timestamp", descending: true).addSnapshotListener { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                let newProjects = querySnapshot?.documents.compactMap { document -> Project? in
                    try? document.data(as: Project.self)
                } ?? []
                
                let newProjectIDs = Set(newProjects.compactMap { $0.id })
                self.checkForNewItems(oldIDsKey: "lastKnownProjectIDs", newItems: newProjects, newIDs: newProjectIDs, type: "Project")
                self.projects = newProjects
            }
        }
    }

    func addProject(_ project: Project) {
        do {
            let _ = try db.collection("projects").addDocument(from: project)
        } catch {
            print("Error adding project: \(error)")
        }
    }

    func updateProject(project: Project) {
        guard let projectID = project.id else {
            print("Project ID is nil")
            return
        }

        let document = db.collection("projects").document(projectID)
        document.setData([
            "title": project.title,
            "description": project.description,
            "image_url": project.image_url,
            "project_url": project.project_url,
            "timestamp": project.timestamp
        ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Document successfully updated")
            }
        }
    }

    func deleteProject(project: Project) {
        guard let projectID = project.id else { return }
        db.collection("projects").document(projectID).delete { error in
            if let error = error {
                print("Error deleting project: \(error.localizedDescription)")
            } else {
                print("Project successfully deleted")
            }
        }
    }

    func addTakeawayToProject(projectID: String, takeaway: String) {
        let document = db.collection("projects").document(projectID)
        document.updateData([
            "takeaways": FieldValue.arrayUnion([takeaway])
        ]) { error in
            if let error = error {
                print("Error adding takeaway to project: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully added to project")
            }
        }
    }

    func removeTakeawayFromProject(projectID: String, takeaway: String) {
        let document = db.collection("projects").document(projectID)
        document.updateData([
            "takeaways": FieldValue.arrayRemove([takeaway])
        ]) { error in
            if let error = error {
                print("Error removing takeaway: \(error.localizedDescription)")
            } else {
                print("Takeaway successfully removed")
            }
        }
    }

    private func checkForNewItems<T: Identifiable & Equatable>(oldIDsKey: String, newItems: [T], newIDs: Set<String>, type: String) {
        let oldIDs = defaults.stringArray(forKey: oldIDsKey) ?? []
        let addedIDs = newIDs.subtracting(Set(oldIDs))
        if !addedIDs.isEmpty {
            for id in addedIDs {
                if let newItem = newItems.first(where: { $0.id as? String == id }) {
                    sendNotification(for: newItem, type: type)
                }
            }
            defaults.set(Array(newIDs), forKey: oldIDsKey)
        }
    }
    
    private func sendNotification<T: Identifiable & Equatable>(for item: T, type: String) {
        let content = UNMutableNotificationContent()
        content.title = "New \(type) Added"
        content.body = (item as? BlogArticle)?.title ?? (item as? Video)?.title ?? (item as? Book)?.title ?? (item as? Podcast)?.title ?? (item as? Course)?.title ?? "New \(type)"
        content.sound = .default
        
        // Create the URL for the notification
        var urlComponents = URLComponents()
        urlComponents.scheme = "howtolearn"
        urlComponents.host = type.lowercased()
        if let id = item.id as? String {
            urlComponents.queryItems = [URLQueryItem(name: "id", value: id)]
        }
        
        if let url = urlComponents.url {
            content.userInfo = ["url": url.absoluteString]
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error adding notification: \(error)")
            }
        }
    }
}


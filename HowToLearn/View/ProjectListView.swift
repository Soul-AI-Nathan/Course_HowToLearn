//
//  ProjectListView.swift
//  HowToLearn
//
//  Created by How on 6/24/24.
//

import SwiftUI
import SwiftSoup
import FirebaseFirestore

struct ProjectListView: View {
    let project: Project
    @State private var isLoading = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if isLoading {
                ProgressView()
                    .frame(width: 160, height: 90)
            } else {
                if let url = URL(string: project.image_url) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 160, height: 90)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(project.title)
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.accentColor)

                Text(project.description)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .padding(.trailing, 8)
            }
        }
        .onAppear {
            if project.title.isEmpty || project.description.isEmpty || project.image_url.isEmpty {
                fetchAndUpdateProjectDetails()
            }
        }
    }

    private func fetchAndUpdateProjectDetails() {
        fetchProjectDetails { title, description, imageUrl in
            if let title = title, let description = description, let imageUrl = imageUrl {
                sendProjectToOpenAIAPI(title: title, description: description) { chineseTitle, chineseDescription in
                    let finalTitle = chineseTitle ?? title
                    let finalDescription = chineseDescription ?? description
                    updateProjectInDatabase(title: finalTitle, description: finalDescription, imageUrl: imageUrl)
                }
            }
        }
    }

    private func fetchProjectDetails(completion: @escaping (String?, String?, String?) -> Void) {
        guard let url = URL(string: project.project_url) else {
            completion(nil, nil, nil)
            return
        }

        isLoading = true

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                completion(nil, nil, nil)
                return
            }

            if let html = String(data: data, encoding: .utf8) {
                parseHTML(html, completion: completion)
            } else {
                DispatchQueue.main.async {
                    isLoading = false
                }
                completion(nil, nil, nil)
            }
        }.resume()
    }

    private func parseHTML(_ html: String, completion: @escaping (String?, String?, String?) -> Void) {
        do {
            let document = try SwiftSoup.parse(html)
            
            // Extract image URL
            let imgUrl = try document.select("meta[property=og:image]").first()?.attr("content")
            
            // Extract title
            let title = try document.select("title").first()?.text()
            
            // Extract description from meta tag
            let description = try document.select("meta[name=description]").first()?.attr("content")

            DispatchQueue.main.async {
                completion(title, description, imgUrl)
                isLoading = false
            }
        } catch {
            print("Error parsing HTML: \(error)")
            DispatchQueue.main.async {
                isLoading = false
            }
            completion(nil, nil, nil)
        }
    }

    private func updateProjectInDatabase(title: String, description: String, imageUrl: String) {
        let db = Firestore.firestore()
        guard let projectID = project.id else {
            print("Project ID is nil")
            return
        }

        let document = db.collection("projects").document(projectID)
        document.updateData([
            "title": title,
            "description": description,
            "image_url": imageUrl
        ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Document successfully updated with project details")
            }
        }
    }

    private func sendProjectToOpenAIAPI(title: String, description: String, completion: @escaping (String?, String?) -> Void) {
        let apiUrl = "https://api.openai.com/v1/chat/completions"
        guard let url = URL(string: apiUrl) else {
            print("Invalid API URL")
            completion(nil, nil)
            return
        }

        guard let apiKey = loadAPIKey() else {
            fatalError("API Key is missing or invalid")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let prompt = """
        给定以下项目的标题和描述，生成一个中文短标题（不超过10个中文字），并总结描述为不超过200个中文字的中文标题。
        标题: \(title)
        描述: \(description)
        输出JSON格式为: {"title": "短标题", "headline": "标题"}
        """

        let payload: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are an assistant that translates and summarizes text to Chinese."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 300
        ]

        do {
            let httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.httpBody = httpBody
        } catch {
            print("Failed to serialize payload: \(error.localizedDescription)")
            completion(nil, nil)
            return
        }

        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("API Request error: \(error.localizedDescription)")
                completion(nil, nil)
                return
            }

            guard let data = data else {
                print("No data received")
                completion(nil, nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String,
                   let responseData = content.data(using: .utf8),
                   let jsonResponse = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: String] {
                    let shortTitle = jsonResponse["title"]
                    let headline = jsonResponse["headline"]
                    DispatchQueue.main.async {
                        completion(shortTitle, headline)
                    }
                } else {
                    print("Could not parse the response")
                    DispatchQueue.main.async {
                        completion(nil, nil)
                    }
                }
            } catch {
                print("Error decoding response: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil, nil)
                }
            }
        }.resume()
    }
}

#Preview {
    ProjectListView(project: Project(id: "1", title: "", description: "", image_url: "", project_url: "https://github.com/BasedHardware/OpenGlass", timestamp: Date()))
}

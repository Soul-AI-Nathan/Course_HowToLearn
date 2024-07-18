//
//  VideoListView.swift
//  HowToLearn
//
//  Created by How on 6/8/24.
//

import Foundation
import SwiftUI
import YouTubePlayerKit
import Firebase

struct VideoListView: View {
    // MARK: - PROPERTIES
    let video: Video

    // MARK: - BODY
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let thumbnailURL = getYouTubeThumbnailURL(for: video.video_url) {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 160, height: 90)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    case .failure:
                        Image(systemName: "xmark.circle")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 90)
                            .foregroundColor(.red)
                    @unknown default:
                        EmptyView()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(video.title)
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.accentColor)

                Text(video.headline)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .padding(.trailing, 8)
            }
        }
        .onAppear {
            if video.title.isEmpty || video.headline.isEmpty {
                guard let videoID = extractYouTubeID(from: video.video_url) else { return }
                fetchYouTubeVideoDetails(videoID: videoID) { title, description in
                    guard let title = title, let description = description else { return }
                    
                    sendVideoToOpenAIAPI(title: title, description: description) { shortTitle, headline in
                        guard let shortTitle = shortTitle, let headline = headline else { return }
                        
                        updateVideoInFirebase(videoID: video.id ?? "", title: shortTitle, headline: headline)
                    }
                }
            }
        }
    }
    
    private func getYouTubeThumbnailURL(for videoURL: String) -> URL? {
        guard let videoID = extractYouTubeID(from: videoURL) else {
            return nil
        }
        return URL(string: "https://img.youtube.com/vi/\(videoID)/hqdefault.jpg")
    }

    private func extractYouTubeID(from url: String) -> String? {
        guard let url = URL(string: url),
              let host = url.host, host.contains("youtube.com") || host.contains("youtu.be") else {
            return nil
        }

        if host.contains("youtu.be") {
            return url.pathComponents.dropFirst().first
        } else if host.contains("youtube.com") {
            return URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "v" })?
                .value
        }
        return nil
    }
}

#Preview {
    VideoListView(video: Video(id: "1", title: "", headline: "", video_url: "https://www.youtube.com/watch?v=VIDEO_ID", timestamp: Date()))
}

func loadAPIKeyGoogle() -> String? {
    if let path = Bundle.main.path(forResource: "config", ofType: "xcprivacy") {
        print("Found config.plist at path: \(path)")
        if let config = NSDictionary(contentsOfFile: path) {
            if let apiKey = config["GOOGLE_API_KEY"] as? String {
                print("API Key loaded successfully")
                return apiKey
            } else {
                print("API Key not found in config.plist")
            }
        } else {
            print("Failed to read config.plist")
        }
    } else {
        print("config.plist not found in bundle")
    }
    return nil
}

func fetchYouTubeVideoDetails(videoID: String, completion: @escaping (String?, String?) -> Void) {
    guard let apiKey = loadAPIKeyGoogle() else {
        fatalError("API Key is missing or invalid")
    }
    let apiUrl = "https://www.googleapis.com/youtube/v3/videos?id=\(videoID)&key=\(apiKey)&part=snippet"

    guard let url = URL(string: apiUrl) else {
        print("Invalid API URL")
        completion(nil, nil)
        return
    }

    let request = URLRequest(url: url)
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
               let items = json["items"] as? [[String: Any]],
               let snippet = items.first?["snippet"] as? [String: Any],
               let title = snippet["title"] as? String,
               let description = snippet["description"] as? String {
                DispatchQueue.main.async {
                    completion(title, description)
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

func sendVideoToOpenAIAPI(title: String, description: String, completion: @escaping (String?, String?) -> Void) {
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
    给定以下视频的标题和描述，生成一个中文短标题（不超过5个中文字），并总结描述为不超过100个中文字的中文标题。
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

func updateVideoInFirebase(videoID: String, title: String, headline: String) {
    let db = Firestore.firestore()
    let document = db.collection("videos").document(videoID)

    document.updateData([
        "title": title,
        "headline": headline
    ]) { error in
        if let error = error {
            print("Error updating document: \(error.localizedDescription)")
        } else {
            print("Document successfully updated with new title and headline")
        }
    }
}

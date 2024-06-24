//
//  PodcastListView.swift
//  HowToLearn
//
//  Created by How on 6/9/24.
//

import SwiftUI
import SwiftSoup
import FirebaseFirestore

struct PodcastListView: View {
    let podcast: Podcast
    @State private var isLoading = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if isLoading {
                ProgressView()
                    .frame(width: 90, height: 90)
            } else {
                if let url = URL(string: podcast.image_url) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(radius: 5)
                    } placeholder: {
                        ProgressView()
                            .frame(width: 90, height: 90)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(podcast.title)
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.accentColor)

                Text(podcast.description)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .padding(.trailing, 8)
            }
        }
        .onAppear {
            if podcast.title.isEmpty || podcast.description.isEmpty || podcast.image_url.isEmpty {
                fetchAndUpdatePodcastDetails()
            }
        }
    }

    private func fetchAndUpdatePodcastDetails() {
        fetchPodcastDetails { title, description, imageUrl in
            if let title = title, let description = description, let imageUrl = imageUrl {
                updatePodcastInDatabase(title: title, description: description, imageUrl: imageUrl)
            }
        }
    }

    private func fetchPodcastDetails(completion: @escaping (String?, String?, String?) -> Void) {
        guard let url = URL(string: podcast.podcast_url) else {
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
            let title = try document.select("meta[property=og:title]").first()?.attr("content")
            
            // Extract description from JSON-LD
            if let scriptElement = try document.select("script[type=application/ld+json]").first() {
                let jsonString = try scriptElement.html()
                if let data = jsonString.data(using: .utf8) {
                    let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    let description = jsonObject?["description"] as? String
                    
                    DispatchQueue.main.async {
                        completion(title, description, imgUrl)
                        isLoading = false
                    }
                    return
                }
            }
            
            // Fallback in case the JSON-LD parsing fails
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


    private func updatePodcastInDatabase(title: String, description: String, imageUrl: String) {
        let db = Firestore.firestore()
        guard let podcastID = podcast.id else {
            print("Podcast ID is nil")
            return
        }

        let document = db.collection("podcasts").document(podcastID)
        document.updateData([
            "title": title,
            "description": description,
            "image_url": imageUrl
        ]) { error in
            if let error = error {
                print("Error updating document: \(error.localizedDescription)")
            } else {
                print("Document successfully updated with podcast details")
            }
        }
    }
}

#Preview {
    PodcastListView(podcast: Podcast(id: "1", title: "", description: "", image_url: "", podcast_url: "https://www.xiaoyuzhoufm.com/episode/665faf066488b5dec3b8b28d", timestamp: Date()))
}

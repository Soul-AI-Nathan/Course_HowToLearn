//
//  ArticleListView.swift
//  HowToLearn
//
//  Created by How on 6/8/24.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct ArticleListView: View {
    // MARK: - PROPERTIES
    let article: BlogArticle
    @State private var imageUrl: String? = nil
    @State private var isLoadingImage = false

    // MARK: - BODY
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let imageUrl = imageUrl, !isLoadingImage {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )
                    } else if phase.error != nil {
                        Color.red
                            .frame(width: 90, height: 90)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12)
                            )
                    } else {
                        ProgressView()
                            .frame(width: 90, height: 90)
                    }
                }
            } else {
                ProgressView()
                    .frame(width: 90, height: 90)
                    .onAppear {
                        loadImage()
                    }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.title3)
                    .fontWeight(.heavy)
                    .foregroundColor(.accentColor)

                Text(article.content)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .padding(.trailing, 8)
            } //: VSTACK
        } //: HSTACK
    }

    private func loadImage() {
        isLoadingImage = true
        let db = Firestore.firestore()
        if let articleID = article.id {
            let document = db.collection("articles").document(articleID)
            document.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    if let url = snapshot.data()?["imageUrl"] as? String {
                        imageUrl = url
                        isLoadingImage = false
                    } else {
                        // Generate image
                        sendArticleToOpenAIAPI(article: article) { prompt in
                            guard let prompt = prompt else {
                                isLoadingImage = false
                                return
                            }
                            generateImageWithDALLE(prompt: prompt, for: article) { url in
                                imageUrl = url
                                isLoadingImage = false
                            }
                        }
                    }
                } else {
                    isLoadingImage = false
                    print("Document does not exist or error: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
}

// Loading API Key from config.plist
func loadAPIKey() -> String? {
    if let path = Bundle.main.path(forResource: "config", ofType: "xcprivacy") {
        print("Found config.plist at path: \(path)")
        if let config = NSDictionary(contentsOfFile: path) {
            if let apiKey = config["OPENAI_API_KEY"] as? String {
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


func sendArticleToOpenAIAPI(article: BlogArticle, completion: @escaping (String?) -> Void) {
    let apiUrl = "https://api.openai.com/v1/chat/completions"
    guard let url = URL(string: apiUrl) else {
        print("Invalid API URL")
        completion(nil)
        return
    }

    guard let apiKey = loadAPIKey() else {
        fatalError("API Key is missing or invalid")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    let payload: [String: Any] = [
        "model": "gpt-4",
        "messages": [
            [
                "role": "system",
                "content": "Generate a DALL-E prompt based on the following article content to transfer this article content to a fantastical image."
            ],
            [
                "role": "user",
                "content": article.content
            ]
        ],
        "max_tokens": 300
    ]

    do {
        let httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        request.httpBody = httpBody
    } catch {
        print("Failed to serialize payload: \(error.localizedDescription)")
        completion(nil)
        return
    }

    let session = URLSession.shared
    session.dataTask(with: request) { data, response, error in
        if let error = error {
            print("API Request error: \(error.localizedDescription)")
            completion(nil)
            return
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let data = data else {
            print("API Request failed with response: \(String(describing: response))")
            completion(nil)
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                DispatchQueue.main.async {
                    completion(content) // Use the completion handler to return the content
                }
            } else {
                print("Could not parse the response")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        } catch {
            print("Error decoding response: \(error.localizedDescription)")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }.resume()
}


func generateImageWithDALLE(prompt: String, for article: BlogArticle, completion: @escaping (String?) -> Void) {
    let apiUrl = "https://api.openai.com/v1/images/generations"
    guard let url = URL(string: apiUrl) else {
        print("Invalid API URL")
        completion(nil)
        return
    }

    guard let apiKey = loadAPIKey() else {
        fatalError("API Key is missing or invalid")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

    let payload: [String: Any] = [
        "model": "dall-e-3",
        "prompt": prompt,
        "n": 1,
        "size": "1024x1024"
    ]

    guard let httpBody = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
        print("Failed to serialize payload")
        completion(nil)
        return
    }
    request.httpBody = httpBody

    let session = URLSession.shared
    session.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error making the request: \(error.localizedDescription)")
            completion(nil)
            return
        }

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Error with the HTTP response.")
            completion(nil)
            return
        }

        guard let data = data else {
            print("Error: No data received.")
            completion(nil)
            return
        }

        do {
            let decoder = JSONDecoder()
            let dalleResponse = try decoder.decode(DALLEResponse.self, from: data)
            if let firstImageUrl = dalleResponse.data.first?.url {
                // Download the image from the DALL-E URL
                downloadImage(from: firstImageUrl) { downloadedImageData in
                    guard let imageData = downloadedImageData else {
                        completion(nil)
                        return
                    }

                    // Upload the image to Firebase Storage
                    uploadImageToFirebaseStorage(imageData: imageData, for: article) { firebaseImageUrl in
                        guard let firebaseImageUrl = firebaseImageUrl else {
                            completion(nil)
                            return
                        }

                        // Store the Firebase Storage URL in Firestore
                        let db = Firestore.firestore()
                        if let articleID = article.id {
                            let document = db.collection("articles").document(articleID)
                            document.updateData(["imageUrl": firebaseImageUrl]) { error in
                                if let error = error {
                                    print("Error updating document: \(error.localizedDescription)")
                                } else {
                                    print("Document successfully updated with image URL")
                                }
                                DispatchQueue.main.async {
                                    completion(firebaseImageUrl)
                                }
                            }
                        }
                    }
                }
            } else {
                print("No images were returned.")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        } catch {
            print("Error decoding DALL-E response: \(error)")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }.resume()
}

func downloadImage(from url: String, completion: @escaping (Data?) -> Void) {
    guard let imageUrl = URL(string: url) else {
        completion(nil)
        return
    }

    let session = URLSession.shared
    session.dataTask(with: imageUrl) { data, response, error in
        if let error = error {
            print("Error downloading image: \(error.localizedDescription)")
            completion(nil)
            return
        }

        guard let data = data else {
            print("Error: No image data received.")
            completion(nil)
            return
        }

        completion(data)
    }.resume()
}

func uploadImageToFirebaseStorage(imageData: Data, for article: BlogArticle, completion: @escaping (String?) -> Void) {
    let storage = Storage.storage()
    let storageRef = storage.reference()
    let articleImageRef = storageRef.child("articles/\(article.id ?? UUID().uuidString).jpg")

    let metadata = StorageMetadata()
    metadata.contentType = "image/jpeg"

    articleImageRef.putData(imageData, metadata: metadata) { metadata, error in
        if let error = error {
            print("Error uploading image: \(error.localizedDescription)")
            completion(nil)
            return
        }

        articleImageRef.downloadURL { url, error in
            if let error = error {
                print("Error getting download URL: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let downloadUrl = url else {
                print("Error: No download URL found.")
                completion(nil)
                return
            }

            completion(downloadUrl.absoluteString)
        }
    }
}


struct DALLEResponse: Decodable {
    struct ImageData: Decodable {
        let url: String
    }

    let data: [ImageData]
}

#Preview {
    ArticleListView(article: BlogArticle(id: "1", title: "Sample Title", content: "Sample content for the article.", timestamp: Date()))
}

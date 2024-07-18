//
//  AudioModel.swift
//  HowToLearn
//
//  Created by How on 7/14/24.
//

import AVFoundation
import Foundation
import Observation
import XCAOpenAIClient
import UIKit

@Observable
class AudioModel: NSObject, AVAudioRecorderDelegate,  AVAudioPlayerDelegate, ObservableObject {

    let client: OpenAIClient
    var audioPlayer: AVAudioPlayer!
    var audioReorder: AVAudioRecorder!
    #if !os(macOS)
    var recordingSession = AVAudioSession.sharedInstance()
    #endif
    var animationTimer: Timer?
    var recordingTimer: Timer?
    var audioPower = 0.0
    var prevAudioPower: Double?
    var processingSpeechTask: Task<Void, Never>?
    var processingImageTask: Task<Void, Never>? // Add a task for processing image
    
    var selectedVoice = VoiceType.alloy
    var assistantPrompt: String
    
    var captureURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("recording.m4a")
    }
    
    var state = VoiceChatState.idle {
        didSet { print(state)}
    }
    var isIdle: Bool {
        if case .idle = state {
            return true
        }
        return false
    }

    var siriWaveFormOpacity: CGFloat {
        switch state {
        case .recordingSpeech, .playingSpeech: return 1
        default: return 0
        }
    }
    
    init(assistantPrompt: String = "You are an AI assistant, named Soul AI.", selectedVoice: VoiceType = .alloy) {
        guard let apiKey = AudioModel.loadAPIKey() else {
            fatalError("API Key is missing or invalid")
        }
                
        self.client = OpenAIClient(apiKey: apiKey)
        self.assistantPrompt = assistantPrompt
        self.selectedVoice = selectedVoice
        super.init()
        #if !os(macOS)
        do {
            #if os(iOS)
            try recordingSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            #else
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            #endif
            try recordingSession.setActive(true)
            
            AVAudioApplication.requestRecordPermission { [unowned self] allowed in
                if !allowed {
                    self.state = .error("Recording not allowed by user")
                }
            }
        } catch {
            state = .error(error)
        }
        #endif
    }
    
    static func loadAPIKey() -> String? {
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
    
    func sendImageToOpenAIAPI(image: UIImage? = nil, userMessage: String? = nil, completion: @escaping (String?) -> Void) {
        guard let apiKey = AudioModel.loadAPIKey() else {
            fatalError("API Key is missing or invalid")
        }

        let apiUrl = "https://api.openai.com/v1/chat/completions"
        var request = URLRequest(url: URL(string: apiUrl)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        if let userMessage = userMessage {
            conversationHistory.append([
                "role": "user",
                "content": userMessage
            ])
        }

        if let image = image, let imageData = image.jpegData(compressionQuality: 0.8) {
            let base64Image = imageData.base64EncodedString()
            conversationHistory.append([
                "role": "user",
                "content": [
                    ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]]
                ]
            ])
        }

        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": conversationHistory,
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
                        conversationHistory.append([
                            "role": "assistant",
                            "content": content
                        ])
                        completion(content)
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
    
    func processImageTask(image: UIImage) -> Task<Void, Never> {
        Task { @MainActor [unowned self] in
            do {
                self.state = .processingSpeech
                let responseText = try await withCheckedThrowingContinuation { continuation in
                    sendImageToOpenAIAPI(image: image) { response in
                        if let response = response {
                            continuation.resume(returning: response)
                        } else {
                            continuation.resume(throwing: NSError(domain: "AIProcessingError", code: 1, userInfo: nil))
                        }
                    }
                }
                
                try Task.checkCancellation()
                let data = try await client.generateSpeechFrom(input: responseText, voice:
                        .init(rawValue: selectedVoice.rawValue) ?? .alloy)
                
                try Task.checkCancellation()
                try self.playAudio(data: data)
            } catch {
                if Task.isCancelled { return }
                state = .error(error)
                resetValues()
            }
        }
    }


    func startCaptureAudio() {
        resetValues()
        state = .recordingSpeech
        do {
            audioReorder = try AVAudioRecorder(url: captureURL, settings: [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                ])
            audioReorder.isMeteringEnabled = true
            audioReorder.delegate = self
            audioReorder.record()
            
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [unowned self]_ in
                guard self.audioReorder != nil else { return }
                self.audioReorder.updateMeters()
                let power = min(1, max(0, 1 - abs(Double(self.audioReorder.averagePower(forChannel: 0)) / 50 )))
                self.audioPower = power
            })
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.6, repeats: true, block: { [unowned self]_ in
                guard self.audioReorder != nil else { return }
                self.audioReorder.updateMeters()
                let power = min(1, max(0, 1 - abs(Double(self.audioReorder.averagePower(forChannel: 0)) / 50 )))
                if self.prevAudioPower == nil {
                    self.prevAudioPower = power
                    return
                }
                if let prevAudioPower = self.prevAudioPower, prevAudioPower < 0.25 && power < 0.175 {
                    self.finishCaptureAudio()
                    return
                }
                self.prevAudioPower = power
            })
            
        } catch {
            resetValues()
            state = .error(error)
        }
    }
    
    func finishCaptureAudio() {
        resetValues()
        do {
            let data = try Data(contentsOf: captureURL)
            processingSpeechTask = processSpeechTask(audioData: data)
        } catch {
            state = .error(error)
            resetValues()
        }
        
    }
    
    func processSpeechTask(audioData: Data) -> Task<Void, Never> {
        Task { @MainActor [unowned self] in
            do {
                self.state = .processingSpeech
                let userMessage = try await client.generateAudioTransciptions(audioData: audioData)
                
                try Task.checkCancellation()
                let responseText = try await withCheckedThrowingContinuation { continuation in
                    sendImageToOpenAIAPI(userMessage: userMessage) { response in
                        if let response = response {
                            continuation.resume(returning: response)
                        } else {
                            continuation.resume(throwing: NSError(domain: "AIProcessingError", code: 1, userInfo: nil))
                        }
                    }
                }

                try Task.checkCancellation()
                let data = try await client.generateSpeechFrom(input: responseText, voice:
                        .init(rawValue: selectedVoice.rawValue) ?? .alloy)
                
                try Task.checkCancellation()
                try self.playAudio(data: data)
            } catch {
                if Task.isCancelled { return }
                state = .error(error)
                resetValues()
            }
        }
    }
    
    
    func playAudio(data: Data) throws {
        self.state = .playingSpeech
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer.enableRate = true // Enable rate adjustment
        audioPlayer.rate = 1.25 // Set playback speed to 1.25x
        audioPlayer.isMeteringEnabled = true
        audioPlayer.delegate = self
        audioPlayer.play()
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true, block: { [unowned self]_ in
            guard self.audioPlayer != nil else { return }
            self.audioPlayer.updateMeters()
            let power = min(1, max(0, 1 - abs(Double(self.audioPlayer.averagePower(forChannel: 0)) / 160 )))
            self.audioPower = power
        })
    }
    
    func cancelRecording() {
        resetValues()
        state = .idle
    }
    
    func cancelProcessingTask() {
        processingSpeechTask?.cancel()
        processingSpeechTask = nil
        processingImageTask?.cancel() // Cancel image processing task if needed
        processingImageTask = nil
        resetValues()
        state = .idle
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            resetValues()
            state = .idle
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        resetValues()
        state = .idle
    }
    
    func resetValues() {
        audioPower = 0
        prevAudioPower = nil
        audioReorder?.stop()
        audioReorder = nil
        audioPlayer?.stop()
        audioPlayer = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

var conversationHistory: [[String: Any]] = [
    [
        "role": "system",
        "content": "You are an assistant that helps users understand the content on the screen from a learning app. Please use the screen content to understand the details and concepts, and be ready to answer any questions the user might have. Respond in Chinese. Start with questions to ask the user how you can help them understand the content inside of this page. Keep the interaction with the user conversational and stimulate interest and fun for them to learn more. Generate response less than 150 words and keep response concise, fun and conversational like friends talking."
    ]
]

func clearConversationHistory() {
    conversationHistory = [
        [
            "role": "system",
            "content": "You are an assistant that helps users understand the content on the screen from a learning app. Please use the screen content to understand the details and concepts, and be ready to answer any questions the user might have. Respond in Chinese. Start with questions to ask the user how you can help them understand the content inside of this page. Keep the interaction with the user conversational and stimulate interest and fun for them to learn more. Generate response less than 150 words and keep response concise, fun and conversational like friends talking."
        ]
    ]
}

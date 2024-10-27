//
//  AudioPlayerView.swift
//  HowToLearn
//
//  Created by How on 7/6/24.
//

import SwiftUI
import AVFoundation

struct AudioPlayerView: View {
    let audioURL: URL
    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0.0
    @State private var duration: Double = 0.0

    private var timeFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }

    var body: some View {
        VStack {
            HStack {
                Text(timeFormatter.string(from: currentTime) ?? "0:00")
                    .font(.footnote)

                // Updated Slider to handle invalid duration gracefully
                Slider(value: $currentTime, in: 0...(duration > 0 ? duration : 1), onEditingChanged: sliderEditingChanged)

                Text(timeFormatter.string(from: duration) ?? "0:00")
                    .font(.footnote)
            }

            HStack {
                Button(action: skipBackward) {
                    Image(systemName: "gobackward.15")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding()
                }

                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .padding()
                }

                Button(action: skipForward) {
                    Image(systemName: "goforward.30")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding()
                }
            }
        }
        .padding()
        .onAppear(perform: setupAudioPlayer)
        .onDisappear(perform: stopAudioPlayer) // Stop audio when view disappears
    }

    private func setupAudioPlayer() {
        // Set up the audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up AVAudioSession: \(error)")
        }

        let playerItem = AVPlayerItem(url: audioURL)
        audioPlayer = AVPlayer(playerItem: playerItem)

        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = CMTimeGetSeconds(time)
            
            // Ensure we handle indefinite duration or invalid value gracefully
            let durationInSeconds = CMTimeGetSeconds(playerItem.duration)
            if durationInSeconds > 0 {
                duration = durationInSeconds
            } else {
                duration = 0
            }
        }
    }

    private func togglePlayPause() {
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }

    private func skipBackward() {
        let currentTime = audioPlayer?.currentTime() ?? CMTime.zero
        let newTime = CMTimeGetSeconds(currentTime) - 15.0
        audioPlayer?.seek(to: CMTime(seconds: max(newTime, 0), preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    private func skipForward() {
        let currentTime = audioPlayer?.currentTime() ?? CMTime.zero
        let newTime = CMTimeGetSeconds(currentTime) + 30.0
        audioPlayer?.seek(to: CMTime(seconds: min(newTime, duration), preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
    }

    private func sliderEditingChanged(_ editingStarted: Bool) {
        if editingStarted {
            audioPlayer?.pause()
        } else {
            let targetTime = CMTime(seconds: currentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            audioPlayer?.seek(to: targetTime) { _ in
                if isPlaying {
                    audioPlayer?.play()
                }
            }
        }
    }

    private func stopAudioPlayer() {
        audioPlayer?.pause()
        audioPlayer = nil
        isPlaying = false
    }
}

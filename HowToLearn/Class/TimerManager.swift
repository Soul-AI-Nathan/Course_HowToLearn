//
//  TimerManager.swift
//  HowToLearn
//
//  Created by How on 7/12/24.
//

import Foundation
import Combine
import SwiftUI

class TimerManager: ObservableObject {
    @Published var totalElapsedTime: TimeInterval = 0
    private var startTime: Date?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    var formattedElapsedTime: String {
        let hours = Int(totalElapsedTime) / 3600
        let minutes = (Int(totalElapsedTime) % 3600) / 60
        let seconds = Int(totalElapsedTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    init() {
        setupScenePhaseObserver()
    }

    func startTimer() {
        guard timer == nil else { return }
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateElapsedTime()
        }
    }

    func pauseTimer() {
        guard let startTime = startTime else { return }
        totalElapsedTime += Date().timeIntervalSince(startTime)
        stopTimer()
    }

    func resumeTimer() {
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.updateElapsedTime()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        startTime = nil
    }

    private func updateElapsedTime() {
        guard let startTime = startTime else { return }
        totalElapsedTime += Date().timeIntervalSince(startTime)
        self.startTime = Date()
    }

    private func setupScenePhaseObserver() {
        NotificationCenter.default.publisher(for: UIScene.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.pauseTimer() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)
            .sink { [weak self] _ in self?.resumeTimer() }
            .store(in: &cancellables)
    }
}

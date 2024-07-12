//
//  TimerView.swift
//  HowToLearn
//
//  Created by How on 7/11/24.
//

import SwiftUI

struct TimerViewModifier: ViewModifier {
    @EnvironmentObject var timerManager: TimerManager

    func body(content: Content) -> some View {
        VStack {
            Text("Time spent: \(timerManager.formattedElapsedTime)")
            content
        }
        .onAppear {
            timerManager.startTimer()
        }
    }
}

extension View {
    func withTimer() -> some View {
        self.modifier(TimerViewModifier())
    }
}

//
//  AIAudioView.swift
//  HowToLearn
//
//  Created by How on 7/14/24.
//

import SwiftUI
import UIKit
import SiriWaveView

struct AIAudioView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State var am = AudioModel()
    @State var isSymbolAnimating = false
    @State var inputDidFail: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("How学")
                .font(.title2)
            
            Spacer()
            SiriWaveView()
                .power(power: am.audioPower)
                .opacity(am.siriWaveFormOpacity)
                .frame(height: 256)
                .overlay { overlayView }
            Spacer()
            
            switch am.state {
            case .recordingSpeech:
                cancelRecordingButton
                
            case .processingSpeech, .playingSpeech:
                cancelButton
                
            default: EmptyView()
            }
            
            Button("Exit") {
                am.cancelProcessingTask()
                clearConversationHistory()
                presentationMode.wrappedValue.dismiss()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
            .background(Color.white)
            .cornerRadius(4)
            
            if inputDidFail {
                Text("You reached the limit of your current plan. Please upgrade your subscription.")
                .foregroundColor(.red)
                .fixedSize(horizontal: false, vertical: true)
            }
            
            if case let .error(error) = am.state {
                Text(error.localizedDescription)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .lineLimit(2)
            }
            
        }
        .padding()
    }

        
    @ViewBuilder
    var overlayView: some View {
        switch am.state {
        case .idle, .error:
            startCaptureButton
        case .processingSpeech:
            Image(systemName: "brain.head.profile")
                .symbolEffect(.bounce.up.byLayer,
                              options: .repeating,
                                value: isSymbolAnimating)
                .font(.system(size: 128))
                .onAppear { isSymbolAnimating = true }
                .onDisappear { isSymbolAnimating = false }
        default: EmptyView()
        }
    }
    
    var startCaptureButton: some View {
        Button {
            applyMessageCounter()
        } label: {
            Image(systemName: "mic")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 128))
        }.buttonStyle(.borderless)
    }
    
    var cancelRecordingButton: some View {
        Button(role: .destructive) {
            am.cancelRecording()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 44))
        }.buttonStyle(.borderless)
    }
    
    var cancelButton: some View {
        Button(role: .destructive) {
            am.cancelProcessingTask()
        } label: {
            Image(systemName: "stop.circle.fill")
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(.red)
                .font(.system(size: 44))
        }.buttonStyle(.borderless)
    }
    
    private func applyMessageCounter() {
        am.startCaptureAudio()
    }
    
}

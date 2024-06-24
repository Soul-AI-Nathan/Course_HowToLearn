//
//  AddVideoAlertView.swift
//  HowToLearn
//
//  Created by How on 6/12/24.
//

import SwiftUI

struct AddVideoAlertView: View {
    @Binding var isPresented: Bool
    @Binding var videoURL: String
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Video")
                .font(.headline)
            TextField("Enter video URL", text: $videoURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            HStack {
                Button("Add") {
                    onAdd()
                    withAnimation {
                        isPresented = false
                    }
                }
                .padding()
                Button("Cancel") {
                    withAnimation {
                        isPresented = false
                    }
                }
                .padding()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 8)
        .frame(maxWidth: 300)
        .scaleEffect(isPresented ? 1 : 0.5)
        .opacity(isPresented ? 1 : 0)
        .animation(.spring(), value: isPresented)
    }
}

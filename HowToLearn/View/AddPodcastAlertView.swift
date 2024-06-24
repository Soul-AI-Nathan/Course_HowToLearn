//
//  AddPodcastAlertView.swift
//  HowToLearn
//
//  Created by How on 6/12/24.
//

import SwiftUI

struct AddPodcastAlertView: View {
    @Binding var isPresented: Bool
    @Binding var podcastURL: String
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Add New Podcast")
                .font(.headline)

            TextField("Podcast URL", text: $podcastURL)
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
                .foregroundColor(.red)
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

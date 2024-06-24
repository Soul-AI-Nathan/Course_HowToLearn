//
//  AddArticleAlertView.swift
//  HowToLearn
//
//  Created by How on 6/16/24.
//

// AddArticleAlertView.swift

// AddArticleAlertView.swift

import SwiftUI

struct AddArticleAlertView: View {
    @Binding var isPresented: Bool
    @Binding var articleTitle: String
    @Binding var articleContent: String
    var onAdd: () -> Void

    @FocusState private var isInputActive: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    isInputActive = false
                }
            
            VStack(spacing: 20) {
                Text("Add New Article")
                    .font(.headline)
                TextField("Enter article title", text: $articleTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focused($isInputActive)
                TextEditor(text: $articleContent)
                    .frame(height: 200) // Adjust the height as needed
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                    .padding()
                    .focused($isInputActive)
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
}

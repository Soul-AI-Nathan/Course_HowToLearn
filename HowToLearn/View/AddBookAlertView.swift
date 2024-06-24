//
//  AddBookAlertView.swift
//  HowToLearn
//
//  Created by How on 6/15/24.
//

import SwiftUI

struct AddBookAlertView: View {
    @Binding var isPresented: Bool
    @Binding var bookURL: String
    var onAdd: () -> Void

    var body: some View {
        VStack {
            Text("Add New Book URL")
                .font(.headline)
                .padding()

            TextField("Enter book URL", text: $bookURL)
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
        .frame(width: 300)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
    }
}

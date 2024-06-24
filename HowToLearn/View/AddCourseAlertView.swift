//
//  AddCourseAlertView.swift
//  HowToLearn
//
//  Created by How on 6/15/24.
//

import SwiftUI

struct AddCourseAlertView: View {
    @Binding var isPresented: Bool
    @Binding var courseURL: String
    var onAdd: () -> Void

    var body: some View {
        VStack {
            Text("Add New Course URL")
                .font(.headline)
                .padding()

            TextField("Enter course URL", text: $courseURL)
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
        .frame(width: 300)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
    }
}


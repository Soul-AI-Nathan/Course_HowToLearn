//
//  AddProjectAlertView.swift
//  HowToLearn
//
//  Created by How on 6/24/24.
//

import SwiftUI

struct AddProjectAlertView: View {
    @Binding var isPresented: Bool
    @Binding var projectURL: String
    var onAdd: () -> Void

    var body: some View {
        VStack {
            Text("Add New Project URL")
                .font(.headline)
                .padding()

            TextField("Enter project URL", text: $projectURL)
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

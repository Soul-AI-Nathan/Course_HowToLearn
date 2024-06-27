//
//  ChatView.swift
//  HowToLearn
//
//  Created by How on 6/27/24.
//

import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    @ObservedObject var chatManager = ChatManager()
    @State private var messageText = ""
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(chatManager.messages) { message in
                        Text(message.text)
                            .padding()
                            .background(message.isCurrentUser ? Color.blue : Color.gray)
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: message.isCurrentUser ? .trailing : .leading)
                    }
                }
                .padding()
            }
            
            HStack {
                TextField("Enter message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30)
                
                Button(action: {
                    chatManager.sendMessage(text: messageText)
                    messageText = ""
                }) {
                    Text("Send")
                }
            }
            .padding()
        }
        .navigationBarTitle("How学群", displayMode: .inline)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}


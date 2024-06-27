// ChatView.swift
// HowToLearn
//
// Created by How on 6/27/24.
//

import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    @ObservedObject var chatManager = ChatManager()
    @State private var messageText = ""
    @State private var showAlert = false
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollView in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(chatManager.messages) { message in
                            Text(message.text)
                                .padding()
                                .background(message.isCurrentUser ? Color.blue : Color.gray)
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: message.isCurrentUser ? .trailing : .leading)
                                .contextMenu {
                                    Button(action: {
                                        chatManager.deleteMessage(id: message.id)
                                    }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                    .onAppear {
                        if let lastMessage = chatManager.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: chatManager.messages.count) { _ in
                        if let lastMessage = chatManager.messages.last {
                            withAnimation {
                                scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            if showAlert {
                Text("Cannot send empty message")
                    .foregroundColor(.red)
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }
            
            HStack {
                TextField("Enter message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(minHeight: 30)
                
                Button(action: {
                    if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        withAnimation {
                            showAlert = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                showAlert = false
                            }
                        }
                    } else {
                        chatManager.sendMessage(text: messageText)
                        messageText = ""
                        hideKeyboard()
                    }
                }) {
                    Text("Send")
                }
            }
            .padding()
        }
        .navigationBarTitle("How学群", displayMode: .inline)
        .background(Color.white.edgesIgnoringSafeArea(.all)) // Ensure the background covers the entire view
        .onTapGesture {
            hideKeyboard()
        }
        .animation(.easeInOut)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}

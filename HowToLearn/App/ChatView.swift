// ChatView.swift
// HowToLearn
//
// Created by How on 6/27/24.
//

import SwiftUI
import FirebaseFirestore
import MessageUI

struct ChatView: View {
    @ObservedObject var chatManager = ChatManager()
    @State private var messageText = ""
    @State private var showAlert = false
    @State private var showMailComposer = false
    @State private var mailData = MailData(subject: "Report Abusive Message", recipients: ["support@soul-ai.xyz"], messageBody: "")
    @State private var quotedMessage: Message? // State for quoted message
    @State private var scrollToLastMessage = false // State to control scrolling

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollViewReader { scrollView in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(chatManager.messages) { message in
                                VStack(alignment: .leading) {
                                    Text(message.text)
                                        .padding()
                                        .background(message.isCurrentUser ? Color.blue : Color.gray)
                                        .cornerRadius(8)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, alignment: message.isCurrentUser ? .trailing : .leading)
                                        .contextMenu {
//                                            Button(action: {
//                                                chatManager.deleteMessage(id: message.id)
//                                            }) {
//                                                Label("Delete", systemImage: "trash")
//                                            }
                                            Button(action: {
                                                quotedMessage = message
                                                scrollToLastMessage = true
                                            }) {
                                                Label("Quote", systemImage: "quote.bubble")
                                            }
                                        }
                                    if let quotedText = message.quotedMessage {
                                        Text("Quoted: \(quotedText)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                            .padding([.leading, .trailing], 8)
                                    }
                                }
                            }
                        }
                        .padding()
                        .onAppear {
                            if let lastMessage = chatManager.messages.last {
                                withAnimation {
                                    print("Scrolling to last message on appear with ID: \(lastMessage.id)")
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: chatManager.messages.count) { _ in
                            if let lastMessage = chatManager.messages.last {
                                withAnimation {
                                    print("Scrolling to last message on change with ID: \(lastMessage.id)")
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: scrollToLastMessage) { value in
                            if value, let lastMessage = chatManager.messages.last {
                                withAnimation {
                                    print("Scrolling to last message on quote with ID: \(lastMessage.id)")
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                                scrollToLastMessage = false // Reset scroll trigger
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

                if let quoted = quotedMessage {
                    HStack {
                        Text("Replying to: \(quoted.text)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding([.leading, .trailing], 8)
                        Spacer()
                        Button(action: {
                            quotedMessage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding([.leading, .trailing, .bottom], 8)
                    .background(Color(UIColor.systemGray6))
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
                            chatManager.sendMessage(text: messageText, quotedMessage: quotedMessage?.text)
                            messageText = ""
                            quotedMessage = nil
                            hideKeyboard()
                        }
                    }) {
                        Text("Send")
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .animation(.easeInOut)
                .onTapGesture {
                    hideKeyboard()
                }
            }
            .navigationBarTitle("How学群", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                showMailComposer = true
            }) {
                Image(systemName: "exclamationmark.bubble")
                    .imageScale(.large)
                    .foregroundColor(.red)
            })
            .background(Color.white.edgesIgnoringSafeArea(.all)) // Ensure the background covers the entire view
            .sheet(isPresented: $showMailComposer) {
                MailView(mailData: mailData) { result in
                    print(result)
                }
            }
            .withTimer() // Apply the timer
        }
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





// MailView.swift
import SwiftUI
import MessageUI

struct MailData {
    var subject: String
    var recipients: [String]?
    var messageBody: String
    var attachments: [(Data, String, String)] = [] // (Data, mimeType, fileName)
}

struct MailView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var mailData: MailData
    var onResult: ((Result<MFMailComposeResult, Error>) -> Void)?

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView

        init(parent: MailView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            defer {
                parent.presentationMode.wrappedValue.dismiss()
            }

            if let error = error {
                parent.onResult?(.failure(error))
            } else {
                parent.onResult?(.success(result))
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setSubject(mailData.subject)
        vc.setToRecipients(mailData.recipients)
        vc.setMessageBody(mailData.messageBody, isHTML: false)

        for attachment in mailData.attachments {
            vc.addAttachmentData(attachment.0, mimeType: attachment.1, fileName: attachment.2)
        }

        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

struct MailView_Previews: PreviewProvider {
    static var previews: some View {
        MailView(mailData: MailData(subject: "Test Subject", recipients: ["test@example.com"], messageBody: "Test Body")) { result in
            print(result)
        }
    }
}


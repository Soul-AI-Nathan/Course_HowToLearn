//
//  ChatManager.swift
//  HowToLearn
//
//  Created by How on 6/27/24.
//

import FirebaseFirestore
import FirebaseAuth

struct Message: Identifiable, Equatable {
    var id: String
    var text: String
    var isCurrentUser: Bool
}

class ChatManager: ObservableObject {
    @Published var messages = [Message]()
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        fetchMessages()
    }
    
    func fetchMessages() {
        listener = db.collection("messages").order(by: "timestamp").addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("No documents")
                return
            }
            
            self.messages = documents.map { queryDocumentSnapshot -> Message in
                let data = queryDocumentSnapshot.data()
                let id = queryDocumentSnapshot.documentID
                let text = data["text"] as? String ?? ""
                let uid = data["uid"] as? String ?? ""
                let isCurrentUser = uid == Auth.auth().currentUser?.uid
                
                return Message(id: id, text: text, isCurrentUser: isCurrentUser)
            }
        }
    }
    
    func sendMessage(text: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let message = [
            "text": text,
            "uid": uid,
            "timestamp": Timestamp()
        ] as [String : Any]
        
        db.collection("messages").addDocument(data: message) { error in
            if let error = error {
                print("Error adding document: \(error)")
            }
        }
    }
    
    func deleteMessage(id: String) {
        db.collection("messages").document(id).delete { error in
            if let error = error {
                print("Error deleting message: \(error)")
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
}

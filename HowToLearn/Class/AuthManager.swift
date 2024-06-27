//
//  AuthManager.swift
//  HowToLearn
//
//  Created by How on 6/27/24.
//

import FirebaseAuth

class AuthManager: ObservableObject {
    @Published var isSignedIn = false
    
    static let shared = AuthManager()
    
    private init() {
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { _, user in
            self.isSignedIn = user != nil
        }
    }
    
    func signInAnonymously() {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                print("Error signing in anonymously: \(error)")
            } else {
                print("Signed in anonymously with user ID: \(authResult?.user.uid ?? "Unknown")")
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
}

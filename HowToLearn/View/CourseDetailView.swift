//
//  CourseDetailView.swift
//  HowToLearn
//
//  Created by How on 6/11/24.
//

import SwiftUI
import FirebaseFirestore

struct CourseDetailView: View {
    let course: Course
    @State private var newTakeawayText = ""
    @State private var showAddTakeawayAlert = false
    @State private var takeaways: [String]
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var isShareSheetPresented = false
    @State private var screenshotImage: IdentifiableImage?
    @State private var showAIResponse = false // State to show/hide the AI response pop-up
    @StateObject private var audioModel = AudioModel() // Use AudioModel instead of AudioRecorderManager

    init(course: Course) {
        self.course = course
        _takeaways = State(initialValue: course.takeaways ?? [])
    }

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    if let url = URL(string: course.image_url) {
                        Link(destination: URL(string: course.course_url)!) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 300)
                        }
                    }

                    Text("点击图片学习")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(course.title.uppercased())
                        .font(.title3)
                        .fontWeight(.heavy)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 8)
                        .foregroundColor(.primary)
                        .background(
                            Color.accentColor
                                .frame(height: 6)
                                .offset(y: 24)
                        )

                    Text(course.description.replacingOccurrences(of: "\\n", with: "\n"))
                        .font(.body)
                        .lineSpacing(9)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black)
                        .padding(.horizontal)

                    // TAKEAWAY VIEW
                    if !takeaways.isEmpty {
                        VStack(alignment: .center, spacing: 5) {
                            Text("How老师的Takeaways")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.top)
                            TakeawayView(itemID: course.id ?? "", contentType: .course, takeaways: $takeaways)
                                .environmentObject(firestoreManager)
                        }
                    }

                    // COMMENTS
                    CommentCourseView(courseID: course.id ?? "")
                        .padding(.bottom, 10) // Add padding at the bottom to keep it above the tab bar
                }
                .navigationBarTitle("Learn about \(course.title)", displayMode: .inline)
                .navigationBarItems(trailing: HStack {
//                    Button(action: {
//                        withAnimation {
//                            showAddTakeawayAlert.toggle()
//                        }
//                    }) {
//                        Image(systemName: "plus")
//                    }
                    Button(action: {
                        takeScreenshot()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: {
                        showAIAudioView()
                    }) {
                        Image(systemName: "brain.head.profile")
                    }
                })
            }

            if showAddTakeawayAlert {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                AddTakeawayAlertView(isPresented: $showAddTakeawayAlert, takeawayText: $newTakeawayText) {
                    addNewTakeaway(takeaway: newTakeawayText)
                    newTakeawayText = ""
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showAddTakeawayAlert)
            }

        }
        .onChange(of: showAddTakeawayAlert) { _ in
            if !showAddTakeawayAlert {
                reloadCourseData()
            }
        }
        .sheet(item: $screenshotImage, onDismiss: {
            screenshotImage = nil
        }, content: { item in
            ShareSheet(activityItems: [item.image])
        })
        .sheet(isPresented: $showAIResponse) {
            AIAudioView(am: audioModel)
        }
    }

    private func takeScreenshot() {
        print("Attempting to take screenshot...")

        guard let window = UIApplication.shared.windows.first else {
            print("No key window found.")
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("Starting renderer...")

            if let image = window.snapshot {
                print("Renderer completed...")
                DispatchQueue.main.async {
                    self.screenshotImage = IdentifiableImage(image: image)
                    print("Screenshot taken, presenting share sheet.")
                }
            } else {
                print("Snapshot failed.")
            }
        }
    }

    private func showAIAudioView() {
        guard let window = UIApplication.shared.windows.first else {
            print("No key window found.")
            return
        }

        if let image = window.snapshot {
            audioModel.processingImageTask = audioModel.processImageTask(image: image)
            showAIResponse = true
        } else {
            print("Snapshot failed.")
        }
    }

    private func addNewTakeaway(takeaway: String) {
        guard let courseID = course.id else { return }
        firestoreManager.addTakeawayToCourse(courseID: courseID, takeaway: takeaway)
        takeaways.append(takeaway)
    }

    private func reloadCourseData() {
        let db = Firestore.firestore()
        if let courseID = course.id {
            let document = db.collection("courses").document(courseID)
            document.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    if let updatedCourse = try? snapshot.data(as: Course.self) {
                        self.takeaways = updatedCourse.takeaways ?? []
                    } else {
                        print("Failed to parse updated course")
                    }
                } else {
                    print("Document does not exist or error: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
}

#Preview {
    CourseDetailView(course: Course(id: "1", title: "Sample Title", description: "Sample description for the course.", image_url: "https://via.placeholder.com/150", course_url: "https://www.xiaoyuzhoufm.com/episode/665faf066488b5dec3b8b28d", timestamp: Date(), takeaways: ["This is a sample takeaway.", "Another takeaway."]))
        .environmentObject(FirestoreManager())
}


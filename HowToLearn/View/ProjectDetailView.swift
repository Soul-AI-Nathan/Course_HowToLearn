import SwiftUI
import FirebaseFirestore

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ProjectDetailView: View {
    let project: Project
    @State private var newTakeawayText = ""
    @State private var showAddTakeawayAlert = false
    @State private var takeaways: [String]
    @EnvironmentObject var firestoreManager: FirestoreManager
    @State private var screenshotImage: IdentifiableImage?

    init(project: Project) {
        self.project = project
        _takeaways = State(initialValue: project.takeaways ?? [])
    }

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .center, spacing: 20) {
                    if let url = URL(string: project.image_url) {
                        Link(destination: URL(string: project.project_url)!) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(height: 250)
                        }
                    }

                    Text("点击图片查看项目")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Text(project.title.uppercased())
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

                    Text(project.description.replacingOccurrences(of: "\\n", with: "\n"))
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
                            TakeawayView(itemID: project.id ?? "", contentType: .project, takeaways: $takeaways)
                                .environmentObject(firestoreManager)
                        }
                    }

                    // COMMENTS
                    CommentProjectView(projectID: project.id ?? "")
                        .padding(.bottom, 10) // Add padding at the bottom to keep it above the tab bar
                }
                .navigationBarTitle("Learn about \(project.title)", displayMode: .inline)
                .navigationBarItems(trailing: HStack {
                    Button(action: {
                        withAnimation {
                            showAddTakeawayAlert.toggle()
                        }
                    }) {
                        Image(systemName: "plus")
                    }
                    Button(action: {
                        takeScreenshot()
                    }) {
                        Image(systemName: "square.and.arrow.up")
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
                reloadProjectData()
            }
        }
        .sheet(item: $screenshotImage, onDismiss: {
            screenshotImage = nil
        }, content: { item in
            ShareSheet(activityItems: [item.image])
        })
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

    private func addNewTakeaway(takeaway: String) {
        guard let projectID = project.id else { return }
        firestoreManager.addTakeawayToProject(projectID: projectID, takeaway: takeaway)
        takeaways.append(takeaway)
    }

    private func reloadProjectData() {
        let db = Firestore.firestore()
        if let projectID = project.id {
            let document = db.collection("projects").document(projectID)
            document.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    if let updatedProject = try? snapshot.data(as: Project.self) {
                        self.takeaways = updatedProject.takeaways ?? []
                    } else {
                        print("Failed to parse updated project")
                    }
                } else {
                    print("Document does not exist or error: \(error?.localizedDescription ?? "unknown error")")
                }
            }
        }
    }
}

#Preview {
    ProjectDetailView(project: Project(id: "1", title: "Sample Title", description: "Sample description for the project.", image_url: "https://via.placeholder.com/150", project_url: "https://www.xiaoyuzhoufm.com/episode/665faf066488b5dec3b8b28d", timestamp: Date(), takeaways: ["This is a sample takeaway.", "Another takeaway."]))
        .environmentObject(FirestoreManager())
}

extension UIView {
    var snapshot: UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        drawHierarchy(in: bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

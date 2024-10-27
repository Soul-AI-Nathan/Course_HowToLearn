//
//  ProjectView.swift
//  HowToLearn
//
//  Created by How on 6/24/24.
//

import SwiftUI

struct ProjectView: View {
    @ObservedObject var firestoreManager = FirestoreManager()
    @State private var selectedProject: Project?
    @State private var showAddProjectAlert = false
    @State private var newProjectURL = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupProjectsByDate(), id: \.key) { date, projects in
                    Section(header: Text(formatDate(date))) {
                        ForEach(projects) { project in
                            NavigationLink(value: project) {
                                ProjectListView(project: project)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteProject(project: project)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Project")
            .navigationBarItems(trailing: Button(action: {
                withAnimation {
                    showAddProjectAlert.toggle()
                }
            }) {
                Image(systemName: "plus")
            })
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .overlay(
                Group {
                    if showAddProjectAlert {
                        AddProjectAlertView(isPresented: $showAddProjectAlert, projectURL: $newProjectURL) {
                            addNewProject(url: newProjectURL)
                            newProjectURL = ""
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
                        .transition(.opacity)
                        .animation(.easeInOut, value: showAddProjectAlert)
                    }
                }
            )
        }
        .withTimer() // Apply the timer
    }

    private func addNewProject(url: String) {
        let newProject = Project(id: UUID().uuidString, title: "", description: "", image_url: "", project_url: url, timestamp: Date())
        firestoreManager.addProject(newProject)
    }

    private func deleteProject(project: Project) {
        firestoreManager.deleteProject(project: project)
    }

    private func groupProjectsByDate() -> [(key: Date, value: [Project])] {
        let groupedDict = Dictionary(grouping: firestoreManager.projects) { (project: Project) -> Date in
            Calendar.current.startOfDay(for: project.timestamp)
        }
        return groupedDict.sorted { $0.key > $1.key }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd"
        return formatter.string(from: date)
    }
}

#Preview {
    ProjectView()
        .environmentObject(TimerManager()) // Inject the TimerManager environment object
}

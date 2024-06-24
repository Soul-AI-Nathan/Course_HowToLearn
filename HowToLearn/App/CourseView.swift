//
//  CourseView.swift
//  HowToLearn
//
//  Created by How on 6/11/24.
//

import SwiftUI

struct CourseView: View {
    @ObservedObject var firestoreManager = FirestoreManager()
    @State private var selectedCourse: Course?
    @State private var showAddCourseAlert = false
    @State private var newCourseURL = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupCoursesByDate(), id: \.key) { date, courses in
                    Section(header: Text(formatDate(date))) {
                        ForEach(courses) { course in
                            NavigationLink(value: course) {
                                CourseListView(course: course)
                            }
//                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                                Button(role: .destructive) {
//                                    deleteCourse(course: course)
//                                } label: {
//                                    Label("Delete", systemImage: "trash")
//                                }
//                            }
                        }
                    }
                }
            }
            .navigationTitle("Course")
//            .navigationBarItems(trailing: Button(action: {
//                withAnimation {
//                    showAddCourseAlert.toggle()
//                }
//            }) {
//                Image(systemName: "plus")
//            })
            .navigationDestination(for: Course.self) { course in
                CourseDetailView(course: course)
            }
//            .overlay(
//                Group {
//                    if showAddCourseAlert {
//                        AddCourseAlertView(isPresented: $showAddCourseAlert, courseURL: $newCourseURL) {
//                            addNewCourse(url: newCourseURL)
//                            newCourseURL = ""
//                        }
//                        .frame(maxWidth: .infinity, maxHeight: .infinity)
//                        .background(Color.black.opacity(0.4).edgesIgnoringSafeArea(.all))
//                        .transition(.opacity)
//                        .animation(.easeInOut, value: showAddCourseAlert)
//                    }
//                }
//            )
        }
    }

    private func addNewCourse(url: String) {
        let newCourse = Course(id: UUID().uuidString, title: "", description: "", image_url: "", course_url: url, timestamp: Date())
        firestoreManager.addCourse(newCourse)
    }

    private func deleteCourse(course: Course) {
        firestoreManager.deleteCourse(course: course)
    }

    private func groupCoursesByDate() -> [(key: Date, value: [Course])] {
        let groupedDict = Dictionary(grouping: firestoreManager.courses) { (course: Course) -> Date in
            Calendar.current.startOfDay(for: course.timestamp)
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
    CourseView()
}

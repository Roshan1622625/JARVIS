import SwiftUI

// MARK: - Models

struct JarvisTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var isCompleted = false
}

struct StudyModule: Identifiable, Codable {
    var id = UUID()
    var code: String
    var name: String
    var topics: [String]

    static let defaults: [StudyModule] = [
        StudyModule(code: "CMP4266", name: "Computer Programming",
                    topics: ["Python Basics", "Functions", "Modules", "Errors"]),
        StudyModule(code: "CMP4272", name: "Data Structures",
                    topics: ["Arrays", "Lists", "Stacks", "Queues"]),
        StudyModule(code: "CMP5332", name: "Object-Oriented Programming",
                    topics: ["Classes", "Objects", "Inheritance", "Polymorphism"]),
        StudyModule(code: "CMP4313", name: "Introduction to Software Engineering",
                    topics: ["Requirements Engineering", "Software Development Life Cycle",
                             "Agile", "Software Ethics"])
    ]
}

// MARK: - Main View

struct ContentView: View {
    @StateObject private var speechManager = SpeechManager()

    @AppStorage("jarvisSelectedSection") private var selectedSection = "Chat"
    @AppStorage("jarvisSavedModules") private var savedModulesData = ""
    @AppStorage("jarvisSavedTasks") private var savedTasksData = ""

    @State private var modules = StudyModule.defaults
    @State private var tasks: [JarvisTask] = []
    @State private var typedMessage = ""
    @State private var newTask = ""
    @State private var newModuleCode = ""
    @State private var newModuleName = ""
    @State private var editingModuleID: UUID?
    @State private var editingModuleCode = ""
    @State private var editingModuleName = ""
    @State private var selectedModuleID: UUID?
    @State private var selectedTopic = ""
    @State private var newTopic = ""
    @State private var difficulty = "Beginner"
    @State private var studyQuestion = ""
    @State private var studyAnswer = ""
    @State private var studyFeedback = ""
    @State private var isMarking = false
    @State private var isGenerating = false
    @State private var screenError = ""

    private let sections = ["Chat", "Tasks", "Study", "Modules"]
    private let difficulties = ["Beginner", "Intermediate", "Exam Level"]

    private var selectedModule: StudyModule? {
        modules.first { $0.id == selectedModuleID }
    }

    private var selectedModuleIndex: Int? {
        modules.firstIndex { $0.id == selectedModuleID }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                header
                navigation

                ScrollView {
                    VStack(spacing: 18) {
                        switch selectedSection {
                        case "Tasks": tasksSection
                        case "Study": studySection
                        case "Modules": modulesSection
                        default: chatSection
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 12)
                }

                Text("VOICE  •  TASKS  •  STUDY")
                    .font(.system(size: 10))
                    .tracking(2)
                    .foregroundStyle(.gray)
            }
            .padding(24)
            .frame(maxWidth: 680, maxHeight: .infinity)
        }
        .frame(minWidth: 460, minHeight: 650)
        .preferredColorScheme(.dark)
        .onAppear(perform: loadSavedData)
    }

    // MARK: - Header and Navigation

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: headerIcon)
                .font(.system(size: 48))
                .foregroundStyle(.cyan)
                .shadow(color: .cyan.opacity(0.5), radius: 15)

            Text("JARVIS")
                .font(.system(size: 30, weight: .bold))
                .tracking(7)
                .foregroundStyle(.white)

            Text(headerSubtitle)
                .font(.caption)
                .tracking(2)
                .foregroundStyle(.gray)
        }
        .padding(.top, 8)
    }

    private var headerIcon: String {
        switch selectedSection {
        case "Tasks": return "checklist"
        case "Study": return "book.closed.fill"
        case "Modules": return "books.vertical.fill"
        default: return speechManager.isListening ? "waveform" : "sparkles"
        }
    }

    private var headerSubtitle: String {
        switch selectedSection {
        case "Tasks": return "TASK MANAGER"
        case "Study": return "STUDY CENTRE"
        case "Modules": return "YOUR UNIVERSITY MODULES"
        default: return "PERSONAL ASSISTANT"
        }
    }

    private var navigation: some View {
        HStack(spacing: 6) {
            ForEach(sections, id: \.self) { section in
                Button {
                    selectedSection = section
                    screenError = ""
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: iconFor(section))
                        Text(section).font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .foregroundStyle(selectedSection == section ? .cyan : .white)
                    .background(selectedSection == section
                                ? Color.cyan.opacity(0.16)
                                : Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func iconFor(_ section: String) -> String {
        switch section {
        case "Tasks": return "checklist"
        case "Study": return "book.closed"
        case "Modules": return "books.vertical"
        default: return "bubble.left.and.bubble.right"
        }
    }

    // MARK: - Chat

    private var chatSection: some View {
        VStack(spacing: 14) {
            Button {
                if speechManager.isListening {
                    speechManager.stopListening()
                } else {
                    speechManager.requestPermission()
                }
            } label: {
                Label(
                    speechManager.isListening ? "Stop Listening" : "Start Listening",
                    systemImage: speechManager.isListening ? "stop.fill" : "mic.fill"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .foregroundStyle(.black)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if !speechManager.transcript.isEmpty {
                        messageCard(heading: "YOU", message: speechManager.transcript,
                                    color: .cyan)
                    }
                    if !speechManager.reply.isEmpty {
                        messageCard(heading: "JARVIS", message: speechManager.reply,
                                    color: .white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 150, maxHeight: 250)

            HStack(spacing: 10) {
                TextField("Type a message to JARVIS...", text: $typedMessage)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onSubmit(sendTypedMessage)

                Button(action: sendTypedMessage) {
                    Image(systemName: "paperplane.fill").padding(12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .foregroundStyle(.black)
            }

            if !speechManager.errorMessage.isEmpty {
                Text(speechManager.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private func sendTypedMessage() {
        let message = typedMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        speechManager.sendMessage(message)
        typedMessage = ""
    }

    // MARK: - Tasks

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            sectionTitle("My Tasks",
                         subtitle: "Keep track of assignments and revision.")

            HStack(spacing: 8) {
                TextField("Add a task or deadline...", text: $newTask)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .onSubmit(addTask)

                Button(action: addTask) {
                    Image(systemName: "plus").padding(12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .foregroundStyle(.black)
            }

            HStack {
                Text("\(tasks.filter { !$0.isCompleted }.count) remaining")
                Spacer()
                Text("\(tasks.filter { $0.isCompleted }.count) completed")
            }
            .font(.caption)
            .foregroundStyle(.gray)

            if tasks.isEmpty {
                emptyState(icon: "checklist", title: "No tasks yet",
                           message: "Add your first task above.")
            } else {
                ForEach(tasks.indices, id: \.self) { index in
                    HStack(spacing: 10) {
                        Button {
                            tasks[index].isCompleted.toggle()
                            saveTasks()
                        } label: {
                            Image(systemName: tasks[index].isCompleted
                                  ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(tasks[index].isCompleted ? .green : .cyan)
                        }
                        .buttonStyle(.plain)

                        Text(tasks[index].title)
                            .strikethrough(tasks[index].isCompleted)
                            .foregroundStyle(tasks[index].isCompleted ? .gray : .white)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(role: .destructive) {
                            tasks.remove(at: index)
                            saveTasks()
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(13)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func addTask() {
        let title = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        tasks.append(JarvisTask(title: title))
        newTask = ""
        saveTasks()
    }

    // MARK: - Modules

    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("My Modules",
                         subtitle: "Add and manage your university modules.")

            Text("ADD A MODULE")
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(.cyan)

            TextField("Module code, e.g. CMP5000", text: $newModuleCode)
                .textFieldStyle(.roundedBorder)

            TextField("Module name", text: $newModuleName)
                .textFieldStyle(.roundedBorder)

            Button(action: addModule) {
                Label("Add Module", systemImage: "plus")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .foregroundStyle(.black)

            if !screenError.isEmpty {
                Text(screenError).font(.caption).foregroundStyle(.orange)
            }

            Divider().overlay(Color.gray.opacity(0.4))

            Text("YOUR MODULES")
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(.cyan)

            ForEach(modules) { module in
                moduleCard(module)
            }
        }
    }

    private func moduleCard(_ module: StudyModule) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if editingModuleID == module.id {
                TextField("Module code", text: $editingModuleCode)
                    .textFieldStyle(.roundedBorder)
                TextField("Module name", text: $editingModuleName)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save") { saveModuleEdit(module) }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    Button("Cancel") { editingModuleID = nil }
                        .buttonStyle(.bordered)
                }
            } else {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(module.code)
                            .font(.caption.bold())
                            .foregroundStyle(.cyan)
                        Text(module.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(module.topics.count) topics")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    Button {
                        editingModuleID = module.id
                        editingModuleCode = module.code
                        editingModuleName = module.name
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        deleteModule(module)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    selectedModuleID = module.id
                    selectedTopic = module.topics.first ?? ""
                    selectedSection = "Study"
                } label: {
                    Label("Study this module", systemImage: "book.open")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.cyan)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func addModule() {
        let code = newModuleCode.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        let name = newModuleName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !code.isEmpty, !name.isEmpty else {
            screenError = "Enter both a module code and a name."
            return
        }
        guard !modules.contains(where: {
            $0.code.caseInsensitiveCompare(code) == .orderedSame
        }) else {
            screenError = "A module with that code already exists."
            return
        }

        let module = StudyModule(code: code, name: name, topics: [])
        modules.append(module)
        selectedModuleID = module.id
        selectedTopic = ""
        newModuleCode = ""
        newModuleName = ""
        screenError = ""
        saveModules()
    }

    private func saveModuleEdit(_ module: StudyModule) {
        guard let index = modules.firstIndex(where: { $0.id == module.id }) else {
            return
        }

        let code = editingModuleCode.trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
        let name = editingModuleName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !code.isEmpty, !name.isEmpty else {
            screenError = "Module code and name cannot be empty."
            return
        }
        guard !modules.contains(where: {
            $0.id != module.id &&
            $0.code.caseInsensitiveCompare(code) == .orderedSame
        }) else {
            screenError = "Another module already uses that code."
            return
        }

        modules[index].code = code
        modules[index].name = name
        editingModuleID = nil
        screenError = ""
        saveModules()
    }

    private func deleteModule(_ module: StudyModule) {
        modules.removeAll { $0.id == module.id }
        if selectedModuleID == module.id {
            selectedModuleID = modules.first?.id
            selectedTopic = modules.first?.topics.first ?? ""
        }
        saveModules()
    }

    // MARK: - Study Centre

    private var studySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("Study Centre",
                         subtitle: "Practise, revise and get feedback.")

            if modules.isEmpty {
                emptyState(icon: "books.vertical",
                           title: "No modules available",
                           message: "Open My Modules to add your first module.")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SELECT MODULE")
                        .font(.caption.bold())
                        .tracking(1.5)
                        .foregroundStyle(.cyan)

                    Picker("Module", selection: $selectedModuleID) {
                        ForEach(modules) { module in
                            Text("\(module.code) · \(module.name)")
                                .tag(Optional(module.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                    .onChange(of: selectedModuleID) { newValue in
                        let module = modules.first { $0.id == newValue }
                        selectedTopic = module?.topics.first ?? ""
                        clearStudyResults()
                    }
                }

                if let module = selectedModule {
                    studyControls(for: module)
                }
            }

            if !screenError.isEmpty {
                Text(screenError).font(.caption).foregroundStyle(.orange)
            }
        }
    }

    private func studyControls(for module: StudyModule) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(module.name)
                .font(.headline)
                .foregroundStyle(.white)

            Text("SELECT OR ADD A TOPIC")
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(.cyan)

            if module.topics.isEmpty {
                Text("This module has no topics yet. Add one below.")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            } else {
                Picker("Topic", selection: $selectedTopic) {
                    ForEach(module.topics, id: \.self) { topic in
                        Text(topic).tag(topic)
                    }
                }
                .pickerStyle(.menu)
                .tint(.white)
            }

            HStack {
                TextField("Add a lecture or topic", text: $newTopic)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTopic)

                Button(action: addTopic) {
                    Image(systemName: "plus").padding(9)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .foregroundStyle(.black)
            }

            Picker("Difficulty", selection: $difficulty) {
                ForEach(difficulties, id: \.self) { level in
                    Text(level).tag(level)
                }
            }
            .pickerStyle(.segmented)

            Button(action: generateQuestion) {
                HStack {
                    if isGenerating { ProgressView().tint(.black) }
                    Text(isGenerating ? "Generating..." : "Generate Exam Question")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .foregroundStyle(.black)
            .disabled(isGenerating || selectedTopic.isEmpty)

            Button(action: explainTopic) {
                Label("Explain Topic", systemImage: "lightbulb")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(.cyan)
            .disabled(isGenerating || selectedTopic.isEmpty)

            if !studyQuestion.isEmpty {
                questionCard
            }
            if !studyFeedback.isEmpty {
                feedbackCard
            }
        }
    }

    private var questionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUESTION")
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(.cyan)

            Text(studyQuestion)
                .foregroundStyle(.white)
                .textSelection(.enabled)

            Text("YOUR ANSWER")
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(.cyan)

            TextEditor(text: $studyAnswer)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 120)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Button(action: markAnswer) {
                HStack {
                    if isMarking { ProgressView().tint(.black) }
                    Text(isMarking ? "Marking..." : "Mark My Answer")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
            .foregroundStyle(.black)
            .disabled(isMarking || studyAnswer.trimmingCharacters(
                in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(14)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var feedbackCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("JARVIS FEEDBACK")
                .font(.caption.bold())
                .tracking(1.5)
                .foregroundStyle(.green)

            Text(studyFeedback)
                .foregroundStyle(.white)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.green.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func clearStudyResults() {
        studyQuestion = ""
        studyAnswer = ""
        studyFeedback = ""
    }

    private func addTopic() {
        let topic = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !topic.isEmpty, let index = selectedModuleIndex else { return }

        guard !modules[index].topics.contains(where: {
            $0.caseInsensitiveCompare(topic) == .orderedSame
        }) else {
            screenError = "That topic already exists in this module."
            return
        }

        modules[index].topics.append(topic)
        selectedTopic = topic
        newTopic = ""
        screenError = ""
        clearStudyResults()
        saveModules()
    }

    private func generateQuestion() {
        guard let module = selectedModule, !selectedTopic.isEmpty else { return }
        clearStudyResults()
        isGenerating = true

        let prompt = """
        You are a supportive university tutor.

        Module: \(module.code) - \(module.name)
        Topic: \(selectedTopic)
        Difficulty: \(difficulty)

        Generate one clear exam-style question appropriate for this level.
        Do not include the answer or marking scheme yet.
        Return the question only.
        """

        Task {
            defer { isGenerating = false }
            do {
                studyQuestion = try await AIManager1.shared.sendMessage(prompt)
            } catch {
                studyFeedback = "Could not generate a question: \(error.localizedDescription)"
            }
        }
    }

    private func explainTopic() {
        guard let module = selectedModule, !selectedTopic.isEmpty else { return }
        clearStudyResults()
        isGenerating = true

        let prompt = """
        Teach this university topic step by step for a student who is still learning.

        Module: \(module.code) - \(module.name)
        Topic: \(selectedTopic)
        Difficulty: \(difficulty)

        Explain the key ideas in plain English, give a worked example,
        identify common mistakes, and finish with one short practice question.
        """

        Task {
            defer { isGenerating = false }
            do {
                studyFeedback = try await AIManager1.shared.sendMessage(prompt)
            } catch {
                studyFeedback = "Could not explain the topic: \(error.localizedDescription)"
            }
        }
    }

    private func markAnswer() {
        guard let module = selectedModule, !isMarking else { return }
        isMarking = true
        studyFeedback = ""

        let prompt = """
        Act as a fair university examiner and supportive tutor.

        Module: \(module.code) - \(module.name)
        Topic: \(selectedTopic)
        Difficulty: \(difficulty)
        Question: \(studyQuestion)
        Student answer: \(studyAnswer)

        Mark the answer out of 10. Explain:
        1. The mark and why it was awarded.
        2. What the student got right.
        3. What is missing or incorrect.
        4. A model answer.
        5. One practical improvement tip.

        Be accurate, fair, and suitable for a beginner.
        """

        Task {
            defer { isMarking = false }
            do {
                studyFeedback = try await AIManager1.shared.sendMessage(prompt)
            } catch {
                studyFeedback = "Could not mark your answer: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Saving

    private func loadSavedData() {
        if !savedModulesData.isEmpty,
           let data = savedModulesData.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([StudyModule].self, from: data) {
            modules = decoded
        } else {
            modules = StudyModule.defaults
            saveModules()
        }

        if !savedTasksData.isEmpty,
           let data = savedTasksData.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([JarvisTask].self, from: data) {
            tasks = decoded
        }

        if !modules.contains(where: { $0.id == selectedModuleID }) {
            selectedModuleID = modules.first?.id
        }

        if let module = selectedModule,
           !module.topics.contains(selectedTopic) {
            selectedTopic = module.topics.first ?? ""
        }
    }

    private func saveModules() {
        guard let data = try? JSONEncoder().encode(modules),
              let string = String(data: data, encoding: .utf8) else { return }
        savedModulesData = string
    }

    private func saveTasks() {
        guard let data = try? JSONEncoder().encode(tasks),
              let string = String(data: data, encoding: .utf8) else { return }
        savedTasksData = string
    }

    // MARK: - Reusable Components

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 34))
                .foregroundStyle(.cyan)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(25)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func messageCard(heading: String, message: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(heading)
                .font(.caption.bold())
                .tracking(2)
                .foregroundStyle(color)
            Text(message)
                .font(.body)
                .foregroundStyle(.white)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    ContentView()
}

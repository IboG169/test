import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        let calendar = Calendar.current

        for i in 0..<14 {
            let entry = DailyEntry(context: viewContext)
            entry.id = UUID()
            entry.date = calendar.date(byAdding: .day, value: -i, to: Date())
            entry.steps = Int32.random(in: 3000...15000)
            entry.calories = Int32.random(in: 1800...3000)
            entry.weight = 123.5 - Double(i) * 0.3
            entry.strengthTraining = Bool.random()
            entry.mood = Int16.random(in: 0...4)
            entry.journalEntry = i == 0 ? "Heute war ein guter Tag! Viel gelaufen und gesund gegessen." : nil
        }

        try? viewContext.save()
        return controller
    }()

    init(inMemory: Bool = false) {
        // Create the model programmatically (no .xcdatamodeld file needed)
        let model = NSManagedObjectModel()

        let entity = NSEntityDescription()
        entity.name = "DailyEntry"
        entity.managedObjectClassName = "DailyEntry"

        var properties: [NSAttributeDescription] = []

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = true
        properties.append(idAttr)

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = true
        properties.append(dateAttr)

        let stepsAttr = NSAttributeDescription()
        stepsAttr.name = "steps"
        stepsAttr.attributeType = .integer32AttributeType
        stepsAttr.defaultValue = 0
        properties.append(stepsAttr)

        let caloriesAttr = NSAttributeDescription()
        caloriesAttr.name = "calories"
        caloriesAttr.attributeType = .integer32AttributeType
        caloriesAttr.defaultValue = 0
        properties.append(caloriesAttr)

        let weightAttr = NSAttributeDescription()
        weightAttr.name = "weight"
        weightAttr.attributeType = .doubleAttributeType
        weightAttr.defaultValue = 0.0
        properties.append(weightAttr)

        let strengthAttr = NSAttributeDescription()
        strengthAttr.name = "strengthTraining"
        strengthAttr.attributeType = .booleanAttributeType
        strengthAttr.defaultValue = false
        properties.append(strengthAttr)

        let moodAttr = NSAttributeDescription()
        moodAttr.name = "mood"
        moodAttr.attributeType = .integer16AttributeType
        moodAttr.defaultValue = 2
        properties.append(moodAttr)

        let journalAttr = NSAttributeDescription()
        journalAttr.name = "journalEntry"
        journalAttr.attributeType = .stringAttributeType
        journalAttr.isOptional = true
        properties.append(journalAttr)

        entity.properties = properties
        model.entities = [entity]

        container = NSPersistentContainer(name: "YallaFitModel", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            try? context.save()
        }
    }

    func deleteAllData() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = DailyEntry.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? context.execute(deleteRequest)
        save()
    }
}

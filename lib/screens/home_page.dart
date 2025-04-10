import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

// Here creates a screen that can change when data changes
class HomePage extends StatefulWidget {
  const HomePage({super.key}); // The constructor for the HomePage

  @override
  // This connects the widget to its state class (where we write the logic)
  State<HomePage> createState() => _HomePageState();
}

// This is where we write all the logic and store the data for HomePage
class _HomePageState extends State<HomePage> {
  // Create a Firestore database connection
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // now helps us get the text typed in the input box
  final TextEditingController nameController = TextEditingController();

  // This list will store all our tasks
  final List<Map<String, dynamic>> tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks(); // Load tasks from the database when the app starts
  }

  // here gets the task data from Firestore and puts it into the app
  Future<void> fetchTasks() async {
    // Get all the tasks from Firestore and sort them by time
    final snapshot = await db.collection('tasks').orderBy('timestamp').get();

    setState(() {
      tasks.clear(); // Remove old tasks first
      tasks.addAll(
        // Go through each task and create a simple map with its info
        snapshot.docs.map(
          (doc) => {
            'id': doc.id, // The document ID
            'name': doc.get('name'), // The task name
            'completed':
                doc.get('completed') ??
                false, // True or false (default is false)
          },
        ),
      );
    });
  }

  // This adds a new task to Firestore and shows it in the app
  Future<void> addTask() async {
    final taskName =
        nameController.text.trim(); // Get the text typed by the user

    // Only add the task if the input is not empty
    if (taskName.isNotEmpty) {
      // Create a new task with default values
      final newTask = {
        'name': taskName,
        'completed': false,
        'timestamp': FieldValue.serverTimestamp(), // Get the time it was added
      };

      // Save the task in Firestore and get the document reference
      final docRef = await db.collection('tasks').add(newTask);

      // Add the task to the list we see on screen
      setState(() {
        tasks.add({'id': docRef.id, ...newTask});
      });

      nameController.clear(); // Clear the input box
    }
  }

  // now updates a task's completed status in Firestore and on screen
  Future<void> updateTask(int index, bool completed) async {
    final task = tasks[index]; // Get the task from the list

    // Update the task's status in Firestore
    await db.collection('tasks').doc(task['id']).update({
      'completed': completed,
    });

    // Update the status in the app's task list
    setState(() {
      tasks[index]['completed'] = completed;
    });
  }

  // here deletes a task from both Firestore and the app
  Future<void> removeTasks(int index) async {
    final task = tasks[index]; // Get the selected task

    // Delete it from Firestore
    await db.collection('tasks').doc(task['id']).delete();

    // Remove it from the app list
    setState(() {
      tasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main app layout
      appBar: AppBar(
        backgroundColor: Colors.blue, // App bar color
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceEvenly, // Even space between items
          children: [
            // App logo
            Expanded(child: Image.asset('assets/rdplogo.png', height: 80)),
            // App title
            const Text(
              'Daily Planner',
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 32,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // The main area that grows with the screen
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Show a calendar view
                  TableCalendar(
                    calendarFormat:
                        CalendarFormat.month, // Show full month view
                    focusedDay: DateTime.now(), // Focus on today's date
                    firstDay: DateTime(2025), // Calendar starts from Jan 2025
                    lastDay: DateTime(2026), // Calendar ends at Dec 2026
                  ),
                  // Show the list of tasks
                  buildTaskList(tasks, removeTasks, updateTask),
                ],
              ),
            ),
          ),
          // Section to add a new task
          buildAddTaskSection(nameController, addTask),
        ],
      ),
      drawer: Drawer(), // Side menu (empty for now)
    );
  }
}

// This creates the input area to type and add a new task
Widget buildAddTaskSection(nameController, addTask) {
  return Container(
    decoration: const BoxDecoration(color: Colors.white),
    child: Padding(
      padding: const EdgeInsets.all(12.0), // Add space around the row
      child: Row(
        children: [
          // Input box to type the task name
          Expanded(
            child: Container(
              child: TextField(
                maxLength: 32, // Limit typing to 32 characters
                controller: nameController, // Use this to get the typed text
                decoration: const InputDecoration(
                  labelText: 'Add Task', // Label inside the box
                  border: OutlineInputBorder(), // Add a border around the box
                ),
              ),
            ),
          ),
          // Button to add the task when clicked
          ElevatedButton(onPressed: addTask, child: Text('Add Task')),
        ],
      ),
    ),
  );
}

// This shows each task as a list item with a checkbox and delete button
Widget buildTaskList(tasks, removeTasks, updateTask) {
  return ListView.builder(
    shrinkWrap: true, // Don't take up extra space
    physics: const NeverScrollableScrollPhysics(), // Don't scroll separately
    itemCount: tasks.length, // Total number of tasks
    itemBuilder: (context, index) {
      final task = tasks[index]; // Get the current task
      final isEven = index % 2 == 0; // Used to alternate background color

      return Padding(
        padding: EdgeInsets.all(1.0), // Small space around the task tile
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          tileColor:
              isEven
                  ? Colors.blue
                  : Colors.green, // Blue and green background alternation
          leading: Icon(
            task['completed']
                ? Icons
                    .check_circle // If done, show checked icon
                : Icons.circle_outlined, // If not done, show empty circle
          ),
          title: Text(
            task['name'], // Show task name
            style: TextStyle(
              decoration:
                  task['completed']
                      ? TextDecoration.lineThrough
                      : null, // Cross out if done
              fontSize: 22,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min, // Make row as small as needed
            children: [
              // Checkbox to mark done or not
              Checkbox(
                value: task['completed'],
                onChanged:
                    (value) => updateTask(index, value!), // Change task status
              ),
              // Delete icon to remove the task
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => removeTasks(index), // Call delete function
              ),
            ],
          ),
        ),
      );
    },
  );
}

import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

// Οι υπόλοιπες οθόνες της εφαρμογής μας
import 'camera.dart';
import 'task.dart';

/// Λίστα στην οποία πρόκειται να προστεθούν οι διαθέσιμες κάμερες της συστκευής.
/// Το late υποδηλώνει ότι μπορεί να αρχικοποιηθεί και αργότερα (και όχι τώρα
/// που δηλώνεται)
late List<CameraDescription> cameras;

/// Μεταβλητή στην οποία θα αποθηκευτεί η κάμερα που θα επιλέξουμε
late CameraDescription firstCamera;

/// Συνάρτηση εισόδου (main) της εφααρμογής μου
Future<void> main() async {
  /// Προκειμένου να πάρουμε μια λίστα με τις διαθέσιμες κάμερες της συσκευής
  /// πρέπει να βεβαιωθούμε ότι όλες οι υπηρεσίες των προσθέτων που χρησιμο-
  /// ποιούμε (plugins) έχουν αρχικοποιηθεί πριν καλέσουμε την runApp()
  WidgetsFlutterBinding.ensureInitialized();

  /// Λήψη λίστας με τις διαθέσιμες κάμερες της συσκευής
  cameras = await availableCameras();

  /// Από τη λίστα που έχει επιστραφεί, παίρνουμε την πρώτη κάμερα
  firstCamera = cameras.first;

  /// Ξεκινάμε την εκτέλεση της εφαρμογής μας
  runApp(const ToDo());
}

/// Υλοποίηση της κεντρικής οθόνης εισόδου της εφαρμογής ως [StatelessWidget]
class ToDo extends StatelessWidget {
  const ToDo({super.key});

  /// Μέθοδος που κατασκευάζει το [Widget] της εφαρμογής μας
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /// Τίτλος της εφαρμογής μας
      title: '2D2D',

      /// Το θέμα της εφαμρογής μας
      theme: ThemeData(primarySwatch: Colors.blue),

      /// Αρχικοποίηση της κεντρικής οθόνης της εφαρμογής μας (TaskListScreen)
      home: const TaskListScreenWidget(),
    );
  }
}

/// Υλοποίηση της οθόνης TaskListScreen ως [StatefulWidget]
class TaskListScreenWidget extends StatefulWidget {
  const TaskListScreenWidget({Key? key}) : super(key: key);

  @override
  _TaskListScreenWidgetState createState() => _TaskListScreenWidgetState();
}

class _TaskListScreenWidgetState extends State<TaskListScreenWidget> {
  late CameraController controller;
  late SQLiteService sqLiteService;

  // Η λίστα με τα tasks μας
  List<Task> _tasks = <Task>[];

  /// Αρχικοποίηση στιγμιοτύπου κλάσης
  @override
  void initState() {
    super.initState();

    /// Αρχικοποίηση στιγμιοτύπου της κλάσης [SQLiteService] για τη δημιουργία
    /// και σύνδεση με την SQLite βάση δεδομένων της εφαρμογής
    sqLiteService = SQLiteService();

    /// Κλήση της μεθόδου initDB() και φόρτωση της λίστας με τα tasks που πιθανώς
    /// να υπάρχουν στη βάση
    sqLiteService.initDB().whenComplete(() async {
      final tasks = await sqLiteService.getTasks();

      setState(() {
        _tasks = tasks;
      });
    });

    /// Αρχικοποίηση του ελεγκτή κάμερας [CameraController] για σύνδεση με την
    /// πρώτη κάμερα.
    controller = CameraController(cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  /// Καταστροφή στιγμιοτύπου κλάσης
  @override
  void dispose() {
    /// Απελευθέρωση της κάμερας
    controller.dispose();

    /// Τέλος, καλούμε την dispose της υπερκλάσης
    super.dispose();
  }

  /// Συνάρτηση προσθήκης νέου task στη λίστα των tasks
  void _addNewTask() async {
    /// Δημιουργία νέου task μέσω της μετάβασης με Navigator.push() στην οθόνη
    /// ViewEditTask.
    Task? newTask = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const ViewEditTaskWidget()));

    /// Επιστρέφοντας από την οθόνη ViewEditTask, πρέπει να ελέγξουμε αν ο χρήσ-
    /// της όντως δημιούργησε task (και δεν πάτησε πχ το Cancel ή το back)
    if (newTask != null) {
      /// Προσθήκη του νέου task στη βάση δεδομένων SQLite
      final newId = await sqLiteService.addTask(newTask);

      /// Η συνάρτηση [addTask] μας επιστρέφει το πρωτεύων κλειδί της νέας
      /// εγγραφής, το οποίο το τοποθετούμε στο πεδίο id του task.
      newTask.id = newId;

      /// Προσθήκη του νέου task στη λίστα των tasks και επανασχεδιασμός του
      /// [Stateful] widget
      _tasks.add(newTask);
      setState(() {});
    }
  }

  /// Συνάρτηση διαγραφής του task στη θέση [idx] της λίστας.
  void _deleteTask(int idx) async {
    /// Εμφάνιση [showDialog] ζητά από τον χρήστη να επιβεβαιώσει την επιλογή
    /// του
    bool? delTask = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              content: const Text('Delete Task?'),
              actions: <Widget>[
                /// Αν επιλεγεί το Cancel επιστρέφεται false στην [delTask]
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),

                /// Αν επιλεγεί το Yes επιστρέφεται true στην [delTask]
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes')),
              ],
            ));

    /// Αν έχει επιλεγεί το Yes στο προηγούμενο dialog box
    if (delTask!) {
      /// Ανέκτησε το προς διαγραφή task από τη θέση [idx] της λίστας [_tasks]
      /// των task
      final task = _tasks.elementAt(idx);

      try {
        /// Αφαίρεσε το από τη βάση δεδομένων
        sqLiteService.deleteTask(task.id);

        /// Αφαίρεσέ το από τη λίστα των tasks
        _tasks.removeAt(idx);
      } catch (err) {
        /// Σε περίπτωση αδυναμίας διαγραφής καταχώρησε σχετικό σφάλμα στην
        /// κονσόλα Debug
        debugPrint('Could not delete task $task: $err');
      }

      /// Επανασχεδιασμός του [Widget] της οθόνης TaskListScreen
      setState(() {});
    }
  }

  /// Συνάρτηση σχεδιασμού στην οθόνη της λίστας των tasks. Χρησιμοποιεί την
  /// [ListView]
  Widget _buildTaskList() {
    return ListView.separated(
      /// Γέμισμα 16 pixel σε όλες τις κατευθύνσεις μεταξύ των κελιών
      padding: const EdgeInsets.all(16.0),

      /// Χρήση της κλάσης [Divider] για τον σχεδιασμό διαχωριστικού μεταξύ των
      /// διαδοχικών στοιχείων της λίστας
      separatorBuilder: (context, index) => const Divider(),

      /// Μέγεθος λίστας όσο μήκος της λίστας των tasks
      itemCount: _tasks.length,

      /// Σχεδιασμός στοιχείου στη θέση [index] της λίστας των tasks
      itemBuilder: (context, index) {
        IconData iconData;
        String toolTip;
        TextDecoration txtDec;

        /// Αν το συγκεκριμένο task έχει επισημανθεί ως ολοκληρωμένο, χρησιμο-
        /// ποίησε διαφορετικό εικονίδιο, διαφορετικό tool tip και εμφάνισε τον
        /// τίτλο του task με διαγράμμιση (lineThrough)
        if (_tasks[index].completed) {
          iconData = Icons.check_box_outlined;
          toolTip = 'Mark as incomplete';
          txtDec = TextDecoration.lineThrough;
        } else {
          iconData = Icons.check_box_outline_blank_outlined;
          toolTip = 'Mark as completed';
          txtDec = TextDecoration.none;
        }

        /// Σχεδιασμός ενός task ως [ListTile] που αποτελείται από εικονίδιο
        /// ολοκλήρωσης του task, τον τίτλο του task, το alarm (αν υπάρχει)
        /// και τέλος εικονίδιο διαγραφής του task
        return ListTile(
          /// Αρχικά εμφανίζουμε το [leading] εικονίδιο για την αλλαγή της
          /// κατάστασης του task από ολοκληρωμένη σε μη-ολοκληρωμένη
          leading: IconButton(
            icon: Icon(iconData),
            onPressed: () {
              /// Άλλαξε την κατάσταση ολοκλήρωσης του task στην αντίθετη από
              /// αυτήν που έιναι τώρα
              _tasks[index].completed = !_tasks[index].completed;

              /// Ενημέρωσε τη σχετική εγγραφή στο βάση δεδομένων SQLite
              sqLiteService.updateCompleted(_tasks[index]);

              /// Επανασχεδιασμός του [Widget] της οθόνης TaskListScreen
              setState(() {});
            },
            tooltip: toolTip,
          ),

          /// Τίτλος του tile είναι ο τίτλος του task
          title:
              Text(_tasks[index].title, style: TextStyle(decoration: txtDec)),

          /// Ως [trailing] [Widget] εμφανίζουμε ένα στοιχείο γραμμής ([Row])
          /// που εμφανίζει το alarm (αν έχει το task), καθώς και το εικονίδιο
          /// διαγραφής
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              /// Πρώτο παιδί είναι ένα [Visibility] [Widget]
              Visibility(

                  /// Συνθήκη εμφάνισης: έχει το task alarm ή όχι;
                  visible: _tasks[index].alarm != null ? true : false,
                  child: Text(
                      _tasks[index].alarm != null
                          ? _tasks[index].alarm!.format(context)
                          : '',
                      style: TextStyle(decoration: txtDec))),

              /// Δεύτερο παιδί το εικονίδιο της διαγραφής
              IconButton(
                  icon: const Icon(Icons.delete),

                  /// Αν πατηθεί, κάλεσε τη συνάρτηση διαγραφής task, περνώντας
                  /// ως παράμετρο τη θέση του task στη λίστα
                  onPressed: () {
                    _deleteTask(index);
                  },
                  tooltip: 'Delete task'),
            ],
          ),
        );
      },
    );
  }

  /// Συνάρτηση μετατροπής της ώρας και των λεπτών σε λεπτά μετά τα μεσάνυχτα
  /// έτσι ώστε να μπορούν να ταξινομηθούν τα tasks ανάλογα με το πιο ολο-
  /// κληρώνεται γρηγορότερα
  double TimeOfDayToDouble(TimeOfDay myTime) =>
      myTime.hour + myTime.minute / 60;

  /// Συνάρτηση που κατασκευάζει το [Widget] της της οθόνης TaskListScreen
  @override
  Widget build(BuildContext context) {
    /// Επιστρέφουμε περιβάλλον [Scaffold]
    return Scaffold(
      appBar: AppBar(
        /// Στην άνω μπάρα της εφαρμογής ([AppBar]) έχουμε μενού
        /// [PopupMenuButton]με 4 επιλογές:
        ///
        /// 1. Καθαρισμός όλων των ολοκληρωμένων task
        /// 2. Καθαρισμός όλων των task
        /// 3. Ταξινόμηση των task με βάση την τιμή του alarm
        /// 4. Αλφαβιτική ταξινόμηση με βάση τον τίτλο του task
        leading: PopupMenuButton<int>(
          icon: const Icon(Icons.menu),
          itemBuilder: (context) => <PopupMenuEntry<int>>[
            const PopupMenuItem(
                value: 1,
                child: ListTile(
                  title: Text('Clear Checked'),
                )),
            const PopupMenuItem(
                value: 2,
                child: ListTile(
                  title: Text('Clear All'),
                )),
            const PopupMenuItem(
                value: 3,
                child: ListTile(
                  title: Text('Order by Time'),
                )),
            const PopupMenuItem(
                value: 4,
                child: ListTile(
                  title: Text('Order by Name'),
                )),
          ],

          /// Εκτέλεση κώδικα ανάλογα με την επιλογή από το μενού (τιμή [value])
          onSelected: (value) => {
            /// Επανασχεδιασμός του [Widget] της οθόνης TaskListScreen
            setState(() {
              /// Επιλογή διαγραφής όλων των ολοκληρωμένων task
              if (value == 1) {
                /// Διαγραφή όλων των ολοκληρωμένων task από τη βάση
                sqLiteService.deleteCompleted();

                /// Διαγραφή όλων των ολοκληρωμένων task από τη λίστα των tasks
                /// (χρήση μεθόδου removeWhere των λιστών σε Dart)
                _tasks.removeWhere((element) => element.completed);

                /// Επιλογή διαγραφής όλων των task
              } else if (value == 2) {
                /// Διαγραφή όλων των task από τη βάση
                sqLiteService.deleteAll();

                /// Εκκαθάριση της λίστας των task
                _tasks.clear();

                /// Επιλογή ταξινόμησης όλων των task με βάση το alarm
              } else if (value == 3) {
                /// Σύγκριση δύο στοιχείων a, b
                _tasks.sort((a, b) {
                  /// Αν το στοιχείο a δεν έχει alarm, φέρτο πίσω από το b
                  if (a.alarm == null) return 1;

                  /// Αν το στοιχείο b δεν έχει alarm, φέρτο μπροστά από το b.
                  if (b.alarm == null) return -1;

                  /// Αν και τα δύο στοιχεία a,b δεν είχαν alarm, το παραπάνω
                  /// "μπρος-πίσω" θα τα επανέφερε στην ίδια αρχική θέση

                  /// Αν και τα δύο στοιχεία έχουν alarm φέρει μπροστά αυτό
                  /// που είναι "χρονικά" μικρότερο μέσω χρήσης της συνάρτησησ
                  /// [TimeOfDayToDouble] που έχουμε ορίσει παραπάνω
                  return TimeOfDayToDouble(a.alarm!)
                      .compareTo(TimeOfDayToDouble(b.alarm!));
                });

                /// Επιλογή ταξινόμησης όλων των task με βάση τον τίτλο τους
              } else if (value == 4) {
                /// Αλφαβητική ταξινόμηση με βάση τον τίτλο του task
                _tasks.sort((a, b) => a.title.compareTo(b.title));
              }
            })
          },
        ),

        /// Τίτλος της κεντρικής οθόνης της εφαρμογής μας
        title: Text('Task List'),

        /// Λίστα με action buttons στη δεξιά πλευρά του [AppBar]
        actions: [
          /// Κουμπί μετάβασης σε λειτουργία οδήγησης (δεν υλοποιείται)
          IconButton(
            onPressed: () {},
            icon: Image.asset('assets/images/steering-wheel.png'),
            tooltip: 'Car Mode',
          ),

          /// Κουμπί μετάβασης στην οθόνη της κάμερας
          IconButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>

                      /// Περάνμε ως παράμετρο στο [CameraScreenWidget] την
                      /// πρώτη κάμερα της συσκευής που αναγνωρίσαμε
                      CameraScreenWidget(camera: firstCamera)));
            },
            icon: Image.asset('assets/images/camera.png'),
            tooltip: 'Camera',
          ),
        ],
      ),

      /// Το σώμα ([body]) του [Scaffold]. Πρόκειτα για [ListView] που κατα-
      /// σκευάζεται από τη συνάρτηση [_buildTaskList] που έχουμε ορίσει
      /// παραπάνω
      body: _buildTaskList(),

      /// Μπάρα στο κάτω μέρος της οθοόνης ([BottomAppBar])
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(onPressed: () {}, icon: const Icon(null))
          ],
        ),
      ),

      /// [FloatingActionButton] για την προσθήκη νέου task. Όταν πατηθεί καλεί
      /// τη συνάρτηση [_addNewTask] που έχουμε ορίσει παραπάνω
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _addNewTask,
        backgroundColor: Colors.teal,
        tooltip: 'Add Task',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}

/// Κλάση [Task] που λειτουργεί ως τύπος δεδομένων για την προσθήκη ενός νέου
/// task. Υποχρεωτικά πεδία είναι μόνο ο τίτλος [title] καθώς και το αν είναι
/// ολοκληρωμένη ή όχι ([completed])
class Task {
  int? id;
  String title;
  String? description;
  TimeOfDay? alarm;
  bool completed;

  /// Constructor (δομητής) της κλάσης
  Task(
      {this.id,
      required this.title,
      this.description,
      this.alarm,
      required this.completed});

  /// Απεικονίση μιας εγγραφής από τη ΒΔ SQLite σε ένα στιγμιότυπο της κλάσης
  /// [Task]
  Task.fromMap(Map<String, dynamic> task)
      : id = task['id'],
        title = task['title'],
        description = task['description'],

        /// Μετατροπή του πεδίου TEXT του alarm της εγγραφής σε στιγμιότυπο
        /// [TimeOfDay] του [Task]
        alarm = (task['alarm'] != null)
            ? TimeOfDay(
                hour: int.parse(task['alarm'].split(':')[0]),
                minute: int.parse(task['alarm'].split(':')[1]))
            : null,

        /// Μετατροπή του πεδίου INTEGER του completed της εγγραφής σε στιγμιό-
        /// τυπο [boolean] του [Task]
        completed = task['completed'] == 1 ? true : false;

  /// Απεικόνιση στιγμιοτύπου της κλάσης [Task] σε εγγραφή της ΒΔ
  Map<String, dynamic> toMap() {
    /// Υποχρεωτικά πεδία. Η ΒΔ SQLite δεν έχει πεδίο boolean, οπότε το
    /// [completed] γίνεται ακέραιος (integer)
    final record = {'title': title, 'completed': completed ? 1 : 0};

    /// Αν υπάρχει πεδίο περιγραφής πρόσθεσέ το και αυτό στην εγγραφή
    if (description != null) {
      record.addAll({'description': '$description'});
    }

    /// Αν υπάρχει alarm πρόσθεσέ το και αυτό στην εγγραφή. Η ΒΔ SQLite δεν έχει
    /// πεδίο TIME, οπότε η ώρα μετατρέπεται σε TEXT
    if (alarm != null) {
      record.addAll({'alarm': '${alarm!.hour}:${alarm!.minute}'});
    }

    return record;
  }
}

/// Κλάση [SQLiteService] που υλοποιεί τη διασύνδεση της εφαρμογής με τη ΒΔ
/// SQLite
class SQLiteService {
  /// Αρχικοποίηση σύνδεσης με ΒΔ SQLite με όνομα todo.db η οποία βρίσκεται
  /// στη διαδρομή που αποθηκεύονται οι ΒΔ της εφαρμογής
  Future<Database> initDB() async {
    return openDatabase(
      p.join(await getDatabasesPath(), 'todo.db'),

      /// Αν δεν υπάρχει η ΒΔ (πχ εκτελούμε πρώτη φορά την εφαρμογή), δημιούρ-
      /// γησέ την στο σύστημα αρχείων της συσκευής και κατόπιν άνοιξέ την
      onCreate: (db, version) {
        return db.execute(
            'CREATE TABLE tasks(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, description TEXT, alarm TEXT, completed INTEGER)');
      },
      version: 1,
    );
  }

  /// Ανάκτηση όλων των εγγραφών από τη ΒΔ
  Future<List<Task>> getTasks() async {
    /// Σύνδεση με ΒΔ
    final db = await initDB();

    final List<Map<String, Object?>> queryResult = await db.query('tasks');

    /// Μετατροπή τους από εγγραφές ΒΔ σε στιγμιότυπα κλάσης [Task]
    return queryResult.map((e) => Task.fromMap(e)).toList();
  }

  /// Προσθήκη του [Task] [task] στη ΒΔ. Επιστρέφει την τιμή πρωτεύοντως κλειδιού
  /// της νέας εγγραφής
  Future<int> addTask(Task task) async {
    /// Σύνδεση με ΒΔ
    final db = await initDB();

    /// Σε περίπτωση που για κάποιο λόγο υπάρχει πανομοίτυπη εγγραφή στη ΒΔ
    /// αντικατέστησε την με την τρέχουσα
    return db.insert('tasks', task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Διαγραφή task με [id] από τη ΒΔ
  Future<void> deleteTask(final id) async {
    /// Σύνδεση με ΒΔ
    final db = await initDB();

    /// Παράμετρος [where] καθορίζει με ποια κριτήρια θα αφαιρεθούν εγγραφές
    /// από τη ΒΔ (αυτή που έχει το πεδίο id ίσο με την τιμή που περνάμε ως
    /// παράμετρο στη [whereArgs]
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Ενημέρωση της κατάστασης ολοκλήρωσης της εγγραφής
  Future<void> updateCompleted(Task task) async {
    /// Σύνδεση με ΒΔ
    final db = await initDB();

    await db.update('tasks', {'completed': task.completed ? 1 : 0},
        where: 'id = ?',
        whereArgs: [task.id],
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Διαγραφή όλων των ολοκληρωμένων εγγραφών tasks από τη ΒΔ
  Future<void> deleteCompleted() async {
    /// Σύνδεση με ΒΔ
    final db = await initDB();

    /// Παράμετρος [where] καθορίζει με ποια κριτήρια θα αφαιρεθούν εγγραφές
    /// από τη ΒΔ (αυτές που έχουν το πεδίο completed true, δηλαδή 1)
    await db.delete('tasks', where: 'completed = 1');
  }

  /// Διαγραφή όλων των εγγραφών tasks από τη ΒΔ
  Future<void> deleteAll() async {
    /// Σύνδεση με ΒΔ
    final db = await initDB();

    await db.delete('tasks');
  }
}

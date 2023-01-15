import 'package:flutter/material.dart';

import 'main.dart';

/// Υλοποίηση της οθόνης ViewEditTask ως [StatefulWidget]
class ViewEditTaskWidget extends StatefulWidget {
  const ViewEditTaskWidget({Key? key}) : super(key: key);

  @override
  _ViewEditTaskWidgetState createState() => _ViewEditTaskWidgetState();
}

class _ViewEditTaskWidgetState extends State<ViewEditTaskWidget> {
  /// Μεταβλητή που μας επιτρέπει να κάνουμε επικύρωση των δεδομένων που έχουν
  /// εισαχθεί στη φόρμα προσθήκης νέου task
  final _formKey = GlobalKey<FormState>();

  /// Αρχικοποίηση μεταβλητών controller για την λήψη των δεδομένων που
  /// έχουν εισαχθεί στο πεδίο του τίτλου και της περιγραφής του task
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  /// Μεταβλητή που κρατάει την ώρα του alarm του task. Επειδή δεν είναι υποχρε-
  /// ωτικό το task να έχει alarm, η μεταβλητή αυτή μπορεί να είναι και null
  TimeOfDay? _alarmTime;

  /// Boolean flag η οποία εμφανίζει το [Widget] διαγραφής alarm όταν είναι true
  bool _visibleAlarmTime = false;

  /// Εμφάνιση του παραθύρου επιλογής ώρας alarm. Γdια περισσότερες πληροφορίες
  /// σχετικές με date/time pickers ανατρέξτε στο documentation
  /// https://m3.material.io/components/time-pickers/overview
  void _show() async {
    /// Εμφάνιση του time picker [showTimePicker] και αποθήκευση του αποτελέσμα-
    /// τος στην μεταβλητή [result] (τύπου [TimeOfDay]). Καθώς ο χρήστης μπορεί
    /// να πατήσει cancel, η μεταβλητή αυτή μπορεί να γίνει και null
    final TimeOfDay? result =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());

    /// Στην περίπτωση που ο χρήστης έχει επιλέξει ώρα alarm, ενημέρωσε την
    /// κατάσταση του [Widget], θέτοντας την ώρα στη μεταβλητή [_alarmTime]
    /// και θέτοντας το boolean flag [_visibleAlarmTime] σε true
    if (result != null) {
      setState(() {
        _alarmTime = result;
        _visibleAlarmTime = true;
      });
    }
  }

  /// Καταστροφή στιγμιοτύπου κλάσης
  @override
  void dispose() {
    /// Απελευθέρωση των πόρων που δέσμευσαν οι [TextEditingController]
    _titleController.dispose();
    _descriptionController.dispose();

    /// Τέλος, καλούμε την dispose της υπερκλάσης
    super.dispose();
  }

  /// Μέθοδος που κατασκευάζει το [Widget] της προσθήκης νέου task
  @override
  Widget build(BuildContext context) {
    /// Επιστρέφουμε περιβάλλον [Scaffold]
    return Scaffold(
      appBar: AppBar(
        title: const Text('View/Edit Task'),
      ),

      /// Έχουμε μια φόρμα ([Form]) από στοιχεία
      body: Form(
        /// To κλειδί της φόρμας για την επικύρωση των δεδομένων της
        key: _formKey,

        /// Στη φόρμα έχουμε μια στήλη ([Column]) από στοιχεία
        child: Column(
          ///  Στοίχιση πάνω αριστερά στο [body] του [Scaffold]
          crossAxisAlignment: CrossAxisAlignment.start,

          /// Λίστα με τα στοιχεία ([Widget]) της στήλης
          children: <Widget>[
            /// Προσθήκη "γεμίσματος" γύρω από τα στοιχεία της φόρμας, έτσι ώστε
            /// να μην "κολλάνε" το ένα με το άλλο, μέσω της χρήσης του [Widget]
            /// [Padding]
            Padding(

                /// Καθορισμός "γεμίσματος" 8 pixel και τις 4 κατευθύνσεις (πάνω,
                /// κάτω, δεξιά, αριστερά), χρησιμοποιώντας την κλάση [EdgeInsets]
                padding: const EdgeInsets.all(8.0),

                /// Πεδίο εισαγωγής κειμένου μιας γραμμής ([TextFormField]) για
                /// τον τίτλο του νέου task
                child: TextFormField(
                  /// Εμφάνιση πληροφοριών για το όνομα του συγκερκιμένου πεδίου
                  /// μέσω της χρήσης της κλάσης [InputDecoration]
                  decoration: const InputDecoration(
                      hintText: 'Title',
                      border: OutlineInputBorder(borderSide: BorderSide())),

                  /// Σύνδεση με τον αντίστοιχο [TextEditingController] για τη
                  /// λήψη των δεδομένων που έχει πληκτρολογίσει ο χρήστης στο
                  /// εν λόγω πεδίο
                  controller: _titleController,

                  /// Επικύρωση φόρμας. Αν ο χρήστης δεν έχει δώσει τίτλο, μην
                  /// επιτρέψεις την υποβολή της φόρμας, εμφανίζοντας σχετικό
                  /// μήνυμα σφάλματος γύρω από το συγκεκριμένο πεδίο
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Title cannot be empty!';
                    }
                    return null;
                  },
                )),
            Padding(
                padding: const EdgeInsets.all(8.0),

                /// Χρήστη [TextField] [Widget] για την είσοδο κειμένου πολλα-
                /// πλών γραμμών.
                child: TextField(
                  minLines: 10,
                  maxLines: 10,
                  decoration: const InputDecoration(
                      hintText: 'Description',
                      border: OutlineInputBorder(borderSide: BorderSide())),

                  /// Σύνδεση με τον αντίστοιχο [TextEditingController]. Σε αυτή
                  /// την περίπτωση δεν έχουμε input validation, μιας και το πε-
                  /// δίο της περιγραφής του task μπορεί να είναι κενό
                  controller: _descriptionController,
                )),
            Padding(
                padding: const EdgeInsets.all(8.0),

                /// Το τελευταίο στοιχείο της στήλης των στοιχείων είναι ένα
                /// στοιχείο γραμμής ([Row]), που περιέχει τα εικονίδια της
                /// επιλογής και ακύρωσης επιλογής alarm, καθώς και των κουμπιών
                /// της ακύρωσης και της καταχώρησης του task
                child: Row(
                  children: <Widget>[
                    /// Εικονίδιο προσθήκης alarm. Όταν πατηθεί καλεί τη συνάρ-
                    /// τηση _show για την εμφάνιση του Time picker
                    IconButton(
                      onPressed: _show,
                      icon: Image.asset('assets/images/notification.png'),
                      tooltip: 'Add reminder',
                    ),

                    /// Στοιχείο [Visibility] που εμφανίζει στοιχείο [Text] όταν
                    /// το boolean flag [_visibleAlarmTime] είναι αληθές, δηλαδή
                    /// όταν ο χρήστης έχει προσθέσει alarm.
                    Visibility(
                        visible: _visibleAlarmTime,
                        child: Text(_alarmTime != null
                            ? _alarmTime!.format(context)
                            : '')),

                    /// Στοιχείο [Visibility] που εμφανίζει εικονίδιο ακύρωσης
                    /// alarm όταν το boolean flag [_visibleAlarmTime] είναι
                    /// αληθές, δηλαδή όταν ο χρήστης έχει προσθέσει alarm. Όταν
                    /// πατηθεί, αλλάζει την κατάσταση του [Widget], σβήνοντας
                    /// το alarm του χρήστη και κάνοντας το boolean flag
                    /// [_visibleAlarmTime] ψευδές. Έτσι, αυτό και το προηγούμενο
                    /// στοιχείο θα πάψουν να είναι ορατά.
                    Visibility(
                        visible: _visibleAlarmTime,
                        child: IconButton(
                            onPressed: () {
                              setState(() {
                                _alarmTime = null;
                                _visibleAlarmTime = false;
                              });
                            },
                            icon: const Icon(Icons.cancel))),

                    /// Στοιχείο [Flexible] που μας επιτρέπει να στοιχίσουμε τα
                    /// δύο τελευταία κουμπιά δεξιά στη γραμμή
                    const Flexible(fit: FlexFit.tight, child: SizedBox()),

                    /// Κουμπί [ElevatedButton] ακύρωσης. Επειδή σε αυτή την
                    /// οθόνη (ViewEditTask) έχουμε έρθει μέσω Navigator.push()
                    /// από την TaskListScreen, θα επιστέψουμε με Navigator.pop()
                    /// για να μην υπερχειλίσουμε τη στοίβα.
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.white),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.blue),
                          )),
                    ),

                    /// Κουμπί [ElevatedButton] υποβολής νέου task
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            /// Αρχικά ελέγχουμε αν τα στοιχεία της φόρμας
                            /// "παιρνούν" την επικύρωση (αν ο τίτλος δεν είναι
                            /// κενός)
                            if (_formKey.currentState!.validate()) {
                              /// Αν ναι, δημιουργώ ένα νέο [Task] από τα στοι-
                              /// χεία της φόρμας
                              final task = Task(
                                title: _titleController.text,
                                description: _descriptionController.text.isEmpty
                                    ? null
                                    : _descriptionController.text,
                                alarm: _alarmTime,
                                completed: false,
                              );

                              /// Όπως και στην περίπτωση της ακύρωσης, επιστρέφω
                              /// το νέο [task] στην TaskListScreen μέσω
                              /// Navigator.pop() για να μην υπερχειλίσω τη
                              /// στοίβα
                              Navigator.pop(context, task);
                            }
                          },
                          child: const Text('Save'),
                        )),
                  ],
                ))
          ],
        ),
      ),
    );
  }
}

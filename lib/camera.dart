import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Χρήση κάμερας μέσω [StatefulWidget]
class CameraScreenWidget extends StatefulWidget {
  const CameraScreenWidget({super.key, required this.camera});

  /// Για την αρχικοποίησή της απαιτεί να της περάσουμε ως παράμετρο μια από
  /// τις κάμερες της συσκευής (μπροστά, πίσω)
  final CameraDescription camera;

  @override
  _CameraScreenWidgetState createState() => _CameraScreenWidgetState();
}

class _CameraScreenWidgetState extends State<CameraScreenWidget> {
  /// Δημιουργία ενός στιγμιοτύπου της κλάσης [TextRecognizer]
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Μεταβλητή χειρισμού της κάμερας. Το late υποδηλώνει ότι μπορεί να
  /// αρχικοποιηθεί και μετά τη δημιουργία του στιγμιοτύπου της κλάσης
  late CameraController _controller;

  /// Μεταβλητή για τη αρχικοποίηση του [CameraController]. Περισσότερα στο
  /// σχετικό documentation - https://pub.dev/packages/camera
  late Future<void> _initializeControllerFuture;

  /// Μεταβλητή στην οποία αποθηκεύεται το κείμενο που έχει αναγνωριστεί από την
  /// εικόνα. Μπορεί να είναι και null (όταν δεν αναγνωρίζεται κείμενο)
  String? _text;

  /// Αρχικοποίηση στιγμιοτύπου κλάσης
  @override
  void initState() {
    /// Πάντα αρχικοποιούμε πρώτα την υπερκλάση
    super.initState();

    /// Σύνδεση με την κάμερα που έχει έρθει ως παράμετρος στο widget. Επίσης
    /// ορίζουμε ότι η ανάλυση της κάμερας θα είναι μεσαία
    _controller = CameraController(widget.camera, ResolutionPreset.medium);

    /// Αρχικοποίηση κάμερας
    _initializeControllerFuture = _controller.initialize();
  }

  /// Καταστροφή στιγμιοτύπου κλάσης
  @override
  void dispose() {
    /// Απελευθέρωση των πόρων του TextRecognizer
    _textRecognizer.close();

    /// Απελευθέρωση της κάμερας
    _controller.dispose();

    /// Τέλος, καλούμε την dispose της υπερκλάσης
    super.dispose();
  }

  /// Μέθοδος που κατασκευάζει το [Widget] της κάμερας
  @override
  Widget build(BuildContext context) {
    /// Επιστρέφουμε περιβάλλον [Scaffold]
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),

      /// Έχουμε μια στήλη ([Column]) από στοιχεία
      body: Column(
        ///  Στοίχιση πάνω αριστερά στο [body] του [Scaffold]
        crossAxisAlignment: CrossAxisAlignment.start,

        /// Λίστα με τα στοιχεία ([Widget]) της στήλης
        children: <Widget>[
          /// Εδώ χρειαζόμαστε [FutureBuilder] γιατί η διαθεσιμότητα δεδομένων
          /// από την κάμερα γίνεται ασύγχρτονα
          FutureBuilder<void>(

              /// [future] ο αρχικοποιημένος controller της κάμερας
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                /// Όταν γίνει διαθέσιμη η ροή δεδομένων από την κάμερα, δείξε
                /// μια προεπισκόπιση (τι δείχνει η κάμερα)
                if (snapshot.connectionState == ConnectionState.done) {
                  return CameraPreview(_controller);
                } else {
                  /// Μέχρι να γίνει διαθέσιμη η ροή δεδομένων από την κάμερα
                  /// δείξε ένα "κυκλάκι" που γυρίζει
                  return const Center(child: CircularProgressIndicator());
                }
              }),

          /// Το δεύτερο στοιχείο είναι ένα [Text] widget που εμφανίζει το
          /// κείμενο που έχει αναγνωριστεί στην εικόνα (αν έχει αναγνωριστεί)
          Text('$_text'),
        ],
      ),

      /// Το περιβάλλον [Scaffold] έχει ένα [FloatingActionButton] κάτω δεξιά
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            /// Με το που πατηθεί το FAB περιμένουμε μέχρι να γίνει διαθέσιμη
            /// η κάμερα σε εμάς
            await _initializeControllerFuture;

            /// Όταν γίνει διαθέσιμη λαμβάνουμε φωτογραφία, η οποία αποθηκεύεται
            /// προσωρινά στο σύστημα αρχείων του Android
            final image = await _controller.takePicture();

            /// Διαβάζουμε τη φωτογραφία από το σύστημα αρχείων και την δίνουμε
            /// στον [TextRecognizer] και περιμένουμε να αναγνωρίσει σε αυτήν
            /// χαρακτήρες κειμένου.
            final recognizedText = await _textRecognizer
                .processImage(InputImage.fromFilePath(image.path));

            /// Εμφανίζουμε στην Debug console το κείμενο που αναγνωρίστηκε
            debugPrint('recognized text: ${recognizedText.text}');

            /// Ενημερώνουμε την κατάσταση του [Widget], αποθηκεύοντας το κειμενο
            /// που αναγνωρίστηκε στην ιδιωτική μεταβλητή [_text]. Αυτό θα έχει
            /// ως αποτέλεσμα να εμφανιστεί στο [Text] widget το κείμενο που
            /// αναγνωρίστηκε
            setState(() {
              _text = recognizedText.text;
            });

            if (!mounted) return;
          } catch (e) {
            /// Σε περίπτωση σφάλματος, γράφουμε στην debug console το σφάλμα
            /// που εμφανίστηκε
            debugPrint('Error during capture: ${e.toString()}');
          }
        },

        /// Ορίζουμε το εικονίδιο που θα έχει το FAB
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

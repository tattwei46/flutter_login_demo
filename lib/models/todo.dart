import 'package:firebase_database/firebase_database.dart';

class Todo {
  String key;
  String subject;

  Todo(this.subject);

  Todo.fromSnapshot(DataSnapshot snapshot) :
    key = snapshot.key,
    subject = snapshot.value["subject"];

  toJson() {
    return {
      "subject": subject,
    };
  }
}
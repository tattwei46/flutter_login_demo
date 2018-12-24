import 'package:flutter/material.dart';
import 'package:flutter_login_demo/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'dart:async';
import 'package:flutter_login_demo/models/todo.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.onSignedOut}) : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Todo> todoList = List();
  Todo todo;
  String userId;

  final FirebaseDatabase database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DatabaseReference databaseReference;

  @override
  void initState() {
    super.initState();
    todo = Todo("");
    databaseReference = database.reference().child("todo");
    databaseReference.onChildAdded.listen(_onEntryAdded);
    databaseReference.onChildChanged.listen(_onEntryChanged);
  }

  void _onEntryChanged(Event event) {
    var oldEntry = todoList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      todoList[todoList.indexOf(oldEntry)] = Todo.fromSnapshot(event.snapshot);
    });
  }

  void _onEntryAdded(Event event) {
    setState(() {
      todoList.add(Todo.fromSnapshot(event.snapshot));
    });
  }

  void _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  void _writeData() {
    database.reference().child("message").set({"first": "David"});
  }

  void _readData() {
    setState(() {
      Completer<String> completer = new Completer<String>();
      database
          .reference()
          .child("message")
          .once()
          .then((DataSnapshot snapshot) {
        Map<dynamic, dynamic> list = snapshot.value;
        print("Values from db is ${list.values}");
      });
    });
  }

  void handleSubmit() {
    final FormState form = formKey.currentState;
    if (form.validate()) {
      form.save();
      form.reset();
      databaseReference.push().set(todo.toJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Flutter login demo'),
          actions: <Widget>[
            new FlatButton(
                child: new Text('Logout',
                    style: new TextStyle(fontSize: 17.0, color: Colors.white)),
                onPressed: _signOut)
          ],
        ),
        body: Column(
          children: <Widget>[
            Flexible(
              flex: 0,
              child: Form(
                key: formKey,
                child: Flex(
                  direction: Axis.vertical,
                  children: <Widget>[
                    ListTile(
                        leading: Icon(Icons.subject),
                        title: TextFormField(
                          initialValue: "",
                          onSaved: (val) => todo.subject = val,
                          validator: (val) => val == "" ? val : null,
                        )),
                    FlatButton(
                        child: Text("Post"),
                        color: Colors.redAccent,
                        onPressed: () {
                          handleSubmit();
                        })
                  ],
                ),
              ),
            ),
            Flexible(
              child: FirebaseAnimatedList(
                query: databaseReference,
                itemBuilder: (_, DataSnapshot snapshot,
                    Animation<double> animation, int index) {
                  return new Card(
                    child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red,
                        ),
                        title: Text(
                          todoList[index].subject,
                        ),
                        onTap: () {
                          print(todoList[index].subject);
                        }),
                  );
                },
              ),
            ),
          ],
        ));
  }
}

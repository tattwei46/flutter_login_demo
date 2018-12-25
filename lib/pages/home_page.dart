import 'package:flutter/material.dart';
import 'package:flutter_login_demo/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_login_demo/models/todo.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Todo> todoList;
  Todo todo;

  final FirebaseDatabase database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  DatabaseReference databaseReference;

  final _textEditingController = TextEditingController();
  StreamSubscription<Event> _onTodoAddedSubscription;
  StreamSubscription<Event> _onTodoChangedSubscription;

  Query _todoQuery;

  @override
  void initState() {
    super.initState();
    todoList = new List();
    _todoQuery = database
        .reference()
        .child("todo")
        .orderByChild("userId")
        .equalTo(widget.userId);
    _onTodoAddedSubscription = _todoQuery.onChildAdded.listen(_onEntryAdded);
    _onTodoChangedSubscription = _todoQuery.onChildChanged.listen(_onEntryChanged);
  }

  @override
  void dispose() {
    _onTodoAddedSubscription.cancel();
    _onTodoChangedSubscription.cancel();
    super.dispose();
  }

  _onEntryChanged(Event event) {
    var oldEntry = todoList.singleWhere((entry) {
      return entry.key == event.snapshot.key;
    });

    setState(() {
      todoList[todoList.indexOf(oldEntry)] = Todo.fromSnapshot(event.snapshot);
    });
  }

  _onEntryAdded(Event event) {
    setState(() {
      todoList.add(Todo.fromSnapshot(event.snapshot));
    });
  }

  _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  addNewTodo(String todoItem) {
    if (todoItem.length > 0) {

      Todo todo = new Todo(todoItem.toString(), widget.userId, false);
      database.reference().child("todo").push().set(todo.toJson());
    }
  }

  updateTodo(Todo todo){
    //Toggle completed
    todo.completed = !todo.completed;
    if (todo != null) {
      database.reference().child("todo").child(todo.key).set(todo.toJson());
    }
  }

  deleteTodo(String todoId, int index) {
    database.reference().child("todo").child(todoId).remove().then((_) {
      print("Delete $todoId successful");
      setState(() {
        todoList.removeAt(index);
      });
    });
  }

  _showDialog(BuildContext context) async {
    _textEditingController.clear();
    await showDialog<String>(
        context: context,
      builder: (BuildContext context) {
          return AlertDialog(
            content: new Row(
              children: <Widget>[
                new Expanded(child: new TextField(
                  controller: _textEditingController,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelText: 'Add new todo',
                  ),
                ))
              ],
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.pop(context);
                  }),
              new FlatButton(
                  child: const Text('Save'),
                  onPressed: () {
                    addNewTodo(_textEditingController.text.toString());
                    Navigator.pop(context);
                  })
            ],
          );
      }
    );
  }

  Widget showTodoList() {
    if (todoList.length > 0) {
      return ListView.builder(
          shrinkWrap: true,
          itemCount: todoList.length,
          itemBuilder: (BuildContext context, int index) {
            String todoId = todoList[index].key;
            String subject = todoList[index].subject;
            bool completed = todoList[index].completed;
            String userId = todoList[index].userId;
            return Dismissible(
              key: Key(todoId),
              background: Container(color: Colors.red),
              onDismissed: (direction) async {
                deleteTodo(todoId, index);
              },
              child: ListTile(
                title: Text(
                  subject,
                  style: TextStyle(fontSize: 20.0),
                ),
                trailing: IconButton(
                    icon: (completed)
                        ? Icon(
                      Icons.done_outline,
                      color: Colors.green,
                      size: 20.0,
                    )
                        : Icon(Icons.done, color: Colors.grey, size: 20.0),
                    onPressed: () {
                      updateTodo(todoList[index]);
                    }),
              ),
            );
          });
    } else {
      return Center(child: Text("Empty"));
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
        body: showTodoList(),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showDialog(context);
          },
          tooltip: 'Increment',
          child: Icon(Icons.add),
        )
    );
  }
}

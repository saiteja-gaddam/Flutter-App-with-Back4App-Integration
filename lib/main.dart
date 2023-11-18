import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final keyApplicationId = 'A18AZwjSoNURQ87jeiFi4cqTCGv2ePdS5fszplHR';
  final keyClientKey = 'fKUikQNisEeqfEkKuD0VlJkAYcgb6AG3UxQnArr7';
  final keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(MaterialApp(
    home: Home(),
    routes: {
        '/taskdetails': (context) => TaskDetailsScreen(),
      }
  ));
}

class TaskDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ParseObject task = ModalRoute.of(context)?.settings.arguments as ParseObject;

    return Scaffold(
      appBar: AppBar(
        title: Text(task.get<String>('title')!),
      ),
      body: Column(
          children: <Widget>[
            Text(task.get<String>('description')!),
            Text(task.get<String>('status')!),
          ]
        )
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();


  void addToDo() async {
    if (titleController.text.trim().isEmpty || descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Empty title"),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    await saveTodo(titleController.text, descriptionController.text);
    setState(() {
      titleController.clear();
      descriptionController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tasks List"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
              padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
              child: Column(
                children: <Widget>[
                TextField(
                      autocorrect: true,
                      textCapitalization: TextCapitalization.sentences,
                      controller: titleController,
                      decoration: InputDecoration(
                          labelText: "New Task",
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                    ),
                  TextField(
                      autocorrect: true,
                      textCapitalization: TextCapitalization.sentences,
                      controller: descriptionController,
                      decoration: InputDecoration(
                          labelText: "Description",
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                    ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        onPrimary: Colors.white,
                        primary: Colors.blueAccent,
                      ),
                      onPressed: addToDo,
                      child: Text("ADD")),
                ],
              )),
          Expanded(
              child: FutureBuilder<List<ParseObject>>(
                  future: getTodo(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return Center(
                          child: Container(
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator()),
                        );
                      default:
                        if (snapshot.hasError) {
                          return Center(
                            child: Text("Error..."),
                          );
                        }
                        if (!snapshot.hasData) {
                          return Center(
                            child: Text("No Data..."),
                          );
                        } else {
                          return ListView.builder(
                              padding: EdgeInsets.only(top: 10.0),
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                //*************************************
                                //Get Parse Object Values
                                final varTodo = snapshot.data![index];
	                              final varTitle = varTodo.get<String>('title')!;
                                final varDescription = varTodo.get<String>('description')!;

                                bool varDone =false;
                                if(varTodo.get<String>('status') != 'Pending')
                                  varDone =  true;

                                //*************************************
                                return GestureDetector(
                                  onTap: () {
                                  Navigator.pushNamed(context, '/taskdetails', arguments: varTodo);
                                  },
                                child: ListTile(
                                  title: Text(varTitle),
                                  subtitle: Text(varDescription),
                                  leading: CircleAvatar(
                                    child: Icon(
                                        varDone ? Icons.check : Icons.error),
                                    backgroundColor:
                                        varDone ? Colors.green : Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                          value: varDone,
                                          onChanged: (value) async {
                                            await updateTodo(
                                                varTodo.objectId!, value!);
                                            setState(() {
                                              //Refresh UI
                                            });
                                          }),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () async {
                                          await deleteTodo(varTodo.objectId!);
                                          setState(() {
                                            final snackBar = SnackBar(
                                              content: Text("Task deleted!"),
                                              duration: Duration(seconds: 2),
                                            );
                                            ScaffoldMessenger.of(context)
                                              ..removeCurrentSnackBar()
                                              ..showSnackBar(snackBar);
                                          });
                                        },
                                      )
                                    ],
                                  ),
                                ),
                                );
                            });
                        }
                    }
                  }))
        ],
      ),
    );
  }

  Future<void> saveTodo(String title, String description) async {
    final todo = ParseObject('Task')..set('title', title)..set('description',description);
    await todo.save();
  }

  Future<List<ParseObject>> getTodo() async {
    QueryBuilder<ParseObject> queryTodo =
        QueryBuilder<ParseObject>(ParseObject('Task'));
    final ParseResponse apiResponse = await queryTodo.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  Future<void> updateTodo(String id, bool done) async {
    var todo = ParseObject('Task')
      ..objectId = id
      ..set('status', 'Completed');
    await todo.save();
  }

  Future<void> deleteTodo(String id) async {
    var todo = ParseObject('Task')..objectId = id;
    await todo.delete();
  }
}
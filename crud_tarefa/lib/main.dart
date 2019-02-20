import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _toDoController = TextEditingController();
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved = Map();
  int _lastRemovedPos;

  @override
  void initState() {
    // Then is called when data is returned
    this._readData().then((data) {
      setState(() {
        this._toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      this._toDoController.text = "";
      newToDo["ok"] = false;
      this._toDoList.add(newToDo);
      this._saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(color: Colors.blueAccent)),
                  textCapitalization: TextCapitalization.sentences,
                  controller: this._toDoController,
                )),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("ADD"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10.0),
                      itemCount: _toDoList.length,
                      itemBuilder: this.buildItem)))
        ],
      ),
    );
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });

      _saveData();
    });

    return null;
  }

  Widget buildItem(context, index) {
    // Swipe
    return Dismissible(
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      background: Container(
        padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            this._saveData();
          });
        },
      ),
      onDismissed: (direction) {
        setState(() {
          this._lastRemoved = Map.from(this._toDoList[index]);
          this._lastRemovedPos = index;
          this._toDoList.removeAt(index);
          this._saveData();

          final snack = SnackBar(
              content: Text("Tarefa ${this._lastRemoved["title"]} removida"),
              action: SnackBarAction(
                  label: "Desfazer",
                  onPressed: () {
                    setState(() {
                      _toDoList.insert(this._lastRemovedPos, this._lastRemoved);
                    });
                  }),
              duration: Duration(seconds: 2));

          Scaffold.of(context).showSnackBar(snack);
        });
      },
    );
  }

  Future<File> _getFile() async {
    // Root directory
    final diretory = await getApplicationDocumentsDirectory();
    return File("${diretory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();

    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}

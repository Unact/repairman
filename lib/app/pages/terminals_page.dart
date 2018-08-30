import 'dart:async';

import 'package:flutter/material.dart';

import 'package:repairman/app/models/terminal.dart';
import 'package:repairman/app/pages/terminal_page.dart';
import 'package:repairman/app/utils/format.dart';

class TerminalsPage extends StatefulWidget {
  TerminalsPage({Key key}) : super(key: key);

  @override
  _TerminalsPageState createState() => _TerminalsPageState();
}

class _TerminalsPageState extends State<TerminalsPage> {
  _TerminalsPageDelegate _delegate = _TerminalsPageDelegate();
  List<Terminal> _terminals = [];
  bool _showOnlyWithError = false;

  Future<void> _loadData() async {
    _terminals = (await Terminal.all()).where((term) => !_showOnlyWithError || term.errorText != '').toList();
    _delegate.terminals = _terminals;
    _terminals.sort((terminal1, terminal2) => terminal1.terminalId.compareTo(terminal2.terminalId));

    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildBody(BuildContext context) {
    List<Terminal> terminals = _terminals ?? [];

    return Container(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      child: ListView(
        children: terminals.map((terminal) {
          return _TerminalTile(
            terminal: terminal,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => TerminalPage(terminal: terminal)));
            }
          );
        }).toList()
      )
    );
  }

  @override
  void initState() {

    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Терминалы'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Поиск',
            icon: Icon(Icons.search),
            onPressed: () async {
              Terminal terminal = await showSearch<Terminal>(context: context, delegate: _delegate);

              if (terminal != null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => TerminalPage(terminal: terminal)));
              }
            },
          ),
          PopupMenuButton<bool>(
            padding: EdgeInsets.zero,
            onSelected: (bool value) async {
              _showOnlyWithError = !value;
              await _loadData();
            },
            itemBuilder: (BuildContext context) => <PopupMenuItem<bool>>[
              CheckedPopupMenuItem<bool>(
                value: _showOnlyWithError,
                checked: _showOnlyWithError,
                child: Text('С ошибкой')
              )
            ]
          )
        ],
      ),
      body: _buildBody(context)
    );
  }
}

class _TerminalTile extends StatelessWidget {
  _TerminalTile({this.terminal, this.onTap});

  final Terminal terminal;
  final Function onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: true,
      title: Text(terminal.terminalId.toString() + ' | ' + terminal.code),
      onTap: onTap,
      subtitle: RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(text: terminal.address + '\n', style: TextStyle(color: Colors.grey)),
            TextSpan(text: Format.untilStr(terminal.lastActivityTime), style: TextStyle(color: Colors.blue))
          ]
        )
      )
    );
  }
}

class _TerminalsPageDelegate extends SearchDelegate<Terminal> {
  List<Terminal> terminals = [];

  _TerminalsPageDelegate();

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Назад',
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

  @override
  Widget buildResults(BuildContext context) {
    String searchStr = query.toLowerCase();
    List<Terminal> suggestions = terminals.where((Terminal term) {
      return term.address.toLowerCase().contains(searchStr) || term.code.toLowerCase().contains(searchStr);
    }).toList();

    if (suggestions.isEmpty) {
      return Center(child: Text('Ничего не найдено', textAlign: TextAlign.center));
    }

    return ListView(
      children: suggestions.map((terminal) {
        return _TerminalTile(
          terminal: terminal,
          onTap: () async {
            close(context, terminal);
          },
        );
      }).toList()
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return <Widget>[
      query.isEmpty
        ? Container()
        : IconButton(tooltip: 'Очистить', icon: Icon(Icons.clear), onPressed: () => query = '')
    ];
  }
}

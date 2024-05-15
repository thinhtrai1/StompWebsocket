import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

final userId = Random().nextInt(1000).toString();

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late StompClient _client;
  dynamic _currentQuestion;

  @override
  void initState() {
    _client = StompClient(
      config: StompConfig(
        url: 'ws://10.253.12.173:8080/gs-guide-websocket',
        stompConnectHeaders: {'Authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0aGluaHRyYWkxIiwiZXhwIjoxNzE1ODUwMTE4fQ.jtGbshFvHStTVGBs-xLUb98XZE5idH_6YjOu2u-oH8c'},
        onConnect: onConnectCallback,
        onStompError: (error) => print('Stomp error: $error'),
        onWebSocketError: (error) => print('WebSocket error: $error'),
      ),
    )..activate();
    super.initState();
  }

  void onConnectCallback(StompFrame connectFrame) {
    print('WebSocket connected');
    _client.subscribe(destination: '/game_1/show_question', callback: (frame) {
      final body = frame.body;
      if (body != null) {
        setState(() {
          _currentQuestion = jsonDecode(body);
        });
        print('Show question: ${frame.body}');
      }
    });
    _client.subscribe(destination: '/game_1/answer', callback: (frame) {
      final body = frame.body;
      if (body != null) {
        final answer = jsonDecode(body);
        if (answer['userId'] == userId && answer['isCorrect'] == true) {
          _incrementCounter();
        }
      }
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  void _sendAnswer(String answer) {
    _client.send(destination: '/app/game_1/answer', body: jsonEncode({
      'userId': userId,
      'gameId': '1',
      'questionId': _currentQuestion?['id'],
      'answer': answer,
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Center(
            child: Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          if (_currentQuestion != null)
            Column(
              children: [
                Text(
                  _currentQuestion['question'],
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                ElevatedButton(
                  child: Text(
                    'A. ${_currentQuestion['a']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onPressed: () {
                    _sendAnswer('a');
                  },
                ),
                ElevatedButton(
                  child: Text(
                    'B. ${_currentQuestion['b']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onPressed: () {
                    _sendAnswer('b');
                  },
                ),
                ElevatedButton(
                  child: Text(
                    'C. ${_currentQuestion['c']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onPressed: () {
                    _sendAnswer('c');
                  },
                ),
                ElevatedButton(
                  child: Text(
                    'D. ${_currentQuestion['d']}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onPressed: () {
                    _sendAnswer('d');
                  },
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _counter = 0;
          });
          _client.send(destination: '/app/game_1/start');
        },
        tooltip: 'Start',
        child: const Text('Start'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

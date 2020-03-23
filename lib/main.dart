import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber/states/app_state.dart';
import 'screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  return runApp(MultiProvider(providers: [
    ChangeNotifierProvider.value(value: AppState(),)
  ],
  child: MyApp(),));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Txapita',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Txapita'),
    );
  }
}
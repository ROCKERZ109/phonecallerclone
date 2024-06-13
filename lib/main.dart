import 'package:flutter/material.dart';
import 'package:phonecaller/phoneCard.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider<ChangeBoolValue>(
      create: (BuildContext context) => GetModel(),
      child: const MaterialApp(
        home: PhoneScreen(),
      ),
    );
  }
}

GetModel (){
  return ChangeBoolValue(value: false);
}

class ChangeBoolValue extends ChangeNotifier{
  bool value;
  int? phoneToDelete;
  ChangeBoolValue({required this.value});
  void changeValue(bool value1, int phone)
  {
     value = value1;
     phoneToDelete = phone;
   print(value1);
    notifyListeners();
  }

}

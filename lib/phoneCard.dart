import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phonecaller/main.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({Key? key}) : super(key: key);

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  String? imagePath;
  bool toDelete = false;
  final _controller = TextEditingController();
  late List<Map> contacts;
  var contexOftheDialogBox;

  _callNumber(String phoneNumber) async {
    String number = phoneNumber; //set the number here
    bool? res = await FlutterPhoneDirectCaller.callNumber(number);
  }

  Future<String?> PickImage(ImageSource source) async {
    var imageFile = await ImagePicker().pickImage(source: source);
    setState(() {});
    return imageFile?.path;
  }

  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        contexOftheDialogBox = context;
        return AlertDialog(
          scrollable: true,
          title: const Center(child: Text('Add a contact')),
          content: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextFormField(
                  controller: _controller,
                  decoration:
                      const InputDecoration(labelText: "Enter the number"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          imagePath = await PickImage(ImageSource.camera);
                          setState(() {
                            Navigator.pop(contexOftheDialogBox);
                            _showDialog(context);
                          });
                        },
                        child: const Text("Camera")),
                    ElevatedButton(
                        onPressed: () async {
                          imagePath = await PickImage(ImageSource.gallery);
                          setState(() {
                            Navigator.pop(contexOftheDialogBox);
                          });
                          _showDialog(context);
                        },
                        child: const Text("Gallery")),
                  ],
                ),
                Container(
                  height: 100,
                  width: 100,
                  child: imagePath == null
                      ? Container()
                      : Image.file(File(imagePath!)),
                ),
                ElevatedButton(
                    onPressed: () async {
                      if (imagePath != null && _controller.text.length >= 10) {
                        String phoneNumber = _controller.text.trim();
                        phoneNumber = phoneNumber.replaceAll(' ', '');
                        phoneNumber = phoneNumber.substring(phoneNumber.length - 10);
                        inserNumberandImage(
                            int.parse(phoneNumber),
                            imagePath!);
                        Navigator.pop(contexOftheDialogBox);
                        setState(() {});
                      }
                    },
                    child: const Text("Save"))
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> initialiseDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = '${databasesPath}/NumberandImage.db';
    return path;
  }

  Future<Database> openDatabaseFromtheDevice() async {
    String path = await initialiseDatabase();
    Database database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('CREATE TABLE mainTable (phone int, image TEXT)');
    });
    return database;
  }

  void inserNumberandImage(int phoneNumber, String image) async {
    Database database = await openDatabaseFromtheDevice();

    await database.transaction((txn) async {
      await txn.insert('mainTable', {'phone': phoneNumber, 'image': image});
    });
  }

  void deleteNumberandImage(int phoneNumber) async {
    Database database = await openDatabaseFromtheDevice();
    int count = await database
        .rawDelete('DELETE FROM mainTable WHERE phone = ?', ['$phoneNumber']);
  }

  Future<List<Map>> getTheListOfNumbersAndImages() async {
    Database database = await openDatabaseFromtheDevice();
    List<Map> list = await database.rawQuery('SELECT * FROM mainTable');
    print(list);
    return list;
  }

  @override
  void initState() {
    initialiseDatabase()
        .whenComplete(() async => await openDatabaseFromtheDevice());
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: GestureDetector(
      onTap: () {
        Provider.of<ChangeBoolValue>(context, listen: false).value = false;
        Provider.of<ChangeBoolValue>(context, listen: false).notifyListeners();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: ElevatedButton(
                  onPressed: () {
                    _showDialog(context);
                  },
                  child: Text('Add Contact'),
                ),
              ),
            ),
            Visibility(
              visible:
                  Provider.of<ChangeBoolValue>(context, listen: true).value ==
                          false
                      ? false
                      : true,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 15.0),
                  child: ElevatedButton(
                    onPressed: () {
                      deleteNumberandImage(
                          Provider.of<ChangeBoolValue>(context, listen: false)
                              .phoneToDelete!);
                      Provider.of<ChangeBoolValue>(context, listen: false)
                          .value = false;
                      Provider.of<ChangeBoolValue>(context, listen: false)
                          .notifyListeners();
                    },
                    child: Text('Delete Contact'),
                  ),
                ),
              ),
            ),
          ],
        ),
        resizeToAvoidBottomInset: false,
        body: SizedBox(
          height: MediaQuery.of(context).size.height * 1,
          width: double.infinity,
          child: FutureBuilder(
              future: getTheListOfNumbersAndImages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: MediaQuery.of(context).size.height * 0.40,
                    ),
                    itemCount: snapshot.data?.length,
                    itemBuilder: (context, index) {
                      return buildPadding(
                          context,
                          snapshot.data?[index]['phone'].toString(),
                          snapshot.data?[index]['image']);
                    });
              }),
        ),
      ),
    ));
  }

  Padding buildPadding(BuildContext context, phoneNumber, String image) {
    return Padding(
        padding: const EdgeInsets.all(15.0),
        child: Card(
            color: Provider.of<ChangeBoolValue>(context, listen: false).value ==
                    true
                && Provider.of<ChangeBoolValue>(context, listen: false).phoneToDelete == int.parse(phoneNumber)? Colors.blue
                : Colors.white,
            elevation: 5.0,
            child: Consumer<ChangeBoolValue>(
                builder: (context, ChangeBoolValue, child) {
              return InkWell(
                onLongPress: () {
                  ChangeBoolValue.changeValue(true, int.parse(phoneNumber));
                },
                onTap: () async {
                  await _callNumber(phoneNumber);
                },
                child: Container(
                  margin: const EdgeInsets.all(5),
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(35)),
                  child: !image.contains('data')
                      ? Image.asset(
                          'assets/$image.jpg',
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(image),
                          fit: BoxFit.cover,
                        ),
                ),
              );
            })));
  }
}

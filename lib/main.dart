///
///
/// This App will select a file using file_pikcer or image_picker package
/// based on what is commented or not, and then we can upload it to my
/// Firebase cloud storage.
/// Also the App implement monitoring the uplaod status with and showing it
/// in addition as a progress bar.
///
///

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_firebase_ex/firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final storageRef = FirebaseStorage.instance.ref();
  PlatformFile? pickedFile;
  XFile? pickedImage;
  UploadTask? uploadTask;
  double? progress;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SafeArea(
          child: Scaffold(
            body: Center(
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Center(
                      child: Container(
                        // color: Colors.blue[100],
                        child: pickedFile != null
                            ? Image.file(
                                File(pickedFile!.path!),
                                // File.fromRawPath(pickedFile!.bytes!).path,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Text('No file selected'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 80.0, vertical: 12.0),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: (progress ?? 0.1) / 100,
                      // valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  ),
                  Text('${progress?.floor() ?? 0}%'),
                ],
              ),
            ),
            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: FloatingActionButton(
                    // child: Icon(Icons.group_work),
                    child: Icon(Icons.camera),
                    onPressed: (() {
                      selectFile();
                    }),
                  ),
                ),
                FloatingActionButton(
                  child: Icon(Icons.cloud_upload_rounded),
                  onPressed: (() {
                    uploadFile();
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: FloatingActionButton(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.cancel_rounded),
                    onPressed: (() async {
                      if (uploadTask != null) {
                        // if(uploadTask!.snapshot.state == Task)
                        switch (uploadTask!.snapshot.state) {
                          case TaskState.paused:
                          case TaskState.running:
                            // uploadTask!.cancel()
                            //   ..catchError(() => print('error catched'))
                            //   ..whenComplete(() => setState(() {
                            //         progress = 0;
                            //       }));
                            uploadTask!.cancel().then((value) {
                              setState(() {
                                progress = 0;
                              });
                            });
                            break;
                          default:
                        }
                        // print('we are here');

                        // progress = 0;
                        // setState(() {
                        //   progress = 0;
                        // });
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void getImages() async {
    Reference? imagesRef = storageRef.child('/');
    final listResult = await imagesRef.listAll();

    print(listResult.items.isEmpty ? 'no Items' : 'we have items');
    for (var item in listResult.items) {
      debugPrint(item.name);
    }
    print('name is ${imagesRef.fullPath}');

    print(
        listResult.prefixes.isEmpty ? 'no Directories' : 'we have directories');
    listResult.prefixes.forEach((prefix) {
      debugPrint(prefix.name);
    });

    final imageUrl = await storageRef.child('/Night.jpg').getDownloadURL();
    print(imageUrl);
  }

  Future selectFile() async {
    ///
    /// Code using file_picker package
    ///
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['JPEG', 'PNG', 'GIF', 'WebP', 'BMP', 'WBMP']);
    if (result == null) return;

    print(result.files.first.name);

    setState(() {
      pickedFile = result.files.first;
    });

    print(pickedFile?.size);
    final f = File(pickedFile!.path!);
    int sizeInBytes = f.lengthSync();
    double sizeInMb = sizeInBytes / (1024 * 1024);
    if (sizeInMb > 1) {
      print('File size ${sizeInMb} is larger than 1 MB');
    }

    ///
    /// Code using image_picker package
    ///
    // final _picker = ImagePicker();
    // final result = await _picker.pickImage(source: ImageSource.gallery);
    // if (result == null) return;

    // setState(() {
    //   pickedImage = result;
    // });

    // print(pickedImage?.length());
    // final f = File(pickedImage!.path);
    // int sizeInBytes = f.lengthSync();
    // double sizeInMb = sizeInBytes / (1024 * 1024);
    // if (sizeInMb > 1) {
    //   print('File size ${sizeInMb} is larger than 1 MB');
    // }
  }

  Future uploadFile() async {
    ///
    /// Code using file_picker package
    ///
    if (pickedFile == null) return;
    final path = 'images/${pickedFile!.name}';
    final file = File(pickedFile!.path!);

    ///
    /// Code using image_picker package
    ///
    // if (pickedImage == null) return;
    // final path = 'images/${pickedImage!.name}';
    // final file = File(pickedImage!.path);

    ///
    ///
    final ref = FirebaseStorage.instance.ref().child(path);

    try {
      uploadTask = ref.putFile(file);
      uploadTask?.snapshotEvents.listen((TaskSnapshot taskSnapshot) {
        switch (taskSnapshot.state) {
          case TaskState.running:
            setState(() {
              progress = 100.0 *
                  (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes);
            });
            // progress = 100.0 *
            //     (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes);
            print("Upload is $progress% complete.");
            break;
          case TaskState.paused:
            print("Upload is paused.");
            break;
          case TaskState.canceled:
            print("Upload was canceled");
            break;
          case TaskState.error:
            // Handle unsuccessful uploads
            break;
          case TaskState.success:
            // Handle successful uploads on complete
            // ...
            break;
        }
      });
    } on FirebaseException catch (e) {
      // do something
      print('ERROR: Exception thrown when uploading the image: $e');
    }
  }
}

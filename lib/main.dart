import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final SharedPreferences programSetting;
  double listViewWidth = 200;
  String? imageDirectory;
  String? labelDirectory;
  List<File> imageFile = [];
  Image showImage = Image.network(
    'https://flutter.cn/assets/images/cn/flutter-cn-logo.png',
    fit: BoxFit.contain,
  );
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 0), () async {
      return await SharedPreferences.getInstance();
    }).then((value) {
      programSetting = value;
      imageDirectory = value.getString('imageDirectory');
      labelDirectory = value.getString('labelDirectory');
      if (imageDirectory != null) {
        imageFile = findFilesInDirectory(Directory(imageDirectory!));
      }
    });
  }

  Future<void> initializeSharedPreferences() async {}

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Row(
      children: [
        const SizedBox(
          width: 10,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                String? selectedDirectory = await FilePicker.platform
                    .getDirectoryPath(initialDirectory: imageDirectory);
                if (selectedDirectory != null) {
                  imageDirectory = selectedDirectory;
                  setState(() {
                    imageFile =
                        findFilesInDirectory(Directory(selectedDirectory));
                  });
                  await programSetting.setString(
                      'imageDirectory', selectedDirectory);
                }
              },
              child: const Text('打开文件夹'),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () async {
                String? selectedDirectory = await FilePicker.platform
                    .getDirectoryPath(initialDirectory: labelDirectory);
                if (selectedDirectory != null) {
                  labelDirectory = selectedDirectory;
                  await programSetting.setString(
                      'labelDirectory', selectedDirectory);
                }
              },
              child: const Text('设置保存文件夹'),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('下一张图片'),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('上一张图片'),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('保存'),
            ),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
              onPressed: () {},
              child: const Text('创建标签矩形标注'),
            ),
          ],
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: Stack(
            fit:StackFit.expand,
            children: [
              showImage,
              Positioned(
                top: 50, // 在垂直方向上距离顶部的偏移量
                left: 320, // 在水平方向上距离左侧的偏移量
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red, // 文字标签背景颜色
                  child: const Text(
                    '标签文本',
                    style: TextStyle(
                      color: Colors.white,
                      backgroundColor: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                if (listViewWidth - details.delta.dx > 15) {
                  listViewWidth -= details.delta.dx;
                } else {
                  listViewWidth = 15;
                }
              });
            },
            child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: Container(
                  width: 7,
                  decoration: const BoxDecoration(),
                  child: const VerticalDivider(
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Color.fromRGBO(158, 158, 158, 1),
                  ),
                ))),
        SizedBox(
          width: listViewWidth,
          child: ListView.builder(
            itemCount: imageFile.length,
            itemBuilder: (BuildContext context, int index) {
              return InkWell(
                onTap: () {
                  setState(() {
                    showImage =
                        Image.file(imageFile[index], fit: BoxFit.contain);
                  });
                },
                child: ListTile(
                  title: Text(imageFile[index]
                      .path
                      .substring(imageDirectory!.length + 1)),
                ),
              );
            },
          ),
        ),
      ],
    ));
  }

  List<File> findFilesInDirectory(Directory directory) {
    List<File> files = [];
    // 遍历目录中的内容（包括子目录）
    directory.listSync(recursive: true).where((fileSystemEntity) {
      return fileSystemEntity is File &&
          fileSystemEntity.path.toLowerCase().endsWith('.jpg');
    }).forEach((fileSystemEntity) {
      files.add(fileSystemEntity as File);
    });
    return files;
  }
}

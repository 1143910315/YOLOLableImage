import 'dart:convert';
import 'dart:io';
import 'dart:math';

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
  List<String> labelName = [];
  List<List<double>> labelPositionList = [];
  Image showImage = Image.network(
    'https://flutter.cn/assets/images/cn/flutter-cn-logo.png',
    fit: BoxFit.contain,
  );
  int imageWidth = 0;
  int imageHeight = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      programSetting = value;
      imageDirectory = value.getString('imageDirectory');
      labelDirectory = value.getString('labelDirectory');
      if (imageDirectory != null) {
        imageFile = findFilesInDirectory(Directory(imageDirectory!));
      }
    });
  }

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
                  setState(() {
                    labelDirectory = selectedDirectory;
                  });
                  programSetting.setString('labelDirectory', selectedDirectory);
                  File('$selectedDirectory/classes.txt')
                      .readAsString()
                      .then((value) {
                    setState(() {
                      labelName = value.split(RegExp(r'\r\n|\n\r|\r|\n'));
                    });
                  });
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
        Expanded(child: LayoutBuilder(
          builder: (context, constraints) {
            if (imageWidth != 0) {
              double widthScale = constraints.maxWidth / imageWidth;
              double heightScale = constraints.maxWidth / imageWidth;
              double minScale = min(widthScale, heightScale);
              double actuallyWidth = widthScale * minScale;
              double actuallyHeight = heightScale * minScale;
            }
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  showImage,
                  Positioned(
                    top: constraints.maxWidth / 2, // 在垂直方向上距离顶部的偏移量
                    left: constraints.maxHeight / 2, // 在水平方向上距离左侧的偏移量
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.red, // 文字标签背景颜色
                      child: const Text(
                        '标签文本',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        )),
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
                    imageWidth = 0;
                    imageHeight = 0;
                    File showImageFile = imageFile[index];
                    File showLabelFile = File(showImageFile.path.replaceRange(
                        0, imageDirectory!.length, labelDirectory!));
                    showImage = Image.file(showImageFile, fit: BoxFit.contain);
                    showImage.image
                        .resolve(const ImageConfiguration())
                        .addListener(ImageStreamListener(
                            (ImageInfo info, bool synchronousCall) {
                      setState(() {
                        imageWidth = info.image.width;
                        imageHeight = info.image.height;
                      });
                    }));
                    showLabelFile.readAsString(encoding: utf8).then((value) {
                      List<List<double>> tempLabelPositionList = [];
                      List<double> tempDoubleList = [];
                      List<String> labelStringList =
                          value.split(RegExp(r'\r\n|\n\r|\r|\n'));
                      for (var element in labelStringList) {
                        List<String> elementSplit =
                            element.split(RegExp(r"\s+"));
                        for (var str in elementSplit) {
                          double n = double.parse(str);
                          tempDoubleList.add(n);
                        }
                        if (tempDoubleList.length == 5) {
                          tempLabelPositionList.add(tempDoubleList);
                        }
                        tempDoubleList = [];
                      }
                      setState(() {
                        labelPositionList = tempLabelPositionList;
                      });
                    });
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

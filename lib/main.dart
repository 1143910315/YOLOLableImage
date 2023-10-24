import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path_util;
import 'components/resizable_rectangle.dart';

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
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

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
      if (labelDirectory != null) {
        File('$labelDirectory/classes.txt').readAsString().then((value) {
          setState(() {
            labelName = value.split(RegExp(r'\r\n|\n\r|\r|\n'));
          });
        });
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
            double actuallyWidth = 0;
            double actuallyHeight = 0;
            if (imageWidth != 0 && imageHeight != 0) {
              double widthScale = constraints.maxWidth / imageWidth;
              double heightScale = constraints.maxHeight / imageHeight;
              double minScale = min(widthScale, heightScale);
              actuallyWidth = imageWidth * minScale;
              actuallyHeight = imageHeight * minScale;
            }
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                fit: StackFit.expand,
                children: List.generate(labelPositionList.length + 1, (index) {
                  if (index == 0) {
                    return GestureDetector(
                      onDoubleTap: () => setState(() {
                        labelPositionList.add(<double>[0, 0, 0, 0, 0]);
                      }),
                      child: showImage,
                    );
                  } else {
                    List<double> labelPosition = labelPositionList[index - 1];
                    int nameIndex = labelPosition[0].toInt();
                    String showName = nameIndex.toString();
                    if (nameIndex < labelName.length) {
                      showName = labelName[nameIndex];
                    }
                    double left = (constraints.maxWidth +
                            actuallyWidth *
                                (2 * labelPosition[1] - labelPosition[3]) -
                            actuallyWidth) /
                        2;
                    double top = (constraints.maxHeight +
                            actuallyHeight *
                                (2 * labelPosition[2] - labelPosition[4]) -
                            actuallyHeight) /
                        2;
                    return ResizableRectangle(
                      width: labelPosition[3] * actuallyWidth,
                      height: labelPosition[4] * actuallyHeight,
                      left: left,
                      top: top,
                      text: showName,
                      onResizeOrMove: (detail) => setState(() {
                        labelPosition[1] = labelPosition[1] +
                            (detail.left + detail.right) / 2 / actuallyWidth;
                        labelPosition[2] = labelPosition[2] +
                            (detail.top + detail.bottom) / 2 / actuallyHeight;
                        labelPosition[3] = max(
                            labelPosition[3] +
                                (detail.right - detail.left) / actuallyWidth,
                            0);
                        labelPosition[4] = max(
                            labelPosition[4] +
                                (detail.bottom - detail.top) / actuallyHeight,
                            0);
                      }),
                      onLongPress: () => setState(() {
                        labelPositionList.removeAt(index - 1);
                      }),
                      onTextTap: () {
                        
                      },
                    );
                  }
                }),
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
                    File showLabelFile = File(path_util.setExtension(
                        showImageFile.path.replaceRange(
                            0, imageDirectory!.length, labelDirectory!),
                        '.txt'));
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
                        if (elementSplit.length >= 5) {
                          for (var str in elementSplit) {
                            double n = double.parse(str);
                            tempDoubleList.add(n);
                          }
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
                  title: DefaultTextStyle(
                    style: const TextStyle(fontSize: 13, color: Colors.black),
                    child: Text(imageFile[index]
                        .path
                        .substring(imageDirectory!.length + 1)),
                  ),
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

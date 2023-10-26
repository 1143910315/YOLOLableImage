import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
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
  int nowShowImageIndex = -1;
  List<File> imageFile = [];
  List<String> labelName = [];
  List<List<double>> labelPositionList = [];
  Image showImage = Image.network(
    'https://flutter.cn/assets/images/cn/flutter-cn-logo.png',
    fit: BoxFit.contain,
  );
  int imageWidth = 0;
  int imageHeight = 0;
  int selectedLabel = -1;
  String newClassName = "";
  late ImageStreamListener listener;
  bool moveToTrain = false;
  String? trainImageDirectory;
  String? trainLabelDirectory;
  bool changeLabelList = false;
  bool changeClassList = false;
  @override
  void initState() {
    super.initState();
    listener = ImageStreamListener((image, synchronousCall) {
      setState(() {
        imageWidth = image.image.width;
        imageHeight = image.image.height;
      });
    });
    SharedPreferences.getInstance().then((value) {
      programSetting = value;
      imageDirectory = value.getString('imageDirectory');
      labelDirectory = value.getString('labelDirectory');
      trainImageDirectory = value.getString('trainImageDirectory');
      trainLabelDirectory = value.getString('trainLabelDirectory');
      moveToTrain = value.getBool("moveToTrain") ?? false;
      if (imageDirectory != null) {
        imageFile = findFilesInDirectory(Directory(imageDirectory!));
      }
      if (labelDirectory != null) {
        File classesFile = File('$labelDirectory/classes.txt');
        if (classesFile.existsSync()) {
          classesFile.readAsString().then((value) {
            setState(() {
              labelName = value.split(RegExp(r'\r\n|\n\r|\r|\n'));
            });
          });
        }
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
              onPressed: () {
                FilePicker.platform
                    .getDirectoryPath(initialDirectory: imageDirectory)
                    .then((selectedDirectory) {
                  if (selectedDirectory != null) {
                    setState(() {
                      showIndexImage(-1);
                      imageDirectory = selectedDirectory;
                      imageFile =
                          findFilesInDirectory(Directory(selectedDirectory));
                      if (imageFile.isNotEmpty) {
                        nowShowImageIndex = 0;
                      } else {
                        nowShowImageIndex = -1;
                      }
                    });
                    programSetting.setString(
                        'imageDirectory', selectedDirectory);
                  }
                });
              },
              child: const Text('选择图片目录'),
            ),
            const SizedBox(
              height: 40,
            ),
            ElevatedButton(
              onPressed: () {
                FilePicker.platform
                    .getDirectoryPath(initialDirectory: labelDirectory)
                    .then((selectedDirectory) {
                  if (selectedDirectory != null) {
                    setState(() {
                      showIndexImage(-1);
                      labelDirectory = selectedDirectory;
                    });
                    programSetting.setString(
                        'labelDirectory', selectedDirectory);
                    File('$selectedDirectory/classes.txt')
                        .readAsString()
                        .then((value) {
                      setState(() {
                        labelName = value.split(RegExp(r'\r\n|\n\r|\r|\n'));
                      });
                    });
                  }
                });
              },
              child: const Text('选择标签目录'),
            ),
            const SizedBox(
              height: 40,
            ),
            SizedBox(
              width: 150,
              child: CheckboxListTile(
                enabled:
                    trainImageDirectory != null && trainLabelDirectory != null,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.all(0),
                title: const Text(
                  "标注修改时移入训练目录",
                  style: TextStyle(fontSize: 14),
                ),
                value: moveToTrain,
                onChanged: (value) => setState(() {
                  moveToTrain = !moveToTrain;
                  programSetting.setBool("moveToTrain", moveToTrain);
                }),
              ),
            ),
            const SizedBox(
              height: 40,
            ),
            ElevatedButton(
              onPressed: () {
                FilePicker.platform
                    .getDirectoryPath(initialDirectory: trainImageDirectory)
                    .then((selectedDirectory) {
                  if (selectedDirectory != null) {
                    setState(() {
                      trainImageDirectory = selectedDirectory;
                    });
                    programSetting.setString(
                        'trainImageDirectory', selectedDirectory);
                  }
                });
              },
              child: const Text('选择训练图片目录'),
            ),
            const SizedBox(
              height: 40,
            ),
            ElevatedButton(
              onPressed: () {
                FilePicker.platform
                    .getDirectoryPath(initialDirectory: trainLabelDirectory)
                    .then((selectedDirectory) {
                  if (selectedDirectory != null) {
                    setState(() {
                      trainLabelDirectory = selectedDirectory;
                    });
                    programSetting.setString(
                        'trainLabelDirectory', selectedDirectory);
                  }
                });
              },
              child: const Text('选择训练标签目录'),
            ),
            const SizedBox(
              height: 40,
            ),
            ElevatedButton(
              onPressed: () {
                changeLabelList = false;
                changeClassList = false;
                showIndexImage(nowShowImageIndex);
              },
              child: const Text('还原标注'),
            ),
            // const SizedBox(
            //   height: 20,
            // ),
            // ElevatedButton(
            //   onPressed: () {},
            //   child: const Text('下一张图片'),
            // ),
            // const SizedBox(
            //   height: 20,
            // ),
            // ElevatedButton(
            //   onPressed: () {},
            //   child: const Text('上一张图片'),
            // ),
            // const SizedBox(
            //   height: 20,
            // ),
            // ElevatedButton(
            //   onPressed: () {},
            //   child: const Text('保存'),
            // ),
            // const SizedBox(
            //   height: 20,
            // ),
            // ElevatedButton(
            //   onPressed: () {},
            //   child: const Text('创建标签矩形标注'),
            // ),
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
            List<Widget> stackChildrenList = [
              Listener(
                onPointerSignal: (PointerSignalEvent event) {
                  if (event is PointerScrollEvent) {
                    // 判断滚动方向
                    if (event.scrollDelta.dy > 0) {
                      // 向下滚动
                      showIndexImage(nowShowImageIndex + 1);
                    } else if (event.scrollDelta.dy < 0) {
                      // 向上滚动
                      showIndexImage(nowShowImageIndex - 1);
                    }
                  }
                },
                child: GestureDetector(
                  onDoubleTapDown: (details) => setState(() {
                    if (nowShowImageIndex >= 0 &&
                        nowShowImageIndex < imageFile.length) {
                      labelPositionList.add(<double>[
                        0,
                        (details.localPosition.dx -
                                (constraints.maxWidth - actuallyWidth) / 2) /
                            max(actuallyWidth, 1),
                        (details.localPosition.dy -
                                (constraints.maxHeight - actuallyHeight) / 2) /
                            max(actuallyHeight, 1),
                        0,
                        0
                      ]);
                    }
                  }),
                  onHorizontalDragEnd: (details) {
                    double ratio = details.velocity.pixelsPerSecond.dx /
                        constraints.maxWidth;
                    if (ratio > 0.5) {
                      showIndexImage(nowShowImageIndex - 1);
                    } else if (ratio < -0.5) {
                      showIndexImage(nowShowImageIndex + 1);
                    }
                  },
                  onVerticalDragEnd: (details) {
                    double ratio = details.velocity.pixelsPerSecond.dy /
                        constraints.maxHeight;
                    if (ratio > 0.5) {
                      showIndexImage(nowShowImageIndex + 1);
                    } else if (ratio < -0.5) {
                      showIndexImage(nowShowImageIndex - 1);
                    }
                  },
                  child: showImage,
                  // child: DragItemWidget(
                  //   dragItemProvider: (request) async {
                  //     // DragItem represents the content begin dragged.
                  //     final item = DragItem();
                  //     // Add data for this item that other applications can read
                  //     // on drop. (optional)
                  //     item.add(Formats.png(await createImageData()));
                  //     item.add(Formats.png(Uint8List.fromList(utf8.encode(
                  //         r"D:\Code\Python\IdentifyingEmoticons\success\image\$$$QGXZTA]YQZLS5@I)$]IY.jpg"))));
                  //     return item;
                  //   },
                  //   allowedOperations: () => [DropOperation.copy],
                  //   // DraggableWidget represents the actual draggable area. It looks
                  //   // for parent DragItemWidget in widget hierarchy to provide the DragItem.
                  //   child: DraggableWidget(
                  //     child: showImage,
                  //   ),
                  // ),
                ),
              )
            ];
            stackChildrenList
                .addAll(List.generate(labelPositionList.length, (index) {
              List<double> labelPosition = labelPositionList[index];
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
                  changeLabelList = true;
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
                  changeLabelList = true;
                  labelPositionList.removeAt(index);
                }),
                onTextTap: () => setState(() {
                  selectedLabel = index;
                }),
                onPointerSignal: (PointerSignalEvent event) {
                  if (event is PointerScrollEvent) {
                    // 判断滚动方向
                    if (event.scrollDelta.dy > 0) {
                      // 向下滚动
                      showIndexImage(nowShowImageIndex + 1);
                    } else if (event.scrollDelta.dy < 0) {
                      // 向上滚动
                      showIndexImage(nowShowImageIndex - 1);
                    }
                  }
                },
              );
            }));
            if (selectedLabel >= 0 &&
                selectedLabel < labelPositionList.length) {
              stackChildrenList.add(Positioned(
                right: 20,
                top: 40,
                width: 200,
                bottom: 40,
                child: Container(
                  color: const Color.fromARGB(209, 211, 211, 211),
                  child: ListView.builder(
                    itemCount: labelName.length + 1,
                    itemBuilder: (context, index) {
                      if (index < labelName.length) {
                        return InkWell(
                          onTap: () => setState(() {
                            changeLabelList = true;
                            int temp = selectedLabel;
                            selectedLabel = -1;
                            labelPositionList[temp][0] = index.toDouble();
                          }),
                          child: ListTile(
                            shape: const Border(
                              bottom: BorderSide(
                                color: Color.fromARGB(255, 133, 133, 133),
                              ),
                              left: BorderSide(
                                color: Color.fromARGB(255, 133, 133, 133),
                              ),
                              right: BorderSide(
                                color: Color.fromARGB(255, 133, 133, 133),
                              ),
                            ),
                            title: DefaultTextStyle(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                              child: Text(labelName[index]),
                            ),
                          ),
                        );
                      } else {
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  style: const TextStyle(fontSize: 12),
                                  decoration: const InputDecoration(
                                    hintText: '请输入文本',
                                  ),
                                  onChanged: (value) {
                                    newClassName = value;
                                  },
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    changeLabelList = true;
                                    changeClassList = true;
                                    int temp = selectedLabel;
                                    selectedLabel = -1;
                                    labelPositionList[temp][0] =
                                        labelName.length.toDouble();
                                    labelName.add(newClassName);
                                  }),
                                  child: const Icon(
                                    Icons.check_box,
                                    color: Color.fromARGB(255, 103, 255, 110),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ));
            }
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                fit: StackFit.expand,
                children: stackChildrenList,
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
                onTap: () => showIndexImage(index),
                child: ListTile(
                  title: DefaultTextStyle(
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                    ),
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
    if (directory.existsSync()) {
      // 遍历目录中的内容（包括子目录）
      directory.listSync(recursive: true).where((fileSystemEntity) {
        return fileSystemEntity is File &&
            fileSystemEntity.path.toLowerCase().endsWith('.jpg');
      }).forEach((fileSystemEntity) {
        files.add(fileSystemEntity as File);
      });
    }
    return files;
  }

  void showIndexImage(int index) {
    bool moveFile = false;
    int operationIndex = nowShowImageIndex;
    if (changeLabelList) {
      File operationFile = imageFile[operationIndex];
      IOSink ioSink = File(path_util.setExtension(
              operationFile.path
                  .replaceRange(0, imageDirectory!.length, labelDirectory!),
              '.txt'))
          .openWrite();
      for (var element in labelPositionList) {
        double centerX = element[1];
        double centerY = element[2];
        double width = element[3];
        double height = element[4];
        if (centerX - width / 2 < 0) {
          double newRight = centerX + width / 2;
          centerX = newRight / 2;
          width = newRight;
        }
        if (centerX + width / 2 > 1) {
          double newLeft = centerX - width / 2;
          centerX = (1 + newLeft) / 2;
          width = 1 - newLeft;
        }
        if (centerY - height / 2 < 0) {
          double newBottom = centerY + height / 2;
          centerY = newBottom / 2;
          height = newBottom;
        }
        if (centerY + height / 2 > 1) {
          double newTop = centerY - height / 2;
          centerY = (1 + newTop) / 2;
          height = 1 - newTop;
        }
        ioSink.writeln(
            "${element[0].toInt()} ${centerX.toStringAsFixed(6)} ${centerY.toStringAsFixed(6)} ${width.toStringAsFixed(6)} ${height.toStringAsFixed(6)}");
      }
      String? tempImageDirectory = trainImageDirectory;
      String? tempLabelDirectory = trainLabelDirectory;
      String? temp = labelDirectory;
      if (moveToTrain &&
          tempImageDirectory != null &&
          tempLabelDirectory != null &&
          temp != null) {
        moveFile = true;
      }
      ioSink.flush().then((value) => ioSink.close().then((value) {
            if (moveFile) {
              setState(() {
                String baseName = path_util.basename(operationFile.path);
                operationFile
                    .rename(path_util.join(tempImageDirectory!, baseName));
                File labelFile = File(path_util.join(temp!, baseName));
                labelFile.exists().then((value) {
                  String toPath = path_util.join(tempLabelDirectory!,
                      path_util.setExtension(baseName, ".txt"));
                  if (value) {
                    labelFile.rename(toPath);
                  } else {
                    File(toPath).create(recursive: true);
                  }
                });
              });
            }
          }));
    }
    if (changeClassList) {
      IOSink ioSink = File('$labelDirectory/classes.txt').openWrite();
      for (var element in labelName) {
        ioSink.writeln(element.trim());
      }
      ioSink.flush().then((value) => ioSink.close());
    }
    setState(() {
      changeLabelList = false;
      changeClassList = false;
      if (moveFile) {
        imageFile.removeAt(operationIndex);
        if (index > operationIndex) {
          index = index - 1;
        }
      }
      if (imageFile.isNotEmpty) {
        if (index != -1) {
          index = index.clamp(0, imageFile.length - 1);
          imageWidth = 0;
          imageHeight = 0;
          selectedLabel = -1;
          File showImageFile = imageFile[index];
          File showLabelFile = File(path_util.setExtension(
              showImageFile.path
                  .replaceRange(0, imageDirectory!.length, labelDirectory!),
              '.txt'));
          nowShowImageIndex = index;
          showImage.image
              .resolve(const ImageConfiguration())
              .removeListener(listener);
          showImage = Image.file(showImageFile, fit: BoxFit.contain);
          showImage.image
              .resolve(const ImageConfiguration())
              .addListener(listener);
          showLabelFile.exists().then((value) {
            if (value) {
              showLabelFile.readAsString(encoding: utf8).then((value) {
                List<List<double>> tempLabelPositionList = [];
                List<double> tempDoubleList = [];
                List<String> labelStringList =
                    value.split(RegExp(r'\r\n|\n\r|\r|\n'));
                for (var element in labelStringList) {
                  List<String> elementSplit = element.split(RegExp(r"\s+"));
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
            } else {
              setState(() {
                labelPositionList = [];
              });
            }
          });
        }
      } else {
        nowShowImageIndex = -1;
        showImage = Image.network(
          'https://flutter.cn/assets/images/cn/flutter-cn-logo.png',
          fit: BoxFit.contain,
        );
      }
    });
  }

  Future<Uint8List> createImageData() async {
    // 加载图片
    final bytes = await imageFile[nowShowImageIndex].readAsBytes();
    final codec = await instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    final image = frameInfo.image;
    final data = await image.toByteData(format: ImageByteFormat.png);
    Uint8List l = data!.buffer.asUint8List();
    return l;
  }
}

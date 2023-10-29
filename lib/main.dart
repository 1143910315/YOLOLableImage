import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path_util;

import 'components/label_image.dart';

class LabelInfo {
  final List<RectangleData> rectangleList;
  bool change;
  LabelInfo(
    this.rectangleList, {
    this.change = false,
  });
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '适用于YOLO模型的图像标注软件',
      theme: ThemeData(
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
  List<LabelInfo> labelInfoList = [];
  List<int>? selectedLabel;
  String newClassName = "";
  bool moveToTrain = false;
  String? trainImageDirectory;
  String? trainLabelDirectory;
  bool changeClassList = false;
  int showPictureNumber = 1;
  late final PointerSignalEventListener onPointerSignal;
  @override
  void initState() {
    super.initState();
    onPointerSignal = (event) {
      if (event is PointerScrollEvent) {
        // 判断滚动方向
        if (event.scrollDelta.dy > 0) {
          if (nowShowImageIndex > -1) {
            // 向下滚动
            showIndexImage(nowShowImageIndex + showPictureNumber);
          } else {
            // 向下滚动
            showIndexImage(0);
          }
        } else if (event.scrollDelta.dy < 0) {
          showIndexImage(nowShowImageIndex - showPictureNumber);
        }
        selectedLabel = null;
      }
    };
    SharedPreferences.getInstance().then((value) => setState(() {
          programSetting = value;
          imageDirectory = value.getString('imageDirectory');
          labelDirectory = value.getString('labelDirectory');
          trainImageDirectory = value.getString('trainImageDirectory');
          trainLabelDirectory = value.getString('trainLabelDirectory');
          moveToTrain = value.getBool("moveToTrain") ?? false;
          showPictureNumber = value.getInt("showPictureNumber") ?? 1;
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
          showIndexImage(nowShowImageIndex);
        }));
  }

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 1;
    for (var i = 1;; i++) {
      if (showPictureNumber > pow(i - 1, 2) && showPictureNumber <= pow(i, 2)) {
        crossAxisCount = i;
        break;
      }
    }
    return Material(
      child: Row(
        children: [
          const SizedBox(
            width: 10,
          ),
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    FilePicker.platform
                        .getDirectoryPath(initialDirectory: imageDirectory)
                        .then((selectedDirectory) {
                      if (selectedDirectory != null) {
                        setState(() {
                          imageDirectory = selectedDirectory;
                          imageFile = findFilesInDirectory(
                              Directory(selectedDirectory));
                          showIndexImage(-1);
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
                          labelDirectory = selectedDirectory;
                          showIndexImage(-1);
                        });
                        programSetting.setString(
                            'labelDirectory', selectedDirectory);
                        var classesFile =
                            File('$selectedDirectory/classes.txt');
                        classesFile.exists().then((value) {
                          if (value) {
                            classesFile.readAsString().then((value) {
                              setState(() {
                                labelName =
                                    value.split(RegExp(r'\r\n|\n\r|\r|\n'));
                              });
                            });
                          }
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
                    enabled: trainImageDirectory != null &&
                        trainLabelDirectory != null,
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
                    for (var element in labelInfoList) {
                      element.change = false;
                    }
                    changeClassList = false;
                    showIndexImage(nowShowImageIndex);
                  },
                  child: const Text('还原标注'),
                ),
                const SizedBox(
                  height: 40,
                ),
                DropdownButton<int>(
                  value: showPictureNumber,
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      showPictureNumber = newValue;
                      programSetting.setInt("showPictureNumber", newValue);
                      changeClassList = false;
                      showIndexImage(nowShowImageIndex);
                    }
                  },
                  items: <int>[1, 4, 9, 16].map((int value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text('一次显示$value张'),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Stack(
              children: [
                Listener(
                  onPointerSignal: onPointerSignal,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double columnSpacing = 5;
                      double rowSpacing = 5;
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount, // 列数
                          crossAxisSpacing: columnSpacing, // 列间距
                          mainAxisSpacing: rowSpacing, // 行间距
                          childAspectRatio: ((constraints.maxWidth +
                                          columnSpacing -
                                          columnSpacing * crossAxisCount) *
                                      (showPictureNumber / crossAxisCount)
                                          .ceil() +
                                  1) /
                              ((constraints.maxHeight +
                                      rowSpacing -
                                      rowSpacing *
                                          (showPictureNumber / crossAxisCount)
                                              .ceil()) *
                                  crossAxisCount),
                        ),
                        itemCount: showPictureNumber, // 网格项数量
                        itemBuilder: (BuildContext context, int index) {
                          if (nowShowImageIndex != -1 &&
                              nowShowImageIndex + index < imageFile.length) {
                            while (index >= labelInfoList.length) {
                              labelInfoList.add(LabelInfo([]));
                            }
                            var tempLabelInfo = labelInfoList[index];
                            return LabelImage(
                              imageFile: imageFile[nowShowImageIndex + index],
                              classNameList: labelName,
                              rectangleDataList: tempLabelInfo.rectangleList,
                              onChangeRectangle: (rectangleIndex, centerX,
                                      centerY, width, height) =>
                                  setState(() {
                                if (rectangleIndex == -1) {
                                  tempLabelInfo.rectangleList.add(RectangleData(
                                      classIndex: 0,
                                      centerX: centerX,
                                      centerY: centerY,
                                      width: width,
                                      height: height));
                                } else {
                                  tempLabelInfo.rectangleList[rectangleIndex]
                                      .centerX = centerX;
                                  tempLabelInfo.rectangleList[rectangleIndex]
                                      .centerY = centerY;
                                  tempLabelInfo.rectangleList[rectangleIndex]
                                      .width = width;
                                  tempLabelInfo.rectangleList[rectangleIndex]
                                      .height = height;
                                }
                                tempLabelInfo.change = true;
                              }),
                              onDeleteRectangle: (rectangleIndex) =>
                                  setState(() {
                                tempLabelInfo.rectangleList
                                    .removeAt(rectangleIndex);
                                tempLabelInfo.change = true;
                              }),
                              onSelectClass: (rectangleIndex) => setState(() {
                                selectedLabel = <int>[index, rectangleIndex];
                              }),
                            );
                          } else {
                            return const Text("无图片");
                          }
                        },
                      );
                    },
                  ),
                ),
                Visibility(
                  visible: selectedLabel != null,
                  child: Positioned(
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
                                  var temp = selectedLabel;
                                  if (temp != null) {
                                    labelInfoList[temp[0]].change = true;
                                    labelInfoList[temp[0]]
                                        .rectangleList[temp[1]]
                                        .classIndex = index;
                                  }
                                  selectedLabel = null;
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
                                          var temp = selectedLabel;
                                          if (temp != null) {
                                            labelInfoList[temp[0]].change =
                                                true;
                                            labelInfoList[temp[0]]
                                                .rectangleList[temp[1]]
                                                .classIndex = labelName.length;
                                          }
                                          selectedLabel = null;
                                          changeClassList = true;
                                          labelName.add(newClassName);
                                        }),
                                        child: const Icon(
                                          Icons.check_box,
                                          color: Color.fromARGB(
                                              255, 103, 255, 110),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }),
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
              ),
            ),
          ),
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
      ),
    );
  }

  List<File> findFilesInDirectory(Directory directory) {
    List<File> files = [];
    if (directory.existsSync()) {
      // 遍历目录中的内容（包括子目录）
      directory.listSync(recursive: true).where((fileSystemEntity) {
        if (fileSystemEntity is File) {
          var filePathLowerCase = fileSystemEntity.path.toLowerCase();
          return filePathLowerCase.endsWith('.jpg') ||
              filePathLowerCase.endsWith('.jpeg') ||
              filePathLowerCase.endsWith('.png') ||
              filePathLowerCase.endsWith('.bmp') ||
              filePathLowerCase.endsWith('.gif');
        }
        return false;
      }).forEach((fileSystemEntity) {
        files.add(fileSystemEntity as File);
      });
    }
    return files;
  }

  void showIndexImage(int index) {
    var moveFile = List.generate(labelInfoList.length, (index) => false);
    var operationIndex = nowShowImageIndex;
    for (var i = 0; i < labelInfoList.length; i++) {
      var labelInfo = labelInfoList[i];
      if (labelInfo.change) {
        var operationFile = imageFile[operationIndex + i];
        var ioSink = File(path_util.setExtension(
                operationFile.path
                    .replaceRange(0, imageDirectory!.length, labelDirectory!),
                '.txt'))
            .openWrite();
        for (var element in labelInfo.rectangleList) {
          double centerX = element.centerX;
          double centerY = element.centerY;
          double width = element.width;
          double height = element.height;
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
              "${element.classIndex} ${centerX.toStringAsFixed(6)} ${centerY.toStringAsFixed(6)} ${width.toStringAsFixed(6)} ${height.toStringAsFixed(6)}");
        }
        String? tempImageDirectory = trainImageDirectory;
        String? tempLabelDirectory = trainLabelDirectory;
        String? temp = labelDirectory;
        if (moveToTrain &&
            tempImageDirectory != null &&
            tempLabelDirectory != null &&
            temp != null) {
          moveFile[i] = true;
        }
        ioSink.flush().then((value) => ioSink.close().then((value) {
              if (moveFile[i]) {
                setState(() {
                  String baseName = path_util.basename(operationFile.path);
                  operationFile
                      .rename(path_util.join(tempImageDirectory!, baseName));
                  File labelFile = File(path_util.setExtension(
                      path_util.join(temp!, baseName), ".txt"));
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
    }
    if (changeClassList) {
      IOSink ioSink = File('$labelDirectory/classes.txt').openWrite();
      for (var element in labelName) {
        ioSink.writeln(element.trim());
      }
      ioSink.flush().then((value) => ioSink.close());
    }
    setState(() {
      changeClassList = false;
      for (var i = 0, removeIndex = 0;
          i < moveFile.length;
          i++, removeIndex++) {
        if (moveFile[i]) {
          imageFile.removeAt(operationIndex + removeIndex);
          if (index > operationIndex + removeIndex) {
            index--;
          }
          removeIndex--;
        }
      }
      if (imageFile.isNotEmpty) {
        index = index.clamp(0, imageFile.length - showPictureNumber);
        var tempLabelInfoList =
            List.generate(showPictureNumber, (_) => LabelInfo([]));
        labelInfoList = tempLabelInfoList;
        nowShowImageIndex = index;
        for (var i = 0; i < tempLabelInfoList.length; i++) {
          (int num, LabelInfo labelInfo) {
            var showImageFile = imageFile[index + num];
            var showLabelFile = File(path_util.setExtension(
                showImageFile.path
                    .replaceRange(0, imageDirectory!.length, labelDirectory!),
                '.txt'));
            showLabelFile.exists().then((isExists) {
              if (isExists) {
                showLabelFile.readAsString(encoding: utf8).then((value) {
                  var tempData = <RectangleData>[];
                  var labelStringList = value.split(RegExp(r'\r\n|\n\r|\r|\n'));
                  for (var element in labelStringList) {
                    var elementSplit = element.split(RegExp(r"\s+"));
                    if (elementSplit.length >= 5) {
                      tempData.add(RectangleData(
                          classIndex: int.tryParse(elementSplit[0]) ?? 0,
                          centerX: double.tryParse(elementSplit[1]) ?? 0,
                          centerY: double.tryParse(elementSplit[2]) ?? 0,
                          width: double.tryParse(elementSplit[3]) ?? 0,
                          height: double.tryParse(elementSplit[4]) ?? 0));
                    }
                  }
                  setState(() {
                    labelInfo.rectangleList.addAll(tempData);
                  });
                });
              }
            });
          }(i, tempLabelInfoList[i]);
        }
      } else {
        nowShowImageIndex = -1;
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

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

typedef ExternalProgramsChangeCallback = void Function(
    String newExternalPrograms);
typedef ArgumentsChangeCallback = void Function(String newArguments);

class ExecuteDialog extends StatefulWidget {
  const ExecuteDialog(
      {super.key,
      this.externalPrograms,
      this.arguments,
      this.onExternalProgramsChange,
      this.onArgumentsChange});

  final String? externalPrograms;
  final String? arguments;

  final ExternalProgramsChangeCallback? onExternalProgramsChange;
  final ArgumentsChangeCallback? onArgumentsChange;
  @override
  State<ExecuteDialog> createState() => _ExecuteDialogState();
}

class _ExecuteDialogState extends State<ExecuteDialog> {
  late final TextEditingController externalProgramsTextEditingController;
  late final List<TextEditingController> argumentsTextEditingController =
      List.empty(growable: true);
  @override
  void initState() {
    super.initState();
    externalProgramsTextEditingController =
        TextEditingController(text: widget.externalPrograms);
    try {
      List<dynamic> argumentArray = jsonDecode(widget.arguments ?? "[]");
      for (var element in argumentArray) {
        argumentsTextEditingController
            .add(generateTextEditingController(element));
      }
    } finally {
      argumentsTextEditingController.add(generateTextEditingController(""));
    }
  }

  @override
  Widget build(BuildContext context) {
    externalProgramsTextEditingController.addListener(() {
      ExternalProgramsChangeCallback? temp = widget.onExternalProgramsChange;
      if (temp != null &&
          externalProgramsTextEditingController.text !=
              widget.externalPrograms) {
        temp(externalProgramsTextEditingController.text);
        setState(() {});
      }
    });
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 600,
          height: 400,
          child: Column(children: [
            SizedBox(
              height: 50,
              child: Center(
                child: Row(
                  children: [
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "外部程序调用",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close))
                  ],
                ),
              ),
            ),
            Row(
              children: [
                const Text("外部程序位置："),
                Expanded(
                  child: TextField(
                    controller: externalProgramsTextEditingController,
                    decoration: const InputDecoration(
                        hintText: "例如：C:\\Windows\\explorer.exe"),
                  ),
                ),
                ElevatedButton(
                  child: const Text('选择外部程序'),
                  onPressed: () {
                    FilePicker.platform
                        .pickFiles(
                      dialogTitle: "选择外部程序",
                    )
                        .then((filePickerResult) {
                      if (filePickerResult != null &&
                          filePickerResult.count == 1) {
                        String? path = filePickerResult.paths[0];
                        if (path != null) {
                          ExternalProgramsChangeCallback? temp =
                              widget.onExternalProgramsChange;
                          if (temp != null &&
                              externalProgramsTextEditingController.text !=
                                  widget.externalPrograms) {
                            temp(externalProgramsTextEditingController.text);
                          }
                        }
                      }
                    });
                  },
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: argumentsTextEditingController.length + 1,
                itemBuilder: (context, index) {
                  if (index < argumentsTextEditingController.length) {
                    return Row(
                      children: [
                        const Text("附加命令行参数："),
                        Expanded(
                          child: TextField(
                            controller: argumentsTextEditingController[index],
                            decoration: const InputDecoration(
                                hintText:
                                    '使用\${file1}和\${file2}表示单文件或多文件的完整路径'),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const SizedBox(
                      height: 5,
                    );
                  }
                },
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(argumentListToString(generateArgumentList(["c:\\1.txt", "c:\\2.txt", "c:\\3.txt"]))),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              child: const Text('调用外部程序'),
              onPressed: () async {
                ProcessResult result = await Process.run(
                    externalProgramsTextEditingController.text, []);
                String str = result.stdout.toString();
                str.isEmpty;
              },
            ),
            const SizedBox(
              height: 20,
            ),
          ]),
        ),
      ),
    );
  }

  List<String> generateArgumentList(List<String> path) {
    List<String> arguments = List.generate(
        argumentsTextEditingController.length - 1,
        (index) => argumentsTextEditingController[index].text);
    int begin = -1;
    int end = -1;
    for (var i = 0; i < arguments.length; i++) {
      String text = arguments[i];
      if (begin == -1) {
        if (text.contains(r"${file1}")) {
          begin = i;
        }
      } else {
        if (text.contains(r"${file2}")) {
          end = i;
          break;
        }
      }
    }
    if (begin == -1 && end == -1) {
      return arguments;
    } else {
      if (path.isEmpty) {
        if (end == -1) {
          end = begin;
        }
        for (var i = begin; i <= end; i++) {
          arguments.removeAt(begin);
        }
      } else {
        if (begin != -1) {
          arguments[begin] = arguments[begin].replaceAll(r"${file1}", path[0]);
          if (end != -1) {
            if (path.length == 1) {
              for (var i = begin + 1; i <= end; i++) {
                arguments.removeAt(begin + 1);
              }
            } else {
              for (var i = path.length - 1; i >= 2; i--) {
                arguments.insertAll(
                    end + 1,
                    List.generate(
                        end - begin,
                        (index) => arguments[begin + 1 + index]
                            .replaceAll(r"${file2}", path[i])));
              }
              for (var i = begin + 1; i <= end; i++) {
                arguments[i] = arguments[i].replaceAll(r"${file2}", path[1]);
              }
            }
          }
        }
      }
      return arguments;
    }
  }

  String argumentListToString(List<String> argumentList) {
    for (var i = 0; i < argumentList.length; i++) {
      String string = argumentList[i];
      if (string.contains(" ")) {
        argumentList[i] =
            "\"${string.replaceAll("\\", "\\\\").replaceAll("\"", "\\\"")}\"";
      }
    }
    return argumentList.join(" ");
  }

  String generateArguments(List<String> path) {
    List<String> arguments = List.generate(
        argumentsTextEditingController.length - 1,
        (index) => argumentsTextEditingController[index].text);
    String argumentsPattern = arguments.join(" ");
    final regex = RegExp(
        r'^(.*?)(?=\$\{file1\}|$)(\$\{file1\})?((?<=\$\{file1\}).*(?=\$\{file2\}))?(\$\{file2\})?(.*)$');
    final match = regex.firstMatch(argumentsPattern);
    if (match != null) {
      String beginString = match.group(1) ?? "";
      String? file1String = match.group(2);
      String? separateString = match.group(3);
      String endString = match.group(5) ?? "";
      if (separateString != null) {
        String concatenationString = path.join(separateString);
        return "$beginString$concatenationString$endString";
      } else {
        if (file1String != null && path.isNotEmpty) {
          String firstPath = path[0];
          return "$beginString$firstPath$endString";
        } else {
          return "$beginString$endString";
        }
      }
    } else {
      return "";
    }
  }

  TextEditingController generateTextEditingController(String text) {
    TextEditingController tempController = TextEditingController(text: text);
    tempController.addListener(() {
      setState(() {
        if (argumentsTextEditingController.indexOf(tempController) !=
            argumentsTextEditingController.length - 1) {
          if (tempController.text.isEmpty) {
            argumentsTextEditingController.remove(tempController);
          }
        } else {
          if (tempController.text.isNotEmpty) {
            argumentsTextEditingController
                .add(generateTextEditingController(""));
          }
        }
        List<String> stringList = List.generate(
            argumentsTextEditingController.length - 1,
            (index) => argumentsTextEditingController[index].text,
            growable: false);
        String json = jsonEncode(stringList);
        ArgumentsChangeCallback? temp = widget.onArgumentsChange;
        if (temp != null && json != widget.arguments) {
          temp(json);
        }
      });
    });
    return tempController;
  }
}

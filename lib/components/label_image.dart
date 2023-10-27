import 'dart:io';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_application_1/components/resizable_rectangle.dart';

typedef ChangeRectangleCallback = void Function(
    int index, double centerX, double centerY, double width, double height);
typedef DeleteRectangleCallback = void Function(int index);
typedef SelectClassCallback = void Function(int index);

class RectangleData {
  final double centerX;
  final double centerY;
  final double width;
  final double height;
  final int classIndex;
  RectangleData({
    required this.classIndex,
    required this.centerX,
    required this.centerY,
    required this.width,
    required this.height,
  });
}

class LabelImage extends StatefulWidget {
  const LabelImage(
      {super.key,
      this.onPointerSignal,
      this.onChangeRectangle,
      required this.imageFile,
      required this.classNameList,
      required this.rectangleDataList,
      this.onDeleteRectangle,
      this.onSelectClass});
  final File imageFile;
  final List<String> classNameList;
  final List<RectangleData> rectangleDataList;
  final PointerSignalEventListener? onPointerSignal;
  final ChangeRectangleCallback? onChangeRectangle;
  final DeleteRectangleCallback? onDeleteRectangle;
  final SelectClassCallback? onSelectClass;
  @override
  State<LabelImage> createState() => _LabelImageState();
}

class _LabelImageState extends State<LabelImage> {
  late ImageStreamListener imageListener;
  int imageWidth = 0;
  int imageHeight = 0;
  Image? showImage;
  File? nowImageFile;
  @override
  void initState() {
    super.initState();
    imageListener = ImageStreamListener((image, synchronousCall) {
      setState(() {
        imageWidth = image.image.width;
        imageHeight = image.image.height;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    File? tempNowImageFile = nowImageFile;
    if (tempNowImageFile == null || tempNowImageFile != widget.imageFile) {
      Image? tempImage = showImage;
      imageWidth = 0;
      imageHeight = 0;
      if (tempImage != null) {
        tempImage.image
            .resolve(const ImageConfiguration())
            .removeListener(imageListener);
      }
      tempImage = Image.file(widget.imageFile, fit: BoxFit.contain);
      tempImage.image
          .resolve(const ImageConfiguration())
          .addListener(imageListener);
      showImage = tempImage;
      nowImageFile = widget.imageFile;
    }
    List<RectangleData> tempRectangleDataList = widget.rectangleDataList;
    List<String> tempClassNameList = widget.classNameList;
    return LayoutBuilder(
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
            onPointerSignal: widget.onPointerSignal,
            child: GestureDetector(
              onDoubleTapDown: (details) {
                ChangeRectangleCallback? callback = widget.onChangeRectangle;
                if (callback != null) {
                  callback(
                      -1,
                      (details.localPosition.dx -
                              (constraints.maxWidth - actuallyWidth) / 2) /
                          max(actuallyWidth, 1),
                      (details.localPosition.dy -
                              (constraints.maxHeight - actuallyHeight) / 2) /
                          max(actuallyHeight, 1),
                      0,
                      0);
                }
              },
              child: showImage,
            ),
          )
        ];
        stackChildrenList
            .addAll(List.generate(tempRectangleDataList.length, (index) {
          RectangleData rectangleData = tempRectangleDataList[index];
          int classIndex = rectangleData.classIndex;
          String showName = classIndex.toString();
          if (classIndex < tempClassNameList.length) {
            showName = tempClassNameList[classIndex];
          }
          double left = (constraints.maxWidth +
                  actuallyWidth *
                      (2 * rectangleData.centerX - rectangleData.width) -
                  actuallyWidth) /
              2;
          double top = (constraints.maxHeight +
                  actuallyHeight *
                      (2 * rectangleData.centerY - rectangleData.height) -
                  actuallyHeight) /
              2;
          return ResizableRectangle(
            width: rectangleData.width * actuallyWidth,
            height: rectangleData.height * actuallyHeight,
            left: left,
            top: top,
            text: showName,
            onResizeOrMove: (detail) {
              ChangeRectangleCallback? callback = widget.onChangeRectangle;
              if (callback != null) {
                callback(
                    index,
                    rectangleData.centerX +
                        (detail.left + detail.right) / 2 / actuallyWidth,
                    rectangleData.centerY +
                        (detail.top + detail.bottom) / 2 / actuallyHeight,
                    max(
                        rectangleData.width +
                            (detail.right - detail.left) / actuallyWidth,
                        0),
                    max(
                        rectangleData.height +
                            (detail.bottom - detail.top) / actuallyHeight,
                        0));
              }
            },
            onLongPress: () {
              DeleteRectangleCallback? callback = widget.onDeleteRectangle;
              if (callback != null) {
                callback(index);
              }
            },
            onTextTap: () {
              SelectClassCallback? callback = widget.onSelectClass;
              if (callback != null) {
                callback(index);
              }
            },
            onPointerSignal: widget.onPointerSignal,
          );
        }));
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            fit: StackFit.expand,
            children: stackChildrenList,
          ),
        );
      },
    );
  }
}

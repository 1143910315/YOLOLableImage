import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef ResizeOrMoveCallback = void Function(ResizeOrMoveDetail detail);
typedef MoveEvent = void Function(double left, double top);

class ResizeOrMoveDetail {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final bool isMove;
  ResizeOrMoveDetail({
    required this.isMove,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });
}

class ResizableRectangle extends StatefulWidget {
  const ResizableRectangle({
    super.key,
    required this.width,
    required this.height,
    required this.left,
    required this.top,
    this.onResizeOrMove,
    this.text = "",
    this.onDoubleTap,
    this.onLongPress,
    this.onTextTap,
    this.onPointerSignal,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final String text;
  final int circleSize = 12;
  final ResizeOrMoveCallback? onResizeOrMove;
  final GestureTapCallback? onDoubleTap;
  final GestureLongPressCallback? onLongPress;
  final GestureTapCallback? onTextTap;
  final PointerSignalEventListener? onPointerSignal;
  @override
  State<ResizableRectangle> createState() => _ResizableRectangleState();
}

class _ResizableRectangleState extends State<ResizableRectangle> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left - widget.circleSize / 2,
      top: widget.top - widget.circleSize / 2,
      child: Listener(
        onPointerSignal: widget.onPointerSignal,
        child: SizedBox(
          width: widget.width + widget.circleSize,
          height: widget.height + widget.circleSize,
          child: Stack(
            children: [
              Positioned(
                  left: widget.circleSize / 2,
                  top: widget.circleSize / 2,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      ResizeOrMoveCallback? tempEvent = widget.onResizeOrMove;
                      if (tempEvent != null) {
                        tempEvent(ResizeOrMoveDetail(
                          isMove: true,
                          left: details.delta.dx,
                          top: details.delta.dy,
                          right: details.delta.dx,
                          bottom: details.delta.dy,
                        ));
                      }
                    },
                    onDoubleTap: widget.onDoubleTap,
                    onLongPress: widget.onLongPress,
                    child: Container(
                      width: widget.width,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(141, 33, 149, 243),
                        border: Border.all(
                            color: const Color.fromARGB(255, 33, 149, 243),
                            width: 2),
                      ),
                    ),
                  )),
              _buildDraggableCorner(const Offset(0, 0), (left, top) {
                ResizeOrMoveCallback? tempEvent = widget.onResizeOrMove;
                if (tempEvent != null) {
                  tempEvent(ResizeOrMoveDetail(
                    isMove: false,
                    left: left,
                    top: top,
                    right: 0,
                    bottom: 0,
                  ));
                }
              }),
              _buildDraggableCorner(Offset(widget.width, 0), (left, top) {
                ResizeOrMoveCallback? tempEvent = widget.onResizeOrMove;
                if (tempEvent != null) {
                  tempEvent(ResizeOrMoveDetail(
                    isMove: false,
                    left: 0,
                    top: top,
                    right: left,
                    bottom: 0,
                  ));
                }
              }),
              _buildDraggableCorner(Offset(0, widget.height), (left, top) {
                ResizeOrMoveCallback? tempEvent = widget.onResizeOrMove;
                if (tempEvent != null) {
                  tempEvent(ResizeOrMoveDetail(
                    isMove: false,
                    left: left,
                    top: 0,
                    right: 0,
                    bottom: top,
                  ));
                }
              }),
              _buildDraggableCorner(Offset(widget.width, widget.height),
                  (left, top) {
                ResizeOrMoveCallback? tempEvent = widget.onResizeOrMove;
                if (tempEvent != null) {
                  tempEvent(ResizeOrMoveDetail(
                    isMove: false,
                    left: 0,
                    top: 0,
                    right: left,
                    bottom: top,
                  ));
                }
              }),
              Positioned(
                left: 5 + widget.circleSize / 2,
                top: 5 + widget.circleSize / 2,
                child: GestureDetector(
                  onTap: widget.onTextTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red, // 文字标签背景颜色
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableCorner(Offset position, MoveEvent event) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          event(details.delta.dx, details.delta.dy);
        },
        child: Container(
          width: widget.circleSize.toDouble(),
          height: widget.circleSize.toDouble(),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

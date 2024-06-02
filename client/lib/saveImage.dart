import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import "package:path_provider/path_provider.dart";
import 'dart:io';
class SaveImages{
  GlobalKey globalKey = GlobalKey();

  Future<void> captureAndSave() async {
    try {
      RenderRepaintBoundary? boundary =
      globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      ui.Image image = await boundary!.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      final result = await ImageGallerySaver.saveImage(byteData!.buffer.asUint8List());

    } catch (e) {
      print(e.toString());
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageView extends StatelessWidget {
  ImageView({this.url});

  String url;
  static const String id = 'ImageViewingScreen';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: EdgeInsets.all(15.0),
        child: Center(
          child: Container(
            height: 500,
            child: PhotoView(
              imageProvider: NetworkImage('$url'),
              loadingBuilder: (context, _progress) => Center(
                  child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                value: _progress == null
                    ? null
                    : _progress.cumulativeBytesLoaded /
                        _progress.expectedTotalBytes,
              )),
              enableRotation: true,
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 3.0,
              initialScale: PhotoViewComputedScale.contained,
            ),
          ),
        ),
      ),
    );
  }
}

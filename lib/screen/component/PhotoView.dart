import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

class PhotoView extends StatefulWidget {
  final List pics;
  final int index;
  PhotoView(this.pics,this.index);

  @override
  _PhotoViewState createState() => _PhotoViewState();
}

class _PhotoViewState extends State<PhotoView> {
  int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.index;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 50,),
        Flexible(
          child: ExtendedImageGesturePageView.builder(
            itemBuilder: (BuildContext context, int index) {
              var item = widget.pics[index];
              Widget image = ExtendedImage.network(
                item,
                fit: BoxFit.contain,
                mode: ExtendedImageMode.gesture,
                // config: GestureConfig(
                //     inPageView: true, initialScale: 1.0,
                //     //you can cache gesture state even though page view page change.
                //     //remember call clearGestureDetailsCache() method at the right time.(for example,this page dispose)
                //     cacheGesture: false
                // ),
              );
              image = Container(
                child: image,
                padding: EdgeInsets.all(5.0),
              );
              if (index == currentIndex) {
                return Hero(
                  tag: item + index.toString(),
                  child: image,
                );
              } else {
                return image;
              }
            },
            itemCount: widget.pics.length,
            onPageChanged: (int index) {
              currentIndex = index;
              // rebuild.add(index);
            },
            controller: PageController(
              initialPage: currentIndex,
            ),
            scrollDirection: Axis.horizontal,
          ),
        ),
        SizedBox(height: 50,),
      ],
    );

  }
}

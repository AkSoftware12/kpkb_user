import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kpUser/BlinkitUI/widgets/text_widget.dart';

class CategoriesWidget extends StatelessWidget {
  const CategoriesWidget(
      {Key? key,
        required this.catText,
        required this.imgPath,
        required this.passedColor,
     })
      : super(key: key);
  final String catText, imgPath;
  final Color passedColor;

  @override
  Widget build(BuildContext context) {
    // Size size = MediaQuery.of(context).size;

    return Column(
      children: [
        InkWell(
        
          child: Container(
            // height: _screenWidth * 0.6,
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              color: passedColor,
              // color: passedColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8), // Reduce the borderRadius value
              border: Border.all(
                color: passedColor.withOpacity(0.7),
                width: 1, // Reduce the width of the border
              ),
            ),
            child: Column(children: [
              // Container for the image
              Container(
                height: 85,
                width: 90,// Set the height of the container
        
                child: CachedNetworkImage(
                  imageUrl: imgPath,
                  // imageUrl:  nearByProperty[0]['picture_urls'][0].toString(),
                  fit: BoxFit.cover, // Adjust this according to your requirement
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.image

                  ),
                ),


              ),
              // Category name
            ]),
          ),
        ),

        Expanded(
          child: Center(
            child: TextWidget(
              text: catText,
              textSize: 9.sp,
              color: Colors.black,
              isTitle: true,
            ),
          ),
        ),
      ],
    );
  }
}


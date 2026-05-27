import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../BlinkitUI/blinkit_cat.dart';
import '../HomeOrderAccount/Home/UI/Stores/stores.dart';
import '../HomeOrderAccount/home_order_account.dart';
import '../Routes/routes.dart';
import '../Themes/colors.dart';


class CardContent extends StatelessWidget {
  final String? text;
  final String? image;
  final String? uiType;
  final String? vendorCategoryId;
  final BuildContext? context;


  CardContent(
  {required this.text,required this.image,required this.uiType,required this.vendorCategoryId,required this.context});

  @override
  Widget build(BuildContext context) {
    return
      GestureDetector(
        onTap: (){
          print("card content pressed");
          hitNavigator(
              context,
              text,
              uiType,
              vendorCategoryId
          );
    },
      child: Container(
          height: 120,
          width: 120,
          child:
            Card(
            elevation: 2,
            child: Container(
                height: 120,
                width: 120,
                child: CachedNetworkImage(
                  imageUrl: '$image',
                  height: 120,
                  width: 120,
                  fit: BoxFit.fill,
                  alignment: Alignment.center,
                  placeholder: (context, url) => Center(child: SpinKitFadingCircle(
                    color: Colors.orangeAccent,
                    size: 30.0,
                  )),
                  errorWidget: (context, url, error) => Image.asset(
                    'assets/default-image_600.png',
                    height: 120,
                    width: 120,
                    fit: BoxFit.fill,
                  ),
                )
              ),

              // Padding(
              //   padding: const EdgeInsets.only(left: 0.0, right: 0.0,top: 5,bottom: 5),
              //   child: Text(
              //     "$text",
              //     textAlign: TextAlign.center,
              //     overflow: TextOverflow.ellipsis,
              //     maxLines: 2,
              //     style: const TextStyle(
              //         fontSize: 12.0,
              //         fontWeight: FontWeight.w700,
              //         fontStyle: FontStyle.normal,
              //         wordSpacing: 0,
              //         height: 1),
              //   ),
              // ),
            )

      )
      );

  }


  void hitNavigator(context, category_name, ui_type, vendor_category_id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (ui_type == "grocery" || ui_type == "Grocery" || ui_type == "1") {
      prefs.setString("vendor_cat_id", '${vendor_category_id}');
      prefs.setString("ui_type", '${ui_type}');
      if(vendor_category_id=='18' || vendor_category_id==18){
        showModalBottomSheet<void>(
          context: context,
          builder: (BuildContext context) {
            return Container(
              height: 500,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Image.asset("images/id.png"),
                    Padding(padding: EdgeInsets.all(10),child:Text('You need to be above 18 years of age',style: TextStyle(
                        color:Colors.red, fontSize:18, fontWeight: FontWeight.w400)),
                    ),
                    Padding(padding: EdgeInsets.all(10),child:
                    Text('Do not buy tobacco products on behalf of underage persons.',style: TextStyle(
                        color: Colors.blueGrey, fontSize:16)
                    ),
                    ),
                    Padding(padding: EdgeInsets.all(10),child:Text('Your location must not be in and around school or college premises.',style: TextStyle(
                        color: Colors.blueGrey, fontSize:16)),
                    ),
                    Divider(),
                    Padding(padding: EdgeInsets.all(10),child:Text('Jhatfat reserves the right to report your account in case you are below 18 years of age and purchasing cigrattes',style: TextStyle(
                        color: Colors.blueGrey, fontSize:14)),
                    ),
                    new GestureDetector(onTap: (){
                      Navigator.popAndPushNamed(context, PageRoutes.tncPage);
                      },
                      child:    Padding(padding: EdgeInsets.all(10),child:Text('Read T&C',style: TextStyle(
                        color: Colors.green, fontSize:12)),
                    ),),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ), backgroundColor: kWhiteColor,
                            padding: EdgeInsets.all(10),),
                          child: const Text("No,I'm not",style: TextStyle(
                              color: Color(0xffeca53d), fontWeight: FontWeight.w400),),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ), backgroundColor: kMainColor,
                            padding: EdgeInsets.all(10),
                          ),

                          child: const Text("Yes,I'm above 18"),
                          onPressed: () => {
                            Navigator.pop(context),
                          Navigator.push(
                          context,
                          MaterialPageRoute(
                          builder: (context) =>
                          StoresPage(category_name, vendor_category_id)))
                        },
                        ),
                        Spacer(),

                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      }
     else
     {
       print("Not cigarette");

       if(vendor_category_id=='24'){
         Navigator.push(
             context,
             MaterialPageRoute(
                 builder: (context) =>
                     BlinkitCategory(category_name, vendor_category_id,'','')));

       } else{
         Navigator.push(
             context,
             MaterialPageRoute(
                 builder: (context) =>
                     StoresPage(category_name, vendor_category_id)));
       }


      }
    }
  }

}

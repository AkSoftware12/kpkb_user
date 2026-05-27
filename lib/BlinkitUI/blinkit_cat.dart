import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kpUser/BlinkitUI/widgets/categories_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../baseurlp/baseurl.dart';
import '../../../../bean/categorylist.dart';
import '../../../../bean/productlistvarient.dart';
import '../../../../databasehelper/dbhelper.dart';
import '../BlinkitProduct/new_blinkit_product.dart';


class BlinkitCategory extends StatefulWidget {
  final String pageTitle;
  final dynamic vendor_id;
  final dynamic distance;
  final dynamic vendorCategoryId;

  BlinkitCategory(this.vendorCategoryId,this.pageTitle, this.vendor_id, this.distance) {
    setStoreName(pageTitle);
  }

  void setStoreName(pageTitle) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("store_name", pageTitle);
  }

  @override
  State<StatefulWidget> createState() {
    return AppCategoryState(vendorCategoryId,pageTitle, vendor_id);
  }
}

class AppCategoryState extends State<BlinkitCategory> {
  final String pageTitle;
  final dynamic vendor_id;
  final dynamic vendorCategoryId;
  bool isCartCount = false;
  bool isFetch = false;
  int cartCount = 0;
  String message = "";
  String vendorId = '';
  String blinkitDist = '';
  String curency = "";
  String image = "";
  List<dynamic> categories = [];





  TextEditingController searchController = TextEditingController();

   AppCategoryState(this.vendorCategoryId,this.pageTitle, this.vendor_id);




  @override
  void initState() {
    super.initState();
    hitStore();
  }




  List<dynamic> data = [];
  List<dynamic> cat = [];

  Future<void> hitStore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final response = await http.post(
      Uri.parse(nearByStore),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'lat': '${prefs.getString('lat')}',
        'lng': '${prefs.getString('lng')}',
        'vendor_category_id': '${24}',
        'ui_type': '1'
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      vendorId=jsonData['data']['vendor_id'].toString();
      blinkitDist=jsonData['data']['distance'].toString();
      _fetchCategories();

    } else {
      throw Exception('Failed to load profile data');
    }

  }

  Future<void> _fetchCategories() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');
    final response = await http.post(
      Uri.parse(categoryList),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'vendor_id': vendorId,
      }),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      setState(() {
        categories = data['data'];
      });
    } else {
      throw Exception('Failed to load categories');
    }
  }








  @override
  Widget build(BuildContext context) {
    return  Scaffold(
        body: SafeArea(
            child: Column(
                children: [
                  Expanded(
                    child:  ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final category = categories[index];

                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Padding(
                                padding:  EdgeInsets.only(left: 5.0,bottom: 25),
                                child:Text(
                                  categories[index]['category_name'].toString(),
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              GridView.count(
                                crossAxisCount: 4,
                                childAspectRatio: 160 / 230,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 6,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                children: (category['subcategories'] as List).asMap().entries.map((entry) {
                                  int subindex = entry.key;
                                  var subCategory = entry.value;
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductsScreen(
                                                    categories[index]['category_name'].toString(),
                                                    categories[index]['vendor_id'].toString(),
                                                    subCategory['subcat_name'].toString(),
                                                    subCategory['category_id'].toString(),
                                                    blinkitDist,
                                                    subindex,
                                                    subCategory['subcat_id'].toString(),
                                                  )))
                                          .then((value) {
                                        // getCartCount();
                                      });
                                    },
                                    child: CategoriesWidget(
                                      imgPath:  '${imageBaseUrl}${ subCategory['subcat_image'].toString()}',
                                      catText: subCategory['subcat_name'].toString(),
                                      passedColor: const Color(0xffB7DFF5),
                                    ),
                                  );
                                }).toList(),

                              ),
                            ],
                          ),
                        );
                      },
                    ), // Adding CategoriesScreen widget here
                  ),
                ]


            )
        )


    );
  }



}


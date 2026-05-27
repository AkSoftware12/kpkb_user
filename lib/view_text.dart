// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// class TextScreen extends StatelessWidget {
//   const TextScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: (gstCharge > 0)
//           ? Container(
//         color: Colors.white,
//         padding: EdgeInsets.symmetric(
//             vertical: 4.0, horizontal: 20.0),
//         child: Row(
//             mainAxisAlignment:
//             MainAxisAlignment.spaceBetween,
//             children: <Widget>[
//               Text(
//                 'GST ',
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodySmall,
//               ),
//
//               Text(
//                 '$currency ${gstCharge.toStringAsFixed(2)}',
//                 style: Theme.of(context)
//                     .textTheme
//                     .bodySmall,
//               ),
//             ]),
//       )
//           : Container(),
//     );
//   }
// }

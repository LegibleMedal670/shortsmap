// import 'package:flutter/material.dart';

// class TimelineItem extends StatelessWidget {
//   final String title;
//   final String time;
//   final String? description;
//   final String imageUrl;
//   final VoidCallback onDelete;

//   const TimelineItem({
//     Key? key,
//     required this.title,
//     required this.time,
//     this.description,
//     this.imageUrl = 'https://picsum.photos/100',
//     required this.onDelete,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
//       child: Card(
//         elevation: 2,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Column(
//           children: [
//             ListTile(
//               leading: ClipRRect(
//                 borderRadius: BorderRadius.circular(8),
//                 child: Image.network(
//                   imageUrl,
//                   width: 50,
//                   height: 50,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               title: Text(
//                 '$time · $title',
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: description != null ? Text(description!) : null,
//               trailing: IconButton(
//                 icon: const Icon(Icons.close),
//                 onPressed: onDelete,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
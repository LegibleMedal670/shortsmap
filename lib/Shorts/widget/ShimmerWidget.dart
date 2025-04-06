import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerWidget extends StatelessWidget {
  final String mode;

  const ShimmerWidget({Key? key, this.mode = 'loading'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (mode == 'error')
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Restart App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        if (mode == 'loading')
          Shimmer.fromColors(
            baseColor: Colors.grey[700] as Color,
            highlightColor: Colors.grey[800]!.withValues(alpha: 0.8),
            child: Stack(
              children: [
                Positioned(
                  right: MediaQuery.of(context).size.width * 0.05,
                  bottom: MediaQuery.of(context).size.height * 0.001,
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ShimmerIcon(),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: MediaQuery.of(context).size.width * 0.05,
                  bottom: MediaQuery.of(context).size.height * 0.001,
                  child: SafeArea(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.82,
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[700],
                                  ),
                                  const SizedBox(width: 13),
                                  Container(
                                    width: 150,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[700],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 17),
                              Container(
                                width: 230,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Colors.grey[700],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

Widget ShimmerIcon() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.grey[700],
        ),
        SizedBox(
          height: 5,
        ),
        Container(
          width: 40,
          height: 10,
          color: Colors.grey[700],
        )
      ],
    ),
  );
}

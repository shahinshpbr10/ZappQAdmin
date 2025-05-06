import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoadingIndicator extends StatelessWidget {


  final double animationSize;

  const LottieLoadingIndicator({
    Key? key,


    this.animationSize = 150.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: animationSize,
            height: animationSize,
            child: Lottie.asset(
              'assets/lotties/loading2.json',
              repeat: true,
              animate: true,
            ),
          ),
        ],
      ),
    );
  }
}

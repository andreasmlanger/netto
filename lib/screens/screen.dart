import 'package:flutter/material.dart';
import 'package:netto/models/coupon.dart';


class Screen extends StatelessWidget {
  final int index;
  final Coupon coupon;

  const Screen({super.key, required this.index, required this.coupon});

  @override
  Widget build(BuildContext context) {
    Color textColor = (index > 2 && index < 5) ? Colors.black : Colors.white;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/${index.toString()}.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  coupon.category,
                  style: TextStyle(
                    fontSize: 50.0,
                    color: textColor,
                    fontFamily: 'IndieFlower',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Card(
                    elevation: 8,
                    child: Image.memory(
                      coupon.base64Image,
                    ),
                  ),
                ),
                Text(
                  '${coupon.number}x ${coupon.discount}% ${coupon.type}',
                  style: TextStyle(
                    fontSize: 40.0,
                    color: textColor,
                    fontFamily: 'IndieFlower',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

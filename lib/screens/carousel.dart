import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:netto/models/coupon.dart';
import 'package:netto/screens/screen.dart';


class CouponCarousel extends StatefulWidget {
  const CouponCarousel({super.key});

  @override
  State<CouponCarousel> createState() => _CouponCarouselState();
}

class _CouponCarouselState extends State<CouponCarousel> {
  @override
  Widget build(BuildContext context) {
    final coupons = Provider.of<QuerySnapshot?>(context);

    List<Coupon> couponList = [];
    if (coupons != null) {
      for (var doc in coupons.docs) {
        couponList.add(Coupon(
          number: doc.get('number'),
          discount: doc.get('discount'),
          type: doc.get('type'),
          base64Image: base64.decode(doc.get('base64ImageString')),
        ));
      }
    }

    return PageView.builder(
      controller: PageController(initialPage: 0),
      scrollDirection: Axis.horizontal,
      itemCount: couponList.length,
      itemBuilder: (context, index) {
        return Screen(index: index, coupon: couponList[index]);
      },
    );
  }
}


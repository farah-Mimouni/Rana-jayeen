import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    Key? key,
    required this.title,
    this.textAlign,
  }) : super(key: key);

  final String title;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.02,
        vertical: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gradient Bar
          Container(
            width: 5,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B5EFA), Color(0xFF48C6BD)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: isRtl ? 10 : 14),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2A364E),
              letterSpacing: -0.3,
            ),
            textAlign: textAlign ?? (isRtl ? TextAlign.right : TextAlign.left),
          ),
        ],
      ),
    );
  }
}

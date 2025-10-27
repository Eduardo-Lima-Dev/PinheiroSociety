import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockAlertTile extends StatelessWidget {
  final String product;
  final int current;
  final int min;

  const StockAlertTile({
    super.key,
    required this.product,
    required this.current,
    required this.min,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: const Color(0xFF2A210E),
          borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Estoque atual: $current | Mínimo: $min',
              style: GoogleFonts.poppins(color: Colors.amber, fontSize: 12)),
        ],
      ),
    );
  }
}

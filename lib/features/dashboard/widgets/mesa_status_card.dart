import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MesaStatusCard extends StatelessWidget {
  final int mesasOcupadas;
  final int totalMesas;
  final String horariosOcupados;

  const MesaStatusCard({
    super.key,
    required this.mesasOcupadas,
    required this.totalMesas,
    required this.horariosOcupados,
  });

  @override
  Widget build(BuildContext context) {
    final percentualOcupacao = totalMesas > 0 ? (mesasOcupadas / totalMesas * 100).round() : 0;
    
    return Container(
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1E21),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.table_chart_outlined, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Status das Mesas',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mesas Ocupadas $mesasOcupadas',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total: $totalMesas | Ocupação: $horariosOcupados',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

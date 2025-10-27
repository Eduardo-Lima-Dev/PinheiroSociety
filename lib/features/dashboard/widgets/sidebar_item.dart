import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback? onTap;

  const SidebarItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selected ? Colors.green.withOpacity(0.15) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          label,
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500),
        ),
        onTap: onTap,
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(999)),
                child: Text(badge!,
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 12)),
              )
            : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

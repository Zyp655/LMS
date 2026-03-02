import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SoftUserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final Color accent;
  final IconData roleIcon;

  const SoftUserTile({
    super.key,
    required this.user,
    required this.accent,
    required this.roleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final fullName = user['fullName'] as String? ?? '(Chưa đặt tên)';
    final email = user['email'] as String? ?? '';
    final stuClass = user['studentClass'] as String?;
    final stuId = user['studentId'] as String?;
    final isBanned = user['isBanned'] == true;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isBanned ? const Color(0xFFFFF0F0) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isBanned
                    ? const Color(0xFFFFCDD2)
                    : accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isBanned ? Icons.block_rounded : roleIcon,
                color: isBanned ? const Color(0xFFE74C3C) : accent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D3436),
                      decoration: isBanned ? TextDecoration.lineThrough : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF636E72),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (stuClass != null || stuId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        [
                          if (stuId != null) stuId,
                          if (stuClass != null) 'Lớp: $stuClass',
                        ].join(' • '),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: accent,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

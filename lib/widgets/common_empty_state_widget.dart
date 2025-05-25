import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommonEmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData? icon; // Optional icon

  const CommonEmptyStateWidget({
    Key? key,
    required this.message,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
            ],
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            // Optionally, add a call to action button here if needed in some contexts
            // For example:
            // const SizedBox(height: 16),
            // ElevatedButton(onPressed: () {}, child: Text("Do Something"))
          ],
        ),
      ),
    );
  }
}

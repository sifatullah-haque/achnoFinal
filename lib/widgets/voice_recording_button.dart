import 'package:flutter/material.dart';

class VoiceRecordingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final bool isRecording;
  final double size;

  const VoiceRecordingButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.mic,
    this.backgroundColor,
    this.iconColor,
    this.isRecording = false,
    this.size = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Positioned layout enforced to be on the left
      alignment: Alignment.centerLeft,
      // Enforce LTR for the button and icon
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor ??
                  (isRecording ? Colors.red : Theme.of(context).primaryColor),
            ),
            child: Icon(
              isRecording ? Icons.stop : icon,
              color: iconColor ?? Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// Input row with fixed LTR layout for text input and recording button
class FixedDirectionInputRow extends StatelessWidget {
  final Widget textField;
  final Widget recordButton;
  final EdgeInsetsGeometry padding;

  const FixedDirectionInputRow({
    super.key,
    required this.textField,
    required this.recordButton,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    // Use Row with mainAxisAlignment to keep layout consistent
    return Padding(
      padding: padding,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            // Recording button always on left
            recordButton,
            const SizedBox(width: 8),
            // Text field in the middle/right
            Expanded(child: textField),
          ],
        ),
      ),
    );
  }
}

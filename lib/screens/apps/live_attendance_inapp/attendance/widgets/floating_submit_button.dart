import 'package:flutter/material.dart';
import 'package:nitris/core/constants/app_colors.dart';


class FloatingSubmitButton extends StatefulWidget {
  final bool isAllMarked;
  final bool isSmallDevice;
  final VoidCallback onPressed;

  const FloatingSubmitButton({
    super.key,
    required this.isAllMarked,
    required this.isSmallDevice,
    required this.onPressed,
  });

  @override
  _FloatingSubmitButtonState createState() => _FloatingSubmitButtonState();
}

class _FloatingSubmitButtonState extends State<FloatingSubmitButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _scale = 0.95;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _scale = 1.0;
    });
  }

  void _onTapCancel() {
    setState(() {
      _scale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: double.infinity,
      height: widget.isSmallDevice ? 50 : 60,
      child: GestureDetector(
        onTapDown: widget.isAllMarked ? _onTapDown : null,
        onTapUp: widget.isAllMarked ? _onTapUp : null,
        onTapCancel: widget.isAllMarked ? _onTapCancel : null,
        onTap: widget.isAllMarked ? widget.onPressed : null,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 100),
          child: ElevatedButton(
            onPressed: widget.isAllMarked ? widget.onPressed : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: widget.isAllMarked ? 6 : 2,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.black.withOpacity(0.2),
            ),
            child: Ink(
                decoration: BoxDecoration(
                color: widget.isAllMarked ? AppColors.primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                ),
              child: Container(
                alignment: Alignment.center,
                child: Text(
                  'Save Attendance',
                  style: TextStyle(
                    fontSize: widget.isSmallDevice ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isAllMarked ? Colors.white : Colors.grey.shade800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

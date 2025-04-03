import 'package:flutter/material.dart';
import '/constants/app_colors.dart';
import '/constants/app_text_styles.dart';
import '/utils/responsive_size.dart';

enum ButtonType { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool iconOnRight;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height,
    this.icon,
    this.iconOnRight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Buton stili belirleme
    final ButtonStyle buttonStyle = _getButtonStyle();

    // İçerik oluşturma
    Widget content = _buildContent();

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? Responsive.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: content,
      ),
    );
  }

  // Buton türüne göre stil belirleme
  ButtonStyle _getButtonStyle() {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        );
      case ButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        );
      case ButtonType.outlined:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          elevation: 0,
        );
      case ButtonType.text:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        );
    }
  }

  // Buton içeriği oluşturma
  Widget _buildContent() {
    final TextStyle textStyle = _getTextStyle();

    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon == null) {
      return Text(text, style: textStyle);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children:
          iconOnRight
              ? [
                Text(text, style: textStyle),
                const SizedBox(width: 8),
                Icon(icon, size: 20),
              ]
              : [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(text, style: textStyle),
              ],
    );
  }

  // Buton türüne göre metin stili belirleme
  TextStyle _getTextStyle() {
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return AppTextStyles.buttonMedium;
      case ButtonType.outlined:
      case ButtonType.text:
        return AppTextStyles.buttonMedium.copyWith(color: AppColors.primary);
    }
  }
}

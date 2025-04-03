import 'package:flutter/material.dart';
import '/constants/app_colors.dart';
import '/constants/app_text_styles.dart';
import '/utils/responsive_size.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? titleColor;
  final double? elevation;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.centerTitle = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.titleColor,
    this.elevation,
    this.leading,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsive davranış
    final bool isMobileView = Responsive.isMobile(context);

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.primary,
      centerTitle: centerTitle,
      elevation: elevation ?? 0,
      automaticallyImplyLeading: showBackButton,
      leading:
          leading ??
          (showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              )
              : null),
      title: Text(
        title,
        style:
            isMobileView
                ? AppTextStyles.heading4.copyWith(
                  color: titleColor ?? Colors.white,
                )
                : AppTextStyles.heading3.copyWith(
                  color: titleColor ?? Colors.white,
                ),
        overflow: TextOverflow.ellipsis,
      ),
      actions: actions,
      bottom: bottom,
      titleSpacing: 16,
      toolbarHeight: 60,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    bottom != null
        ? kToolbarHeight + bottom!.preferredSize.height
        : kToolbarHeight,
  );
}

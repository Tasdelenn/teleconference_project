import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:teleconference_app/services/config_service.dart';

class PlatformAdaptiveUI {
  static final ConfigService _configService = ConfigService();
  
  // Platform uyumlu buton
  static Widget button({
    required String text,
    required VoidCallback onPressed,
    Color? color,
    IconData? icon,
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    if (Platform.isIOS) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: isDestructive ? CupertinoColors.destructiveRed : color ?? CupertinoColors.activeBlue,
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CupertinoActivityIndicator()
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: CupertinoColors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? Colors.red : color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    const SizedBox(width: 8),
                  ],
                  Text(text),
                ],
              ),
      );
    }
  }
  
  // Platform uyumlu dialog
  static Future<T?> showDialog<T>({
    required BuildContext context,
    required String title,
    required String message,
    String? cancelText,
    String? confirmText,
    VoidCallback? onCancel,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    if (Platform.isIOS) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onCancel != null) onCancel();
                },
                child: Text(cancelText),
              ),
            if (confirmText != null)
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onConfirm != null) onConfirm();
                },
                child: Text(confirmText),
              ),
          ],
        ),
      );
    } else {
      return showGeneralDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        pageBuilder: (context, _, __) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (cancelText != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onCancel != null) onCancel();
                },
                child: Text(cancelText),
              ),
            if (confirmText != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onConfirm != null) onConfirm();
                },
                child: Text(confirmText),
              ),
          ],
        ),
      );
    }
  }
  
  // Platform uyumlu loading göstergesi
  static Widget loadingIndicator({Color? color}) {
    if (Platform.isIOS) {
      return CupertinoActivityIndicator(
        color: color,
      );
    } else {
      return CircularProgressIndicator(
        valueColor: color != null ? AlwaysStoppedAnimation<Color>(color) : null,
      );
    }
  }
  
  // Platform uyumlu switch
  static Widget switchWidget({
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    if (Platform.isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    } else {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
      );
    }
  }
  
  // Platform uyumlu text field
  static Widget textField({
    required TextEditingController controller,
    String? hintText,
    String? labelText,
    bool obscureText = false,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    FocusNode? focusNode,
    InputDecoration? decoration,
  }) {
    if (Platform.isIOS) {
      return CupertinoTextField(
        controller: controller,
        placeholder: hintText,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        focusNode: focusNode,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    } else {
      return TextField(
        controller: controller,
        decoration: decoration ??
            InputDecoration(
              hintText: hintText,
              labelText: labelText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        focusNode: focusNode,
      );
    }
  }
  
  // Cihaz tipine göre UI ölçekleme
  static double getScaleFactor() {
    return _configService.getUIScaleFactor();
  }
  
  // Cihaz tipine göre padding değeri
  static EdgeInsets getPadding({bool isCompact = false}) {
    final scale = getScaleFactor();
    
    if (isCompact) {
      return EdgeInsets.all(8.0 * scale);
    } else {
      return EdgeInsets.all(16.0 * scale);
    }
  }
  
  // Cihaz tipine göre font boyutu
  static double getFontSize({required double baseSize}) {
    final scale = getScaleFactor();
    return baseSize * scale;
  }
  
  // Cihaz tipine göre ikon boyutu
  static double getIconSize({required double baseSize}) {
    final scale = getScaleFactor();
    return baseSize * scale;
  }
}
import 'package:flutter/material.dart';
import '../error/failures.dart';
import '../../core/theme/app_colors.dart';

class ErrorDialogHandler {
  static void showError(BuildContext context, Failure failure) {
    String title = 'Lỗi';
    String message = failure.message;
    Color iconColor = Colors.redAccent;
    IconData icon = Icons.error_outline;

    if (failure is ServerFailure && failure.statusCode != null) {
      if (failure.statusCode == 409) {
        title = 'Thông tin đã tồn tại';
        iconColor = Colors.orangeAccent;
        icon = Icons.warning_amber_rounded;

        if (message.toLowerCase().contains('conflict') || message.length < 5) {
          message =
              'Thông tin đăng ký (email hoặc tên đăng nhập) đã tồn tại trong hệ thống. Vui lòng kiểm tra lại.';
        }
      } else if (failure.statusCode == 401) {
        title = 'Xác thực thất bại';
        message = 'Email hoặc mật khẩu không chính xác.';
      }
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.darkSurface.withValues(alpha: 0.95), 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Đóng',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

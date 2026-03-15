import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TwilioWhatsAppService {
  static const String accountSid = "ACc4c9d6cace00d8519b331a93d9d3fe22";
  static const String authToken = "da5897e3d05c48d6fcd199cb2e6e82da";
  static const String fromWhatsAppNumber = "whatsapp:+14155238886";

  /// Send a single WhatsApp message with detailed logging
  static Future<Map<String, dynamic>> sendMessage({
    required String toPhoneNumber,
    required String message,
  }) async {
    final url = Uri.parse(
      'https://api.twilio.com/2010-04-01/Accounts/$accountSid/Messages.json',
    );

    final credentials = base64Encode(utf8.encode('$accountSid:$authToken'));

    try {
      debugPrint('📤 Attempting to send to: $toPhoneNumber');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': fromWhatsAppNumber,
          'To': toPhoneNumber,
          'Body': message,
        },
      );

      debugPrint('📊 Response Status: ${response.statusCode}');
      debugPrint('📊 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        debugPrint('✅ Success for: $toPhoneNumber');
        return {
          'success': true,
          'data': responseData,
          'to': toPhoneNumber,
          'messageSid': responseData['sid'],
        };
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error';
        final errorCode = errorData['code'] ?? response.statusCode;

        debugPrint('❌ Failed for: $toPhoneNumber');
        debugPrint('❌ Error: $errorMessage (Code: $errorCode)');

        return {
          'success': false,
          'error': errorMessage,
          'errorCode': errorCode,
          'to': toPhoneNumber,
          'statusCode': response.statusCode,
          'fullError': errorData,
        };
      }
    } catch (e) {
      debugPrint('💥 Exception for: $toPhoneNumber - $e');
      return {'success': false, 'error': e.toString(), 'to': toPhoneNumber};
    }
  }

  /// Send bulk WhatsApp messages with improved error handling
  static Future<Map<String, dynamic>> sendBulkMessages({
    required List<String> phoneNumbers,
    required String message,
    Duration delayBetweenMessages = const Duration(seconds: 2),
    Function(int current, int total)? onProgress,
  }) async {
    debugPrint('🚀 Starting bulk send to ${phoneNumbers.length} numbers');

    final results = <Map<String, dynamic>>[];
    int successCount = 0;
    int failureCount = 0;
    final errors = <String, int>{};

    for (int i = 0; i < phoneNumbers.length; i++) {
      debugPrint(
        '\n📱 Processing ${i + 1}/${phoneNumbers.length}: ${phoneNumbers[i]}',
      );

      // Notify progress
      if (onProgress != null) {
        onProgress(i + 1, phoneNumbers.length);
      }

      final result = await sendMessage(
        toPhoneNumber: phoneNumbers[i],
        message: message,
      );

      results.add(result);

      if (result['success'] == true) {
        successCount++;
      } else {
        failureCount++;

        // Track error types
        final errorMsg = result['error']?.toString() ?? 'Unknown error';
        errors[errorMsg] = (errors[errorMsg] ?? 0) + 1;
      }

      // Add delay between messages to avoid rate limiting
      if (i < phoneNumbers.length - 1) {
        debugPrint(
          '⏳ Waiting ${delayBetweenMessages.inSeconds}s before next message...',
        );
        await Future.delayed(delayBetweenMessages);
      }
    }

    debugPrint('\n📊 BULK SEND COMPLETE:');
    debugPrint('   ✅ Success: $successCount');
    debugPrint('   ❌ Failed: $failureCount');
    if (errors.isNotEmpty) {
      debugPrint('   📋 Error Summary:');
      errors.forEach((error, count) {
        debugPrint('      • $error: $count times');
      });
    }

    return {
      'success': failureCount == 0,
      'results': results,
      'successCount': successCount,
      'failureCount': failureCount,
      'total': phoneNumbers.length,
      'errors': errors,
    };
  }

  /// Format phone number to WhatsApp format
  static String formatPhoneNumber(String phoneNumber) {
    // Remove any spaces, dashes, or special characters
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // If doesn't start with +, add country code (assuming India +91)
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('91')) {
        cleaned = '+$cleaned';
      } else {
        cleaned = '+91$cleaned';
      }
    }

    debugPrint('📞 Formatted: $phoneNumber -> whatsapp:$cleaned');
    return 'whatsapp:$cleaned';
  }

  /// Test sending to a single number first
  static Future<bool> testConnection(String testPhoneNumber) async {
    debugPrint('\n🧪 TESTING CONNECTION...');
    debugPrint('Testing with number: $testPhoneNumber');

    final result = await sendMessage(
      toPhoneNumber: formatPhoneNumber(testPhoneNumber),
      message: 'This is a test message from your WhatsApp service.',
    );

    if (result['success'] == true) {
      debugPrint('✅ TEST PASSED: Connection working!');
      return true;
    } else {
      debugPrint('❌ TEST FAILED: ${result['error']}');
      return false;
    }
  }
}

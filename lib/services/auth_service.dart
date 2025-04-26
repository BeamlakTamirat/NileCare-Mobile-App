import 'dart:async';
import 'package:flutter/material.dart';

class AuthService {
  // Simulate verifying an OTP code
  Future<bool> verifyOTP(String otpCode) async {
    //  API call to verify the OTP should be made
    // For now,it simulate a delay and return true if the code is "123456"
    await Future.delayed(const Duration(seconds: 1));
    return otpCode == "123456";
  }

  // Simulate resending OTP
  Future<bool> resendOTP() async {
    // an API call to resend the OTP is needed
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

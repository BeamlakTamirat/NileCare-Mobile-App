import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'new_password_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneOrEmail;

  const OTPVerificationScreen({Key? key, required this.phoneOrEmail})
    : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  // OTP code controllers
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  // Timer variables
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _timerActive = true;

  // Loading state
  bool _isLoading = false;
  String? _errorMessage;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 60;
    _timerActive = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timerActive = false;
          _timer?.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Get the full OTP code from all controllers
  String _getFullOTP() {
    return _controllers.map((c) => c.text).join();
  }

  // Verify the OTP code
  Future<void> _verifyOTP() async {
    final String otpCode = _getFullOTP();

    // Validate all fields are filled
    if (otpCode.length != 6) {
      setState(() {
        _errorMessage = "Please enter all 6 digits";
      });
      return;
    }

    // Check if OTP is only digits
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otpCode)) {
      setState(() {
        _errorMessage = "OTP should contain only digits";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate server-side validations (for demo purposes)
      if (otpCode == "000000") {
        throw Exception("Invalid OTP code: code expired");
      }
      if (otpCode == "111111") {
        throw Exception("Too many attempts. Try again in 30 minutes");
      }

      final bool result = await _authService.verifyOTP(otpCode);

      if (result) {
        if (mounted) {
          // Navigate to new password screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NewPasswordScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = "Invalid OTP code. Please try again.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Resend OTP code
  Future<void> _resendOTP() async {
    if (_timerActive) {
      setState(() {
        _errorMessage =
            "Please wait ${_secondsRemaining}s before requesting a new code";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bool result = await _authService.resendOTP();

      if (result) {
        setState(() {
          // Reset timer
          _startTimer();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP code resent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = "Failed to resend OTP. Please try again later.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            "Server error: ${e.toString().replaceAll("Exception: ", "")}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B5368),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'NileCare',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                const Text(
                  'OTP Verification',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),

                // Subtitle
                Text(
                  'We sent a verification code to\n${widget.phoneOrEmail}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => _buildOTPDigitField(index),
                  ),
                ),
                const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                const SizedBox(height: 24),

                // Timer and Resend button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Didn't receive code? ",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    _timerActive
                        ? Text(
                          "Resend in ${_secondsRemaining}s",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF3B5368),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                        : GestureDetector(
                          onTap: _isLoading ? null : _resendOTP,
                          child: const Text(
                            "Resend OTP",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF3B5368),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 40),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5368),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOTPDigitField(int index) {
    return SizedBox(
      width: 45,
      height: 50,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20),
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF3B5368), width: 2),
          ),
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          // Auto move to next field when filled
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              // Optionally auto-verify when all fields are filled
              // _verifyOTP();
            }
          }
        },
      ),
    );
  }
}

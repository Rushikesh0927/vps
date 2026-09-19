import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/user_provider.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  String _verificationId = '';
  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) {
      phone = '+91$phone'; // Defaulting to India for prototype, adjust as needed
    }

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (rare on iOS, common on Android)
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.message ?? 'Verification failed. Try again.';
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );
      await _signInWithCredential(credential);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid OTP. Please try again.';
      });
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final UserCredential userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCred.user;
      
      if (firebaseUser != null) {
        // Send to Riverpod provider to sync with Node.js/Supabase
        await ref.read(userProvider.notifier).loginWithPhone(
          firebaseUser.uid, 
          firebaseUser.phoneNumber ?? _phoneController.text.trim()
        );
        
        if (mounted) {
          Navigator.pop(context); // Go back to Auth Screen which will auto-redirect to Home
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 384,
              height: 384,
              decoration: const BoxDecoration(
                color: Color(0x1AFF5A5F),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _codeSent ? Icons.message : Icons.phone_android, 
                            size: 48, 
                            color: Colors.white
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _codeSent ? 'Enter OTP' : 'Mobile Login',
                            style: const TextStyle(
                              fontSize: 28, 
                              fontWeight: FontWeight.w900, 
                              color: Colors.white, 
                              letterSpacing: -0.5
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _codeSent 
                                ? 'Enter the 6-digit code sent to ${_phoneController.text}' 
                                : 'Enter your mobile number to receive a one-time password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 32),
                          
                          if (!_codeSent) ...[
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: InputDecoration(
                                hintText: 'Mobile Number',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                prefixText: '+91 ',
                                prefixStyle: const TextStyle(color: Colors.white, fontSize: 18),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ] else ...[
                            TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '000000',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 8),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ],
                          
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Color(0xFFFF5A5F), fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            
                          const SizedBox(height: 32),
                          
                          InkWell(
                            onTap: _isLoading 
                                ? null 
                                : (_codeSent ? _verifyOTP : _verifyPhone),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5A5F),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: _isLoading
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _codeSent ? 'Verify & Login' : 'Send OTP',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16, 
                                        fontWeight: FontWeight.bold, 
                                        color: Colors.white
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

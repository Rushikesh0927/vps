import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../models/user_models.dart';
import 'home_dashboard.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  final bool isInitialSetup;
  const EditProfileScreen({super.key, this.isInitialSetup = false});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  late TextEditingController _pincodeController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _mobileController = TextEditingController(text: user?.mobile ?? '');
    _addressController = TextEditingController(text: user?.savedAddress?.address ?? '');
    _pincodeController = TextEditingController(text: user?.savedAddress?.pincode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userNotifier = ref.read(userProvider.notifier);
    final currentUser = ref.read(userProvider).user;
    
    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final updatedUser = UserProfile(
        id: currentUser.id,
        name: _nameController.text.trim(),
        email: currentUser.email,
        mobile: _mobileController.text.trim(),
        savedAddress: SavedAddress(
          address: _addressController.text.trim(),
          pincode: _pincodeController.text.trim(),
        ),
      );
      
      await userNotifier.updateProfileLocal(updatedUser);
      
      if (mounted) {
        if (widget.isInitialSetup) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeDashboard()));
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: AppBar(
              backgroundColor: const Color(0xFF1D1D1F).withOpacity(0.5),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(widget.isInitialSetup ? 'Complete Profile' : 'Edit Profile', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              if (widget.isInitialSetup) ...[
                const Text(
                  'Welcome to Snap-N-Wrap!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please complete your profile to continue. This address will be used for delivery.',
                  style: TextStyle(fontSize: 14, color: Color(0xFFA1A1A6)),
                ),
                const SizedBox(height: 32),
              ],
              
              _buildTextField('Full Name', _nameController, Icons.person_outline, TextInputType.name),
              const SizedBox(height: 16),
              _buildTextField('Mobile Number', _mobileController, Icons.phone_outlined, TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Complete Address', _addressController, Icons.home_outlined, TextInputType.streetAddress, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField('Pincode', _pincodeController, Icons.pin_drop_outlined, TextInputType.number),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5A5F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, TextInputType keyboardType, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        alignLabelWithHint: true,
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFFA1A1A6)),
        prefixIcon: Icon(icon, color: const Color(0xFFA1A1A6)),
        filled: true,
        fillColor: const Color(0xFF1D1D1F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF5A5F)),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}

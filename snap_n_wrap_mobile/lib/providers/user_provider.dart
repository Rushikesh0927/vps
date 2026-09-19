import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_sign;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_models.dart';
import '../utils/config.dart';

class UserState {
  final bool isLoggedIn;
  final UserProfile? user;
  final List<UserOrder> orders;
  final bool isLoading;
  final String? error;

  UserState({
    required this.isLoggedIn,
    this.user,
    required this.orders,
    this.isLoading = false,
    this.error,
  });

  factory UserState.initial() {
    return UserState(
      isLoggedIn: false,
      user: null,
      orders: [],
    );
  }

  UserState copyWith({
    bool? isLoggedIn,
    UserProfile? user,
    List<UserOrder>? orders,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      user: user ?? this.user,
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  // Replace with the actual API URL from the environment/config
  final String apiUrl = AppConfig.apiUrl;

  @override
  UserState build() {
    return UserState.initial();
  }

  Future<void> loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr);
        SavedAddress? parsedAddress;
        if (userData['savedAddress'] != null) {
          final addrData = userData['savedAddress'];
          parsedAddress = SavedAddress(
            address: addrData['address'] ?? '',
            pincode: addrData['pincode'] ?? '',
          );
        }
        
        final userProfile = UserProfile(
          id: userData['id'],
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          mobile: userData['mobile'] ?? '',
          savedAddress: parsedAddress,
        );
        state = state.copyWith(
          isLoggedIn: true,
          user: userProfile,
          isLoading: false,
        );
        // Fetch orders and fresh profile silently
        fetchOrders(userProfile.id);
        fetchProfile(userProfile.id);
      }
    } catch (e) {
      print('Failed to load user: $e');
    }
  }

  Future<void> fetchProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': userId,
        },
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        
        SavedAddress? parsedAddress;
        if (userData['savedAddress'] != null) {
          final addrData = userData['savedAddress'];
          parsedAddress = SavedAddress(
            address: addrData['address'] ?? '',
            pincode: addrData['pincode'] ?? '',
          );
        }

        final updatedProfile = UserProfile(
          id: userData['id'],
          name: userData['name'] ?? state.user?.name ?? '',
          email: userData['email'] ?? state.user?.email ?? '',
          mobile: userData['mobile'] ?? state.user?.mobile ?? '',
          savedAddress: parsedAddress,
        );

        // Update local SharedPreferences with fresh data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode({
          'id': updatedProfile.id,
          'name': updatedProfile.name,
          'email': updatedProfile.email,
          'mobile': updatedProfile.mobile,
          'savedAddress': parsedAddress != null ? {
            'address': parsedAddress.address,
            'pincode': parsedAddress.pincode,
          } : null,
        }));

        state = state.copyWith(user: updatedProfile);
      }
    } catch (e) {
      print('Failed to fetch profile: $e');
    }
  }

  Future<void> updateProfileLocal(UserProfile updatedUser) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode({
      'id': updatedUser.id,
      'name': updatedUser.name,
      'email': updatedUser.email,
      'mobile': updatedUser.mobile,
      'savedAddress': updatedUser.savedAddress != null ? {
        'address': updatedUser.savedAddress!.address,
        'pincode': updatedUser.savedAddress!.pincode,
      } : null,
    }));
    state = state.copyWith(user: updatedUser);
  }

  Future<void> fetchOrders(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiUrl/api/orders'),
        headers: {
          'Content-Type': 'application/json',
          'x-user-id': userId,
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<UserOrder> fetchedOrders = data.map<UserOrder>((o) => UserOrder(
          orderId: o['id'] ?? '',
          productName: o['productName'] ?? o['product_name'] ?? o['category_id'] ?? 'Custom Photo Gift',
          date: o['date'] ?? o['created_at'] ?? '',
          size: o['size'] ?? 'Various',
          qty: o['qty'] ?? 1,
          total: double.tryParse(o['amount']?.toString() ?? '0') ?? 0,
          status: o['status'] ?? 'pending',
          driveLink: o['gdrive_link'] ?? o['drive_link'],
        )).toList();
        
        state = state.copyWith(orders: fetchedOrders);
      }
    } catch (e) {
      print('Failed to fetch orders: $e');
    }
  }

  Future<void> _saveUserLocal(UserProfile user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode({
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'mobile': user.mobile,
    }));
  }

  Future<void> _clearUserLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  final google_sign.GoogleSignIn _googleSignIn = google_sign.GoogleSignIn(
    // Web client ID (client_type 3) from google-services.json
    serverClientId: '521792570049-sbdjsev9jtm00s6p87nstbibed3qne8e.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<void> loginWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // 1. Trigger Google Sign-In
      final google_sign.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the login
        state = state.copyWith(isLoading: false);
        return;
      }

      // 2. Get auth tokens (may be null on Android - that's OK)
      final google_sign.GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      // 3. Send all available data to Node.js backend
      // uid (googleUser.id) is always available even when tokens are null
      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          if (idToken != null) 'id_token': idToken,
          if (accessToken != null) 'access_token': accessToken,
          'uid': googleUser.id,
          'email': googleUser.email,
          'name': googleUser.displayName ?? googleUser.email,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['user'];

        final userProfile = UserProfile(
          id: userData['id'],
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          mobile: userData['mobile'] ?? '',
        );

        state = state.copyWith(
          isLoggedIn: true,
          user: userProfile,
          isLoading: false,
        );
        await _saveUserLocal(userProfile);
        fetchOrders(userProfile.id);
      } else {
        throw Exception('Backend authentication failed: ${response.body}');
      }
    } catch (e) {
      // In case of DEVELOPER_ERROR, provide a helpful message
      String errorMsg = e.toString();
      if (errorMsg.contains('ApiException: 10')) {
        errorMsg = 'Developer Error: SHA-1 not registered in Google Cloud Console for this app.';
      }
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  Future<void> loginWithPhone(String uid, String phone) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Send uid and phone to Node.js backend
      final response = await http.post(
        Uri.parse('$apiUrl/api/auth/phone'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': uid, 'phone': phone}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userData = responseData['user'];

        final userProfile = UserProfile(
          id: userData['id'],
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          mobile: userData['mobile'] ?? '',
        );

        state = state.copyWith(
          isLoggedIn: true,
          user: userProfile,
          isLoading: false,
        );
        await _saveUserLocal(userProfile);
        fetchOrders(userProfile.id);
      } else {
        throw Exception('Backend phone authentication failed: ${response.body}');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _clearUserLocal();
    state = UserState.initial();
  }

  void updateUser(UserProfile user) {
    state = state.copyWith(user: user);
  }

  void saveAddress(String address, String pincode) {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(
        savedAddress: SavedAddress(address: address, pincode: pincode),
      );
      state = state.copyWith(user: updatedUser);
    }
  }

  void setOrders(List<UserOrder> orders) {
    state = state.copyWith(orders: orders);
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(() {
  return UserNotifier();
});

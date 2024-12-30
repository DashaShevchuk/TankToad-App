//login_page.dart

// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:logger/logger.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:country_code_picker/country_code_picker.dart';
// import 'dart:convert';
// import 'main_page.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({Key? key}) : super(key: key);

//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _phoneController = TextEditingController();
//   String _selectedCountryCode = '+380';
//   final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
//   final _logger = Logger();
//   bool _isLoading = false;
//   int _selectedLoginMethod = 0;
//   bool _obscurePassword = true;

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   Future<void> _handleGoogleSignIn() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) {
//         setState(() {
//           _isLoading = false;
//         });
//         return;
//       }

//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//       final token = googleAuth.idToken;

//       _logger.d("Google token received: ${token?.substring(0, 10)}...");

//       final response = await http.post(
//         Uri.parse('${dotenv.env['API_URL']}${dotenv.env['GOOGLE_LOGIN']}'),
//         headers: {
//           'Content-Type': 'application/json',
//           'accept': 'application/json',
//         },
//         body: jsonEncode({
//           'Id': 0,
//           'FirstName': googleUser.displayName?.split(' ').first ?? '',
//           'LastName': googleUser.displayName?.split(' ').last ?? '',
//           'Name': googleUser.displayName ?? '',
//           'Email': googleUser.email,
//           'AuthToken': '',
//           'TokenId': token,
//         }),
//       );

//       _logger.d("Google login response status: ${response.statusCode}");
//       _logger.d("Google login response body: ${response.body}");

//       if (response.statusCode == 200) {
//         final userData = json.decode(response.body);
//         final userId = userData['Id'];

//         if (mounted) {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (context) => MainPage(userId: userId)),
//           );
//         }
//       } else {
//         throw Exception('Google login failed');
//       }
//     } catch (e) {
//       _logger.e("Google sign in error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Failed to sign in with Google'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _trySubmitForm() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final url = _selectedLoginMethod == 1
//           ? '${dotenv.env['API_URL']}${dotenv.env['PHONE_LOGIN']}'
//           : '${dotenv.env['API_URL']}${dotenv.env['LOGIN']}';

//       final body = _selectedLoginMethod == 1
//           ? {'Phone': '$_selectedCountryCode${_phoneController.text}'}
//           : {
//               'Username': _emailController.text,
//               'Password': _passwordController.text,
//             };

// if (_selectedLoginMethod == 1) {
//   _logger.d('$_selectedCountryCode${_phoneController.text}');
// }

//       _logger.d("Login URL: $url");
//       _logger.d("Request body: $body");

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'accept': 'application/json',
//         },
//         body: jsonEncode(body),
//       );

//       _logger.d("Response status: ${response.statusCode}");
//       _logger.d("Response body: ${response.body}");

//       if (response.statusCode == 200) {
//         final userData = json.decode(response.body);
//         final userId = userData['Id'];

//         if (mounted) {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (context) => MainPage(userId: userId)),
//           );
//         }
//       } else {
//         throw Exception('Login failed');
//       }
//     } catch (e) {
//       _logger.e("Login error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(_selectedLoginMethod == 1
//                 ? 'Invalid phone number'
//                 : 'Invalid email or password'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Image.asset('assets/logo.png', height: 100),
//                   const SizedBox(height: 40),

//                   // Login Methods Selection
//                   Container(
//                     decoration: BoxDecoration(
//                       color: Colors.grey[100],
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     padding: const EdgeInsets.all(4),
//                     child: Row(
//                       children: [
//                         _buildMethodButton(0, Icons.email, 'Email'),
//                         _buildMethodButton(1, Icons.phone, 'Phone'),
//                         _buildMethodButton(2, Icons.g_mobiledata_rounded, 'Google'),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 32),

//                   // Login Forms
//                   if (_selectedLoginMethod == 0) ...[
//                     // Email Login
//                     TextFormField(
//                       controller: _emailController,
//                       decoration: InputDecoration(
//                         labelText: 'Email',
//                         border: const OutlineInputBorder(),
//                         filled: true,
//                         fillColor: Colors.grey[100],
//                         prefixIcon: const Icon(Icons.email_outlined),
//                       ),
//                       keyboardType: TextInputType.emailAddress,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your email';
//                         }
//                         // if (!value.contains('@')) {
//                         //   return 'Please enter a valid email';
//                         // }
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextFormField(
//                       controller: _passwordController,
//                       decoration: InputDecoration(
//                         labelText: 'Password',
//                         border: const OutlineInputBorder(),
//                         filled: true,
//                         fillColor: Colors.grey[100],
//                         prefixIcon: const Icon(Icons.lock_outline),
//                         suffixIcon: IconButton(
//                           icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
//                           onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                         ),
//                       ),
//                       obscureText: _obscurePassword,
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter your password';
//                         }
//                         return null;
//                       },
//                     ),
//                   ] else if (_selectedLoginMethod == 1) ...[
//                     // Phone Login
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: Row(
//                         children: [
//                           CountryCodePicker(
//                             onChanged: (CountryCode countryCode) {
//                               setState(() {
//                                 _selectedCountryCode = countryCode.dialCode ?? '+380';
//                               });
//                             },
//                             initialSelection: 'UA',
//                             favorite: const ['UA', 'US', 'GB'],
//                             showCountryOnly: false,
//                             showOnlyCountryWhenClosed: false,
//                             alignLeft: false,
//                             padding: const EdgeInsets.symmetric(horizontal: 8),
//                           ),
//                           Expanded(
//                             child: TextFormField(
//                               controller: _phoneController,
//                               decoration: const InputDecoration(
//                                 hintText: 'Phone Number',
//                                 border: InputBorder.none,
//                                 contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                               ),
//                               keyboardType: TextInputType.phone,
//                               validator: (value) {
//                                 if (value == null || value.isEmpty) {
//                                   return 'Please enter your phone number';
//                                 }
//                                 return null;
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ] else ...[
//                     // Google Login
//                     Center(
//                       child: Column(
//                         children: [
//                           const Text(
//                             'Continue with Google',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           ElevatedButton.icon(
//                             onPressed: _isLoading ? null : _handleGoogleSignIn,
//                             icon: Image.asset('assets/google_logo.png', height: 24),
//                             label: const Text('Sign in with Google'),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.white,
//                               foregroundColor: Colors.black87,
//                               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                               elevation: 2,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8),
//                                 side: BorderSide(color: Colors.grey[300]!),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],

//                   const SizedBox(height: 24),

//                   // Submit Button (hidden for Google login)
//                   if (_selectedLoginMethod != 2)
//                     ElevatedButton(
//                       onPressed: _isLoading ? null : _trySubmitForm,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.indigo,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: _isLoading
//                           ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             )
//                           : Text(
//                               _selectedLoginMethod == 1 ? 'Login with Phone' : 'Login',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                     ),

//                   // Forgot Password Link
//                   if (_selectedLoginMethod == 0) ...[
//                     const SizedBox(height: 16),
//                     Center(
//                       child: TextButton(
//                         onPressed: () {
//                           // TODO: Navigate to password recovery
//                         },
//                         child: const Text('Forgot Password?'),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMethodButton(int index, IconData icon, String label) {
//     return Expanded(
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: () => setState(() => _selectedLoginMethod = index),
//           borderRadius: BorderRadius.circular(12),
//           child: Container(
//             padding: const EdgeInsets.symmetric(vertical: 12),
//             decoration: BoxDecoration(
//               color: _selectedLoginMethod == index ? Colors.white : Colors.transparent,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: _selectedLoginMethod == index
//                   ? [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 4,
//                         offset: const Offset(0, 2),
//                       ),
//                     ]
//                   : null,
//             ),
//             child: Column(
//               children: [
//                 Icon(
//                   icon,
//                   color: _selectedLoginMethod == index ? Colors.indigo : Colors.grey,
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   label,
//                   style: TextStyle(
//                     color: _selectedLoginMethod == index ? Colors.indigo : Colors.grey,
//                     fontSize: 12,
//                     fontWeight: _selectedLoginMethod == index ? FontWeight.bold : FontWeight.normal,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }



// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:logger/logger.dart';
// import 'dart:convert';
// import 'main_page.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({Key? key}) : super(key: key);

//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   final _smsCodeController = TextEditingController();
//   final _logger = Logger();
//   bool _isLoading = false;
//   bool _showSmsForm = false;
//   String _verificationId = '';

//    Future<void> _sendSmsCode() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final url = '${dotenv.env['API_URL']}${dotenv.env['PHONE_LOGIN']}';
//       final body = {'Phone': _phoneController.text, "Code":""};

//       _logger.d("Send SMS Code URL: $url");
//       _logger.d("Request body: $body");

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'accept': 'application/json',
//         },
//         body: jsonEncode(body),
//       );

//       _logger.d("Response status: ${response.statusCode}");
//       _logger.d("Response body: ${response.body}");

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         _verificationId = data['VerificationId'];
//         setState(() {
//           _showSmsForm = true;
//         });
//       } else if (response.statusCode == 404) {
//         throw Exception('User not found');
//       } else {
//         throw Exception('Failed to send SMS code');
//       }
//     } catch (e) {
//       _logger.e("Send SMS code error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(e.toString() == 'User not found'
//                 ? 'User not found'
//                 : 'Failed to send SMS code'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _verifySmsCode() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final url = '${dotenv.env['API_URL']}${dotenv.env['PHONE_LOGIN']}';
//       final body = {
//         'Phone': _phoneController.text,
//         'Code': _smsCodeController.text,
//       };

//       _logger.d("Verify SMS Code URL: $url");
//       _logger.d("Request body: $body");

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'accept': 'application/json',
//         },
//         body: jsonEncode(body),
//       );

//       _logger.d("Response status: ${response.statusCode}");
//       _logger.d("Response body: ${response.body}");

//       if (response.statusCode == 200) {
//         final userData = json.decode(response.body);
//         final userId = userData['Id'];

//         if (mounted) {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (context) => MainPage(userId: userId)),
//           );
//         }
//       } else if (response.statusCode == 404) {
//         throw Exception('User not found');
//       } else {
//         throw Exception('SMS code verification failed');
//       }
//     } catch (e) {
//       _logger.e("Verify SMS code error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(e.toString() == 'User not found'
//                 ? 'User not found'
//                 : 'Invalid SMS code'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Image.asset('assets/logo.png', height: 100),
//                   const SizedBox(height: 40),
//                   if (!_showSmsForm) ...[
//                     // Phone Number Input
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: TextFormField(
//                         controller: _phoneController,
//                         decoration: const InputDecoration(
//                           hintText: 'Phone Number',
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                         ),
//                         keyboardType: TextInputType.phone,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter your phone number';
//                           }
//                           return null;
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: _isLoading ? null : _sendSmsCode,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.indigo,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: _isLoading
//                           ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             )
//                           : const Text(
//                               'Send SMS Code',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                     ),
//                   ] else ...[
//                     // SMS Code Input
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: TextFormField(
//                         controller: _smsCodeController,
//                         decoration: const InputDecoration(
//                           hintText: 'SMS Code',
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(horizontal: 16),
//                         ),
//                         keyboardType: TextInputType.number,
//                         validator: (value) {
//                           if (value == null || value.isEmpty) {
//                             return 'Please enter the SMS code';
//                           }
//                           return null;
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     ElevatedButton(
//                       onPressed: _isLoading ? null : _verifySmsCode,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.indigo,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: _isLoading
//                           ? const SizedBox(
//                               height: 20,
//                               width: 20,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             )
//                           : const Text(
//                               'Verify SMS Code',
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }





import 'package:first_flutter_proj/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'password_recovery_screen.dart';
import 'main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  String _selectedCountryCode = '380';
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final _logger = Logger();
  bool _isLoading = false;
  int _selectedLoginMethod = 0;
  bool _obscurePassword = true;
  bool _showSmsForm = false;

Future<void> _saveSession(String token, int userId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('auth_token', token);
  await prefs.setInt('user_id', userId);
}
// Автоматична перевірка сесії при запуску
Future<void> _checkSession() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final userId = prefs.getInt('user_id');

  if (token != null && userId != null) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainPage(userId: userId)),
    );
  }
}

// Виклик перевірки сесії при ініціалізації сторінки
@override
void initState() {
  super.initState();
  _checkSession();
}

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    super.dispose();
  }

 Future<void> _handleGoogleSignIn() async {
  setState(() {
    _isLoading = true;
  });

  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final token = googleAuth.idToken;

    _logger.d("Google token received: ${token?.substring(0, 10)}...");

    final requestBody = {
      'Id': 0,
      'FirstName': googleUser.displayName?.split(' ').first ?? '',
      'LastName': googleUser.displayName?.split(' ').last ?? '',
      'Name': googleUser.displayName ?? '',
      'Email': googleUser.email,
      'AuthToken': '',
      'TokenId': token ?? '',
    };

    final response = await http.post(
      Uri.parse('${dotenv.env['API_URL']}${dotenv.env['GOOGLE_LOGIN']}'),
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    _logger.d("Google login response status: ${response.statusCode}");
    _logger.d("Google login response body: ${response.body}");

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      final userId = userData['Id'];

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainPage(userId: userId)),
        );
      }
    } else {
      throw Exception('Google login failed');
    }
  } catch (e) {
    _logger.e("Google sign in error: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to sign in with Google'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

 Future<void> _sendSmsCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
     final url = '${dotenv.env['API_URL']}${dotenv.env['PHONE_LOGIN']}';
      final body = {'Phone': _selectedCountryCode + _phoneController.text, "Code": ""};

      _logger.d("Send SMS Code URL: $url");
      _logger.d("Request body: $body");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      _logger.d("Response status: ${response.statusCode}");
      _logger.d("Response body: ${response.body}");

      if (response.statusCode == 200) {
        setState(() {
          _showSmsForm = true;
        });
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('Failed to send SMS code');
      }
    } catch (e) {
      _logger.e("Send SMS code error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString() == 'User not found'
                ? 'User not found'
                : 'Failed to send SMS code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifySmsCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = '${dotenv.env['API_URL']}${dotenv.env['PHONE_LOGIN']}';
      final body = {
        'Phone': _phoneController.text,
        'Code': _smsCodeController.text,
      };

      _logger.d("Verify SMS Code URL: $url");
      _logger.d("Request body: $body");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      _logger.d("Response status: ${response.statusCode}");
      _logger.d("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        final userId = userData['Id'];

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MainPage(userId: userId)),
          );
        }
      } else if (response.statusCode == 404) {
        throw Exception('User not found');
      } else {
        throw Exception('SMS code verification failed');
      }
    } catch (e) {
      _logger.e("Verify SMS code error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString() == 'User not found'
                ? 'User not found'
                : 'Invalid SMS code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _trySubmitForm() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    final url = _selectedLoginMethod == 1
        ? '${dotenv.env['API_URL']}${dotenv.env['PHONE_LOGIN']}'
        : '${dotenv.env['API_URL']}${dotenv.env['LOGIN']}';

    final body = _selectedLoginMethod == 1
        ? {'Phone': '$_selectedCountryCode${_phoneController.text}', 'Code': ' '}
        : {
            'Username': _usernameController.text,
            'Password': _passwordController.text,
          };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final userData = json.decode(response.body);
      final userId = userData['Id'];
      final token = userData['Token'];

      await _saveSession(token, userId); // Збереження токену та userId

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainPage(userId: userId)),
        );
      }
    } else {
      throw Exception('Login failed');
    }
  } catch (e) {
    _logger.e("Login error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_selectedLoginMethod == 1
            ? 'Invalid phone number'
            : 'Invalid email or password'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset('assets/logo.png', height: 100),
                const SizedBox(height: 40),

                // Login Methods Selection
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      _buildMethodButton(0, Icons.person, 'Username'),
                      _buildMethodButton(1, Icons.phone, 'Phone'),
                      _buildMethodButton(2, Icons.g_mobiledata_rounded, 'Google'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Login Forms
                if (_selectedLoginMethod == 0) ...[
                  // Email Login
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                ] else if (_selectedLoginMethod == 1) ...[
                  if (!_showSmsForm) ...[
                    // Phone Number Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          CountryCodePicker(
                            onChanged: (CountryCode countryCode) {
                              setState(() {
                                _selectedCountryCode = countryCode.dialCode ?? '+380';
                              });
                            },
                            initialSelection: 'UA',
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                            alignLeft: false,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                hintText: 'Phone Number',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendSmsCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Send me SMS with code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ] else ...[
                    // SMS Code Input
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextFormField(
                        controller: _smsCodeController,
                        decoration: const InputDecoration(
                          hintText: 'SMS Code',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the SMS code';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _verifySmsCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Verify SMS Code',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ] else ...[
                  // Google Login
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: Image.asset('assets/google_logo.png', height: 24),
                          label: const Text('Sign in with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Submit Button (hidden for Google login)
                if (_selectedLoginMethod != 2)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _trySubmitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _selectedLoginMethod == 0 ? 'Login' : 'Login with Phone',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),

                // Forgot Password Link
                if (_selectedLoginMethod == 0) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                     onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PasswordRecoveryScreen(),
          ),
        );
      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildMethodButton(int index, IconData icon, String label) {
  return Expanded(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedLoginMethod = index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _selectedLoginMethod == index ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _selectedLoginMethod == index
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: _selectedLoginMethod == index ? Colors.indigo : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: _selectedLoginMethod == index ? Colors.indigo : Colors.grey,
                  fontSize: 12,
                  fontWeight: _selectedLoginMethod == index ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
                            
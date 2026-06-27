import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'main_navigation_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoginMode = true;
  String? _errorMessage;

  Map<String, dynamic>? _settings;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ApiService.fetchSettings();
    if (mounted) {
      setState(() {
        _settings = settings;
        _isLoadingSettings = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _submit() async {
    if (_settings?['mobileApp']?['allowLogins'] == false) {
      _showError('Logins are temporarily disabled on the mobile app. Please order from the website.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? error;

    if (_isLoginMode) {
      error = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
    } else {
      error = await authProvider.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _phoneController.text.trim(),
      );
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration successful! Please login.'),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _isLoginMode = true;
        });
        return;
      }
    }

    if (!mounted) return;

    if (error != null) {
      _showError(error);
    } else if (_isLoginMode) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    }
  }

  void _handleGoogleSignIn() async {
    if (_settings?['mobileApp']?['allowLogins'] == false) {
      _showError('Logins are temporarily disabled on the mobile app. Please order from the website.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (error != null) {
      // If user cancelled, don't show red error box, just log
      if (error.contains('cancelled')) {
        print('[GOOGLE AUTH] Cancelled by user');
      } else {
        _showError(error);
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (matching Pills & More premium layout)
          Container(
            height: size.height,
            width: size.width,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF00804A), // Deep Teal
                  Color(0xFF00A05C), // Medical Teal
                  Color(0xFF1E293B), // Premium Slate/Dark
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.06),
                  
                  // App Branding
                  const Hero(
                    tag: 'logo',
                    child: Icon(
                      Icons.local_pharmacy_rounded,
                      size: 72,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pills & More',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLoginMode ? 'Your Trusted Online Medical Store' : 'Create an account to order medicines',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: size.height * 0.05),
                  
                  // Glassmorphic Form Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isLoginMode ? 'Welcome Back' : 'Get Started',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00804A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          
                          if (!_isLoginMode) ...[
                            // Name field
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person_rounded, color: Color(0xFF00804A)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 3) {
                                  return 'Enter a valid name (min 3 characters)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Phone field
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: const Icon(Icons.phone_rounded, color: Color(0xFF00804A)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().length < 10) {
                                  return 'Enter a valid 10-digit phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.email_rounded, color: Color(0xFF00804A)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || !value.contains('@') || value.trim().length < 5) {
                                  return 'Please enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_rounded, color: Color(0xFF00804A)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Login/Register Button
                          authProvider.isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00804A),
                                    foregroundColor: Colors.white,
                                    shadowColor: const Color(0xFF00804A).withOpacity(0.4),
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    minimumSize: const Size(double.infinity, 50),
                                  ),
                                  child: Text(
                                    _isLoginMode ? 'LOGIN' : 'REGISTER',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                          
                          const SizedBox(height: 16),
                          
                          // OR Divider
                          const Row(
                            children: [
                              Expanded(child: Divider(thickness: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(child: Divider(thickness: 1)),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Google Login Button
                          authProvider.isLoading
                              ? const SizedBox()
                              : OutlinedButton.icon(
                                  onPressed: _handleGoogleSignIn,
                                  icon: Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1024px-Google_%22G%22_logo.svg.png',
                                    height: 20,
                                    width: 20,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.login, size: 20),
                                  ),
                                  label: Text(
                                    _isLoginMode ? 'Continue with Google' : 'Sign Up with Google',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    minimumSize: const Size(double.infinity, 50),
                                    backgroundColor: Colors.white,
                                  ),
                                ),

                          const SizedBox(height: 20),

                          // Switch Mode Button
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLoginMode = !_isLoginMode;
                                _errorMessage = null;
                              });
                            },
                            child: Text(
                              _isLoginMode
                                  ? "Don't have an account? Sign Up"
                                  : 'Already have an account? Login',
                              style: const TextStyle(
                                color: Color(0xFF00804A),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

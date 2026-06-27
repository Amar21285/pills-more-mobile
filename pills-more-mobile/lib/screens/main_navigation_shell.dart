import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import 'home_screen.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';
import '../services/api_service.dart';
import 'dart:convert';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  static bool _welcomeShown = false;

  @override
  void initState() {
    super.initState();
    if (!_welcomeShown) {
      _welcomeShown = true;
      _showWelcomePopup();
    }
  }

  void _showWelcomePopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Brand Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2F5EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.healing_rounded,
                    color: Color(0xFF00804A),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Welcome to Pills & More!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00804A),
                    fontFamily: 'Outfit',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your trusted chemist and supermarket. Explore genuine medicines, health, and personal care products delivered to your doorstep.',
                  style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Buttons
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00804A),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    if (!auth.isAuthenticated) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  child: const Text('LOGIN / SIGN UP'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Skip & Explore Products',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  final List<Widget> _tabs = [
    const HomeScreen(),
    const ShopScreen(),
    const CartScreenBody(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF00804A),
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            activeIcon: Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: const Icon(Icons.shopping_bag),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}

// ================== SHOP SCREEN ==================
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ApiService.fetchProducts();
      final Set<String> uniqueCats = {'All'};
      for (var p in products) {
        if (p['category'] != null && p['category'].toString().isNotEmpty) {
          uniqueCats.add(p['category'].toString());
        }
      }
      if (mounted) {
        setState(() {
          _allProducts = products;
          _filteredProducts = products;
          _categories = uniqueCats.toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredProducts = _allProducts.where((p) {
      final matchesSearch = p['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          (p['category'] != null && p['category'].toString() == _selectedCategory);
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Catalog', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Search catalog...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Categories
          if (_categories.length > 1)
            Container(
              height: 40,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = cat == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00804A),
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                      backgroundColor: Colors.grey.shade100,
                      onSelected: (_) => _selectCategory(cat),
                    ),
                  );
                },
              ),
            ),
          // Products Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00804A)))
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final double price = (product['price'] ?? 0.0).toDouble();
                          final double mrp = (product['mrp'] ?? price).toDouble();
                          final int discount = mrp > price ? (((mrp - price) / mrp) * 100).round() : 0;
                          
                          String imageUrl = '';
                          final images = product['images'];
                          if (images is String && images.isNotEmpty) {
                            try {
                              final List<dynamic> parsed = jsonDecode(images);
                              if (parsed.isNotEmpty) imageUrl = parsed[0];
                            } catch (_) {}
                          } else if (product['imageUrl'] != null) {
                            imageUrl = product['imageUrl'];
                          }
                          if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
                            imageUrl = 'https://pillsnmore.in$imageUrl';
                          }

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: product),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                      ),
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      child: imageUrl.isNotEmpty
                                          ? Image.network(imageUrl, fit: BoxFit.contain)
                                          : const Icon(Icons.medical_services_outlined, size: 40, color: Colors.grey),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product['brand'] ?? 'General',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text(
                                              '₹${price.toStringAsFixed(1)}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF00804A)),
                                            ),
                                            const SizedBox(width: 4),
                                            if (discount > 0)
                                              Text(
                                                '₹${mrp.toStringAsFixed(1)}',
                                                style: TextStyle(
                                                  decoration: TextDecoration.lineThrough,
                                                  color: Colors.grey.shade400,
                                                  fontSize: 10,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// ================== ACCOUNT SCREEN ==================
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    final isGuest = !auth.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Details Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00804A), Color(0xFF00A05C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGuest ? 'Guest Customer' : (auth.user?['name'] ?? 'User'),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isGuest ? 'Log in to place orders & view history' : (auth.user?['email'] ?? 'Welcome to Pills & More'),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Menu Items
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF00804A)),
                  title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    if (isGuest) {
                      _showLoginPrompt(context);
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined, color: Color(0xFF00804A)),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF00804A)),
                  title: const Text('Support'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Action Button (Login / Sign Up for Guest, Logout for Logged In user)
          isGuest
              ? ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00804A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('LOGIN / SIGN UP'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                )
              : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade100),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('LOG OUT ACCOUNT'),
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                ),
        ],
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please login to view your orders.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import 'cart_screen.dart';
import 'order_history_screen.dart';
import 'product_detail_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _allProducts = [];
  List<dynamic> _filteredProducts = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  bool _isLoadingProducts = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  String _currentLocation = '📍 Detect location...';
  bool _isLocating = false;
  Map<String, dynamic>? _settings;

  PageController? _bannerPageController;
  Timer? _bannerTimer;
  int _currentBannerPage = 0;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController(initialPage: 0);
    _loadData();
    _updateLocation(silent: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerPageController?.dispose();
    _bannerTimer?.cancel();
    super.dispose();
  }

  Future<void> _updateLocation({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLocating = true;
        _currentLocation = '📍 Locating...';
      });
    }

    try {
      final locData = await LocationService.getCurrentAddress();
      if (locData != null && mounted) {
        setState(() {
          _currentLocation = '📍 ${locData['city']}, ${locData['state']} - ${locData['pincode']}';
          _isLocating = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentLocation = '📍 Tap to detect location';
        _isLocating = false;
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _loadData() async {
    // 1. Fetch public settings to sync GST calculation rules
    final settings = await ApiService.fetchSettings();
    if (settings != null && mounted) {
      final taxConfig = settings['tax'];
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      if (taxConfig != null) {
        cartProvider.setTaxConfig(
          taxConfig['isInclusive'] ?? true,
          taxConfig['enabled'] ?? true,
        );
      }
    }

    // 2. Fetch products
    final products = await ApiService.fetchProducts();
    if (mounted) {
      setState(() {
        _settings = settings;
        _allProducts = products;
        _filteredProducts = products;
        _isLoadingProducts = false;
        
        // Extract unique categories
        final Set<String> uniqueCats = {'All'};
        for (var p in products) {
          if (p['category'] != null && p['category'].toString().isNotEmpty) {
            uniqueCats.add(p['category'].toString());
          }
        }
        _categories = uniqueCats.toList();
        
        final List<dynamic> bannerList = _settings?['promo']?['posterImageUrls'] ?? [];
        _startBannerTimer(bannerList.length);
      });
    }
  }

  void _startBannerTimer(int count) {
    _bannerTimer?.cancel();
    if (count <= 1) return;
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerPageController?.hasClients == true) {
        _currentBannerPage = (_currentBannerPage + 1) % count;
        _bannerPageController?.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Widget _buildBannerCarousel() {
    final List<dynamic> bannerList = _settings?['promo']?['posterImageUrls'] ?? [];
    if (bannerList.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 160,
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      child: PageView.builder(
        controller: _bannerPageController,
        onPageChanged: (idx) {
          _currentBannerPage = idx;
        },
        itemCount: bannerList.length,
        itemBuilder: (context, index) {
          final banner = bannerList[index];
          final rawUrl = banner['url'] ?? '';
          if (rawUrl.isEmpty) return const SizedBox.shrink();
          final imageUrl = rawUrl.startsWith('http') ? rawUrl : 'https://pillsnmore.in$rawUrl';
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported_rounded, size: 40, color: Colors.grey),
                ),
              ),
            ),
          );
        },
      ),
    );
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
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    if (_settings?['mobileApp']?['maintenanceMode'] == true) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00804A), Color(0xFF00A05C), Color(0xFF1E293B)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Scheduled Maintenance',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Outfit',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'The mobile app is currently undergoing scheduled maintenance. Please visit our website to place orders and manage your account.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() {
                      _isLoadingProducts = true;
                    });
                    await _loadData();
                    await _updateLocation(silent: true);
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('CHECK AGAIN'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00804A),
                    minimumSize: const Size(180, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    await auth.logout();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text(
                    'Logout Account',
                    style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        titleSpacing: 8,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Color(0xFF00804A)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF00804A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.healing_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Pills ',
                      style: TextStyle(
                        color: Color(0xFF00804A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const Text(
                      '& ',
                      style: TextStyle(
                        color: Color(0xFFD92D20),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const Text(
                      'More',
                      style: TextStyle(
                        color: Color(0xFFD92D20),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00804A),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 7),
                          SizedBox(width: 1.5),
                          Text(
                            'VERIFIED',
                            style: TextStyle(color: Colors.white, fontSize: 5, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Text(
                  'CHEMIST & HEALTH STYLE SUPERMARKET',
                  style: TextStyle(
                    color: Color(0xFF00804A),
                    fontSize: 6.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: authProvider.user?['avatar'] != null
                    ? NetworkImage(authProvider.user?['avatar'])
                    : null,
                child: authProvider.user?['avatar'] == null
                    ? const Icon(Icons.person, size: 40, color: Color(0xFF00804A))
                    : null,
              ),
              accountName: Text(authProvider.user?['name'] ?? 'Guest Customer'),
              accountEmail: Text(authProvider.user?['email'] ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home Catalog'),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('My Orders'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text('My Cart'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await authProvider.logout();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: _isLoadingProducts
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00804A)))
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildMarqueeBanner(),
                  _buildDeliveringCard(cartProvider),
                  // Search Bar Section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.white,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterProducts,
                      decoration: InputDecoration(
                        hintText: 'Search medicines, health products...',
                        prefixIcon: const Icon(Icons.search, color: Colors.black54),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterProducts('');
                                },
                              )
                            : null,
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
                  
                  // Quick Actions Bar
                  _buildQuickActionsRow(),
                  
                  // Banner Carousel
                  _buildBannerCarousel(),
                  
                  // Category Selector Pills
                  if (_categories.length > 1)
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
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
                  
                  // Product Grid
                  _filteredProducts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('No products found matching your filter'),
                            ],
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                            final double price = _toDouble(product['price']);
                            final double mrp = _toDouble(product['mrp'] ?? product['price']);
                            final int discount = mrp > price ? (((mrp - price) / mrp) * 100).round() : 0;
                            
                            // Image parsing helper
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
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Product Image Container
                                        Expanded(
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(12),
                                                topRight: Radius.circular(12),
                                              ),
                                            ),
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            child: imageUrl.isNotEmpty
                                                ? Image.network(
                                                    imageUrl,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __, ___) => const Icon(
                                                      Icons.medical_services_outlined,
                                                      size: 48,
                                                      color: Colors.grey,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.medical_services_outlined,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                          ),
                                        ),
                                        
                                        // Info Section
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product['name'] ?? 'Product',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                product['category'] ?? 'Medicine',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 11,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Text(
                                                    '₹${price.toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: theme.colorScheme.primary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  if (discount > 0) ...[
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      '₹${mrp.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        decoration: TextDecoration.lineThrough,
                                                        color: Colors.grey,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Add to Cart Button
                                        Padding(
                                          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(double.infinity, 32),
                                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                              foregroundColor: theme.colorScheme.primary,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                            ),
                                            onPressed: () {
                                              cartProvider.addToCart(product);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('${product['name']} added to cart!'),
                                                  duration: const Duration(seconds: 1),
                                                  action: SnackBarAction(
                                                    label: 'View',
                                                    textColor: Colors.yellow,
                                                    onPressed: () {
                                                      Navigator.of(context).push(
                                                        MaterialPageRoute(builder: (_) => const CartScreen()),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text('Add to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Discount Badge
                                    if (discount > 0)
                                      Positioned(
                                        left: 8,
                                        top: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade700,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '$discount% OFF',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildMarqueeBanner() {
    final bannerText = _settings?['promo']?['discountBannerText'] ?? 'Special Offer: 10% OFF on all medicines!';
    return Container(
      width: double.infinity,
      color: const Color(0xFF00804A),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Text(
        bannerText.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDeliveringCard(CartProvider cartProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FBF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2F5EC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE2F5EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on_rounded, color: Color(0xFF00804A), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DELIVERING TO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: _isLocating ? null : () => _updateLocation(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _currentLocation.replaceAll('📍 ', ''),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (_isLocating)
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00804A)),
            )
          else
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black54),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    final storePhone = _settings?['store']?['phone'] ?? '9372973836';
    final whatsappNum = _settings?['notifications']?['whatsappNumber'] ?? '9372973836';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildQuickActionCard(
            icon: Icons.upload_file_rounded,
            title: 'UPLOAD RX',
            bgColor: const Color(0xFFF3F3FA),
            iconColor: const Color(0xFF6366F1),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Prescription upload feature is available on checkout.')),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildQuickActionCard(
            icon: Icons.phone_in_talk_rounded,
            title: 'BOOK CALL',
            bgColor: const Color(0xFFF0F4FA),
            iconColor: const Color(0xFF3B82F6),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling Store: $storePhone')),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildQuickActionCard(
            icon: Icons.chat_rounded,
            title: 'WHATSAPP',
            bgColor: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening WhatsApp Chat: $whatsappNum')),
              );
            },
          ),
          const SizedBox(width: 8),
          _buildQuickActionCard(
            icon: Icons.card_giftcard_rounded,
            title: 'OFFERS',
            bgColor: const Color(0xFFFFF1F2),
            iconColor: const Color(0xFFF43F5E),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Use coupon code FIRST50 for ₹50 off on first order.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: iconColor.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

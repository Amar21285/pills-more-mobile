import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      });
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
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pills & More'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
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
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF0F766E)),
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
      body: Column(
        children: [
          // Search Bar Section
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primary.withOpacity(0.08),
            child: TextField(
              controller: _searchController,
              onChanged: _filterProducts,
              decoration: InputDecoration(
                hintText: 'Search medicines, healthcare products...',
                prefixIcon: const Icon(Icons.search),
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
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
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
                      selectedColor: theme.colorScheme.primary,
                      textColor: isSelected ? Colors.white : Colors.black87,
                      backgroundColor: Colors.white,
                      onSelected: (_) => _selectCategory(cat),
                    ),
                  );
                },
              ),
            ),

          // Product Grid
          Expanded(
            child: _isLoadingProducts
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
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
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: const BorderRadius.only(
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
          ),
        ],
      ),
    );
  }
}

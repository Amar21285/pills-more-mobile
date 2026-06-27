import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _incrementQty() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQty() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final theme = Theme.of(context);
    final product = widget.product;

    final double price = (product['price'] ?? 0.0).toDouble();
    final double mrp = (product['mrp'] ?? price).toDouble();
    final double discount = mrp > price ? (((mrp - price) / mrp) * 100) : 0.0;
    final bool isPrescriptionRequired = product['isPrescriptionRequired'] ?? false;

    // Parse image URL
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

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big Image Gallery Area
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.medical_services_outlined,
                        size: 96,
                        color: Colors.grey,
                      ),
                    )
                  : const Icon(
                      Icons.medical_services_outlined,
                      size: 96,
                      color: Colors.grey,
                    ),
            ),
            
            // Product Info Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product['brand'] != null && product['brand'].toString().isNotEmpty)
                    Text(
                      product['brand'].toString().toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    product['name'] ?? 'Medicine Product',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Category & Size / Volume info
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product['category'] ?? 'General',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (product['weightVolume'] != null && product['weightVolume'].toString().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          product['weightVolume'].toString(),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Pricing Container
                  Row(
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (discount > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          'MRP ₹${mrp.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${discount.round()}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Prescription Required Flag
                  if (isPrescriptionRequired)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Prescription Required: You must upload a valid doctor prescription to complete this purchase.',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(),
                  const SizedBox(height: 10),
                  
                  // Description
                  const Text(
                    'Product Description',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['description'] ?? 'No description available for this product. Please check the packaging instructions or contact a pharmacist before use.',
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 100), // Padding to prevent buttons overlap
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Quantity Selector
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: _decrementQty,
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: _incrementQty,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            // Add to Cart Button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  cartProvider.addToCart(product, quantity: _quantity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $_quantity x ${product['name']} to cart!'),
                      action: SnackBarAction(
                        label: 'View Cart',
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
                child: const Text(
                  'ADD TO CART',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';

class MobileCartItem {
  final String productId;
  final String name;
  final double price;
  final double mrp;
  final double gstPercentage;
  final String imageUrl;
  int quantity;

  MobileCartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.mrp,
    required this.gstPercentage,
    required this.imageUrl,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'originalPrice': mrp,
      'quantity': quantity,
      'gstPercentage': gstPercentage,
    };
  }
}

class CartProvider extends ChangeNotifier {
  final List<MobileCartItem> _items = [];
  bool _isTaxInclusive = true; // Default inclusive
  bool _isTaxEnabled = true;

  List<MobileCartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void setTaxConfig(bool isInclusive, bool isEnabled) {
    _isTaxInclusive = isInclusive;
    _isTaxEnabled = isEnabled;
    notifyListeners();
  }

  // --- CALCULATIONS (ACCURATE MATH ALIGNED WITH SERVER) ---
  
  // Total Selling Price Sum (inclusive of GST by default if isInclusive is active)
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  double get gstAmount {
    if (!_isTaxEnabled) return 0.0;
    
    return _items.fold(0.0, (sum, item) {
      if (_isTaxInclusive) {
        // Inclusive: price * qty * (rate / (100 + rate))
        return sum + (item.price * item.quantity * (item.gstPercentage / (100 + item.gstPercentage)));
      } else {
        // Exclusive: price * qty * (rate / 100)
        return sum + (item.price * item.quantity * (item.gstPercentage / 100));
      }
    });
  }

  // Taxable subtotal (value before GST, saved under 'subtotal' in database)
  double get taxableSubtotal {
    if (_isTaxEnabled && _isTaxInclusive) {
      return subtotal - gstAmount;
    }
    return subtotal;
  }

  double get shippingCost {
    if (subtotal == 0) return 0.0;
    return subtotal > 499 ? 0.0 : 40.0;
  }

  double get grandTotal {
    final taxToAdd = (_isTaxEnabled && !_isTaxInclusive) ? gstAmount : 0.0;
    return subtotal + shippingCost + taxToAdd;
  }

  // --- ACTIONS ---
  void addToCart(Map<String, dynamic> product, {int quantity = 1}) {
    final productId = product['id'] ?? '';
    final existingIndex = _items.indexWhere((item) => item.productId == productId);

    if (existingIndex > -1) {
      _items[existingIndex].quantity += quantity;
    } else {
      final images = product['images'];
      String imgUrl = '';
      if (images is String && images.isNotEmpty) {
        try {
          final parsed = jsonDecode(images);
          if (parsed is List && parsed.isNotEmpty) {
            imgUrl = parsed[0];
          }
        } catch (_) {}
      } else if (product['imageUrl'] != null) {
        imgUrl = product['imageUrl'];
      }

      _items.add(MobileCartItem(
        productId: productId,
        name: product['name'] ?? 'Product',
        price: (product['price'] ?? 0.0).toDouble(),
        mrp: (product['mrp'] ?? product['price'] ?? 0.0).toDouble(),
        gstPercentage: (product['gstRate'] ?? product['gstPercentage'] ?? 0.0).toDouble(),
        imageUrl: imgUrl,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index > -1) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}


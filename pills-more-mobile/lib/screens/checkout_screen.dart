import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 1; // 1: Address, 2: Payment, 3: Review & Success
  List<dynamic> _addresses = [];
  Map<String, dynamic>? _selectedAddress;
  bool _isLoadingAddresses = true;
  bool _isCreatingOrder = false;

  // New Address Form Controllers
  final _addressFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _isSavingAddress = false;

  String _paymentMethod = 'COD'; // COD or ONLINE
  final _notesController = TextEditingController();
  final _transactionIdController = TextEditingController();

  Map<String, dynamic>? _settings;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
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
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _notesController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;
    
    setState(() {
      _isLoadingAddresses = true;
    });

    final addresses = await ApiService.fetchAddresses(auth.token!);
    
    if (mounted) {
      setState(() {
        _addresses = addresses;
        _isLoadingAddresses = false;
        if (addresses.isNotEmpty) {
          _selectedAddress = addresses[0];
        }
      });
    }
  }

  void _showAddAddressDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _addressFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add New Address',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Recipient Name', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().length < 3 ? 'Enter recipient name' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: '10-digit Phone Number', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().length < 10 ? 'Enter valid phone number' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address Line 1 (Street, Building)', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().length < 5 ? 'Enter valid address' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pincode (ZIP)', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Enter pincode' : null,
                  ),
                  const SizedBox(height: 20),

                  _isSavingAddress
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveAddress,
                          child: const Text('SAVE ADDRESS', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveAddress() async {
    if (!_addressFormKey.currentState!.validate()) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    setState(() {
      _isSavingAddress = true;
    });

    final addressData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'addressLine1': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
    };

    final result = await ApiService.createAddress(addressData, auth.token!);

    if (mounted) {
      setState(() {
        _isSavingAddress = false;
      });

      if (result['statusCode'] == 200 || result['statusCode'] == 201) {
        Navigator.of(context).pop(); // close sheet
        _nameController.clear();
        _phoneController.clear();
        _addressController.clear();
        _cityController.clear();
        _stateController.clear();
        _pincodeController.clear();
        _loadAddresses(); // reload list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['body']['error'] ?? 'Failed to save address'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a delivery address.')),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    if (auth.token == null || cart.items.isEmpty) return;

    if (_settings?['mobileApp']?['allowOrders'] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ordering is temporarily disabled on the mobile app. Please order from the website.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_paymentMethod == 'ONLINE') {
      final txId = _transactionIdController.text.trim();
      if (txId.length != 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid 12-digit UPI UTR/Transaction ID to confirm payment.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() {
      _isCreatingOrder = true;
    });

    final orderData = {
      'userId': auth.user?['id'],
      'addressId': _selectedAddress!['id'],
      'items': cart.items.map((i) => i.toJson()).toList(),
      'subtotal': cart.taxableSubtotal,
      'shipping': cart.shippingCost,
      'tax': cart.gstAmount,
      'discount': 0.0,
      'couponCode': null,
      'total': cart.grandTotal,
      'paymentMethod': _paymentMethod == 'COD' ? 'Cash on Delivery' : 'UPI',
      'paymentId': _paymentMethod == 'ONLINE' ? _transactionIdController.text.trim() : null,
      'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    };

    final response = await ApiService.createOrder(orderData, auth.token!);

    if (mounted) {
      setState(() {
        _isCreatingOrder = false;
      });

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        cart.clearCart();
        setState(() {
          _currentStep = 3; // Success screen
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['body']['error'] ?? 'Error placing order'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);

    // If order placed successfully, show success screen
    if (_currentStep == 3) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 100,
                ),
                const SizedBox(height: 24),
                Text(
                  'Order Placed Successfully!',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your order has been recorded. Our pharmacist will verify details and package your items shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text('CONTINUE SHOPPING'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                    );
                  },
                  child: const Text('VIEW ORDER HISTORY'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 1 ? 'Select Delivery Address' : 'Payment & Review'),
      ),
      body: Column(
        children: [
          // Checkout Progress Bar Indicator
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _currentStep >= 1 ? theme.colorScheme.primary : Colors.grey.shade300,
                  child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
                Expanded(child: Divider(color: _currentStep >= 2 ? theme.colorScheme.primary : Colors.grey.shade300)),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _currentStep >= 2 ? theme.colorScheme.primary : Colors.grey.shade300,
                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
                Expanded(child: Divider(color: Colors.grey.shade300)),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade300,
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _currentStep == 1
                    ? _buildAddressStep()
                    : _buildPaymentReviewStep(cart, theme),
              ),
            ),
          ),
          
          // Next / Place Order Fixed Footer Button
          if (_currentStep < 3)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_currentStep == 2) ...[
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStep = 1;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(100, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('BACK'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _isCreatingOrder
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _currentStep == 1
                                  ? (_selectedAddress == null
                                      ? null
                                      : () {
                                          setState(() {
                                            _currentStep = 2;
                                          });
                                        })
                                  : (_settings?['mobileApp']?['allowOrders'] == false ? null : _placeOrder),
                              child: Text(
                                _settings?['mobileApp']?['allowOrders'] == false
                                    ? 'ORDERING DISABLED'
                                    : (_currentStep == 1 ? 'CONTINUE TO PAYMENT' : 'PLACE ORDER (₹${cart.grandTotal.toStringAsFixed(2)})'),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    if (_isLoadingAddresses) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Delivery Address',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New'),
              onPressed: _showAddAddressDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        if (_addresses.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No addresses found. Please add a new delivery address.'),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addresses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final addr = _addresses[index];
              final isSelected = _selectedAddress != null && _selectedAddress!['id'] == addr['id'];
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedAddress = addr;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF00804A).withOpacity(0.04) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF00804A) : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? const Color(0xFF00804A) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              addr['name'] ?? 'Recipient',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${addr['addressLine1']}, ${addr['city']}, ${addr['state']} - ${addr['pincode']}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${addr['phone']}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPaymentReviewStep(CartProvider cart, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Method Box
        const Text(
          'Select Payment Method',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // COD Radio Option
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _paymentMethod == 'COD' ? theme.colorScheme.primary : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: _paymentMethod == 'COD' ? theme.colorScheme.primary.withOpacity(0.04) : Colors.transparent,
          ),
          child: RadioListTile<String>(
            value: 'COD',
            groupValue: _paymentMethod,
            title: const Text('Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Pay when you receive the medicine shipment'),
            activeColor: theme.colorScheme.primary,
            onChanged: (val) {
              setState(() {
                _paymentMethod = val!;
              });
            },
          ),
        ),
        const SizedBox(height: 12),

        // Online Radio Option (Mocked or instructions detailed)
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _paymentMethod == 'ONLINE' ? theme.colorScheme.primary : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: _paymentMethod == 'ONLINE' ? theme.colorScheme.primary.withOpacity(0.04) : Colors.transparent,
          ),
          child: RadioListTile<String>(
            value: 'ONLINE',
            groupValue: _paymentMethod,
            title: const Text('Pay Online (UPI, Cards)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Make online payment securely'),
            activeColor: theme.colorScheme.primary,
            onChanged: (val) {
              setState(() {
                _paymentMethod = val!;
              });
            },
          ),
        ),
        if (_paymentMethod == 'ONLINE') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Scan to Pay using UPI',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF00804A)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Amount: ₹${cart.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // QR Code Image
                Center(
                  child: Builder(
                    builder: (context) {
                      final upiId = _settings?['payments']?['upiId'] ?? 'Q66193336@ybl';
                      final upiName = _settings?['store']?['name'] ?? 'Pills More';
                      final amount = cart.grandTotal.toStringAsFixed(2);
                      final upiUrl = 'upi://pay?pa=${Uri.encodeComponent(upiId)}&pn=${Uri.encodeComponent(upiName)}&am=$amount&cu=INR';
                      final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(upiUrl)}';
                      
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: Image.network(
                          qrUrl,
                          height: 180,
                          width: 180,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.qr_code_2_rounded, size: 80, color: Colors.grey),
                              Text('Failed to load QR code. Please check internet.', style: TextStyle(fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    }
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan the QR code with any UPI app (GPay, PhonePe, Paytm, etc.) to complete your payment, and then enter the 12-digit transaction UTR reference ID below.',
                  style: TextStyle(fontSize: 11, color: Colors.black54, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Transaction ID Input
                TextFormField(
                  controller: _transactionIdController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: 'UPI UTR / Transaction ID (12 digits)',
                    hintText: 'Enter 12-digit reference ID',
                    prefixIcon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF00804A)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    counterText: '',
                  ),
                  maxLength: 12,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Preferred Delivery Notes / Comments
        const Text(
          'Preferred Delivery Notes',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            hintText: 'e.g. Please call before delivery, leave with neighbor...',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 24),

        // Summary Header
        const Text(
          'Order Summary',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Summary details box
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Items total (${cart.itemCount} items)', style: const TextStyle(color: Colors.grey)),
                    Text('₹${cart.taxableSubtotal.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GST Tax Estimate', style: TextStyle(color: Colors.grey)),
                    Text('₹${cart.gstAmount.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Shipping Cost', style: TextStyle(color: Colors.grey)),
                    Text(cart.shippingCost == 0 ? 'FREE' : '₹${cart.shippingCost.toStringAsFixed(2)}'),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '₹${cart.grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Selected Address Display
        if (_selectedAddress != null) ...[
          const Text(
            'Deliver To:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            '${_selectedAddress!['name']} - ${_selectedAddress!['addressLine1']}, ${_selectedAddress!['city']} (${_selectedAddress!['pincode']})',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

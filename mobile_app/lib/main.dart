import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const KreysetuApp());
}

class KreysetuApp extends StatelessWidget {
  const KreysetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kreysetu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

// ---------------- LOGIN SCREEN ----------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String message = '';
  bool isLoading = false;

  final String baseUrl = "http://127.0.0.1:5000/api";

  Future<void> loginUser() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = data['user'];
        if (mounted) {
          if (user['role'] == 'seller') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SellerDashboard(user: user),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(user: user),
              ),
            );
          }
        }
      } else {
        setState(() {
          message = data['error'] ?? 'Login failed';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error: Could not connect to server';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Kreysetu',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bridging Buyers & Sellers',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login'),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                child: const Text("Don't have an account? Sign up"),
              ),
              const SizedBox(height: 16),
              if (message.isNotEmpty)
                Text(
                  message,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- SIGNUP SCREEN ----------------
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String selectedRole = 'buyer';
  String message = '';
  bool isLoading = false;

  final String baseUrl = "http://127.0.0.1:5000/api";

  Future<void> registerUser() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'password': passwordController.text,
          'role': selectedRole,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() {
          message = 'Account created! You can now login.';
        });
      } else {
        setState(() {
          message = data['error'] ?? 'Registration failed';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error: Could not connect to server';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'I am a:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Buyer'),
                      value: 'buyer',
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Seller'),
                      value: 'seller',
                      groupValue: selectedRole,
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: isLoading ? null : registerUser,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up'),
                ),
              ),
              const SizedBox(height: 16),
              if (message.isNotEmpty)
                Text(
                  message,
                  style: TextStyle(
                    color: message.contains('created')
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- HOME SCREEN (BUYER - PRODUCTS LIST) ----------------
class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String baseUrl = "http://127.0.0.1:5000/api";
  List products = [];
  bool isLoading = true;
  String errorMessage = '';

  // Cart: {product_id: {product: {...}, quantity: n}}
  Map<int, Map<String, dynamic>> cart = {};

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(Uri.parse('$baseUrl/products/'));

      if (response.statusCode == 200) {
        setState(() {
          products = jsonDecode(response.body);
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load products';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: Could not connect to server';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void addToCart(Map product) {
    final id = product['id'];
    setState(() {
      if (cart.containsKey(id)) {
        cart[id]!['quantity'] += 1;
      } else {
        cart[id] = {'product': product, 'quantity': 1};
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} added to cart')),
    );
  }

  int get cartItemCount =>
      cart.values.fold(0, (sum, item) => sum + (item['quantity'] as int));

  void openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(
          cart: cart,
          buyerId: widget.user['id'],
          onOrderPlaced: () {
            setState(() {
              cart.clear();
            });
            fetchProducts();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kreysetu'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: openCart,
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchProducts,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : products.isEmpty
                    ? const Center(child: Text('No products available yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final inStock = (product['stock'] ?? 0) > 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: const Icon(
                                Icons.shopping_bag,
                                size: 40,
                                color: Colors.deepPurple,
                              ),
                              title: Text(
                                product['name'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${product['description'] ?? ''}\nStock: ${product['stock']}',
                              ),
                              trailing: Column(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
                                  Text(
                                    '₹${product['price']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 32,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                      ),
                                      onPressed: inStock
                                          ? () => addToCart(product)
                                          : null,
                                      child: Text(
                                        inStock ? 'Add' : 'Out of Stock',
                                        style: const TextStyle(fontSize: 12),
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
    );
  }
}

// ---------------- CART SCREEN ----------------
class CartScreen extends StatefulWidget {
  final Map<int, Map<String, dynamic>> cart;
  final int buyerId;
  final VoidCallback onOrderPlaced;

  const CartScreen({
    super.key,
    required this.cart,
    required this.buyerId,
    required this.onOrderPlaced,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final addressController = TextEditingController();
  bool isPlacingOrder = false;
  String message = '';

  final String baseUrl = "http://127.0.0.1:5000/api";

  double get total {
    double sum = 0;
    widget.cart.forEach((id, item) {
      sum += (item['product']['price'] as num) * (item['quantity'] as int);
    });
    return sum;
  }

  void increaseQty(int id) {
    setState(() {
      widget.cart[id]!['quantity'] += 1;
    });
  }

  void decreaseQty(int id) {
    setState(() {
      if (widget.cart[id]!['quantity'] > 1) {
        widget.cart[id]!['quantity'] -= 1;
      } else {
        widget.cart.remove(id);
      }
    });
  }

  Future<void> placeOrder() async {
    if (widget.cart.isEmpty) return;
    if (addressController.text.trim().isEmpty) {
      setState(() {
        message = 'Please enter a delivery address';
      });
      return;
    }

    setState(() {
      isPlacingOrder = true;
      message = '';
    });

    try {
      final items = widget.cart.values
          .map((item) => {
                'product_id': item['product']['id'],
                'quantity': item['quantity'],
              })
          .toList();

      final response = await http.post(
        Uri.parse('$baseUrl/orders/place'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'buyer_id': widget.buyerId,
          'address': addressController.text.trim(),
          'items': items,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        widget.onOrderPlaced();
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Order Placed!'),
              content: Text(
                  'Your order (#${data['order_id']}) worth ₹${data['total']} has been placed successfully.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // close cart screen
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        setState(() {
          message = data['error'] ?? 'Failed to place order';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error: Could not connect to server';
      });
    }

    setState(() {
      isPlacingOrder = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cart.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: items.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final id = items[index].key;
                      final item = items[index].value;
                      final product = item['product'];
                      final qty = item['quantity'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(product['name'] ?? ''),
                          subtitle: Text('₹${product['price']} each'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => decreaseQty(id),
                              ),
                              Text('$qty'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => increaseQty(id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(
                          labelText: 'Delivery Address',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isPlacingOrder ? null : placeOrder,
                          child: isPlacingOrder
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Place Order'),
                        ),
                      ),
                      if (message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            message,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ---------------- SELLER DASHBOARD ----------------
class SellerDashboard extends StatefulWidget {
  final Map<String, dynamic> user;
  const SellerDashboard({super.key, required this.user});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  final String baseUrl = "http://127.0.0.1:5000/api";
  List allProducts = [];
  List myProducts = [];
  Map<String, dynamic>? earnings;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    setState(() {
      isLoading = true;
    });

    try {
      final sellerId = widget.user['id'];

      final productsRes = await http.get(Uri.parse('$baseUrl/products/'));
      if (productsRes.statusCode == 200) {
        final all = jsonDecode(productsRes.body);
        setState(() {
          allProducts = all;
          myProducts =
              all.where((p) => p['seller_id'] == sellerId).toList();
        });
      }

      final earningsRes = await http.get(
        Uri.parse('$baseUrl/orders/seller/$sellerId/earnings'),
      );
      if (earningsRes.statusCode == 200) {
        setState(() {
          earnings = jsonDecode(earningsRes.body);
        });
      }
    } catch (e) {
      // ignore, keep UI usable
    }

    setState(() {
      isLoading = false;
    });
  }

  void openAddProductForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductScreen(sellerId: widget.user['id']),
      ),
    ).then((_) => loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seller Dashboard — ${widget.user['name']}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddProductForm,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Colors.deepPurple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Earnings',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '₹${earnings?['total_earning'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Total Orders',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                '${earnings?['total_orders'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'My Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (myProducts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('You have not added any products yet.'),
                    )
                  else
                    ...myProducts.map((product) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.inventory_2,
                                color: Colors.deepPurple),
                            title: Text(product['name'] ?? ''),
                            subtitle: Text('Stock: ${product['stock']}'),
                            trailing: Text(
                              '₹${product['price']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

// ---------------- ADD PRODUCT SCREEN ----------------
class AddProductScreen extends StatefulWidget {
  final int sellerId;
  const AddProductScreen({super.key, required this.sellerId});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final nameController = TextEditingController();
  final descController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final categoryController = TextEditingController();
  String message = '';
  bool isLoading = false;

  final String baseUrl = "http://127.0.0.1:5000/api";

  Future<void> addProduct() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'seller_id': widget.sellerId,
          'name': nameController.text.trim(),
          'description': descController.text.trim(),
          'price': double.tryParse(priceController.text) ?? 0,
          'stock': int.tryParse(stockController.text) ?? 0,
          'category': categoryController.text.trim(),
          'image_url': '',
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          message = data['error'] ?? 'Failed to add product';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error: Could not connect to server';
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : addProduct,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Product'),
              ),
            ),
            const SizedBox(height: 16),
            if (message.isNotEmpty)
              Text(message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
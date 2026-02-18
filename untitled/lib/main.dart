import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

/// ---------------------------
/// App + Routes
/// ---------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Inventory',
      theme: ThemeData(useMaterial3: false),
      home: const LoginPage(),
    );
  }
}

/// ---------------------------
/// Models (เบาๆ ไม่ใช้ package เพิ่ม)
/// ---------------------------
double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class Product {
  final String id;
  final String name;
  final int stockCount;
  final String category;
  final String aisle;
  final String imageUrl;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.stockCount,
    required this.category,
    required this.aisle,
    required this.imageUrl,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      stockCount: _toInt(json['stockCount']),
      category: (json['category'] ?? '').toString(),
      aisle: (json['aisle'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      price: _toDouble(json['price']), // << สำคัญ: ต้องมี price ใน JSON
    );
  }
}

class CartItem {
  final Product product;
  int qty;
  CartItem({required this.product, this.qty = 1});

  double get lineTotal => product.price * qty;
}

/// ---------------------------
/// Page 1: Login
/// ---------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameCtrl = TextEditingController();
  final _branchCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _branchCtrl.dispose();
    super.dispose();
  }

  void _go() {
    final name = _nameCtrl.text.trim();
    final branch = _branchCtrl.text.trim();

    if (name.isEmpty || branch.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อผู้ค้นหา และรหัสสาขา')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPage(
          searcherName: name,
          branchCode: branch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('แอปร้านลุงแช่ม'),
        backgroundColor: Colors.pink[300],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อคนที่ค้นหาของ',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _branchCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'รหัสสาขาร้านลุงแช่ม',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _go,
                      icon: const Icon(Icons.login),
                      label: const Text('เข้าร้านลุงแช่ม'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------
/// Page 2: Search + Filters + Product mini detail + Cart
/// ---------------------------
class SearchPage extends StatefulWidget {
  final String searcherName;
  final String branchCode;

  const SearchPage({
    super.key,
    required this.searcherName,
    required this.branchCode,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Product> _products = [];
  List<Product> _filtered = [];

  String _selectedCategory = "ทั้งหมด";
  List<String> _categories = ["ทั้งหมด"];
  String _query = "";

  final Map<String, CartItem> _cart = {}; // key = productId

  int get _cartCount => _cart.values.fold(0, (sum, e) => sum + e.qty);
  double get _cartTotal => _cart.values.fold(0, (sum, e) => sum + e.lineTotal);

  Future<void> _loadJsonData() async {
    final String response = await rootBundle.loadString('assets/data/products.json');
    final dynamic decoded = json.decode(response);

    final List<dynamic> data = decoded is List ? decoded : <dynamic>[];

    final products = data
        .whereType<Map<String, dynamic>>()
        .map((m) => Product.fromJson(m))
        .toList();

    final set = <String>{"ทั้งหมด"};
    for (final p in products) {
      if (p.category.trim().isNotEmpty) set.add(p.category);
    }

    setState(() {
      _products = products;
      _categories = set.toList();
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();

    setState(() {
      _filtered = _products.where((p) {
        final matchesSearch = p.name.toLowerCase().contains(q);
        final matchesCategory = (_selectedCategory == "ทั้งหมด") || (p.category == _selectedCategory);
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadJsonData();
  }

  void _addToCart(Product p) {
    setState(() {
      final existing = _cart[p.id];
      if (existing == null) {
        _cart[p.id] = CartItem(product: p, qty: 1);
      } else {
        existing.qty += 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('ใส่ตะกร้า: ${p.name} (+1)')),
    );
  }

  void _openMiniDetail(Product p) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      p.imageUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag, size: 48, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('ล็อก: ${p.aisle} • หมวด: ${p.category}'),
                        const SizedBox(height: 4),
                        Text('คงเหลือ: ${p.stockCount}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: p.stockCount > 0 ? Colors.green[700] : Colors.red,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('ราคา:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    '${p.price.toStringAsFixed(2)} บาท',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                  ),
                  const Spacer(),
                  Text('ในตะกร้า: ${_cart[p.id]?.qty ?? 0}'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _addToCart(p);
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('ใส่ตะกร้า'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _goSummary() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีสินค้าในตะกร้า')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryPage(
          searcherName: widget.searcherName,
          branchCode: widget.branchCode,
          cart: _cart.values.toList(),
          onFinishReset: () {
            // reset กลับมาหน้า login แบบล้าง stack
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สินค้าร้านลุงแช่ม • ${widget.branchCode}'),
        backgroundColor: Colors.green[700],
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'ตะกร้า',
                  onPressed: _goSummary, // << กดแล้วไปหน้า 3
                  icon: Stack(
                    children: [
                      const Icon(Icons.shopping_cart, size: 26),
                      if (_cartCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_cartCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_cartTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      '${_cartTotal.toStringAsFixed(0)}฿',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ช่องค้นหา
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              onChanged: (val) {
                _query = val;
                _applyFilter();
              },
              decoration: InputDecoration(
                hintText: "ค้นหาสินค้า",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ชิปหมวดหมู่ (ใส่กลับมาเหมือนเดิม)
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: Colors.orange[800],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    onSelected: (_) {
                      setState(() => _selectedCategory = cat);
                      _applyFilter();
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // รายการสินค้า
          Expanded(
            child: _filtered.isEmpty && _products.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final p = _filtered[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    onTap: () => _openMiniDetail(p),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        p.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
                      ),
                    ),
                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("ล็อก: ${p.aisle} | ${p.category} | ${p.price.toStringAsFixed(0)}฿"),
                    trailing: Text(
                      "${p.stockCount}",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: p.stockCount > 0 ? Colors.green[700] : Colors.red,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ปุ่มสรุปยอด
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _goSummary,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('สรุปยอดสินค้า'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------
/// Page 3: Summary + Promotion + Reset
/// ---------------------------
class SummaryPage extends StatelessWidget {
  final String searcherName;
  final String branchCode;
  final List<CartItem> cart;
  final VoidCallback onFinishReset;

  const SummaryPage({
    super.key,
    required this.searcherName,
    required this.branchCode,
    required this.cart,
    required this.onFinishReset,
  });

  double get subtotal => cart.fold(0, (sum, e) => sum + e.lineTotal);

  /// โปรโมชันตัวอย่าง (แก้กติกาตรงนี้ได้เลย)
  /// - ยอดรวม >= 1000 ลด 10%
  /// - ยอดรวม >= 500 ลด 5%
  double get discount {
    final s = subtotal;
    if (s >= 1000) return s * 0.10;
    if (s >= 500) return s * 0.05;
    return 0;
  }

  String get promoText {
    final s = subtotal;
    if (s >= 1000) return 'โปรโมชัน: ลด 10% เมื่อครบ 1,000 บาท';
    if (s >= 500) return 'โปรโมชัน: ลด 5% เมื่อครบ 500 บาท';
    return 'โปรโมชัน: -';
  }

  @override
  Widget build(BuildContext context) {
    final total = subtotal - discount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('สรุปยอดตะกร้า'),
        backgroundColor: Colors.green[700],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              child: ListTile(
                title: Text('ผู้ค้นหา: $searcherName'),
                subtitle: Text('สาขา: $branchCode\n$promoText'),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];
                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    title: Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'ราคา ${item.product.price.toStringAsFixed(2)}฿ • จำนวน ${item.qty}\nล็อก ${item.product.aisle} • ${item.product.category}',
                    ),
                    trailing: Text(
                      '${item.lineTotal.toStringAsFixed(2)}฿',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _sumRow('ยอดรวม', subtotal),
                    _sumRow('ส่วนลด', -discount),
                    const Divider(),
                    _sumRow('ยอดสุทธิ', total, isTotal: true),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onFinishReset,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('เสร็จสิ้นการค้นหาสินค้า (รีเซ็ต)'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumRow(String label, double value, {bool isTotal = false}) {
    final textStyle = TextStyle(
      fontSize: isTotal ? 18 : 16,
      fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
    );

    final v = value >= 0 ? value.toStringAsFixed(2) : '-${value.abs().toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: textStyle),
          const Spacer(),
          Text('$v ฿', style: textStyle),
        ],
      ),
    );
  }
}

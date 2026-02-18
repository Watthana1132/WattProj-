import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MaterialApp(
  home: SmartInventoryApp(),
  debugShowCheckedModeBanner: false,
));

class SmartInventoryApp extends StatefulWidget {
  @override
  _SmartInventoryAppState createState() => _SmartInventoryAppState();
}

class _SmartInventoryAppState extends State<SmartInventoryApp> {
  List _products = [];
  List _filteredProducts = [];
  String _selectedCategory = "ทั้งหมด";
  List<String> _categories = ["ทั้งหมด"];

  Future<void> loadJsonData() async {
    final String response = await rootBundle.loadString('assets/data/products.json');
    final data = await json.decode(response);

    // ดึงรายชื่อหมวดหมู่ที่ไม่ซ้ำกันออกมาทำปุ่ม
    Set<String> categorySet = {"ทั้งหมด"};
    for (var item in data) {
      categorySet.add(item['category']);
    }

    setState(() {
      _products = data;
      _filteredProducts = data;
      _categories = categorySet.toList();
    });
  }

  @override
  void initState() {
    super.initState();
    loadJsonData();
  }

  // ฟังก์ชันกรองสินค้า (รวมทั้ง Search และ Category)
  void _filterLogic(String query, String category) {
    setState(() {
      _filteredProducts = _products.where((item) {
        bool matchesSearch = item['name'].toString().toLowerCase().contains(query.toLowerCase());
        bool matchesCategory = (category == "ทั้งหมด") || (item['category'] == category);
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('สินค้าร้านลุงแช่ม'),
        backgroundColor: Colors.green[700], // เปลี่ยนเป็นสีเขียวเซเว่น
      ),
      body: Column(
        children: [
          // 1. ช่องค้นหา
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: (val) => _filterLogic(val, _selectedCategory),
              decoration: InputDecoration(
                hintText: "ค้นหาสินค้า",
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),

          // 2. แถบเลือกหมวดหมู่ (Category Chips)
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              padding: EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                bool isSelected = _selectedCategory == _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(_categories[index]),
                    selected: isSelected,
                    selectedColor: Colors.orange[800],
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = _categories[index];
                      });
                      _filterLogic("", _selectedCategory);
                    },
                  ),
                );
              },
            ),
          ),

          // 3. รายการสินค้า
          Expanded(
            child: _filteredProducts.isEmpty && _products.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                var item = _filteredProducts[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        item['imageUrl'] ?? '',
                        width: 50, height: 50, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.shopping_bag, size: 40, color: Colors.grey),
                      ),
                    ),
                    title: Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("ล็อก: ${item['aisle']} | ${item['category']}"),
                    trailing: Text(
                      "${item['stockCount']}",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: item['stockCount'] > 0 ? Colors.green[700] : Colors.red
                      ),
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
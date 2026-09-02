import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_page.dart';

void main() {
  runApp(const AfghanExchangeApp());
}

class AfghanExchangeApp extends StatelessWidget {
  const AfghanExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'افغان نرخ',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadRates();
  }

  Future<void> loadRates() async {
    try {
      final String response = await rootBundle.loadString('assets/rates.json');
      setState(() {
        data = json.decode(response);
      });
    } catch (e) {
      debugPrint('Error loading rates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onLongPress: () {
              // با لمس طولانی عنوان برنامه، صفحه ورود مدیر باز می‌شود
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginPage()),
              );
            },
            child: const Text('افغان نرخ (سرای شهزاده)'),
          ),
          centerTitle: true,
          backgroundColor: Colors.green[800],
          actions: [
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'ورود مدیر',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminLoginPage()),
                );
              },
            ),
          ],
        ),
        body: data == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // کارت بنر تبلیغاتی ویژه مدیر
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber[700]!, Colors.orange[800]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.campaign, color: Colors.white, size: 36),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'مکان تبلیغات شما',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'برای سفارش تبلیغ و دیده شدن توسط هزاران کاربر، با ما تماس بگیرید.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // زمان بروزرسانی
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.green[50],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'آخرین بروزرسانی: ${data!['last_updated']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),

                  // لیست نرخ‌ها
                  Expanded(
                    child: ListView.builder(
                      itemCount: data!['rates'].length,
                      itemBuilder: (context, index) {
                        final rate = data!['rates'][index];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child: const Icon(Icons.attach_money, color: Colors.green),
                            ),
                            title: Text(rate['currency'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(rate['unit'], style: const TextStyle(fontSize: 12)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('خرید: ${rate['buy']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                Text('فروش: ${rate['sell']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

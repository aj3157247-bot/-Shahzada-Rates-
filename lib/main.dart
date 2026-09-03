import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase error: $e');
  }
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
  Map<String, dynamic> fullData = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadRatesSafely();
  }

  Future<void> loadRatesSafely() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/rates.json');
      if (jsonString.isNotEmpty) {
        setState(() {
          fullData = json.decode(jsonString);
        });
      }
    } catch (e) {
      debugPrint('Asset load error: $e');
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  void _shareApp() {
    Share.share(
      'برنامه «افغان نرخ» را نصب کنید و از آخرین نرخ‌های لحظه‌ای ارز و طلا مطلع شوید!',
    );
  }

  @override
  Widget build(BuildContext context) {
    String lastUpdated = fullData['last_updated']?.toString() ?? 'نامشخص';
    List ratesList = fullData['rates'] is List ? fullData['rates'] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('افغان نرخ'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareApp,
            tooltip: 'اشتراک‌گذاری برنامه',
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // بخش نمایش تاریخ بروزرسانی
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.update, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'آخرین بروزرسانی: $lastUpdated',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: ratesList.isEmpty
                ? const Center(child: Text('نرخی موجود نیست'))
                : ListView.builder(
                    itemCount: ratesList.length,
                    itemBuilder: (context, index) {
                      var item = ratesList[index];
                      String currencyName = item['currency']?.toString() ?? '';
                      String buyPrice = item['buy']?.toString() ?? '';
                      String sellPrice = item['sell']?.toString() ?? '';
                      String unit = item['unit']?.toString() ?? '';

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.currency_exchange, color: Colors.green),
                          title: Text(
                            currencyName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text('واحد: $unit'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('خرید: $buyPrice', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              Text('فروش: $sellPrice', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          GestureDetector(
            onTap: () => _launchExternalUrl('https://t.me/your_channel'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.green[100],
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'تبلیغات: برای ارتباط با ما کلیک کنید (تلگرام / واتساپ)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات ادمین'),
        backgroundColor: Colors.green[800],
      ),
      body: const Center(
        child: Text(
          'بخش مدیریت نرخ‌ها',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

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
    // موقتاً برای تست، اگر فایربیس خطا داد رد شود
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
  Map<String, dynamic> rates = {
    'دالر آمریکایی': '70.50',
    'کلدار پاکستانی': '25.20',
    'یورو': '76.00',
    'تومان ایران': '0.0011',
    'طلای یک عیار (گرام)': '4500'
  };
  bool isLoading = false;
  String errorMessage = '';

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
          rates = json.decode(jsonString);
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
          Expanded(
            child: rates.isEmpty
                ? const Center(child: Text('نرخی موجود نیست'))
                : ListView.builder(
                    itemCount: rates.keys.length,
                    itemBuilder: (context, index) {
                      String key = rates.keys.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.currency_exchange, color: Colors.green),
                        title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: Text(rates[key].toString(), style: const TextStyle(fontSize: 16, color: Colors.black87)),
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

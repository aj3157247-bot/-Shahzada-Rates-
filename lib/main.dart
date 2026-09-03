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
    await Firebase.initializeApp(); // فعال‌سازی فایربیس برای آمارگیری تعداد کاربران
  } catch (e) {
    debugPrint('Firebase error: $e');
  }
  runApp(const AfghanExchangeApp());
}

class AfghanExchangeApp extends StatelessWidget {
  const AfghanExchangeApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'افغان نرخ',
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
      ),
      navigatorObservers: [observer],
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

  @override
  void initState() {
    super.initState();
    loadRates();
  }

  Future<void> loadRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedJson = prefs.getString('saved_rates_data');

      if (savedJson != null && savedJson.isNotEmpty) {
        setState(() {
          fullData = json.decode(savedJson);
        });
        return;
      }

      final String jsonString = await rootBundle.loadString('assets/rates.json');
      if (jsonString.isNotEmpty) {
        setState(() {
          fullData = json.decode(jsonString);
        });
      }
    } catch (e) {
      debugPrint('Load rates error: $e');
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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminPage()),
              );
              loadRates();
            },
          ),
        ],
      ),
      body: Column(
        children: [
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
          // بخش تبلیغات و راه‌های ارتباطی در پایین صفحه
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

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  List ratesList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? savedJson = prefs.getString('saved_rates_data');

      String jsonString;
      if (savedJson != null && savedJson.isNotEmpty) {
        jsonString = savedJson;
      } else {
        jsonString = await rootBundle.loadString('assets/rates.json');
      }

      var decoded = json.decode(jsonString);
      setState(() {
        ratesList = decoded['rates'] is List ? List.from(decoded['rates']) : [];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      Map<String, dynamic> data = {
        'last_updated': DateTime.now().toString().substring(0, 19),
        'rates': ratesList,
      };
      await prefs.setString('saved_rates_data', json.encode(data));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('نرخ‌ها با موفقیت ذخیره شدند')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره اطلاعات: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تنظیمات ادمین - مدیریت نرخ‌ها'),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveChanges,
            tooltip: 'ذخیره تغییرات',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: ratesList.length,
              itemBuilder: (context, index) {
                var item = ratesList[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['currency'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(labelText: 'نرخ خرید'),
                                controller: TextEditingController(text: item['buy']?.toString() ?? ''),
                                onChanged: (value) {
                                  ratesList[index]['buy'] = value;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(labelText: 'نرخ فروش'),
                                controller: TextEditingController(text: item['sell']?.toString() ?? ''),
                                onChanged: (value) {
                                  ratesList[index]['sell'] = value;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

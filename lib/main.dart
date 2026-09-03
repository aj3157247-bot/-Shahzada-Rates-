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
    await Firebase.initializeApp(); // فعال‌سازی فایربیس برای آمارگیری کاربران
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
  bool isLoading = true;
  String adText = 'تبلیغات: برای ارتباط با ما کلیک کنید (تلگرام / واتساپ)';
  String adLink = 'https://t.me/your_channel';

  @override
  void initState() {
    super.initState();
    loadAppData();
  }

  Future<void> loadAppData() async {
    setState(() => isLoading = true);
    
    // بارگذاری تنظیمات تبلیغات از حافظه محلی
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adText = prefs.getString('ad_text') ?? 'تبلیغات: برای ارتباط با ما کلیک کنید (تلگرام / واتساپ)';
      adLink = prefs.getString('ad_link') ?? 'https://t.me/your_channel';
    });

    // تلاش برای دریافت خودکار نرخ‌ها از اینترنت با فال‌بک به فایل محلی
    try {
      final response = await http
          .get(Uri.parse('https://raw.githubusercontent.com/shahzada-rates/app/main/assets/rates.json'))
          .timeout(const Duration(seconds: 6));
      
      if (response.statusCode == 200) {
        final onlineData = json.decode(response.body);
        setState(() {
          fullData = onlineData;
          isLoading = false;
        });
        // ذخیره نسخه آنلاین در حافظه برای دسترسی آفلاین بعدی
        prefs.setString('cached_rates_json', response.body);
        return;
      }
    } catch (_) {
      // خطا در اتصال اینترنت، استفاده از کش یا فایل محلی
    }

    try {
      String? cachedJson = prefs.getString('cached_rates_json');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        setState(() {
          fullData = json.decode(cachedJson);
          isLoading = false;
        });
        return;
      }

      final String jsonString = await rootBundle.loadString('assets/rates.json');
      setState(() {
        fullData = json.decode(jsonString);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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
      'برنامه «افغان نرخ» را نصب کنید و از آخرین نرخ‌های لحظه‌ای ارز، طلا و نقره مطلع شوید!\nلینک دانلود: https://github.com/shahzada-rates/app',
    );
  }

  @override
  Widget build(BuildContext context) {
    String lastUpdated = fullData['last_updated']?.toString() ?? 'بروز رسانی خودکار';
    List ratesList = fullData['rates'] is List ? fullData['rates'] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('افغان نرخ'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadAppData,
            tooltip: 'بروزرسانی نرخ‌ها',
          ),
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
                MaterialPageRoute(builder: (context) => const AdminLoginPage()),
              );
              loadAppData(); // بازخوانی تبلیغات پس از بازگشت از پنل ادمین
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
                  'آخرین بروزرسانی اینترنتی: $lastUpdated',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ratesList.isEmpty
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
            onTap: () => _launchExternalUrl(adLink),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.green[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.campaign, color: Colors.green),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      adText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
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
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String errorMessage = '';

  void _login() {
    String adminEmail = 'abdullahjafari712@gmail.com';
    String adminPass = '05050505';

    if (_emailController.text.trim() == adminEmail &&
        _passwordController.text.trim() == adminPass) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminDashboardPage()),
      );
    } else {
      setState(() {
        errorMessage = 'ایمیل یا رمز عبور اشتباه است';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ورود به پنل مدیریت'),
        backgroundColor: Colors.green[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'ایمیل ادمین',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'رمز عبور',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _login,
              child: const Text('ورود', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// داشبورد حرفه‌ای ادمین: مدیریت تبلیغات و آمار کاربران
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final TextEditingController _adTextController = TextEditingController();
  final TextEditingController _adLinkController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAdminSettings();
  }

  Future<void> loadAdminSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adTextController.text = prefs.getString('ad_text') ?? 'تبلیغات: برای ارتباط با ما کلیک کنید (تلگرام / واتساپ)';
      _adLinkController.text = prefs.getString('ad_link') ?? 'https://t.me/your_channel';
      isLoading = false;
    });
  }

  Future<void> saveAdSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ad_text', _adTextController.text.trim());
    await prefs.setString('ad_link', _adLinkController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تنظیمات تبلیغات با موفقیت ذخیره شد')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل مدیریت حرفه‌ای'),
        backgroundColor: Colors.green[800],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // بخش آمار کاربران و بازدید اپلیکیشن
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          children: [
                            Icon(Icons.analytics, color: Colors.green, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'آمار و تحلیل کاربران (Firebase Analytics)',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Divider(height: 20),
                        Text(
                          'وضعیت رصد کاربران: فعال و آنلاین',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'برای مشاهده دقیق تعداد کاربران فعال لحظه‌ای، میزان نصب و آمار جغرافیایی، لطفاً به کنسول رسمی فایربیس (Firebase Console) مراجعه کنید.',
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // بخش مدیریت حرفه‌ای تبلیغات
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.campaign, color: Colors.green, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'مدیریت حرفه‌ای بنر تبلیغاتی',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        TextField(
                          controller: _adTextController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'متن تبلیغاتی بنر پایین صفحه',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _adLinkController,
                          decoration: const InputDecoration(
                            labelText: 'لینک مقصد (تلگرام، واتساپ یا وب‌سایت)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.link),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.styleFrom != null
                            ? ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: saveAdSettings,
                                child: const Text('ذخیره و اعمال آنی تبلیغ', style: TextStyle(fontSize: 16, color: Colors.white)),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

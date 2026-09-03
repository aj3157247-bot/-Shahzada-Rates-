import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final prefs = await SharedPreferences.getInstance();
    int openCount = prefs.getInt('app_open_count') ?? 0;
    await prefs.setInt('app_open_count', openCount + 1);
  } catch (_) {}

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
  List<Map<String, dynamic>> activeAds = [];
  bool isLoading = true;
  final PageController _adPageController = PageController();
  Timer? _adTimer;
  int _currentAdIndex = 0;

  @override
  void initState() {
    super.initState();
    loadAppData();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _adPageController.dispose();
    super.dispose();
  }

  Future<void> loadAppData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    // ۱. بارگذاری تبلیغات فعال از پنل ادمین
    String? adsJson = prefs.getString('ads_list_json');
    List<Map<String, dynamic>> loadedAds = [];
    if (adsJson != null && adsJson.isNotEmpty) {
      List decodedAds = json.decode(adsJson);
      for (var ad in decodedAds) {
        if (ad['active'] == true) {
          loadedAds.add({'text': ad['text'] ?? '', 'link': ad['link'] ?? ''});
        }
      }
    } else {
      loadedAds.add({'text': 'تبلیغات صرافی و خدمات ارزی', 'link': 'https://t.me/your_channel'});
    }

    setState(() {
      activeAds = loadedAds;
    });

    int adDurationSeconds = prefs.getInt('ad_duration_seconds') ?? 4;

    _adTimer?.cancel();
    if (activeAds.length > 1) {
      _adTimer = Timer.periodic(Duration(seconds: adDurationSeconds), (timer) {
        if (_adPageController.hasClients) {
          _currentAdIndex = (_currentAdIndex + 1) % activeAds.length;
          _adPageController.animateToPage(
            _currentAdIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }

    String currentFormattedTime = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";

    final Map<String, dynamic> defaultComprehensiveData = {
      "last_updated": currentFormattedTime,
      "rates": [
        {"currency": "USD (دلار آمریکا)", "buy": "67.20", "sell": "67.30", "unit": "AFN"},
        {"currency": "EUR (یورو)", "buy": "72.40", "sell": "72.60", "unit": "AFN"},
        {"currency": "GBP (پوند انگلیس)", "buy": "85.50", "sell": "85.80", "unit": "AFN"},
        {"currency": "TRY (لیر ترکیه)", "buy": "1.95", "sell": "2.00", "unit": "AFN"},
        {"currency": "PKR (روپیه پاکستان - ۱۰۰۰ کلدار)", "buy": "241.00", "sell": "242.00", "unit": "AFN"},
        {"currency": "IRR (تومان ایران - ۱۰۰۰ تومان)", "buy": "1.10", "sell": "1.15", "unit": "AFN"},
        {"currency": "AED (درهم امارات)", "buy": "18.30", "sell": "18.40", "unit": "AFN"},
        {"currency": "SAR (ریال عربستان)", "buy": "17.90", "sell": "18.00", "unit": "AFN"},
        {"currency": "طلا (یک گرم عیار ۷۵۰)", "buy": "5200", "sell": "5300", "unit": "AFN"},
        {"currency": "طلا (یک مثقال عیار ۷۵۰)", "buy": "24100", "sell": "24400", "unit": "AFN"}
      ]
    };

    // ۲. دریافت نرخ‌ها به صورت آنلاین از گیت‌هاب
    try {
      final response = await http
          .get(Uri.parse('https://raw.githubusercontent.com/shahzada-rates/app/main/assets/rates.json'))
          .timeout(const Duration(seconds: 6));
      
      if (response.statusCode == 200) {
        final onlineData = json.decode(response.body);
        onlineData['last_updated'] = currentFormattedTime;
        
        setState(() {
          fullData = onlineData;
          isLoading = false;
        });
        prefs.setString('cached_rates_json', json.encode(onlineData));
        return;
      }
    } catch (_) {}

    try {
      String? cachedJson = prefs.getString('cached_rates_json');
      if (cachedJson != null && cachedJson.isNotEmpty) {
        Map<String, dynamic> cachedData = json.decode(cachedJson);
        cachedData['last_updated'] = currentFormattedTime;
        setState(() {
          fullData = cachedData;
          isLoading = false;
        });
        return;
      }

      setState(() {
        fullData = defaultComprehensiveData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        fullData = defaultComprehensiveData;
        isLoading = false;
      });
    }
  }

  Future<void> _launchExternalUrl(String urlString) async {
    final targetUrl = urlString.trim().isEmpty ? 'https://t.me/your_channel' : urlString;
    final Uri url = Uri.parse(targetUrl);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // اصلاح بخش اشتراک‌گذاری برای ارسال متن همراه با لینک دانلود برنامه
  void _shareApp() {
    Share.share(
      'برنامه حرفه‌ای «افغان نرخ» را نصب کنید و از دقیق‌ترین نرخ‌های لحظه‌ای ارز، طلا و نقره مطلع شوید!\n\nلینک دانلود برنامه:\nhttps://github.com/shahzada-rates/app'
    );
  }

  @override
  Widget build(BuildContext context) {
    String lastUpdated = fullData['last_updated']?.toString() ?? '';
    List ratesList = fullData['rates'] is List ? fullData['rates'] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('افغان نرخ'),
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadAppData,
            tooltip: 'بروزرسانی',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareApp,
            tooltip: 'اشتراک‌گذاری',
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminLoginPage()),
              );
              loadAppData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.update, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    'آخرین بروزرسانی: $lastUpdated',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: loadAppData,
                    child: ratesList.isEmpty
                        ? const Center(child: Text('نرخی موجود نیست'))
                        : ListView.builder(
                            itemCount: ratesList.length,
                            itemBuilder: (context, index) {
                              var item = ratesList[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                elevation: 2,
                                child: ListTile(
                                  leading: const Icon(Icons.currency_exchange, color: Colors.green),
                                  title: Text(
                                    item['currency']?.toString() ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  subtitle: Text('واحد: ${item['unit'] ?? ''}'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('خرید: ${item['buy'] ?? ''}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      Text('فروش: ${item['sell'] ?? ''}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
          if (activeAds.isNotEmpty)
            Container(
              height: 55,
              width: double.infinity,
              color: Colors.green[100],
              child: PageView.builder(
                controller: _adPageController,
                itemCount: activeAds.length,
                itemBuilder: (context, index) {
                  var ad = activeAds[index];
                  return GestureDetector(
                    onTap: () => _launchExternalUrl(ad['link']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.campaign, color: Colors.green, size: 22),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              ad['text'],
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
    if (_emailController.text.trim() == 'abdullahjafari712@gmail.com' &&
        _passwordController.text.trim() == '05050505') {
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
      appBar: AppBar(title: const Text('ورود به پنل مدیریت'), backgroundColor: Colors.green[800]),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'ایمیل ادمین', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'رمز عبور', border: OutlineInputBorder())),
            const SizedBox(height: 20),
            if (errorMessage.isNotEmpty) Text(errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], minimumSize: const Size.fromHeight(50)),
              onPressed: _login,
              child: const Text('ورود', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int totalAppOpens = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> adsList = [];
  final TextEditingController _durationController = TextEditingController(text: '4');

  @override
  void initState() {
    super.initState();
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    totalAppOpens = prefs.getInt('app_open_count') ?? 1;
    int duration = prefs.getInt('ad_duration_seconds') ?? 4;
    _durationController.text = duration.toString();

    String? adsJson = prefs.getString('ads_list_json');
    if (adsJson != null && adsJson.isNotEmpty) {
      List decoded = json.decode(adsJson);
      adsList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      adsList = [
        {'text': 'تبلیغ اول صرافی', 'link': 'https://t.me/your_channel', 'active': true}
      ];
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveAllSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('ads_list_json', json.encode(adsList));
    int duration = int.tryParse(_durationController.text.trim()) ?? 4;
    await prefs.setInt('ad_duration_seconds', duration);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تنظیمات تبلیغات با موفقیت ذخیره شد')),
    );
    Navigator.pop(context);
  }

  void _addNewAd() {
    setState(() {
      adsList.add({'text': 'تبلیغ جدید', 'link': 'https://t.me/your_channel', 'active': true});
    });
  }

  void _removeAd(int index) {
    setState(() {
      adsList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پنل مدیریت تبلیغات و آمار'),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveAllSettings,
            tooltip: 'ذخیره تغییرات',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('آمار برنامه', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                        const Divider(),
                        Text('تعداد دفعات باز شدن برنامه توسط کاربران: $totalAppOpens بار', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('سیستم تبلیغات نامحدود', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                              onPressed: _addNewAd,
                              icon: const Icon(Icons.add, size: 18, color: Colors.white),
                              label: const Text('افزودن تبلیغ جدید', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        const Divider(),
                        TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'زمان تغییر تبلیغات در اسلایدر (به ثانیه)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...List.generate(adsList.length, (index) {
                          var ad = adsList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('بنر تبلیغاتی شماره ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Row(
                                      children: [
                                        Switch(
                                          value: ad['active'] ?? true,
                                          activeColor: Colors.green,
                                          onChanged: (val) {
                                            setState(() {
                                              ad['active'] = val;
                                            });
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeAd(index),
                                          tooltip: 'حذف این تبلیغ',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                TextField(
                                  controller: TextEditingController(text: ad['text']),
                                  onChanged: (val) => ad['text'] = val,
                                  decoration: const InputDecoration(labelText: 'متن تبلیغ', border: OutlineInputBorder(), isDense: true),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: TextEditingController(text: ad['link']),
                                  onChanged: (val) => ad['link'] = val,
                                  decoration: const InputDecoration(labelText: 'لینک مقصد (تلگرام/واتساپ)', border: OutlineInputBorder(), isDense: true),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: saveAllSettings,
                  child: const Text('ذخیره تغییرات', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
    );
  }
}

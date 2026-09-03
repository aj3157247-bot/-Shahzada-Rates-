import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
    
    // ۱. بارگذاری تبلیغات فعال (فقط آنهایی که فعال هستند)
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
      // پیش‌فرض اگر تبلیغی نبود
      loadedAds.add({'text': 'تبلیغات صرافی و خدمات ارزی', 'link': 'https://t.me/your_channel'});
    }

    setState(() {
      activeAds = loadedAds;
    });

    // خواندن سرعت چرخش اسلایدر از تنظیمات ادمین (پیش‌فرض ۴ ثانیه)
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

    // ۲. بارگذاری نرخ‌ها (اولویت با نرخ‌های ثبت‌شده توسط ادمین برای تطابق ۱۰۰٪ با بانک مرکزی)
    try {
      String? savedRates = prefs.getString('custom_rates_json');
      if (savedRates != null && savedRates.isNotEmpty) {
        setState(() {
          fullData = json.decode(savedRates);
          isLoading = false;
        });
        return;
      }

      // در غیر این صورت فایل پیش‌فرض
      final String jsonString = await rootBundle.loadString('assets/rates.json');
      setState(() {
        fullData = json.decode(jsonString);
        isLoading = false;
      });
    } catch (e) {
      // داده پیش‌فرض استاندارد در صورت بروز خطا
      setState(() {
        fullData = {
          "last_updated": "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day} ${DateTime.now().hour}:${DateTime.now().minute}",
          "rates": [
            {"currency": "USD (دلار)", "buy": "64.53", "sell": "64.73", "unit": "AFN"},
            {"currency": "EUR (یورو)", "buy": "73.50", "sell": "74.10", "unit": "AFN"},
          ]
        };
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

  void _shareApp() {
    Share.share('برنامه حرفه‌ای «افغان نرخ» را نصب کنید و از دقیق‌ترین نرخ‌های لحظه‌ای ارز، طلا و نقره مطلع شوید!');
  }

  @override
  Widget build(BuildContext context) {
    String lastUpdated = fullData['last_updated']?.toString() ?? 'بروز';
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

// پنل مدیریت پیشرفته با قابلیت ادیت نرخ‌ها، تبلیغات نامحدود با دکمه حذف، و تعیین زمان چرخش
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int totalAppOpens = 0;
  bool isLoading = true;

  // لیست پویا برای تبلیغات نامحدود
  List<Map<String, dynamic>> adsList = [];
  
  // کنترل‌کننده زمان چرخش اسلایدر
  final TextEditingController _durationController = TextEditingController(text: '4');

  // لیست نرخ‌ها برای ویرایش آنی جهت تطابق با بانک مرکزی
  List<Map<String, dynamic>> ratesList = [];

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

    // بارگذاری تبلیغات ذخیره‌شده
    String? adsJson = prefs.getString('ads_list_json');
    if (adsJson != null && adsJson.isNotEmpty) {
      List decoded = json.decode(adsJson);
      adsList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      // پیش‌فرض یک تبلیغ
      adsList = [
        {'text': 'تبلیغ اول صرافی', 'link': 'https://t.me/your_channel', 'active': true}
      ];
    }

    // بارگذاری نرخ‌ها برای ویرایش
    String? ratesJson = prefs.getString('custom_rates_json');
    if (ratesJson != null && ratesJson.isNotEmpty) {
      Map<String, dynamic> data = json.decode(ratesJson);
      ratesList = List<Map<String, dynamic>>.from(data['rates'] ?? []);
    } else {
      // نرخ‌های پیش‌فرض
      ratesList = [
        {"currency": "USD (دلار)", "buy": "64.53", "sell": "64.73", "unit": "AFN"},
        {"currency": "EUR (یورو)", "buy": "73.50", "sell": "74.10", "unit": "AFN"},
        {"currency": "طلا (یک گرم عیار ۷۵۰)", "buy": "4500", "sell": "4550", "unit": "AFN"},
        {"currency": "طلا (یک مثقال عیار ۷۵۰)", "buy": "20700", "sell": "20900", "unit": "AFN"},
      ];
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveAllSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // ۱. ذخیره لیست تبلیغات نامحدود
    await prefs.setString('ads_list_json', json.encode(adsList));

    // ۲. ذخیره زمان چرخش اسلایدر
    int duration = int.tryParse(_durationController.text.trim()) ?? 4;
    await prefs.setInt('ad_duration_seconds', duration);

    // ۳. ذخیره نرخ‌های جدید همراه با تاریخ و ساعت دقیق فعلی
    String nowFormatted = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";
    
    Map<String, dynamic> newRatesData = {
      "last_updated": nowFormatted,
      "rates": ratesList
    };
    await prefs.setString('custom_rates_json', json.encode(newRatesData));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمامی تغییرات با موفقیت ذخیره و اعمال شد')),
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
        title: const Text('پنل مدیریت پیشرفته'),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveAllSettings,
            tooltip: 'ذخیره کل تغییرات',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // آمار کاربران
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

                // بخش مدیریت نرخ‌ها (تطابق کامل با بانک مرکزی و بازار)
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('مدیریت و ویرایش نرخ‌ها (تطابق با د افغانستان بانک)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                          ],
                        ),
                        const Divider(),
                        const Text('در این بخش می‌توانید نرخ خرید و فروش را مستقیماً ویرایش کنید تا دقیقاً مطابق نرخ روز بانک مرکزی یا بازار شود.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 10),
                        ...List.generate(ratesList.length, (index) {
                          var rate = ratesList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rate['currency'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(text: rate['buy']),
                                        onChanged: (val) => rate['buy'] = val,
                                        decoration: const InputDecoration(labelText: 'نرخ خرید', border: OutlineInputBorder(), isDense: true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: TextEditingController(text: rate['sell']),
                                        onChanged: (val) => rate['sell'] = val,
                                        decoration: const InputDecoration(labelText: 'نرخ فروش', border: OutlineInputBorder(), isDense: true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // بخش مدیریت تبلیغات نامحدود + دکمه حذف و تنظیم زمان
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
                        // تنظیم سرعت چرخش
                        TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'زمان تغییر تبلیغات در اسلایدر (به ثانیه، مثلاً ۴)',
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
                                    Text('تبلیغ شماره ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  child: const Text('ذخیره نهایی تغییرات', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
    );
  }
}

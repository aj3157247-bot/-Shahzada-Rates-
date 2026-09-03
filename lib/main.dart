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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Map<String, dynamic> fullData = {};
  List<Map<String, dynamic>> activeAds = [];
  bool isLoading = true;
  late TabController _tabController;
  late PageController _adPageController;
  Timer? _adTimer;
  int _currentAdIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _adPageController = PageController();
    loadAppData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _adPageController.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  void _startAdTimer() {
    _adTimer?.cancel();
    if (activeAds.isEmpty) return;

    var currentAd = activeAds[_currentAdIndex % activeAds.length];
    int durationSec = int.tryParse(currentAd['duration']?.toString() ?? '5') ?? 5;
    if (durationSec < 1) durationSec = 5;

    _adTimer = Timer(Duration(seconds: durationSec), () {
      if (!mounted) return;
      if (activeAds.length > 1 && _adPageController.hasClients) {
        int nextPage = _currentAdIndex + 1;
        if (nextPage >= activeAds.length) {
          nextPage = 0;
        }
        _currentAdIndex = nextPage;
        _adPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
      _startAdTimer();
    });
  }

  Future<void> loadAppData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    String? adsJson = prefs.getString('ads_list_json');
    List<Map<String, dynamic>> loadedAds = [];
    if (adsJson != null && adsJson.isNotEmpty) {
      List decodedAds = json.decode(adsJson);
      for (var ad in decodedAds) {
        if (ad['active'] == true) {
          loadedAds.add({
            'text': ad['text'] ?? '',
            'link': ad['link'] ?? '',
            'duration': ad['duration'] ?? '5',
            'rank': ad['rank'] ?? '1',
          });
        }
      }
    } else {
      loadedAds.add({
        'text': '📢 تبلیغات هزینه نیست، سرمایه است! برای نشر خدمات و صرافی خود با ما در تماس باشید.',
        'link': 'https://t.me/your_channel',
        'duration': '6',
        'rank': '1'
      });
      loadedAds.add({
        'text': '🌟 صرافی معتبر شما؛ انجام حوالجات بین‌المللی با بهترین نرخ و امنیت کامل.',
        'link': 'https://t.me/your_channel',
        'duration': '4',
        'rank': '2'
      });
    }

    loadedAds.sort((a, b) {
      int rankA = int.tryParse(a['rank']?.toString() ?? '1') ?? 1;
      int rankB = int.tryParse(b['rank']?.toString() ?? '1') ?? 1;
      return rankA.compareTo(rankB);
    });

    setState(() {
      activeAds = loadedAds;
      _currentAdIndex = 0;
    });

    _startAdTimer();

    String currentFormattedTime = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}";

    final Map<String, dynamic> defaultStructuredData = {
      "last_updated": currentFormattedTime,
      "currencies": [
        {"currency": "USD (دلار آمریکا)", "buy": "64.54", "sell": "64.74", "unit": "AFN"},
        {"currency": "EUR (یورو)", "buy": "73.50", "sell": "74.10", "unit": "AFN"},
        {"currency": "GBP (پوند انگلیس)", "buy": "84.98", "sell": "85.78", "unit": "AFN"},
        {"currency": "TRY (لیر ترکیه)", "buy": "1.88", "sell": "1.94", "unit": "AFN"},
        {"currency": "PKR (روپیه پاکستان - ۱۰۰۰ کلدار)", "buy": "221.60", "sell": "229.60", "unit": "AFN"},
        {"currency": "IRR (تومان ایران - ۱۰۰۰ تومان)", "buy": "1.05", "sell": "1.12", "unit": "AFN"},
        {"currency": "AED (درهم امارات)", "buy": "17.32", "sell": "17.42", "unit": "AFN"},
        {"currency": "SAR (ریال عربستان)", "buy": "16.82", "sell": "16.92", "unit": "AFN"}
      ],
      "gold_rates": [
        {"currency": "طلای ایرانی (عیار ۷۵۰ - یک گرم)", "buy": "5300", "sell": "5450", "unit": "AFN"},
        {"currency": "طلای بحرینی (عیار ۲۴ - یک گرم)", "buy": "5900", "sell": "6100", "unit": "AFN"},
        {"currency": "طلای عربی (عیار ۲۱ - یک گرم)", "buy": "5550", "sell": "5700", "unit": "AFN"},
        {"currency": "طلای متفرقه / عیار ۷۵۰ (یک گرم)", "buy": "5150", "sell": "5300", "unit": "AFN"},
        {"currency": "طلای ۷۵۰ (یک مثقال)", "buy": "24100", "sell": "24500", "unit": "AFN"}
      ],
      "silver_rates": [
        {"currency": "نقره جهانی (یک اونس)", "buy": "28.50", "sell": "29.20", "unit": "USD"},
        {"currency": "نقره خالص (یک گرم)", "buy": "95", "sell": "110", "unit": "AFN"},
        {"currency": "نقره خالص (یک مثقال)", "buy": "450", "sell": "480", "unit": "AFN"}
      ]
    };

    try {
      final response = await http
          .get(Uri.parse('https://raw.githubusercontent.com/aj3157247-bot/-Shahzada-Rates-/main/assets/rates.json'))
          .timeout(const Duration(seconds: 5));
      
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
        fullData = defaultStructuredData;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        fullData = defaultStructuredData;
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
    Share.share(
      'برنامه حرفه‌ای «افغان نرخ» را نصب کنید و از دقیق‌ترین نرخ‌های لحظه‌ای اسعار، انواع طلا و نقره مطلع شوید!\n\nلینک دانلود برنامه:\nhttps://github.com/aj3157247-bot/-Shahzada-Rates-/releases/download/v1.0.0/app-release.apk'
    );
  }

  List<LinearGradient> _getAdGradients(int index) {
    const gradients = [
      LinearGradient(colors: [Color(0xFF7E22CE), Color(0xFF4F46E5), Color(0xFFDB2777)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      LinearGradient(colors: [Color(0xFFD97706), Color(0xFFEA580C), Color(0xFFCA8A04)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      LinearGradient(colors: [Color(0xFF059669), Color(0xFF0D9488), Color(0xFF0284C7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFBE185D), Color(0xFF9F1239)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ];
    return [gradients[index % gradients.length]];
  }

  @override
  Widget build(BuildContext context) {
    String lastUpdated = fullData['last_updated']?.toString() ?? '';
    List currenciesList = fullData['currencies'] is List ? fullData['currencies'] : [];
    List goldList = fullData['gold_rates'] is List ? fullData['gold_rates'] : [];
    List silverList = fullData['silver_rates'] is List ? fullData['silver_rates'] : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('افغان نرخ'),
        backgroundColor: Colors.green[700],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(text: 'نرخ اسعار', icon: Icon(Icons.currency_exchange, size: 20)),
            Tab(text: 'انواع طلا', icon: Icon(Icons.monetization_on, size: 20)),
            Tab(text: 'نقره جهانی و بازار', icon: Icon(Icons.shutter_speed, size: 20)),
          ],
        ),
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
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRateListView(currenciesList, Icons.currency_exchange, Colors.green),
                      _buildRateListView(goldList, Icons.monetization_on, Colors.amber[800]!),
                      _buildRateListView(silverList, Icons.blur_on, Colors.blueGrey),
                    ],
                  ),
          ),
          if (activeAds.isNotEmpty)
            Container(
              height: 75,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: PageView.builder(
                controller: _adPageController,
                itemCount: activeAds.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentAdIndex = index;
                  });
                  _startAdTimer();
                },
                itemBuilder: (context, index) {
                  var ad = activeAds[index];
                  return GestureDetector(
                    onTap: () => _launchExternalUrl(ad['link']),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: _getAdGradients(index)[0],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.campaign, color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: MarqueeTickerText(
                              text: ad['text'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontSize: 13.5,
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
        ],
      ),
    );
  }

  Widget _buildRateListView(List items, IconData iconData, Color iconColor) {
    if (items.isEmpty) {
      return const Center(child: Text('نرخی موجود نیست'));
    }
    return RefreshIndicator(
      onRefresh: loadAppData,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          var item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 2,
            child: ListTile(
              leading: Icon(iconData, color: iconColor),
              title: Text(
                item['currency']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Text('واحد پایه: ${item['unit'] ?? ''}'),
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
    );
  }
}

class MarqueeTickerText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const MarqueeTickerText({super.key, required this.text, required this.style});

  @override
  State<MarqueeTickerText> createState() => _MarqueeTickerTextState();
}

class _MarqueeTickerTextState extends State<MarqueeTickerText> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (_scrollController.hasClients) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_scrollController.hasClients) break;
      double maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent > 0) {
        await _scrollController.animateTo(
          maxExtent,
          duration: Duration(milliseconds: (maxExtent * 25).toInt()),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!_scrollController.hasClients) break;
        _scrollController.jumpTo(0);
      } else {
        break;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          Text(widget.text, style: widget.style),
          const SizedBox(width: 80),
          Text(widget.text, style: widget.style),
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

  @override
  void initState() {
    super.initState();
    loadAdminData();
  }

  Future<void> loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    totalAppOpens = prefs.getInt('app_open_count') ?? 1;

    String? adsJson = prefs.getString('ads_list_json');
    if (adsJson != null && adsJson.isNotEmpty) {
      List decoded = json.decode(adsJson);
      adsList = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      adsList = [
        {
          'text': '📢 تبلیغات هزینه نیست، سرمایه است! برای نشر خدمات و صرافی خود با ما در تماس باشید.',
          'link': 'https://t.me/your_channel',
          'active': true,
          'duration': '5',
          'rank': '1'
        }
      ];
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> saveAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ads_list_json', json.encode(adsList));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تنظیمات تبلیغات، رنک و زمان‌بندی با موفقیت ذخیره شد')),
    );
    Navigator.pop(context);
  }

  void _addNewAd() {
    setState(() {
      adsList.add({
        'text': 'متن تبلیغ جدید...',
        'link': 'https://t.me/your_channel',
        'active': true,
        'duration': '5',
        'rank': (adsList.length + 1).toString()
      });
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
                            const Text('سیستم تبلیغات، رنک و زمان‌بندی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                              onPressed: _addNewAd,
                              icon: const Icon(Icons.add, size: 18, color: Colors.white),
                              label: const Text('افزودن تبلیغ جدید', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
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
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        controller: TextEditingController(text: ad['link']),
                                        onChanged: (val) => ad['link'] = val,
                                        decoration: const InputDecoration(labelText: 'لینک مقصد (تلگرام/واتساپ)', border: OutlineInputBorder(), isDense: true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: TextEditingController(text: ad['duration']?.toString() ?? '5'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) => ad['duration'] = val,
                                        decoration: const InputDecoration(labelText: 'مدت (ثانیه)', border: OutlineInputBorder(), isDense: true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: TextEditingController(text: ad['rank']?.toString() ?? '1'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) => ad['rank'] = val,
                                        decoration: const InputDecoration(labelText: 'رنک (ترتیب)', border: OutlineInputBorder(), isDense: true),
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

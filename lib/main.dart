import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
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
      theme: ThemeData(primarySwatch: Colors.green),
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
  List<AdItem> activeAds = [];
  int currentAdIndex = 0;
  Timer? _adTimer;
  int rotationInterval = 5;

  @override
  void initState() {
    super.initState();
    loadRates();
    loadAdsAndStartTimer();
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    super.dispose();
  }

  Future<void> loadAdsAndStartTimer() async {
    final prefs = await SharedPreferences.getInstance();
    int interval = prefs.getInt('ad_rotation_interval') ?? 5;
    String? rawAds = prefs.getString('ad_list_json');

    List<AdItem> allAds = [];
    if (rawAds != null && rawAds.isNotEmpty) {
      List<dynamic> decoded = json.decode(rawAds);
      allAds = decoded.map((item) => AdItem.fromJson(item)).toList();
    } else {
      allAds = [
        AdItem(
          id: "1",
          title: "صرافی بزرگ شهزاده",
          content: "حواله‌جات با نازل‌ترین قیمت و سریع‌ترین زمان به تمام نقاط جهان.",
          contact: "https://wa.me/93700000000",
          isActive: true,
          badgeText: "پیشنهاد ویژه",
          bgHexColor: "#FF8C00",
        ),
        AdItem(
          id: "2",
          title: "خرید و فروش طلا و اسعار",
          content: "مناسب‌ترین نرخ خرید و فروش طلا و ارزهای خارجی در سرای شهزاده.",
          contact: "https://t.me/sarafy_shahzada",
          isActive: true,
          badgeText: "بازار طلا",
          bgHexColor: "#2E7D32",
        ),
      ];
    }

    List<AdItem> filtered = allAds.where((ad) => ad.isActive).toList();

    setState(() {
      activeAds = filtered;
      rotationInterval = interval;
      currentAdIndex = 0;
    });

    _startAdTimer();
  }

  void _startAdTimer() {
    _adTimer?.cancel();
    if (activeAds.length > 1) {
      _adTimer = Timer.periodic(Duration(seconds: rotationInterval), (timer) {
        if (mounted && activeAds.isNotEmpty) {
          setState(() {
            currentAdIndex = (currentAdIndex + 1) % activeAds.length;
          });
        }
      });
    }
  }

  Future<void> loadRates() async {
    // ۱. ابتدا تلاش برای دریافت نرخ‌های آنلاین از سرور (لینک زیر را با آدرس فایل rates.json روی هاست خود جایگزین کنید)
    try {
      final response = await http.get(
        Uri.parse('https://yourdomain.com/rates.json'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        setState(() {
          data = json.decode(response.body);
        });
        return; 
      }
    } catch (e) {
      debugPrint('اینترنت وصل نیست یا سرور پاسخ نمی‌دهد. استفاده از حالت آفلاین...');
    }

    // ۲. اگر اتصال اینترنت برقرار نبود، به صورت خودکار از فایل محلی داخل اپ استفاده می‌کند
    try {
      final String response = await rootBundle.loadString('assets/rates.json');
      setState(() {
        data = json.decode(response);
      });
    } catch (localError) {
      debugPrint('خطا در خواندن فایل محلی: $localError');
    }
  }

  Color _parseColor(String hexColor) {
    try {
      String cleanHex = hexColor.replaceAll('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF' + cleanHex;
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (e) {
      return Colors.orange[800]!;
    }
  }

  Future<void> _launchContact(String url) async {
    if (url.trim().isEmpty) return;
    final Uri uri = Uri.parse(url.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('افغان نرخ (سرای شهزاده)'),
          centerTitle: true,
          backgroundColor: Colors.green[800],
          actions: [
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdminLoginPage()),
                );
                loadAdsAndStartTimer();
              },
            ),
          ],
        ),
        body: data == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (activeAds.isNotEmpty) _buildAdBanner(),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: Colors.green[50],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.green),
                        const SizedBox(width: 8),
                        Text('آخرین بروزرسانی: ${data!['last_updated']}'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: data!['rates'].length,
                      itemBuilder: (context, index) {
                        final rate = data!['rates'][index];
                        bool isGoldOrSilver = rate['currency'].contains('طلا') || rate['currency'].contains('نقره');
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isGoldOrSilver ? Colors.amber[100] : Colors.green[100],
                              child: Icon(
                                isGoldOrSilver ? Icons.diamond : Icons.attach_money,
                                color: isGoldOrSilver ? Colors.amber[800] : Colors.green,
                              ),
                            ),
                            title: Text(rate['currency'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(rate['unit'], style: const TextStyle(fontSize: 12)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('خرید: ${rate['buy']}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                Text('فروش: ${rate['sell']}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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

  Widget _buildAdBanner() {
    final currentAd = activeAds[currentAdIndex % activeAds.length];
    final cardColor = _parseColor(currentAd.bgHexColor);

    return InkWell(
      onTap: () => _launchContact(currentAd.contact),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Container(
          key: ValueKey<String>(currentAd.id + currentAdIndex.toString()),
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cardColor, cardColor.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.campaign, color: Colors.white, size: 32),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentAd.title,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                currentAd.badgeText,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currentAd.content,
                          style: const TextStyle(color: Colors.white90, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (activeAds.length > 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(activeAds.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: currentAdIndex == index ? 12 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: currentAdIndex == index ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

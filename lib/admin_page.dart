import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdItem {
  String id;
  String title;
  String content;
  String contact;
  bool isActive;
  String badgeText;
  String bgHexColor;

  AdItem({
    required this.id,
    required this.title,
    required this.content,
    required this.contact,
    this.isActive = true,
    this.badgeText = "تبلیغ ویژه",
    this.bgHexColor = "#FF8C00",
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'contact': contact,
        'isActive': isActive,
        'badgeText': badgeText,
        'bgHexColor': bgHexColor,
      };

  factory AdItem.fromJson(Map<String, dynamic> json) => AdItem(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? '',
        content: json['content'] ?? '',
        contact: json['contact'] ?? '',
        isActive: json['isActive'] ?? true,
        badgeText: json['badgeText'] ?? 'تبلیغ ویژه',
        bgHexColor: json['bgHexColor'] ?? '#FF8C00',
      );
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final String allowedEmail = "abdullahjafari712@gmail.com";
  final String allowedPassword = "05050505";

  bool isLoggedIn = false;
  List<AdItem> adList = [];
  int rotationInterval = 5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      rotationInterval = prefs.getInt('ad_rotation_interval') ?? 5;
      String? rawAds = prefs.getString('ad_list_json');
      if (rawAds != null && rawAds.isNotEmpty) {
        List<dynamic> decoded = json.decode(rawAds);
        adList = decoded.map((item) => AdItem.fromJson(item)).toList();
      } else {
        adList = [
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
            title: "خرید و فروش اسعار دیجیتال",
            content: "تبادل تتر و کرپتو با مناسب‌ترین نرخ روز در سرای شهزاده.",
            contact: "https://t.me/sarafy_shahzada",
            isActive: true,
            badgeText: "بازار ارز",
            bgHexColor: "#2E7D32",
          ),
        ];
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ad_rotation_interval', rotationInterval);
    String encoded = json.encode(adList.map((e) => e.toJson()).toList());
    await prefs.setString('ad_list_json', encoded);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تنظیمات و لیست تبلیغات با موفقیت ذخیره شد!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void login() {
    if (_emailController.text.trim().toLowerCase() == allowedEmail &&
        _passwordController.text.trim() == allowedPassword) {
      setState(() {
        isLoggedIn = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ایمیل یا رمز عبور اشتباه است!'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAdDialog({AdItem? existingAd, int? index}) {
    final titleController = TextEditingController(text: existingAd?.title ?? '');
    final contentController = TextEditingController(text: existingAd?.content ?? '');
    final contactController = TextEditingController(text: existingAd?.contact ?? '');
    final badgeController = TextEditingController(text: existingAd?.badgeText ?? 'تبلیغ ویژه');
    String selectedColor = existingAd?.bgHexColor ?? '#FF8C00';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                title: Text(existingAd == null ? 'افزایش تبلیغ جدید' : 'ویرایش تبلیغ'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'عنوان تبلیغ', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: contentController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'متن کامل تبلیغ', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: contactController,
                        decoration: const InputDecoration(
                          labelText: 'لینک واتس‌اپ / تلگرام / شماره تماس',
                          hintText: 'https://wa.me/937...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: badgeController,
                        decoration: const InputDecoration(
                          labelText: 'برچسب (مانند: ویژه، تخفیف، فوری)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('رنگ بنر: '),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: selectedColor,
                            items: const [
                              DropdownMenuItem(value: '#FF8C00', child: Text('نارنجی / طلایی')),
                              DropdownMenuItem(value: '#2E7D32', child: Text('سبز زمردی')),
                              DropdownMenuItem(value: '#1565C0', child: Text('آبی ملکی')),
                              DropdownMenuItem(value: '#C62828', child: Text('قرمز زرشکی')),
                              DropdownMenuItem(value: '#6A1B9A', child: Text('بنفش ویژه')),
                            ],
                            onChanged: (val) {
                              if (val != null) setDialogState(() => selectedColor = val);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('انصراف'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
                    onPressed: () {
                      if (titleController.text.isEmpty) return;
                      setState(() {
                        if (existingAd == null) {
                          adList.add(AdItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: titleController.text,
                            content: contentController.text,
                            contact: contactController.text,
                            badgeText: badgeController.text,
                            bgHexColor: selectedColor,
                            isActive: true,
                          ));
                        } else if (index != null) {
                          adList[index].title = titleController.text;
                          adList[index].content = contentController.text;
                          adList[index].contact = contactController.text;
                          adList[index].badgeText = badgeController.text;
                          adList[index].bgHexColor = selectedColor;
                        }
                      });
                      _saveData();
                      Navigator.pop(context);
                    },
                    child: const Text('ذخیره', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isLoggedIn ? 'مدیریت حرفه‌ای تبلیغات' : 'ورود مدیر'),
          backgroundColor: Colors.green[800],
        ),
        floatingActionButton: isLoggedIn
            ? FloatingActionButton.extended(
                backgroundColor: Colors.green[800],
                onPressed: () => _showAdDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('تبلیغ جدید', style: TextStyle(color: Colors.white)),
              )
            : null,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: !isLoggedIn ? _buildLoginForm() : _buildAdminPanel(),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.admin_panel_settings, size: 80, color: Colors.green[800]),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'جیمیل اختصاصی', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'رمز عبور', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: login,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
            child: const Text('ورود به پنل مدیریت', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          color: Colors.green[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timer, color: Colors.green),
                    SizedBox(width: 8),
                    Text('زمان چرخش تبلیغ‌ها:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                DropdownButton<int>(
                  value: rotationInterval,
                  items: const [
                    DropdownMenuItem(value: 3, child: Text('هر ۳ ثانیه')),
                    DropdownMenuItem(value: 5, child: Text('هر ۵ ثانیه')),
                    DropdownMenuItem(value: 10, child: Text('هر ۱۰ ثانیه')),
                    DropdownMenuItem(value: 30, child: Text('هر ۳۰ ثانیه')),
                    DropdownMenuItem(value: 60, child: Text('هر ۱ دقیقه')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => rotationInterval = val);
                      _saveData();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('لیست تبلیغات فعال/غیرفعال (${adList.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save, color: Colors.green),
              label: const Text('ذخیره تغییرات', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        adList.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(30.0),
                  child: Text('هیچ تبلیغی وجود ندارد. دکمه «تبلیغ جدید» را بزنید.'),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: adList.length,
                itemBuilder: (context, index) {
                  final ad = adList[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: Switch(
                        activeColor: Colors.green,
                        value: ad.isActive,
                        onChanged: (val) {
                          setState(() {
                            ad.isActive = val;
                          });
                          _saveData();
                        },
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              ad.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ad.isActive ? Colors.black : Colors.grey,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(ad.badgeText, style: const TextStyle(fontSize: 10, color: Colors.orange)),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        ad.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: ad.isActive ? Colors.black87 : Colors.grey),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                            onPressed: () => _showAdDialog(existingAd: ad, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                adList.removeAt(index);
                              });
                              _saveData();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}

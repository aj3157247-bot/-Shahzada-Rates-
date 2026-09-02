import 'package:flutter/material.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _adTitleController = TextEditingController();
  final _adContentController = TextEditingController();
  final _adLinkController = TextEditingController();

  // ایمیل مجاز
  final String allowedEmail = "abdullahjafari712@gmail.com";
  // رمز عبور اختصاصی
  final String allowedPassword = "05050505";

  bool isLoggedIn = false;
  
  // پیش‌فرض تبلیغات
  String adTitle = "تبلیغ ویژه صرافی";
  String adContent = "جهت ثبت تبلیغ کسب‌وکار و صرافی خود در این مکان، با ما تماس بگیرید.";
  String adLink = "https://wa.me/93700000000";

  void login() {
    String inputEmail = _emailController.text.trim().toLowerCase();
    String inputPassword = _passwordController.text.trim();

    if (inputEmail == allowedEmail && inputPassword == allowedPassword) {
      setState(() {
        isLoggedIn = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('خوش آمدید مدیر محترم!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ایمیل یا رمز عبور اشتباه است!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void saveAd() {
    setState(() {
      adTitle = _adTitleController.text.isEmpty ? adTitle : _adTitleController.text;
      adContent = _adContentController.text.isEmpty ? adContent : _adContentController.text;
      adLink = _adLinkController.text.isEmpty ? adLink : _adLinkController.text;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تبلیغات جدید با موفقیت منتشر شد.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isLoggedIn ? 'پنل مدیریت تبلیغات' : 'ورود مدیر'),
          backgroundColor: Colors.green[800],
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: !isLoggedIn ? _buildLoginForm() : _buildAdminPanel(),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(Icons.admin_panel_settings, size: 80, color: Colors.green[800]),
        const SizedBox(height: 16),
        const Text(
          'احراز هویت مدیر',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'تنها جیمیل و رمز اختصاصی مدیر دسترسی دارد.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'جیمیل اختصاصی',
            prefixIcon: const Icon(Icons.email),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'رمز عبور',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ورود به سیستم', style: TextStyle(fontSize: 18, color: Colors.white)),
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
          color: Colors.green[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.green),
                    SizedBox(width: 8),
                    Text('پیش‌نمایش بنر فعلی', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Divider(),
                Text('عنوان: $adTitle', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('متن: $adContent'),
                const SizedBox(height: 4),
                Text('لینک / شماره: $adLink', style: const TextStyle(color: Colors.blue)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('ساخت و تغییر تبلیغ جدید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _adTitleController,
          decoration: InputDecoration(
            labelText: 'عنوان تبلیغ (مثلا: صرافی شهزاده)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _adContentController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'متن کامل تبلیغ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _adLinkController,
          decoration: InputDecoration(
            labelText: 'لینک واتس‌اپ یا وب‌سایت (اختیاری)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: saveAd,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('انتشار فوری تبلیغ', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

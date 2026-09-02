import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const AfghanExchangeApp());
}

class AfghanExchangeApp extends StatelessWidget {
  const AfghanExchangeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'نرخ اسعار سرای شهزاده',
      theme: ThemeData(
        primarySwatch: Colors.green,
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
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadRates();
  }

  Future<void> loadRates() async {
    final String response = await rootBundle.loadString('assets/rates.json');
    setState(() {
      data = json.decode(response);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('نرخ لحظه‌ای اسعار - سرای شهزاده'),
          centerTitle: true,
          backgroundColor: Colors.green[800],
        ),
        body: data == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.green[50],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'آخرین بروزرسانی: ${data!['last_updated']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: data!['rates'].length,
                      itemBuilder: (context, index) {
                        final rate = data!['rates'][index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.monetization_on, color: Colors.green),
                            title: Text(rate['currency'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(rate['unit']),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('خرید: ${rate['buy']}', style: const TextStyle(color: Colors.green)),
                                Text('فروش: ${rate['sell']}', style: const TextStyle(color: Colors.red)),
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
}

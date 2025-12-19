import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

// -----------------------------------------------------------------------------
// 📦 1. نموذج البيانات (Data Models)
// -----------------------------------------------------------------------------

class Prices {
  double cadre;
  double daffa;
  double glass;
  double caison;
  double lame;
  double accessories;

  Prices({
    required this.cadre,
    required this.daffa,
    required this.glass,
    required this.caison,
    required this.lame,
    required this.accessories,
  });

  factory Prices.fromJson(Map<String, dynamic> json) {
    // التعامل مع الأرقام التي قد تكون مخزنة كـ int في JSON
    return Prices(
      cadre: json['cadre'] is int ? (json['cadre'] as int).toDouble() : json['cadre'],
      daffa: json['daffa'] is int ? (json['daffa'] as int).toDouble() : json['daffa'],
      glass: json['glass'] is int ? (json['glass'] as int).toDouble() : json['glass'],
      caison: json['caison'] is int ? (json['caison'] as int).toDouble() : json['caison'],
      lame: json['lame'] is int ? (json['lame'] as int).toDouble() : json['lame'],
      accessories: json['accessories'] is int ? (json['accessories'] as int).toDouble() : json['accessories'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cadre': cadre,
      'daffa': daffa,
      'glass': glass,
      'caison': caison,
      'lame': lame,
      'accessories': accessories,
    };
  }
}

class Window {
  final double L; // الطول الأصلي
  final double W; // العرض الأصلي

  // الأبعاد المحسوبة
  final double windowLength;
  final double windowWidth;
  final double caisonLength;
  final double lameLength;
  final double H25Length;
  final double length108;
  final int lameCount;

  Window({
    required this.L,
    required this.W,
    required this.windowLength,
    required this.windowWidth,
    required this.caisonLength,
    required this.lameLength,
    required this.H25Length,
    required this.length108,
    required this.lameCount,
  });

  // -----------------------------------------------------------------------------
  // 🧮 2. المنطق الحسابي (مطابق 100% لكود JavaScript)
  // -----------------------------------------------------------------------------

  static Window calculateDimensions({required double L, required double W}) {
    // windowLength = L - 21.5
    double windowLength = L - 21.5;
    // windowWidth = (W - 6) / 2
    double windowWidth = (W - 6) / 2;
    // caisonLength = W - 1
    double caisonLength = W - 1;
    // lameLength = caisonLength - 5.5
    double lameLength = caisonLength - 5.5;
    // H25Length = (L - 12.5) + 1
    double H25Length = (L - 12.5) + 1;
    // length108 = windowLength - 3.5
    double length108 = windowLength - 3.5;
    // lameCount = round(H25Length / 4)
    // Math.round() في JS يقابله .round() في Dart
    int lameCount = (H25Length / 4).round();

    // التحقق من أن الأبعاد النهائية لا تكون سالبة (كما في JS)
    if (windowLength < 0 || windowWidth < 0 || caisonLength < 0 || lameLength < 0 || H25Length < 0 || length108 < 0 || lameCount < 0) {
      throw Exception("⚠️ الأبعاد المحسوبة أدت إلى قيم سالبة. يرجى مراجعة الطول والعرض الأصليين.");
    }

    return Window(
      L: L,
      W: W,
      windowLength: windowLength,
      windowWidth: windowWidth,
      caisonLength: caisonLength,
      lameLength: lameLength,
      H25Length: H25Length,
      length108: length108,
      lameCount: lameCount,
    );
  }

  // -----------------------------------------------------------------------------
  // 💰 3. حساب التكلفة (مطابق 100% لكود JavaScript)
  // -----------------------------------------------------------------------------

  Map<String, double> calculateCost(Prices prices) {
    // ملاحظة: جميع الأبعاد في الكود الأصلي (JS) تُقسم على 100 عند حساب التكلفة،
    // مما يعني أن الأبعاد المدخلة هي بالسنتيمتر (cm) والتكلفة تحسب بالمتر (m).

    // cadreCost
    double cadreCost = (windowLength * 2 + windowWidth * 2) / 100 * prices.cadre;
    // daffaCost
    double daffaCost = (windowLength * 2 + windowWidth * 2) / 100 * prices.daffa;
    // glassArea
    double glassArea = (windowLength / 100) * (windowWidth / 100);
    // glassCost
    double glassCost = glassArea * prices.glass;
    // caisonCost
    double caisonCost = (caisonLength / 100) * prices.caison;
    // lameCost
    double lameCost = (lameLength / 100) * lameCount * prices.lame;
    // accessoriesCost
    double accessoriesCost = prices.accessories; // قيمة ثابتة لكل نافذة

    double total = cadreCost + daffaCost + glassCost + caisonCost + lameCost + accessoriesCost;

    return {
      'cadreCost': cadreCost,
      'daffaCost': daffaCost,
      'glassArea': glassArea,
      'glassCost': glassCost,
      'caisonCost': caisonCost,
      'lameCost': lameCost,
      'accessoriesCost': accessoriesCost,
      'total': total,
    };
  }

  // تحويل من وإلى JSON لتخزين قائمة النوافذ
  factory Window.fromJson(Map<String, dynamic> json) {
    return Window(
      L: json['L'],
      W: json['W'],
      windowLength: json['windowLength'],
      windowWidth: json['windowWidth'],
      caisonLength: json['caisonLength'],
      lameLength: json['lameLength'],
      H25Length: json['H25Length'],
      length108: json['length108'],
      lameCount: json['lameCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'L': L,
      'W': W,
      'windowLength': windowLength,
      'windowWidth': windowWidth,
      'caisonLength': caisonLength,
      'lameLength': lameLength,
      'H25Length': H25Length,
      'length108': length108,
      'lameCount': lameCount,
    };
  }
}

// -----------------------------------------------------------------------------
// 💾 4. إدارة التخزين (SharedPreferences)
// -----------------------------------------------------------------------------

class StorageManager {
  static const String _pricesKey = 'pvcPrices';
  static const String _windowsKey = 'pvcWindows';

  static Prices get defaultPrices => Prices(
        cadre: 270.0,
        daffa: 270.0,
        glass: 1600.0,
        caison: 410.0,
        lame: 35.0,
        accessories: 0.0,
      );

  static Future<Prices> loadPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_pricesKey);
    if (saved != null) {
      return Prices.fromJson(json.decode(saved));
    }
    return defaultPrices;
  }

  static Future<void> savePrices(Prices prices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pricesKey, json.encode(prices.toJson()));
  }

  static Future<List<Window>> loadWindows() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_windowsKey);
    if (saved != null) {
      return saved.map((item) => Window.fromJson(json.decode(item))).toList();
    }
    return [];
  }

  static Future<void> saveWindows(List<Window> windows) async {
    final prefs = await SharedPreferences.getInstance();
    final list = windows.map((win) => json.encode(win.toJson())).toList();
    await prefs.setStringList(_windowsKey, list);
  }
}

// -----------------------------------------------------------------------------
// 📱 5. واجهة المستخدم (UI)
// -----------------------------------------------------------------------------

void main() {
  // لضمان تهيئة Flutter قبل استخدام SharedPreferences
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PVCApp());
}

class PVCApp extends StatelessWidget {
  const PVCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'حاسبة نوافذ PVC',
      debugShowCheckedModeBanner: false,
      // RTL كامل واللغة العربية افتراضياً
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // Arabic
      ],
      locale: const Locale('ar', ''),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        // لا يمكن إضافة خط 'Tajawal' بدون ملف الخط، لذا سنعتمد على الخط الافتراضي
        // مع الإشارة إلى ضرورة إضافة الخط في pubspec.yaml وتعيينه هنا.
        useMaterial3: true,
      ),
      home: const PVCWindowCalculator(),
    );
  }
}

class PVCWindowCalculator extends StatefulWidget {
  const PVCWindowCalculator({super.key});

  @override
  State<PVCWindowCalculator> createState() => _PVCWindowCalculatorState();
}

class _PVCWindowCalculatorState extends State<PVCWindowCalculator> {
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();

  Prices _prices = StorageManager.defaultPrices;
  List<Window> _windows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _prices = await StorageManager.loadPrices();
    _windows = await StorageManager.loadWindows();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveWindows() async {
    await StorageManager.saveWindows(_windows);
  }

  // -----------------------------------------------------------------------------
  // ➕ إضافة نافذة
  // -----------------------------------------------------------------------------

  void _addWindow() {
    final L = double.tryParse(_lengthController.text);
    final W = double.tryParse(_widthController.text);

    if (L == null || W == null || L <= 0 || W <= 0) {
      _showAlertDialog("⚠️ خطأ في الإدخال", "يرجى إدخال قيم صحيحة وموجبة للطول والعرض.");
      return;
    }

    try {
      final newWindow = Window.calculateDimensions(L: L, W: W);
      setState(() {
        _windows.add(newWindow);
        _lengthController.clear();
        _widthController.clear();
      });
      _saveWindows();
    } catch (e) {
      // إزالة "Exception: " من رسالة الخطأ
      _showAlertDialog("⚠️ خطأ في الحساب", e.toString().replaceAll('Exception: ', ''));
    }
  }

  // -----------------------------------------------------------------------------
  // ❌ حذف نافذة
  // -----------------------------------------------------------------------------

  void _deleteWindow(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف", textAlign: TextAlign.right),
        content: const Text("هل أنت متأكد من حذف هذه النافذة؟", textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _windows.removeAt(index);
              });
              _saveWindows();
              Navigator.pop(context);
            },
            child: const Text("حذف", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // ⚙️ مودال تعديل الأسعار
  // -----------------------------------------------------------------------------

  void _openPriceModal() {
    final cadreCtrl = TextEditingController(text: _prices.cadre.toString());
    final daffaCtrl = TextEditingController(text: _prices.daffa.toString());
    final glassCtrl = TextEditingController(text: _prices.glass.toString());
    final caisonCtrl = TextEditingController(text: _prices.caison.toString());
    final lameCtrl = TextEditingController(text: _prices.lame.toString());
    final accCtrl = TextEditingController(text: _prices.accessories.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "⚙️ تعديل الأسعار",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 20),
                _buildPriceTextField(cadreCtrl, "سعر الكادر / متر (دج)"),
                _buildPriceTextField(daffaCtrl, "سعر الدفة / متر (دج)"),
                _buildPriceTextField(glassCtrl, "سعر الزجاج / م² (دج)"),
                _buildPriceTextField(caisonCtrl, "سعر Caison / متر (دج)"),
                _buildPriceTextField(lameCtrl, "سعر Lame / متر (دج)"),
                _buildPriceTextField(accCtrl, "سعر الإكسسوارات (دج)"),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Text("إلغاء", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _savePriceChanges(
                          cadreCtrl.text,
                          daffaCtrl.text,
                          glassCtrl.text,
                          caisonCtrl.text,
                          lameCtrl.text,
                          accCtrl.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.all(15),
                        ),
                        child: const Text("حفظ التغييرات", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceTextField(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // السماح برقمين عشريين
        ],
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  void _savePriceChanges(
    String cadre,
    String daffa,
    String glass,
    String caison,
    String lame,
    String acc,
  ) async {
    final newCadre = double.tryParse(cadre);
    final newDaffa = double.tryParse(daffa);
    final newGlass = double.tryParse(glass);
    final newCaison = double.tryParse(caison);
    final newLame = double.tryParse(lame);
    final newAcc = double.tryParse(acc);

    if (newCadre == null || newDaffa == null || newGlass == null || newCaison == null || newLame == null || newAcc == null) {
      _showAlertDialog("⚠️ خطأ في الإدخال", "يرجى إدخال قيم رقمية صحيحة لجميع الأسعار.");
      return;
    }

    final newPrices = Prices(
      cadre: newCadre,
      daffa: newDaffa,
      glass: newGlass,
      caison: newCaison,
      lame: newLame,
      accessories: newAcc,
    );

    await StorageManager.savePrices(newPrices);
    setState(() {
      _prices = newPrices;
    });
    Navigator.pop(context);
    _showAlertDialog("✅ تم بنجاح", "تم حفظ الأسعار بنجاح!");
  }

  // -----------------------------------------------------------------------------
  // 💰 مودال حساب التكلفة
  // -----------------------------------------------------------------------------

  void _openCostModal() {
    if (_windows.isEmpty) {
      _showAlertDialog("⚠️ لا توجد نوافذ", "يرجى إضافة نوافذ أولاً لحساب التكلفة.");
      return;
    }

    double totalOverallCost = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "💰 تكلفة النوافذ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        ..._windows.asMap().entries.map((entry) {
                          final index = entry.key;
                          final win = entry.value;
                          final cost = win.calculateCost(_prices);
                          totalOverallCost += cost['total']!;

                          return _buildCostCard(index + 1, win, cost);
                        }).toList(),
                        const SizedBox(height: 10),
                        _buildTotalOverallCost(totalOverallCost),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 10),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(15),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text("إغلاق", style: TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCostCard(int index, Window win, Map<String, double> cost) {
    // استخدام toStringAsFixed(2) لضمان نفس التقريب (toFixed(2) في JS)
    String format(double value) => value.toStringAsFixed(2);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "نافذة رقم $index (L:${win.L}, W:${win.W})",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
              fontSize: 16,
            ),
          ),
          const Divider(height: 15),
          _buildCostRow("الكادر:", format(cost['cadreCost']!)),
          _buildCostRow("الدفة:", format(cost['daffaCost']!)),
          _buildCostRow("الزجاج (${format(cost['glassArea']!)} م²):", format(cost['glassCost']!)),
          _buildCostRow("Caison:", format(cost['caisonCost']!)),
          _buildCostRow("Lame (${win.lameCount} قطعة):", format(cost['lameCost']!)),
          _buildCostRow("الإكسسوارات:", format(cost['accessoriesCost']!)),
          const Divider(height: 15, color: Colors.green, thickness: 2),
          _buildCostRow("الإجمالي:", format(cost['total']!), isTotal: true),
        ],
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green.shade700 : Colors.black87,
            ),
          ),
          Text(
            "$value دج",
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green.shade700 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalOverallCost(double total) {
    return Container(
      padding: const EdgeInsets.all(15),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade500, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            "الإجمالي الكلي لجميع النوافذ:",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "${total.toStringAsFixed(2)} دج",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // ⚠️ رسائل التنبيه
  // -----------------------------------------------------------------------------

  void _showAlertDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, textAlign: TextAlign.right),
        content: Text(content, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("حسناً"),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // 🖼️ بناء الواجهة الرئيسية
  // -----------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('حاسبة نوافذ PVC', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // العنوان
                const Text(
                  '🪟 حساب الأبعاد و التكلفة لــ PVC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF), // Blue-700
                  ),
                ),
                const SizedBox(height: 20),

                // حقول الإدخال
                _buildInputField(_lengthController, "الطول الأصلي (L)"),
                const SizedBox(height: 10),
                _buildInputField(_widthController, "العرض الأصلي (W)"),
                const SizedBox(height: 20),

                // زر إضافة نافذة
                ElevatedButton(
                  onPressed: _addWindow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    '➕ أضف نافذة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),

                // أزرار الإجراءات
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openPriceModal,
                        icon: const Icon(Icons.settings, color: Colors.white),
                        label: const Text('تعديل الأسعار', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openCostModal,
                        icon: const Icon(Icons.attach_money, color: Colors.white),
                        label: const Text('حساب التكلفة', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // جدول عرض القيم
                _buildWindowsTable(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // السماح برقمين عشريين
      ],
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
        ),
        contentPadding: const EdgeInsets.all(15),
      ),
    );
  }

  Widget _buildWindowsTable() {
    if (_windows.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
        ),
        child: const Text(
          'لا توجد نوافذ مدخلة بعد.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    // رؤوس الأعمدة
    final List<String> headers = [
      'L',
      'W',
      'طول النافذة',
      'عرض النافذة',
      'Caison',
      'Lame',
      'H25',
      '108',
      'عدد Lame',
      'حذف'
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 15,
          horizontalMargin: 10,
          headingRowColor: MaterialStateProperty.resolveWith((states) => Colors.blue.shade100),
          columns: headers
              .map((h) => DataColumn(
                    label: Text(
                      h,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      textAlign: TextAlign.center,
                    ),
                  ))
              .toList(),
          rows: _windows.asMap().entries.map((entry) {
            final index = entry.key;
            final win = entry.value;
            // استخدام toStringAsFixed(2) لضمان نفس التقريب (toFixed(2) في JS)
            String format(double value) => value.toStringAsFixed(2);

            return DataRow(
              cells: [
                DataCell(Text(win.L.toString())),
                DataCell(Text(win.W.toString())),
                DataCell(Text(format(win.windowLength))),
                DataCell(Text(format(win.windowWidth))),
                DataCell(Text(format(win.caisonLength))),
                DataCell(Text(format(win.lameLength))),
                DataCell(Text(format(win.H25Length))),
                DataCell(Text(format(win.length108))),
                DataCell(Text(win.lameCount.toString())),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteWindow(index),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

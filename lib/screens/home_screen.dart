import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';

import '../models/product.dart';
import '../services/vodafone_cash_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _service = VodafoneCashService();
  late TabController _tabController;

  LoginResult? _login;
  Product? _selectedProduct;
  bool _loadingLogin = true;
  bool _submitting = false;

  final _receiverController = TextEditingController();
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loginNow();
  }

  Future<void> _loginNow() async {
    setState(() => _loadingLogin = true);
    try {
      final login = await _service.getSeamlessAndMsisdn();
      setState(() => _login = login);
    } catch (_) {
      // Silently handle or show a small error state
    } finally {
      setState(() => _loadingLogin = false);
    }
  }

  void _openCheckout() {
    if (_selectedProduct == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckoutSheet(
        product: _selectedProduct!,
        login: _login,
        receiverController: _receiverController,
        pinController: _pinController,
        onSubmit: _submitPurchase,
      ),
    );
  }

  Future<void> _submitPurchase() async {
    Navigator.pop(context); // close sheet

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE60000)),
      ),
    );

    try {
      final result = await _service.purchaseProduct(
        selectedProduct: _selectedProduct!.id,
        receiver: _receiverController.text.trim(),
        pin: _pinController.text.trim(),
        seamlessToken: _login!.seamlessToken,
        senderMsisdn: _login!.senderMsisdn,
      );

      Navigator.pop(context); // close loading
      _pinController.clear();
      _showResultDialog(result.success, result.message);

    } catch (e) {
      Navigator.pop(context);
      _showResultDialog(false, e.toString());
    }
  }

  void _showResultDialog(bool success, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: success ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: success ? Colors.green : Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                success ? 'نجاح' : 'فشل العملية',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: success ? Colors.green : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('حسناً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFFE60000),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFE60000).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.all(6),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black45,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    tabs: const [
                      Tab(text: 'كروت فكة'),
                      Tab(text: 'كروت مارد'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrid(fakkaProducts.map((id) => Product(id: id, type: ProductType.fakka)).toList()),
                _buildGrid(maredProducts.map((id) => Product(id: id, type: ProductType.mared)).toList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _selectedProduct == null ? null : FadeInUp(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: FloatingActionButton.extended(
              onPressed: _openCheckout,
              backgroundColor: const Color(0xFFE60000),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              icon: const Icon(Icons.shopping_bag_rounded, color: Colors.white),
              label: Text(
                'شراء ${_selectedProduct!.priceLabel}',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFF4F6F9),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE60000), Color(0xFF990000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FadeInRight(
                        child: const Text(
                          'مرحباً بك،',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeInRight(
                        delay: const Duration(milliseconds: 100),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'فودافون كاش',
                              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            if (_loadingLogin)
                              const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            else if (_login != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _login!.senderMsisdn,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<Product> items) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        final isSelected = _selectedProduct?.id == product.id;

        return FadeInUp(
          delay: Duration(milliseconds: 50 * (index % 10)),
          child: GestureDetector(
            onTap: () => setState(() => _selectedProduct = product),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuart,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE60000) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isSelected ? const Color(0xFFE60000) : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [BoxShadow(color: const Color(0xFFE60000).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))]
                    : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFF4F6F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      product.type == ProductType.mared ? Icons.local_fire_department_rounded : Icons.confirmation_num_rounded,
                      color: isSelected ? Colors.white : const Color(0xFFE60000),
                      size: 28,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.priceLabel,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.title.replaceAll('Fakka ', '').replaceAll('Mared ', ''),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.black45,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CheckoutSheet extends StatelessWidget {
  final Product product;
  final LoginResult? login;
  final TextEditingController receiverController;
  final TextEditingController pinController;
  final VoidCallback onSubmit;

  const _CheckoutSheet({
    required this.product,
    required this.login,
    required this.receiverController,
    required this.pinController,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, bottomInset + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('تأكيد الشراء', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(product.priceLabel, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFE60000))),
              ],
            ),
            const SizedBox(height: 8),
            Text('كارت: ${product.title}', style: const TextStyle(color: Colors.black54, fontSize: 16)),
            const SizedBox(height: 32),

            _buildInput(
              controller: receiverController,
              label: 'رقم المستلم',
              icon: Icons.phone_android_rounded,
              maxLength: 11,
            ),
            const SizedBox(height: 20),
            _buildInput(
              controller: pinController,
              label: 'الرقم السري (Vodafone Cash)',
              icon: Icons.lock_rounded,
              maxLength: 6,
              isPassword: true,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton(
                onPressed: () {
                  if (login == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء الانتظار حتى يتم تسجيل الدخول')));
                    return;
                  }
                  if (receiverController.text.length != 11 || pinController.text.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال البيانات بشكل صحيح')));
                    return;
                  }
                  onSubmit();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE60000),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('تأكيد الدفع', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required int maxLength,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: TextInputType.number,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          counterText: '',
          hintText: label,
          hintStyle: const TextStyle(color: Colors.black38, fontSize: 16),
          prefixIcon: Icon(icon, color: Colors.black45),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}

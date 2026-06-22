import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/vodafone_cash_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = VodafoneCashService();
  final _receiverController = TextEditingController();
  final _pinController = TextEditingController();

  LoginResult? _login;
  Product? _selectedProduct;
  bool _loadingLogin = false;
  bool _submitting = false;
  String? _status;
  bool _statusSuccess = false;

  @override
  void initState() {
    super.initState();
    _loginNow();
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loginNow() async {
    setState(() {
      _loadingLogin = true;
      _status = 'جاري تسجيل الدخول...';
      _statusSuccess = false;
    });
    try {
      final login = await _service.getSeamlessAndMsisdn();
      await _service.getAccessToken(login.seamlessToken);
      setState(() {
        _login = login;
        _status = 'تم تسجيل الدخول: ${login.senderMsisdn}';
        _statusSuccess = true;
      });
    } catch (e) {
      setState(() {
        _status = e.toString().replaceFirst('Exception: ', '');
        _statusSuccess = false;
      });
    } finally {
      setState(() => _loadingLogin = false);
    }
  }

  bool get _validReceiver {
    final value = _receiverController.text.trim();
    return value.startsWith('01') && value.length == 11 && int.tryParse(value) != null;
  }

  bool get _validPin {
    final value = _pinController.text.trim();
    return value.length == 6 && int.tryParse(value) != null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_login == null) {
      _showSnack('سجل الدخول أولا');
      return;
    }
    if (_selectedProduct == null) {
      _showSnack('اختر الكارت أولا');
      return;
    }
    if (!_validReceiver) {
      _showSnack('رقم المستلم يجب أن يبدأ بـ 01 ويتكون من 11 رقم');
      return;
    }
    if (!_validPin) {
      _showSnack('الرقم السري يجب أن يكون 6 أرقام');
      return;
    }

    setState(() {
      _submitting = true;
      _status = 'جاري تنفيذ عملية الشراء...';
      _statusSuccess = false;
    });

    try {
      final result = await _service.purchaseProduct(
        selectedProduct: _selectedProduct!.id,
        receiver: _receiverController.text.trim(),
        pin: _pinController.text.trim(),
        seamlessToken: _login!.seamlessToken,
        senderMsisdn: _login!.senderMsisdn,
      );
      _pinController.clear();
      setState(() {
        _status = result.message;
        _statusSuccess = result.success;
      });
    } catch (e) {
      setState(() {
        _status = e.toString().replaceFirst('Exception: ', '');
        _statusSuccess = false;
      });
    } finally {
      setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(status: _status, success: _statusSuccess)),
            SliverToBoxAdapter(child: _buildLoginCard()),
            SliverToBoxAdapter(child: _buildForm()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverGrid.builder(
                itemCount: allProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.36,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final product = allProducts[index];
                  final selected = _selectedProduct?.id == product.id;
                  return _ProductCard(
                    product: product,
                    selected: selected,
                    onTap: () => setState(() => _selectedProduct = product),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _submitting || _loadingLogin ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.shopping_cart_checkout_rounded),
            label: Text(_submitting ? 'جاري التنفيذ...' : 'تنفيذ الشراء'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _login == null ? Colors.orange.shade50 : Colors.green.shade50,
              child: Icon(_login == null ? Icons.sync_rounded : Icons.verified_rounded,
                  color: _login == null ? Colors.orange : Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _login == null ? 'لم يتم تسجيل الدخول بعد' : 'الرقم المرسل: ${_login!.senderMsisdn}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(onPressed: _loadingLogin ? null : _loginNow, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _receiverController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            decoration: const InputDecoration(
              labelText: 'رقم المستلم',
              prefixIcon: Icon(Icons.phone_android_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'الرقم السري لفودافون كاش',
              prefixIcon: Icon(Icons.lock_rounded),
              counterText: '',
            ),
          ),
          const SizedBox(height: 18),
          const Text('اختر الكارت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String? status;
  final bool success;

  const _Header({required this.status, required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE60000), Color(0xFFB00020)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on_rounded, color: Colors.white, size: 32),
              SizedBox(width: 8),
              Text('كروت فكة ومارد', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'تطبيق سريع لتنفيذ طلبات Vodafone Cash من الموبايل',
            style: TextStyle(color: Colors.white.withOpacity(.9), fontSize: 14),
          ),
          if (status != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Icon(success ? Icons.check_circle_rounded : Icons.info_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(status!, style: const TextStyle(color: Colors.white))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool selected;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isMared = product.type == ProductType.mared;
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE60000) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? const Color(0xFFE60000) : const Color(0xFFE5E7EB)),
          boxShadow: selected
              ? const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 8))]
              : const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(isMared ? Icons.local_fire_department_rounded : Icons.confirmation_number_rounded,
                    color: selected ? Colors.white : const Color(0xFFE60000)),
                const Spacer(),
                if (selected) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.priceLabel,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: selected ? Colors.white70 : Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

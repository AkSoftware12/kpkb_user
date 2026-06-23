import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../HomeOrderAccount/home_order_account.dart';

class OrderFailed extends StatelessWidget {
  final String cartId;
  final String currency;

  const OrderFailed(this.cartId, this.currency, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF06087A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _FailedCard(cartId: cartId, currency: currency),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FailedCard extends StatelessWidget {
  final String cartId;
  final String currency;

  const _FailedCard({required this.cartId, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _FailedIcon(),
          const SizedBox(height: 20),
          const Text(
            'Order could not be placed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Something went wrong while processing your payment. Don't worry — you won't be charged.",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B6B6B),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _RefundBanner(),
          const SizedBox(height: 16),
          _OrderMeta(cartId: cartId, currency: currency),
          const SizedBox(height: 20),
          _ActionButtons(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _FailedIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFFFCEBEB),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.close_rounded,
        color: Color(0xFFA32D2D),
        size: 32,
      ),
    );
  }
}

class _RefundBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3DE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF97C459), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.shield_outlined,
            color: Color(0xFF3B6D11),
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF27500A),
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: 'If any amount was deducted, it will be '),
                  TextSpan(
                    text: 'automatically refunded',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' within 3–5 business days.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderMeta extends StatelessWidget {
  final String cartId;
  final String currency;

  const _OrderMeta({required this.cartId, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _MetaRow(label: 'Order ID', value: '#$cartId'),
          const SizedBox(height: 8),
          _MetaRow(label: 'Currency', value: currency),
          const SizedBox(height: 8),
          _MetaRowWithBadge(label: 'Status'),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF888780)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}

class _MetaRowWithBadge extends StatelessWidget {
  final String label;

  const _MetaRowWithBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF888780)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFCEBEB),
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'Failed',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFFA32D2D),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [

        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeOrderAccount(0, 1)),
                    (Route<dynamic> route) => false,
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Color(0xFF06087A),
              foregroundColor: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFCCCCCC), width: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Go to home',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400,color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _handleRetry(BuildContext context) {
    // TODO: apna checkout/retry logic yahan daalo
    Navigator.of(context).pop();
  }

  void _handleHome(BuildContext context) {
    // TODO: home route pe navigate karo
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}


// ─── _onOrderFailed() mein use karo ────────────────────────────────────────
// void _onOrderFailed() {
//   if (!mounted) return;
//   setState(() => showDialogBox = false);
//   Navigator.of(context).pushReplacement(
//     MaterialPageRoute(
//       builder: (_) => OrderFailed(widget.cart_id, currency),
//     ),
//   );
// }
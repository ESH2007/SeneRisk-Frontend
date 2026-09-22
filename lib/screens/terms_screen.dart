import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_top_bar.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Términos y privacidad'),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/legal/terminos.md'),
        builder: (context, snap) {
          final texto = snap.data;
          if (texto == null) return const Center(child: CircularProgressIndicator());
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final linea in texto.split('\n')) _linea(linea)],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _linea(String l) {
    if (l.trim().isEmpty) return const SizedBox(height: 8);
    if (l.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(l.substring(2), style: AppTextStyles.title),
      );
    }
    final m = RegExp(r'^#{2,3} ').firstMatch(l);
    if (m != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(l.substring(m.end), style: AppTextStyles.titleSmall),
      );
    }
    return Text(l, style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.5));
  }
}

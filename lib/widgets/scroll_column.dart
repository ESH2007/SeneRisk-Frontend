import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Columna desplazable que ocupa al menos el alto disponible, para que un
/// `Spacer` empuje el botón principal al fondo y, si no cabe, todo haga scroll.
class ScrollColumn extends StatelessWidget {
  const ScrollColumn({
    super.key,
    required this.children,
    this.horizontalPadding = AppDimens.pagePadding,
    this.safeTop = true,
  });

  final List<Widget> children;
  final double horizontalPadding;
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: safeTop,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

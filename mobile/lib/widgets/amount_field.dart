import 'package:flutter/material.dart';

import 'package:flouze/utils/config.dart';

class AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool notNull;
  final FocusNode _focusNode = FocusNode();

  AmountField({Key key, this.controller, this.label, this.notNull = false}) : super(key: key) {
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        this.controller.selection = TextSelection(baseOffset: 0, extentOffset: this.controller.text.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      TextFormField(
        textAlign: TextAlign.end,
        keyboardType: TextInputType.numberWithOptions(signed: false, decimal: true),
        controller: controller,
        decoration: InputDecoration(
          hintText: '0',
          labelText: label,
          suffixText: AppConfig.currencySymbol,
        ),
        focusNode: _focusNode,
        validator: (value) {
          if (value.isEmpty) {
            return notNull ? 'Amount cannot be empty' : null;
          }

          final double numVal = double.tryParse(value.replaceFirst(String.fromCharCode(AppConfig.decimalSeparator), '.'));

          if (numVal == null) {
            return 'Amount is not a valid number';
          }

          if (notNull && numVal == 0) {
            return 'Amount should be greater than 0';
          }
        },
      );

}
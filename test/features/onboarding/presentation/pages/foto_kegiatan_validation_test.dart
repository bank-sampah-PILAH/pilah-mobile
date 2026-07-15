import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the `FormField<File>` wiring used for "Foto Kegiatan" in
/// RegisterBankSampahScreen.
///
/// The real screen needs a cubit, a router and an image picker to build, none of
/// which this behaviour depends on. What matters — and what QA reported missing
/// — is that the photo participates in Form.validate() like every other required
/// field, rather than failing separately.
class _PhotoFieldHarness extends StatefulWidget {
  const _PhotoFieldHarness();

  @override
  State<_PhotoFieldHarness> createState() => _PhotoFieldHarnessState();
}

class _PhotoFieldHarnessState extends State<_PhotoFieldHarness> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
              ),
              FormField<File>(
                initialValue: _selectedImage,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (file) =>
                    file == null ? 'Foto kegiatan wajib diunggah' : null,
                builder: (field) {
                  final errorColor = Theme.of(field.context).colorScheme.error;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => _selectedImage = File('fake.jpg'));
                          field.didChange(_selectedImage);
                        },
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: field.hasError
                                  ? errorColor
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: const Text('Pilih foto'),
                        ),
                      ),
                      if (field.hasError)
                        Text(
                          field.errorText!,
                          style: TextStyle(color: errorColor),
                        ),
                    ],
                  );
                },
              ),
              ElevatedButton(
                onPressed: () {
                  if (!(_formKey.currentState?.validate() ?? false)) return;
                  submitted = true;
                },
                child: const Text('Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('Foto Kegiatan validation', () {
    testWidgets('submitting with no photo shows the inline error', (tester) async {
      await tester.pumpWidget(const _PhotoFieldHarness());

      expect(find.text('Foto kegiatan wajib diunggah'), findsNothing);

      await tester.tap(find.text('Daftar'));
      await tester.pump();

      expect(
        find.text('Foto kegiatan wajib diunggah'),
        findsOneWidget,
        reason: 'the photo must report inline like the other required fields',
      );
    });

    testWidgets('the photo error appears alongside the text field errors',
        (tester) async {
      await tester.pumpWidget(const _PhotoFieldHarness());

      await tester.tap(find.text('Daftar'));
      await tester.pump();

      // The whole form reports at once — this is the inconsistency QA hit,
      // where every field turned red except the picker.
      expect(find.text('Nama wajib diisi'), findsOneWidget);
      expect(find.text('Foto kegiatan wajib diunggah'), findsOneWidget);
    });

    testWidgets('picking a photo clears the error without another submit',
        (tester) async {
      await tester.pumpWidget(const _PhotoFieldHarness());

      await tester.tap(find.text('Daftar'));
      await tester.pump();
      expect(find.text('Foto kegiatan wajib diunggah'), findsOneWidget);

      await tester.tap(find.text('Pilih foto'));
      await tester.pump();

      expect(
        find.text('Foto kegiatan wajib diunggah'),
        findsNothing,
        reason: 'didChange should clear the error as soon as a photo is chosen',
      );
    });

    testWidgets('a missing photo blocks submission', (tester) async {
      await tester.pumpWidget(const _PhotoFieldHarness());
      final state = tester.state<_PhotoFieldHarnessState>(
        find.byType(_PhotoFieldHarness),
      );

      await tester.enterText(find.byType(TextFormField), 'Bank Sampah BTH');
      await tester.tap(find.text('Daftar'));
      await tester.pump();

      expect(state.submitted, isFalse,
          reason: 'validate() must fail while the photo is missing');
    });
  });
}

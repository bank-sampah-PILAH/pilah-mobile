import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/authentication_bloc.dart';
import 'package:pilah_mobile/features/authentication/presentation/blocs/events/login_with_reviewer_events.dart';

class ReviewerLoginPanel extends StatefulWidget {
  final Future<bool> Function() loadReviewerLoginEnabled;
  final bool isLoading;

  final bool? isReleaseModeOverride;

  const ReviewerLoginPanel({
    super.key,
    required this.loadReviewerLoginEnabled,
    this.isLoading = false,
    this.isReleaseModeOverride,
  });

  @override
  State<ReviewerLoginPanel> createState() => _ReviewerLoginPanelState();
}

class _ReviewerLoginPanelState extends State<ReviewerLoginPanel>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoadingConfig = true;
  bool _enabled = false;
  bool _configFailed = false;

  bool get _isRelease => widget.isReleaseModeOverride ?? kReleaseMode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_isRelease) {
      _loadConfig();
    } else {
      _isLoadingConfig = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRelease) {
      _loadConfig();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoadingConfig = true;
      _enabled = false;
      _configFailed = false;
    });
    try {
      final enabled = await widget.loadReviewerLoginEnabled();
      if (!mounted) return;
      setState(() {
        _enabled = enabled;
        _isLoadingConfig = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _configFailed = true;
        _isLoadingConfig = false;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthenticationBloc>().add(
          LoginWithReviewerRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isRelease) return const SizedBox.shrink();
    if (_isLoadingConfig) {
      return Semantics(
        label: 'Memuat opsi login peninjau',
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    if (_configFailed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Opsi login peninjau tidak dapat dimuat.'),
          TextButton(
            onPressed: _loadConfig,
            child: const Text('Coba muat ulang'),
          ),
        ],
      );
    }
    if (!_enabled) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Login peninjau',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                enableSuggestions: false,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Masukkan email.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Kata sandi'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Masukkan kata sandi.'
                    : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.isLoading ? null : _submit,
                  child: const Text('Masuk dengan akun peninjau'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

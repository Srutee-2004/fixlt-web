import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Role role = Role.user;
  bool hide = true;
  final email = TextEditingController(text: 'nadia@fixit.app');
  final pass = TextEditingController(text: 'password123');

  static const emails = {
    Role.user: 'nadia@fixit.app',
    Role.worker: 'srutee@fixit.app',
    Role.admin: 'admin@fixit.app',
  };

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  void pick(Role r) => setState(() {
        role = r;
        email.text = emails[r]!;
      });

  void signIn() {
    app.login(role);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => shellFor(role)));
  }

  String get _roleName => switch (role) {
        Role.user => 'User',
        Role.worker => 'Worker',
        Role.admin => 'Admin',
      };

  String get _roleHint => switch (role) {
        Role.user => 'Post jobs, compare workers, track progress and rate the work.',
        Role.worker => 'Find nearby jobs, send offers and manage your assignments.',
        Role.admin => 'Verify workers, manage categories and resolve disputes.',
      };

  Widget _brand() => Container(
        padding: const EdgeInsets.all(56),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [C.navy, Color(0xFF2B4A8B)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.handyman_rounded, color: Colors.white, size: 36),
              SizedBox(width: 12),
              Text('FixIt',
                  style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 28),
            const Text('Hire verified local\nskilled workers, fast.',
                style: TextStyle(
                    color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, height: 1.2)),
            const SizedBox(height: 16),
            const Text(
                'An on-demand, location-aware marketplace connecting Users with independent, verified Workers.',
                style: TextStyle(color: C.onDarkMuted, fontSize: 16, height: 1.5)),
            const SizedBox(height: 36),
            for (final f in const [
              (Icons.place_outlined, 'GPS-first job matching by distance'),
              (Icons.compare_arrows_rounded, 'Transparent offers & counter-offers'),
              (Icons.verified_user_outlined, 'NID-verified workers'),
              (Icons.star_outline_rounded, 'Ratings that build trust'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  Icon(f.$1, color: Colors.white70),
                  const SizedBox(width: 12),
                  Text(f.$2, style: const TextStyle(color: Colors.white, fontSize: 15)),
                ]),
              ),
            const SizedBox(height: 40),
            const Text('CSE-3240 · Leading University, Sylhet',
                style: TextStyle(color: C.onDarkMuted)),
          ],
        ),
      );

  Widget _form() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Welcome back',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: C.navy)),
          const SizedBox(height: 6),
          const Text('Choose a role to explore the demo.', style: TextStyle(color: C.muted)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<Role>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: Role.user, label: Text('User'), icon: Icon(Icons.person_outline)),
                ButtonSegment(
                    value: Role.worker, label: Text('Worker'), icon: Icon(Icons.construction_rounded)),
                ButtonSegment(
                    value: Role.admin,
                    label: Text('Admin'),
                    icon: Icon(Icons.admin_panel_settings_outlined)),
              ],
              selected: {role},
              onSelectionChanged: (s) => pick(s.first),
            ),
          ),
          const SizedBox(height: 10),
          Text(_roleHint, style: const TextStyle(color: C.muted, fontSize: 13)),
          const SizedBox(height: 22),
          TextField(
            controller: email,
            decoration: const InputDecoration(
                labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: pass,
            obscureText: hide,
            onSubmitted: (_) => signIn(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => hide = !hide),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: signIn, child: Text('Sign in as $_roleName')),
          ),
          const SizedBox(height: 16),
          const Text('Demo system: no real account needed. All data is in memory.',
              style: TextStyle(color: C.muted, fontSize: 12)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= 900;
        final form = Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 40 : 24),
            child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: _form()),
          ),
        );
        if (!wide) return form;
        return Row(children: [Expanded(flex: 6, child: _brand()), Expanded(flex: 5, child: form)]);
      }),
    );
  }
}

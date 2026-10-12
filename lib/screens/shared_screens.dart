import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HelpScreen extends StatelessWidget {
  final Role role;
  const HelpScreen({super.key, required this.role});

  static const _faq = [
    ('How does a job move through FixIt?',
        'Every job follows Pending -> Assigned -> In progress -> Completed. Cancelled jobs are kept for history.'),
    ('How is payment handled?',
        'Payment is cash on completion. In-app payments are planned for a later phase.'),
    ('How are workers verified?',
        'Workers upload their NID document. An Admin reviews it and approves or rejects the worker before they can see jobs.'),
    ('What if something goes wrong?',
        'Open the job and use "Report a problem". An Admin reviews the dispute and records a resolution.'),
  ];

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Help & support',
      subtitle: 'Answers to common questions',
      children: [
        for (final f in _faq)
          AppCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(f.$1,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: C.navy)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(f.$2, style: const TextStyle(color: C.muted))],
              ),
            ),
          ),
        const AppCard(
          child: Row(children: [
            Icon(Icons.mail_outline_rounded, color: C.blue),
            SizedBox(width: 12),
            Expanded(child: Text('Still stuck? Email support@fixit.app')),
          ]),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool push = true, location = true, sms = false;

  Widget _row(String t, String sub, bool v, ValueChanged<bool> on) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, color: C.navy)),
          subtitle: Text(sub),
          value: v,
          onChanged: on,
        ),
      );

  @override
  Widget build(BuildContext context) => PageFrame(
        title: 'Settings',
        children: [
          _row('Push notifications', 'Offers, assignments and ratings', push,
              (v) => setState(() => push = v)),
          _row('Location access', 'Used to show nearby jobs and workers', location,
              (v) => setState(() => location = v)),
          _row('SMS alerts', 'Get texts for important updates', sms,
              (v) => setState(() => sms = v)),
          const AppCard(
            child: Row(children: [
              Icon(Icons.language_rounded, color: C.navy),
              SizedBox(width: 12),
              Expanded(child: Text('Language')),
              Text('English', style: TextStyle(color: C.muted)),
            ]),
          ),
        ],
      );
}

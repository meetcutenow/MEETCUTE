

//NE KORISTIMO!!!!!!!!!!! PRIVREMENO!!!!!!





import 'package:flutter/material.dart';

const Color _primaryDark = Color(0xFF700D25);
const Color _primaryLight = Color(0xFFF2E8E9);

// ──────────────────────────────────────────────────────────────────────────────
// EVENTS NEARBY
// ──────────────────────────────────────────────────────────────────────────────
class EventsNearbyScreen extends StatelessWidget {
  const EventsNearbyScreen({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(
    title: 'Events Nearby',
    icon: Icons.calendar_today_outlined,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// ORGANIZE MEET-UP
// ──────────────────────────────────────────────────────────────────────────────
class OrganizeMeetupScreen extends StatelessWidget {
  const OrganizeMeetupScreen({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(
    title: 'Organize a Meet-Up',
    icon: Icons.alarm_outlined,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// FILTER MATCHES
// ──────────────────────────────────────────────────────────────────────────────
class FilterMatchesScreen extends StatelessWidget {
  const FilterMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(
    title: 'Filter Your Matches',
    icon: Icons.filter_list_outlined,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// CHAT
// ──────────────────────────────────────────────────────────────────────────────
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(
    title: 'Chat',
    icon: Icons.chat_bubble_outline_rounded,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// NOTIFICATIONS
// ──────────────────────────────────────────────────────────────────────────────
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(
    title: 'Notifications',
    icon: Icons.notifications_none_rounded,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// PROFILE
// ──────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(
    title: 'Profile',
    icon: Icons.person_outline_rounded,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// SETTINGS
// ──────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => _PlaceholderScreen(
    title: 'Settings',
    icon: Icons.settings_outlined,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// SHARED PLACEHOLDER WIDGET
// ──────────────────────────────────────────────────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEBEBEB),
      appBar: AppBar(
        backgroundColor: _primaryLight,
        foregroundColor: _primaryDark,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: _primaryDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _primaryLight,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _primaryDark.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: _primaryDark, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: _primaryDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: TextStyle(
                color: _primaryDark.withOpacity(0.45),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
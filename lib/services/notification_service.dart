import 'package:overlay_support/overlay_support.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static void showNewEventNotification(String eventTitle, String eventDate) {
    showSimpleNotification(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_available, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'NUOVO EVENTO!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            eventTitle,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          Text(
            eventDate,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
      background: const Color(0xFF8B0000), // Rosso Guzzi
      duration: const Duration(seconds: 5),
    );
  }

  static void showPushNotification(String title, String body) {
    showSimpleNotification(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              body,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      background: const Color(0xFF8B0000),
      duration: const Duration(seconds: 5),
    );
  }

  static void showEventReminderNotification(
    String eventTitle,
    String eventDate,
  ) {
    showSimpleNotification(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'PROMEMORIA EVENTO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            eventTitle,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          Text(
            'Tra 3 giorni - $eventDate',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
      background: const Color(0xFF8B0000),
      duration: const Duration(seconds: 6),
    );
  }
}

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
}
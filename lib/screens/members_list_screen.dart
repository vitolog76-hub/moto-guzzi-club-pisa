import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MembersListScreen extends StatelessWidget {
  const MembersListScreen({super.key});

  static const Color guzziRed = Color(0xFF8B0000);

  static String _displayFullName(Map<String, dynamic> data) {
    final nome = (data['nome'] ?? '').toString().trim();
    final cognome = (data['cognome'] ?? '').toString().trim();
    if (nome.isEmpty && cognome.isEmpty) {
      return 'Senza nome';
    }
    if (cognome.isEmpty) {
      return nome;
    }
    if (nome.isEmpty) {
      return cognome;
    }
    return '$nome $cognome';
  }

  static String? _grado(Map<String, dynamic> data) {
    final g = data['grado'];
    if (g == null) return null;
    final s = g.toString().trim();
    return s.isEmpty ? null : s;
  }

  static String _moto(Map<String, dynamic> data) {
    final m = data['modelloMoto'];
    if (m == null) return '—';
    final s = m.toString().trim();
    return s.isEmpty ? '—' : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Soci registrati',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: guzziRed,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: guzziRed),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Errore: ${snapshot.error}'),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Nessun utente trovato',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final items = docs.map((d) => MapEntry(d.id, d.data())).toList()
            ..sort(
              (a, b) => _displayFullName(a.value).toLowerCase().compareTo(
                _displayFullName(b.value).toLowerCase(),
              ),
            );

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = items[index].value;
              final fullName = _displayFullName(data);
              final grado = _grado(data);
              final moto = _moto(data);

              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (grado != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: guzziRed.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: guzziRed.withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                grado,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: guzziRed,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.two_wheeler,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              moto,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

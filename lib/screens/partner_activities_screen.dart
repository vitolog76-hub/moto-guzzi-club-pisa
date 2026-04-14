import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/partner_activity_service.dart';

class PartnerActivitiesScreen extends StatefulWidget {
  const PartnerActivitiesScreen({super.key});

  @override
  State<PartnerActivitiesScreen> createState() =>
      _PartnerActivitiesScreenState();
}

class _PartnerActivitiesScreenState extends State<PartnerActivitiesScreen> {
  final PartnerActivityService _service = PartnerActivityService();
  static const Color guzziRed = Color(0xFF8B0000);

  Future<void> _openGoogleMaps(String indirizzo) async {
    final query = indirizzo.trim();
    if (query.isEmpty) return;

    final encodedAddress = Uri.encodeComponent(query);
    final url =
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossibile aprire Google Maps'),
          backgroundColor: guzziRed,
        ),
      );
    }
  }

  Future<void> _showActivityForm({
    Map<String, dynamic>? existing,
    String? docId,
  }) async {
    final nomeController = TextEditingController(
      text: existing?['nomeAttivita']?.toString() ?? '',
    );
    final indirizzoController = TextEditingController(
      text: existing?['indirizzo']?.toString() ?? '',
    );
    final telefonoController = TextEditingController(
      text: existing?['telefono']?.toString() ?? '',
    );
    final cellulareController = TextEditingController(
      text: existing?['cellulare']?.toString() ?? '',
    );
    final emailController = TextEditingController(
      text: existing?['email']?.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          docId == null ? 'Nuova attività convenzionata' : 'Modifica attività',
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome attività',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci il nome attività'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: indirizzoController,
                  decoration: const InputDecoration(
                    labelText: 'Indirizzo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci l\'indirizzo'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Telefono',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci il telefono'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: cellulareController,
                  decoration: const InputDecoration(
                    labelText: 'Cellulare',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Inserisci il cellulare'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Inserisci l\'email';
                    }
                    if (!v.contains('@')) {
                      return 'Email non valida';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULLA'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: guzziRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (docId == null) {
                await _service.createActivity(
                  nomeAttivita: nomeController.text,
                  indirizzo: indirizzoController.text,
                  telefono: telefonoController.text,
                  cellulare: cellulareController.text,
                  email: emailController.text,
                );
              } else {
                await _service.updateActivity(
                  id: docId,
                  nomeAttivita: nomeController.text,
                  indirizzo: indirizzoController.text,
                  telefono: telefonoController.text,
                  cellulare: cellulareController.text,
                  email: emailController.text,
                );
              }
              if (context.mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Text(docId == null ? 'SALVA' : 'AGGIORNA'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            docId == null ? 'Attività inserita' : 'Attività aggiornata',
          ),
          backgroundColor: guzziRed,
        ),
      );
    }
  }

  Future<void> _openDialer(String number) async {
    final trimmed = number.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.parse('tel:$trimmed');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;
    final uri = Uri.parse('mailto:$trimmed');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _deleteActivity(String id, String nome) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina attività'),
        content: Text('Vuoi eliminare "$nome"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULLA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ELIMINA'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteActivity(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Attività eliminata'),
            backgroundColor: guzziRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isAdmin = authService.isAdmin();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Negozi e Attivita\' Convenzionati',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: guzziRed,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showActivityForm(),
              backgroundColor: guzziRed,
              icon: const Icon(Icons.add_business, color: Colors.white),
              label: const Text(
                'ATTIVITA\'',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.streamActivities(),
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
                child: Text('Errore caricamento attività: ${snapshot.error}'),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Nessuna attività convenzionata disponibile',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final nome = (data['nomeAttivita'] ?? '').toString();
              final indirizzo = (data['indirizzo'] ?? '').toString();
              final telefono = (data['telefono'] ?? '').toString();
              final cellulare = (data['cellulare'] ?? '').toString();
              final email = (data['email'] ?? '').toString();

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nome,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isAdmin) ...[
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              color: guzziRed,
                              tooltip: 'Modifica',
                              onPressed: () => _showActivityForm(
                                existing: data,
                                docId: doc.id,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red,
                              tooltip: 'Elimina',
                              onPressed: () => _deleteActivity(doc.id, nome),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openDialer(telefono),
                              child: Text(
                                telefono,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.smartphone_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openDialer(cellulare),
                              child: Text(
                                cellulare,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openEmail(email),
                              child: Text(
                                email,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _openGoogleMaps(indirizzo),
                              child: Text(
                                indirizzo,
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
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

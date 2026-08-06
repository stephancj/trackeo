import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'promotions_repository.dart';

class ReferralView extends ConsumerWidget {
  const ReferralView({super.key});

  static void navigateTo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReferralView()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(referralInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parrainer un Ami'),
        elevation: 0,
      ),
      body: referralAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Erreur de chargement: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (info) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  color: const Color(0xFF2563EB),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: const [
                        Icon(Icons.card_giftcard, size: 48, color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Offrez 20% & Gagnez 1 Mois Gratuit !',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Partagez votre code parrain. Votre ami reçoit 20% de remise sur son 1er abonnement, et vous gagnez 30 jours offerts dès son premier paiement !',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Code Parrain Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Votre Code Parrain',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: SelectableText(
                                  info.referralCode,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              icon: const Icon(Icons.copy),
                              tooltip: 'Copier le code',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: info.referralCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Code parrain copié !')),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Section
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                '${info.totalReferred}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(height: 4),
                              const Text('Filleuls Inscrits', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                '${info.qualifiedCount}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              const SizedBox(height: 4),
                              const Text('Abonnements Validés', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Historique des parrainages
                const Text(
                  'Vos Filleuls',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (info.referrals.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'Aucun filleul parrainé pour le moment.\nPartagez votre code pour gagner vos premiers mois offerts !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: info.referrals.length,
                    itemBuilder: (context, index) {
                      final item = info.referrals[index] as Map<String, dynamic>;
                      final status = item['status'] as String? ?? 'pending';
                      final isRewarded = status == 'rewarded' || status == 'qualified';

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRewarded ? Colors.green.shade100 : Colors.orange.shade100,
                            child: Icon(
                              isRewarded ? Icons.check : Icons.hourglass_empty,
                              color: isRewarded ? Colors.green : Colors.orange,
                              size: 20,
                            ),
                          ),
                          title: Text('Filleul #${item['refereeId']}'),
                          subtitle: Text(
                            isRewarded ? 'Abonnement actif — Récompense attribuée !' : 'Inscrit — En attente du 1er abonnement',
                            style: TextStyle(
                              fontSize: 12,
                              color: isRewarded ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/services/cep_service.dart';
import '../providers/customer_providers.dart';

class AddressSelectionSheet extends ConsumerStatefulWidget {
  const AddressSelectionSheet({super.key});

  @override
  ConsumerState<AddressSelectionSheet> createState() =>
      _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends ConsumerState<AddressSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingCep = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchAndAddAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Se tiver formato de CEP (8 dígitos)
    final clean = query.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 8) {
      setState(() => _isLoadingCep = true);
      final cepResult = await CepService.searchCep(clean);
      setState(() => _isLoadingCep = false);

      if (cepResult != null && !cepResult.erro) {
        final newAddr = AddressModel(
          id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
          label: cepResult.bairro.isNotEmpty ? cepResult.bairro : 'Endereço',
          street: cepResult.logradouro.isNotEmpty ? cepResult.logradouro : query,
          number: 'S/N',
          neighborhood: cepResult.bairro,
          city: cepResult.localidade,
          state: cepResult.uf,
          cep: cepResult.cep,
          isDefault: false,
        );

        ref.read(savedAddressesProvider.notifier).update((list) => [...list, newAddr]);
        ref.read(currentAddressProvider.notifier).set(newAddr);
        if (mounted) Navigator.pop(context);
        return;
      }
    }

    String street = query;
    String number = 'S/N';
    String neighborhood = 'Centro';

    if (query.contains('-')) {
      final parts = query.split('-');
      neighborhood = parts.last.trim();
      street = parts.first.trim();
    } else if (query.contains(',')) {
      final parts = query.split(',');
      street = parts[0].trim();
      if (parts.length > 1) {
        final sec = parts[1].trim();
        final matchNum = RegExp(r'^\d+').firstMatch(sec);
        if (matchNum != null) {
          number = matchNum.group(0)!;
          final remaining = sec.substring(number.length).trim();
          if (remaining.isNotEmpty) neighborhood = remaining;
        } else {
          neighborhood = sec;
        }
      }
      if (parts.length > 2) {
        neighborhood = parts[2].trim();
      }
    }

    final newAddr = AddressModel(
      id: 'addr-${DateTime.now().millisecondsSinceEpoch}',
      label: neighborhood.isNotEmpty ? neighborhood : 'Meu Endereço',
      street: street,
      number: number,
      neighborhood: neighborhood.isNotEmpty ? neighborhood : 'Centro',
      city: 'São Paulo',
      state: 'SP',
      cep: '01000-000',
      isDefault: false,
    );

    ref.read(savedAddressesProvider.notifier).update((list) => [...list, newAddr]);
    ref.read(currentAddressProvider.notifier).set(newAddr);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final addresses = ref.watch(savedAddressesProvider);
    final current = ref.watch(currentAddressProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Onde você quer receber seu gás?',
            style: AppTypography.titleLarge.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 14),

          // Search bar with ViaCEP integration
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _searchAndAddAddress(),
            decoration: InputDecoration(
              hintText: 'Digite o CEP (ex: 01310-100) ou rua...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              suffixIcon: _isLoadingCep
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.add_location_alt_rounded, color: AppColors.primary),
                      onPressed: _searchAndAddAddress,
                    ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'ENDEREÇOS SALVOS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          ...addresses.map((addr) {
            final isSelected = addr.id == current.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: ListTile(
                onTap: () {
                  ref.read(currentAddressProvider.notifier).set(addr);
                  Navigator.pop(context);
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    addr.label == 'Casa' ? Icons.home_rounded : Icons.work_rounded,
                    size: 20,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                title: Text(
                  addr.label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  '${addr.street}, ${addr.number} - ${addr.neighborhood}',
                  style: AppTypography.bodySmall,
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primary)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}

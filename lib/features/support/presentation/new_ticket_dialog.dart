import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/support_providers.dart';

class NewTicketDialog extends ConsumerStatefulWidget {
  final String? relatedOrderId;

  const NewTicketDialog({super.key, this.relatedOrderId});

  @override
  ConsumerState<NewTicketDialog> createState() => _NewTicketDialogState();
}

class _NewTicketDialogState extends ConsumerState<NewTicketDialog> {
  String _selectedCategory = 'Atraso na Entrega';
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final List<String> _categories = [
    'Atraso na Entrega',
    'Problema com Pagamento / Maquininha',
    'Botijão Avariado ou Lacre Violado',
    'Dúvida Financeira da Loja / Comissão',
    'Outros Assuntos',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.relatedOrderId != null) {
      _subjectController.text = 'Dúvida sobre o Pedido ${widget.relatedOrderId}';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitTicket() {
    if (_subjectController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      return;
    }

    ref.read(supportTicketsProvider.notifier).createTicket(
          requesterName: 'Carlos Eduardo Silva',
          requesterRole: 'customer',
          category: _selectedCategory,
          subject: _subjectController.text.trim(),
          initialMessage: _messageController.text.trim(),
          relatedOrderId: widget.relatedOrderId,
        );

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chamado aberto com sucesso! Nosso suporte responderá em instantes.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.headset_mic_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          Text('Novo Chamado de Ajuda'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Motivo do Contato'),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Assunto Breve',
                hintText: 'Ex.: Entregador não localizou o interfone',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descreva a ocorrência',
                hintText: 'Explique detalhadamente para agilizar o suporte...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submitTicket,
          child: const Text('Enviar Chamado'),
        ),
      ],
    );
  }
}

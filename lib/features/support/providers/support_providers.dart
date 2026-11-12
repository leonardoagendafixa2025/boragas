import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../core/services/backend_config_service.dart';
import '../../../core/services/remote_config_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../auth/providers/auth_provider.dart';

final supportTicketsProvider =
    NotifierProvider<SupportTicketsNotifier, List<SupportTicketModel>>(
  SupportTicketsNotifier.new,
);

class SupportTicketsNotifier extends Notifier<List<SupportTicketModel>> {
  static const _prefKeyTickets = 'boragas_support_tickets_cache_v2';
  static const _prefKeyAdminPhone = 'boragas_baileys_admin_connected_phone';

  @override
  List<SupportTicketModel> build() {
    ref.listen(authProvider, (prev, next) {
      if (prev?.user?.id != next.user?.id || prev?.user?.role != next.user?.role) {
        _loadTickets();
      }
    });
    _loadTickets();
    return const [];
  }

  /// Método público para recarregar chamados do backend/Supabase em tempo real
  Future<void> refreshTickets() async {
    await _loadTickets();
  }

  /// Carrega os chamados do cache local, sincroniza com o Backend centralizado e com o Supabase
  Future<void> _loadTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_prefKeyTickets);
      if (cachedJson != null && cachedJson.isNotEmpty && state.isEmpty) {
        final rawList = jsonDecode(cachedJson) as List;
        final list = rawList
            .map((item) => SupportTicketModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        state = list;
      }

      final auth = ref.read(authProvider);
      final currentUser = auth.user;
      final isAdmin = currentUser?.role == UserRole.admin;

      // 1. Sincroniza com o Backend Centralizado BoraGás (Render)
      try {
        final backendUrl = BackendConfigService.baseUrl;
        final queryParam = isAdmin
            ? 'role=admin'
            : (currentUser != null
                ? 'requester_id=${currentUser.id}&role=${currentUser.role.name}'
                : '');
        final uri = Uri.parse('$backendUrl/api/v1/support/tickets${queryParam.isNotEmpty ? "?$queryParam" : ""}');
        final res = await http.get(uri).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body['success'] == true && body['data'] is List) {
            final rawBackendList = body['data'] as List;
            if (rawBackendList.isNotEmpty) {
              final backendTickets = rawBackendList.map((item) {
                final map = Map<String, dynamic>.from(item as Map);
                return SupportTicketModel(
                  id: map['id']?.toString() ?? '',
                  ticketNumber: map['ticketNumber']?.toString() ?? '#SUP-0000',
                  requesterId: map['requesterId']?.toString() ?? '',
                  requesterName: map['requesterName']?.toString() ?? 'Cliente BoraGás',
                  requesterPhone: map['requesterPhone']?.toString(),
                  requesterEmail: map['requesterEmail']?.toString(),
                  requesterRole: map['requesterRole']?.toString() ?? 'customer',
                  category: map['category']?.toString() ?? 'Outros',
                  subject: map['subject']?.toString() ?? 'Suporte',
                  status: TicketStatus.values.firstWhere(
                    (s) => s.name == map['status']?.toString(),
                    orElse: () => TicketStatus.open,
                  ),
                  relatedOrderId: map['relatedOrderId']?.toString(),
                  createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
                  updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
                  messages: (map['messages'] as List? ?? []).map((m) {
                    final msgMap = Map<String, dynamic>.from(m as Map);
                    return SupportMessageModel(
                      id: msgMap['id']?.toString() ?? '',
                      ticketId: map['id']?.toString() ?? '',
                      senderId: msgMap['senderId']?.toString() ?? '',
                      senderName: msgMap['senderName']?.toString() ?? 'Usuário',
                      senderRole: msgMap['senderRole']?.toString() ?? 'customer',
                      content: msgMap['content']?.toString() ?? '',
                      sentAt: DateTime.tryParse(msgMap['sentAt']?.toString() ?? '') ?? DateTime.now(),
                    );
                  }).toList(),
                );
              }).toList();

              _mergeTicketsPreservingLocal(backendTickets);
              return;
            }
          }
        }
      } catch (backendErr) {
        debugPrint('Aviso ao sincronizar tickets com backend central: $backendErr');
      }

      // 2. Tenta sincronizar com o Supabase se disponível
      if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
        if (currentUser != null) {
          var query = SupabaseService.client
              .from('support_tickets')
              .select('*, support_messages(*)');

          // Clientes e Lojistas veem apenas os seus chamados; Admins veem todos
          if (!isAdmin) {
            query = query.eq('requester_id', currentUser.id);
          }

          final response = await query.order('created_at', ascending: false);
          if (response.isNotEmpty) {
            final remoteTickets = response.map((data) {
              final map = Map<String, dynamic>.from(data as Map);
              final rawMsgs = map['support_messages'] as List? ?? [];
              final messages = rawMsgs
                  .map((m) => SupportMessageModel.fromJson(Map<String, dynamic>.from(m as Map)))
                  .toList();
              // Ordena mensagens por data
              messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
              map['messages'] = messages.map((m) => m.toJson()).toList();
              return SupportTicketModel.fromJson(map);
            }).toList();

            _mergeTicketsPreservingLocal(remoteTickets);
          }
        }
      }
    } catch (e) {
      debugPrint('Aviso ao carregar chamados de suporte: $e');
    }
  }

  void _mergeTicketsPreservingLocal(List<SupportTicketModel> incoming) {
    final merged = <String, SupportTicketModel>{};
    for (final t in incoming) {
      merged[t.id] = t;
    }
    for (final local in state) {
      final remote = merged[local.id];
      if (remote == null || local.messages.length >= remote.messages.length) {
        merged[local.id] = local;
      }
    }
    final result = merged.values.toList();
    result.sort((a, b) => (b.updatedAt ?? b.createdAt).compareTo(a.updatedAt ?? a.createdAt));
    state = result;
    _persistTickets(result);
  }

  Future<void> _persistTickets(List<SupportTicketModel> tickets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = tickets.map((t) => t.toJson()).toList();
      await prefs.setString(_prefKeyTickets, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Erro ao persistir chamados: $e');
    }
  }

  /// Busca o número real de WhatsApp do Admin conectado via QR Code no Baileys Hub
  Future<String> getActiveAdminSupportPhone() async {
    try {
      final backendUrl = BackendConfigService.baseUrl;
      final res = await http
          .get(Uri.parse('$backendUrl/api/v1/whatsapp/status'))
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final connectedPhone = body['data']['connectedPhone'] as String?;
          if (connectedPhone != null && connectedPhone.isNotEmpty) {
            final clean = connectedPhone.replaceAll(RegExp(r'\D'), '');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_prefKeyAdminPhone, clean);
            return clean;
          }
        }
      }
    } catch (e) {
      debugPrint('Aviso ao obter status do WhatsApp Baileys: $e');
    }

    // Fallback para cache local salvo anteriormente
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefKeyAdminPhone);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    } catch (_) {}

    // Fallback final: suporte configurado no RemoteConfig
    final remotePhone = ref.read(remoteConfigProvider).supportContactPhone;
    final digits = remotePhone.replaceAll(RegExp(r'\D'), '');
    return digits.isNotEmpty ? digits : '5511987654321';
  }

  /// CRIAÇÃO REAL DE CHAMADO COM PROTOCOLO E NOTIFICAÇÃO NO WHATSAPP DO ADMIN
  Future<SupportTicketModel> createTicket({
    required String category,
    required String subject,
    required String initialMessage,
    String? relatedOrderId,
  }) async {
    final auth = ref.read(authProvider);
    final user = auth.user;

    final requesterId = user?.id ?? 'usr-${DateTime.now().millisecondsSinceEpoch}';
    final requesterName = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim()
        : 'Cliente BoraGás';
    final requesterPhone = user?.phone ?? '';
    final requesterEmail = user?.email ?? '';
    final requesterRole = user?.role.name ?? 'customer';

    // Gera protocolo único e verificável: ex: #SUP-2026-7492
    final year = DateTime.now().year;
    final seq = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    final protocol = '#SUP-$year-$seq';

    final ticketId = 'tkt-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();

    final initialMsg = SupportMessageModel(
      id: 'msg-${now.millisecondsSinceEpoch}',
      ticketId: ticketId,
      senderId: requesterId,
      senderName: requesterName,
      senderRole: requesterRole,
      content: initialMessage,
      sentAt: now,
    );

    final newTicket = SupportTicketModel(
      id: ticketId,
      ticketNumber: protocol,
      requesterId: requesterId,
      requesterName: requesterName,
      requesterPhone: requesterPhone,
      requesterEmail: requesterEmail,
      requesterRole: requesterRole,
      category: category,
      subject: subject,
      status: TicketStatus.open,
      relatedOrderId: relatedOrderId,
      createdAt: now,
      updatedAt: now,
      messages: [initialMsg],
    );

    SupportTicketModel finalTicket = newTicket;

    // 1. Tenta criar no Backend Centralizado (Render) para visibilidade instantânea do Admin
    try {
      final backendUrl = BackendConfigService.baseUrl;
      final res = await http.post(
        Uri.parse('$backendUrl/api/v1/support/tickets'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'category': category,
          'subject': subject,
          'initialMessage': initialMessage,
          'requesterId': requesterId,
          'requesterName': requesterName,
          'requesterPhone': requesterPhone,
          'requesterEmail': requesterEmail,
          'requesterRole': requesterRole,
          'relatedOrderId': relatedOrderId,
        }),
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 201 || res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body['success'] == true && body['data'] != null) {
          final m = Map<String, dynamic>.from(body['data'] as Map);
          finalTicket = SupportTicketModel(
            id: m['id']?.toString() ?? ticketId,
            ticketNumber: m['ticketNumber']?.toString() ?? protocol,
            requesterId: m['requesterId']?.toString() ?? requesterId,
            requesterName: m['requesterName']?.toString() ?? requesterName,
            requesterPhone: m['requesterPhone']?.toString() ?? requesterPhone,
            requesterEmail: m['requesterEmail']?.toString() ?? requesterEmail,
            requesterRole: m['requesterRole']?.toString() ?? requesterRole,
            category: m['category']?.toString() ?? category,
            subject: m['subject']?.toString() ?? subject,
            status: TicketStatus.open,
            relatedOrderId: m['relatedOrderId']?.toString() ?? relatedOrderId,
            createdAt: now,
            updatedAt: now,
            messages: [initialMsg],
          );
        }
      }
    } catch (e) {
      debugPrint('Aviso backend ao criar ticket: $e');
    }

    // 2. Atualiza estado e persiste localmente imediatamente
    state = [finalTicket, ...state];
    await _persistTickets(state);

    // 3. Persiste no Supabase se conectado
    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.from('support_tickets').insert({
          'id': finalTicket.id,
          'ticket_number': finalTicket.ticketNumber,
          'requester_id': requesterId,
          'requester_name': requesterName,
          'requester_phone': requesterPhone,
          'requester_email': requesterEmail,
          'category': category,
          'subject': subject,
          'status': 'open',
          'order_id': relatedOrderId,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });

        await SupabaseService.client.from('support_messages').insert({
          'id': initialMsg.id,
          'ticket_id': finalTicket.id,
          'sender_id': requesterId,
          'sender_name': requesterName,
          'sender_role': requesterRole,
          'content': initialMessage,
          'created_at': now.toIso8601String(),
        });
      } catch (dbErr) {
        debugPrint('Aviso Supabase ao salvar ticket: $dbErr');
      }
    }

    // 4. Dispara aviso real no WhatsApp do Admin conectado ao Baileys Hub
    _notifyAdminOnWhatsApp(
      ticket: finalTicket,
      messageText: initialMessage,
    );

    return finalTicket;
  }

  /// ENVIO DE NOVA MENSAGEM NO CHAT DE SUPORTE (CLIENTE OU ADMIN)
  Future<void> addMessage({
    required String ticketId,
    required String content,
  }) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return;

    final auth = ref.read(authProvider);
    final user = auth.user;

    final senderId = user?.id ?? 'usr-reply';
    final senderName = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim()
        : 'Suporte BoraGás';
    final senderRole = user?.role.name ?? 'customer';
    final now = DateTime.now();

    final newMsg = SupportMessageModel(
      id: 'msg-${now.millisecondsSinceEpoch}',
      ticketId: ticketId,
      senderId: senderId,
      senderName: senderRole == 'admin' ? 'Suporte Oficial BoraGás' : senderName,
      senderRole: senderRole,
      content: cleanContent,
      sentAt: now,
    );

    SupportTicketModel? updatedTicket;

    state = state.map((t) {
      if (t.id == ticketId) {
        // Se o admin responder um ticket 'open', passa para 'inProgress'
        final nextStatus = (senderRole == 'admin' && t.status == TicketStatus.open)
            ? TicketStatus.inProgress
            : t.status;

        updatedTicket = t.copyWith(
          status: nextStatus,
          updatedAt: now,
          messages: [...t.messages, newMsg],
        );
        return updatedTicket!;
      }
      return t;
    }).toList();

    await _persistTickets(state);

    // Envia ao Backend Centralizado (Render)
    try {
      final backendUrl = BackendConfigService.baseUrl;
      await http.post(
        Uri.parse('$backendUrl/api/v1/support/tickets/$ticketId/messages'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'content': cleanContent,
          'senderId': senderId,
          'senderName': newMsg.senderName,
          'senderRole': senderRole,
        }),
      ).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('Aviso backend ao adicionar mensagem: $e');
    }

    // Persiste no Supabase
    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.from('support_messages').insert({
          'id': newMsg.id,
          'ticket_id': ticketId,
          'sender_id': senderId,
          'sender_name': newMsg.senderName,
          'sender_role': senderRole,
          'content': cleanContent,
          'created_at': now.toIso8601String(),
        });

        await SupabaseService.client.from('support_tickets').update({
          'updated_at': now.toIso8601String(),
          'status': updatedTicket?.status.name ?? 'open',
        }).eq('id', ticketId);
      } catch (err) {
        debugPrint('Aviso Supabase ao salvar mensagem: $err');
      }
    }

    // Se a mensagem partiu do cliente, avisa o Admin no WhatsApp
    if (senderRole != 'admin' && updatedTicket != null) {
      _notifyAdminOnWhatsApp(
        ticket: updatedTicket!,
        messageText: cleanContent,
        isUpdate: true,
      );
    }
  }

  /// ATUALIZAÇÃO DE STATUS DO CHAMADO (ABERTO / EM ATENDIMENTO / RESOLVIDO)
  Future<void> updateTicketStatus(String ticketId, TicketStatus newStatus) async {
    final now = DateTime.now();

    state = state.map((t) {
      if (t.id == ticketId) {
        return t.copyWith(status: newStatus, updatedAt: now);
      }
      return t;
    }).toList();

    await _persistTickets(state);

    // Atualiza no Backend Centralizado (Render)
    try {
      final backendUrl = BackendConfigService.baseUrl;
      await http.patch(
        Uri.parse('$backendUrl/api/v1/support/tickets/$ticketId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus.name}),
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}

    if (SupabaseService.isConfigured && SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.from('support_tickets').update({
          'status': newStatus.name,
          'updated_at': now.toIso8601String(),
        }).eq('id', ticketId);
      } catch (e) {
        debugPrint('Erro ao atualizar status do ticket no Supabase: $e');
      }
    }
  }

  /// Dispara a notificação via Baileys WhatsApp Hub
  Future<void> _notifyAdminOnWhatsApp({
    required SupportTicketModel ticket,
    required String messageText,
    bool isUpdate = false,
  }) async {
    try {
      final adminPhone = await getActiveAdminSupportPhone();
      final backendUrl = BackendConfigService.baseUrl;

      final title = isUpdate
          ? '💬 *NOVA MENSAGEM NO SUPORTE - BORAGÁS*'
          : '🚨 *NOVO CHAMADO DE SUPORTE ABERTO - BORAGÁS*';

      final clientInfo = ticket.requesterPhone != null && ticket.requesterPhone!.isNotEmpty
          ? '${ticket.requesterName} (${ticket.requesterPhone})'
          : ticket.requesterName;

      final messagePayload = '''
$title

📋 *Protocolo:* ${ticket.ticketNumber}
👤 *Cliente:* $clientInfo
✉️ *E-mail:* ${ticket.requesterEmail ?? "Não informado"}
📂 *Categoria:* ${ticket.category}
📝 *Assunto:* ${ticket.subject}
${ticket.relatedOrderId != null ? "📦 *Pedido Relacionado:* ${ticket.relatedOrderId}\n" : ""}
💬 *Mensagem:*
"$messageText"

⏱️ *Data/Hora:* ${ticket.createdAt.day.toString().padLeft(2, '0')}/${ticket.createdAt.month.toString().padLeft(2, '0')} às ${ticket.createdAt.hour.toString().padLeft(2, '0')}:${ticket.createdAt.minute.toString().padLeft(2, '0')}
━━━━━━━━━━━━━━━━━━━━
👉 Acesse o Painel do Super Admin > Helpdesk para responder em tempo real.
''';

      await http.post(
        Uri.parse('$backendUrl/api/v1/whatsapp/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': adminPhone,
          'message': messagePayload,
        }),
      ).timeout(const Duration(seconds: 4));

      debugPrint('✅ Notificação de suporte disparada para o WhatsApp Admin ($adminPhone)');
    } catch (e) {
      debugPrint('Aviso ao enviar notificação de suporte no WhatsApp: $e');
    }
  }

  /// Abre o WhatsApp oficial do suporte para conversa direta do cliente
  Future<bool> launchDirectWhatsAppSupport({String? ticketNumber, String? customText}) async {
    final adminPhone = await getActiveAdminSupportPhone();
    final cleanPhone = adminPhone.startsWith('55') ? adminPhone : '55$adminPhone';

    final text = customText ??
        (ticketNumber != null
            ? 'Olá Suporte BoraGás! Preciso de ajuda com meu chamado protocolo $ticketNumber.'
            : 'Olá Suporte BoraGás! Gostaria de atendimento com um atendente.');

    final encodedText = Uri.encodeComponent(text);

    final appUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText');
    final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return true;
      }
    } catch (_) {}

    try {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
      return true;
    } catch (_) {
      return false;
    }
  }
}

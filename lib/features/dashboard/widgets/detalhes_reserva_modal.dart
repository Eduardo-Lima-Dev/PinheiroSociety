import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/detalhes_reserva_controller.dart';
import '../controllers/nova_reserva_controller.dart';
import 'nova_reserva_modal.dart';

class DetalhesReservaModal extends StatefulWidget {
  final int reservaId;
  final String? dataOcorrencia; // yyyy-MM-dd
  final int? horaOcorrencia;    // 0-23

  const DetalhesReservaModal({
    super.key,
    required this.reservaId,
    this.dataOcorrencia,
    this.horaOcorrencia,
  });

  @override
  State<DetalhesReservaModal> createState() => _DetalhesReservaModalState();
}

class _DetalhesReservaModalState extends State<DetalhesReservaModal> {
  String? _formatarData(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      final base = iso.split('T')[0];
      final p = base.split('-');
      if (p.length == 3) {
        return '${p[2]}/${p[1]}/${p[0]}';
      }
      return base;
    } catch (_) {
      return iso;
    }
  }

  String? _formatarHora(int? hora) {
    if (hora == null) return null;
    return '${hora.toString().padLeft(2, '0')}:00';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DetalhesReservaController>().carregarDetalhes(widget.reservaId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Consumer<DetalhesReservaController>(
          builder: (context, controller, _) {
            if (controller.isLoading && controller.reserva == null) {
              return const SizedBox(
                height: 400,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              );
            }

            if (controller.error != null && controller.reserva == null) {
              return SizedBox(
                height: 300,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      controller.error!,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        'Fechar',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  ],
                ),
              );
            }

            final reserva = controller.reserva;
            if (reserva == null) {
              return const SizedBox(
                height: 300,
                child: Center(
                  child: Text('Reserva não encontrada'),
                ),
              );
            }

            final clienteNome = reserva.cliente?['nomeCompleto'] ?? 'Cliente não informado';
            final clienteTelefone = reserva.cliente?['telefone'] ?? '';
            final quadraNome = reserva.quadra?['nome'] ?? 'Quadra não informada';
            final statusCor = _getStatusColor(reserva.status);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Detalhes da Reserva',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusCor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusCor),
                      ),
                      child: Text(
                        _getStatusText(reserva.status),
                        style: GoogleFonts.poppins(
                          color: statusCor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      iconSize: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Informações do Cliente
                _buildSection(
                  'Cliente',
                  Icons.person,
                  [
                    _buildInfoRow('Nome', clienteNome),
                    if (clienteTelefone.isNotEmpty)
                      _buildInfoRow('Telefone', clienteTelefone),
                  ],
                ),

                const SizedBox(height: 16),

                // Informações da Reserva
                _buildSection(
                  'Reserva',
                  Icons.event,
                  [
                    _buildInfoRow('Quadra', quadraNome),
                    _buildInfoRow('Data', _formatarData(widget.dataOcorrencia) ?? reserva.dataFormatada),
                    _buildInfoRow('Horário', _formatarHora(widget.horaOcorrencia) ?? reserva.horaFormatada),
                    _buildInfoRow('Duração', reserva.duracaoFormatada),
                    _buildInfoRow(
                      'Valor',
                      'R\$ ${reserva.precoReais.toStringAsFixed(2)}',
                    ),
                  ],
                ),

                if (reserva.observacoes != null && reserva.observacoes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    'Observações',
                    Icons.notes,
                    [
                      Text(
                        reserva.observacoes!,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],

                if (reserva.recorrente) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.repeat,
                          color: Colors.blue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Esta é uma reserva recorrente',
                          style: GoogleFonts.poppins(
                            color: Colors.blue,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        controller.error!,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Botões de ação
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (reserva.status == 'ATIVA') ...[
                      OutlinedButton.icon(
                        onPressed: controller.isLoading
                            ? null
                            : () => _reagendarReserva(context, controller),
                        icon: const Icon(Icons.edit_calendar, size: 18),
                        label: Text(
                          'Reagendar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: controller.isLoading
                            ? null
                            : () => _confirmarCancelamento(context, controller),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: Text(
                          'Cancelar',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Fechar',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ATIVA':
        return Colors.green;
      case 'CANCELADA':
        return Colors.red;
      case 'CONCLUIDA':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'ATIVA':
        return 'Ativa';
      case 'CANCELADA':
        return 'Cancelada';
      case 'CONCLUIDA':
        return 'Concluída';
      default:
        return status;
    }
  }

  Future<void> _confirmarCancelamento(
    BuildContext context,
    DetalhesReservaController controller,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Cancelar Reserva',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Tem certeza que deseja cancelar esta reserva?',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Não',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Sim, cancelar',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      final sucesso = await controller.cancelarReserva();
      
      if (!context.mounted) return;

      if (sucesso) {
        Navigator.of(context).pop(true); // Retorna true para indicar sucesso
      }
    }
  }

  Future<void> _reagendarReserva(
    BuildContext context,
    DetalhesReservaController controller,
  ) async {
    final reserva = controller.reserva;
    if (reserva == null) return;

    // Criar controller para nova reserva em modo de edição
    final novaReservaController = NovaReservaController();
    
    // Inicializar modo de edição com os dados da reserva atual
    novaReservaController.inicializarModoEdicao(reserva);
    
    // Abrir modal de reagendamento
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: novaReservaController,
        child: const NovaReservaModal(modoEdicao: true),
      ),
    );

    // Se reagendou com sucesso
    if (resultado == true && context.mounted) {
      // Fechar modal de detalhes PRIMEIRO
      Navigator.of(context).pop(true); // Retorna true para indicar sucesso
    }
    
    // Limpar o controller após o uso
    novaReservaController.dispose();
  }
}


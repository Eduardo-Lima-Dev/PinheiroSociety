import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/agendamentos_controller.dart';
import '../controllers/nova_reserva_controller.dart';
import '../widgets/agendamentos_grid.dart';
import '../widgets/legenda_item.dart';
import '../widgets/nova_reserva_modal.dart';

class AgendamentosSection extends StatelessWidget {
  final AgendamentosController controller;

  const AgendamentosSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Text(
                'Agendamentos',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Gerencie as reservas das quadras',
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Barra de controles (Calendário, Navegação de Data e Nova Reserva)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                // Seletor de data com ícone
                Consumer<AgendamentosController>(
                  builder: (context, ctrl, _) => InkWell(
                    onTap: () => _selecionarData(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            ctrl.dataController.text,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Botões de navegação de data
                Consumer<AgendamentosController>(
                  builder: (context, ctrl, _) => Row(
                    children: [
                      _buildNavButton(
                        'Anterior',
                        () => ctrl.irParaDiaAnterior(),
                      ),
                      const SizedBox(width: 8),
                      _buildNavButton(
                        'Hoje',
                        () => ctrl.irParaHoje(),
                        isSelected: _isHoje(ctrl.dataSelecionada),
                      ),
                      const SizedBox(width: 8),
                      _buildNavButton(
                        'Próximo',
                        () => ctrl.irParaProximoDia(),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Botão Nova Reserva
                ElevatedButton.icon(
                  onPressed: () => _abrirNovaReserva(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(
                    'Nova Reserva',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        
        // Timeline label e Legenda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  'Timeline das Quadras',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const LegendaItem(
                  color: Colors.green,
                  label: 'Confirmado',
                ),
                const SizedBox(width: 16),
                const LegendaItem(
                  color: Colors.blue,
                  label: 'Pré-reserva',
                ),
                const SizedBox(width: 16),
                LegendaItem(
                  color: Colors.grey.shade700,
                  label: 'Cliente Fixo',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Grid de agendamentos com navegação de horários
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Consumer<AgendamentosController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  );
                }
                
                if (controller.quadras.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_tennis,
                          size: 64,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma quadra encontrada',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return Row(
                  children: [
                    // Seta esquerda
                    IconButton(
                      onPressed: controller.podePaginaAnterior
                          ? () => controller.paginaAnteriorHorarios()
                          : null,
                      icon: const Icon(Icons.chevron_left),
                      color: Colors.white,
                      disabledColor: Colors.white24,
                      iconSize: 32,
                      tooltip: 'Horários anteriores',
                    ),
                    
                    // Grid
                    Expanded(
                      child: AgendamentosGrid(
                        quadras: controller.quadras,
                        horarios: controller.horariosPaginados,
                        getCorStatus: _getCorStatus,
                      ),
                    ),
                    
                    // Seta direita
                    IconButton(
                      onPressed: controller.podePaginaProxima
                          ? () => controller.proximaPaginaHorarios()
                          : null,
                      icon: const Icon(Icons.chevron_right),
                      color: Colors.white,
                      disabledColor: Colors.white24,
                      iconSize: 32,
                      tooltip: 'Próximos horários',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: controller.dataSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Color(0xFF1B1E21),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dataSelecionada != null) {
      controller.selecionarData(dataSelecionada);
    }
  }

  Color _getCorStatus(String status) {
    switch (status.toLowerCase()) {
      case 'disponivel':
        return const Color(0xFF4CAF50).withOpacity(0.5); // Verde claro mais visível
      case 'confirmado':
        return const Color(0xFF2E7D32); // Verde escuro para confirmado
      case 'pre_reserva':
        return const Color(0xFF2196F3); // Azul para pré-reserva
      case 'cliente_fixo':
        return Colors.grey.shade700; // Cinza para cliente fixo
      case 'ocupado':
      case 'reservado':
        return Colors.red; // Vermelho para ocupado (fallback)
      case 'indisponivel':
        return Colors.grey; // Cinza para indisponível
      default:
        return Colors.grey; // Padrão cinza
    }
  }
  
  Widget _buildNavButton(String label, VoidCallback onPressed, {bool isSelected = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
            ? Colors.white.withOpacity(0.2) 
            : Colors.black.withOpacity(0.3),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
  
  bool _isHoje(DateTime data) {
    final hoje = DateTime.now();
    return data.year == hoje.year && 
           data.month == hoje.month && 
           data.day == hoje.day;
  }
  
  void _abrirNovaReserva(BuildContext context) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ChangeNotifierProvider(
        create: (_) => NovaReservaController(),
        child: const NovaReservaModal(),
      ),
    );

    // Se a reserva foi criada com sucesso, recarregar os agendamentos
    if (resultado == true && context.mounted) {
      controller.carregarDadosAgendamentos();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reserva criada com sucesso!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

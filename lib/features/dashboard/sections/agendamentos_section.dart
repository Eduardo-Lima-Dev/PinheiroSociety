import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/agendamentos_controller.dart';
import '../widgets/agendamentos_grid.dart';
import '../widgets/legenda_item.dart';

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
              const Spacer(),
              // Seletor de data
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      controller.dataController.text,
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _selecionarData(context),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      iconSize: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Legenda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Legenda: ',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 16),
              LegendaItem(
                color: Colors.green,
                label: 'Disponível',
              ),
              const SizedBox(width: 16),
              LegendaItem(
                color: Colors.red,
                label: 'Reservado',
              ),
              const SizedBox(width: 16),
              LegendaItem(
                color: Colors.grey,
                label: 'Indisponível',
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Grid de agendamentos
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
                
                return AgendamentosGrid(
                  quadras: controller.quadras,
                  horarios: controller.horariosDisponiveis,
                  getCorStatus: _getCorStatus,
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
        return Colors.green;
      case 'reservado':
        return Colors.red;
      case 'indisponivel':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

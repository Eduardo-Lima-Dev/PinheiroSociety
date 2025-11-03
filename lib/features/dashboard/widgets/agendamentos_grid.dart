import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/detalhes_reserva_controller.dart';
import 'detalhes_reserva_modal.dart';

class AgendamentosGrid extends StatelessWidget {
  final List<Map<String, dynamic>> quadras;
  final List<String> horarios;
  final Color Function(String) getCorStatus;

  const AgendamentosGrid({
    super.key,
    required this.quadras,
    required this.horarios,
    required this.getCorStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho com horários
        Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                'Quadra',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: horarios.map((hora) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Text(
                        hora,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Linhas das quadras
        Expanded(
          child: ListView.builder(
            itemCount: quadras.length,
            itemBuilder: (context, index) {
              final quadra = quadras[index];
              final nomeQuadra = quadra['nome'] as String;
              final horariosQuadra =
                  (quadra['horarios'] as List<Map<String, dynamic>>?) ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Nome da quadra
                    SizedBox(
                      width: 120,
                      child: Text(
                        nomeQuadra,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Horários da quadra
                    Expanded(
                      child: Row(
                        children: horarios.map((hora) {
                          Map<String, dynamic> horarioQuadra;
                          try {
                            horarioQuadra = horariosQuadra.firstWhere(
                              (h) => h['hora'] == hora,
                            ) as Map<String, dynamic>;
                          } catch (e) {
                            // Se não encontrar, usar valores padrão
                            horarioQuadra = {
                              'hora': hora,
                              'status': 'disponivel',
                              'texto': 'Disponível',
                            };
                          }

                          final status = horarioQuadra['status'] as String;
                          final texto = horarioQuadra['texto'] as String;
                          final cor = getCorStatus(status);
                          final reservaId = horarioQuadra['reservaId'] as int?;

                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 44,
                              child: ElevatedButton(
                                onPressed: reservaId != null
                                    ? () => _abrirDetalhesReserva(
                                          context,
                                          reservaId,
                                          horarioQuadra['ocorrenciaData'] as String?,
                                          horarioQuadra['ocorrenciaHora'] as int?,
                                        )
                                    : () {}, // Botão clicável mesmo quando disponível
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cor,
                                  foregroundColor: status == 'disponivel'
                                      ? Colors.white70
                                      : Colors.white,
                                  disabledBackgroundColor: cor, // Mantém a cor mesmo quando "desabilitado"
                                  disabledForegroundColor: Colors.white70,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  texto,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _abrirDetalhesReserva(
    BuildContext context,
    int reservaId,
    String? ocorrenciaData,
    int? ocorrenciaHora,
  ) {
    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider(
        create: (_) => DetalhesReservaController(),
        child: DetalhesReservaModal(
          reservaId: reservaId,
          dataOcorrencia: ocorrenciaData,
          horaOcorrencia: ocorrenciaHora,
        ),
      ),
    );
  }
}

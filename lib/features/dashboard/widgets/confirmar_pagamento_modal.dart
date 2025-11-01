import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/nova_reserva_controller.dart';

class ConfirmarPagamentoModal extends StatefulWidget {
  const ConfirmarPagamentoModal({super.key});

  @override
  State<ConfirmarPagamentoModal> createState() => _ConfirmarPagamentoModalState();
}

class _ConfirmarPagamentoModalState extends State<ConfirmarPagamentoModal> {
  String? formaPagamentoSelecionada;
  int? percentualPagoSelecionado;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Consumer<NovaReservaController>(
          builder: (context, controller, _) {
            final cliente = controller.clienteSelecionado;
            final quadra = controller.quadraSelecionada;
            final data = controller.dataSelecionada;
            final horario = controller.horarioSelecionado;
            final valorTotal = controller.valorTotal;
            final isPreReserva = percentualPagoSelecionado == 50;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Confirmar Pagamento',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white70),
                      iconSize: 20,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                // Informações da reserva
                _buildInfoRow('Cliente:', cliente?.nomeCompleto ?? ''),
                _buildInfoRow('Campo:', quadra?['nome'] ?? ''),
                _buildInfoRow(
                  'Data/Hora:',
                  data != null && horario != null
                      ? '${data.day.toString().padLeft(2, '0')}/'
                          '${data.month.toString().padLeft(2, '0')}/'
                          '${data.year} às ${horario.horaFormatada}'
                      : '',
                ),
                _buildInfoRow('Valor Total:', 'R\$ ${valorTotal.toStringAsFixed(2)}'),

                const SizedBox(height: 24),

                // Forma de Pagamento
                Text(
                  'Forma de Pagamento',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                _buildFormaPagamentoButton('PIX'),
                const SizedBox(height: 8),
                _buildFormaPagamentoButton('Dinheiro'),
                const SizedBox(height: 8),
                _buildFormaPagamentoButton('Cartão (Crédito/Débito)'),

                const SizedBox(height: 24),

                // Valor do Pagamento
                Text(
                  'Valor do Pagamento',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                _buildValorPagamentoButton(
                  '50% - R\$ ${(valorTotal * 0.5).toStringAsFixed(2)}',
                  50,
                ),
                const SizedBox(height: 8),
                _buildValorPagamentoButton(
                  '100% - R\$ ${valorTotal.toStringAsFixed(2)}',
                  100,
                ),

                if (isPreReserva) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Esta pré-reserva expira em 20 minutos. Confirme o pagamento para garantir a reserva.',
                            style: GoogleFonts.poppins(
                              color: Colors.orange,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (controller.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      controller.error!,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Botões
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: controller.isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'Voltar',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _podeConfirmar() && !controller.isLoading
                          ? () => _confirmarReserva(context, controller)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade700,
                        disabledForegroundColor: Colors.white38,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: controller.isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Confirmar Reserva',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white70,
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

  Widget _buildFormaPagamentoButton(String forma) {
    final isSelected = formaPagamentoSelecionada == forma;
    
    return InkWell(
      onTap: () {
        setState(() {
          formaPagamentoSelecionada = forma;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.2)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.green : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              forma,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValorPagamentoButton(String texto, int percentual) {
    final isSelected = percentualPagoSelecionado == percentual;
    
    return InkWell(
      onTap: () {
        setState(() {
          percentualPagoSelecionado = percentual;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.green.withOpacity(0.2)
              : Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? Colors.green : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              texto,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _podeConfirmar() {
    return formaPagamentoSelecionada != null && 
           percentualPagoSelecionado != null;
  }

  Future<void> _confirmarReserva(
    BuildContext context,
    NovaReservaController controller,
  ) async {
    // Definir os dados de pagamento diretamente no controller ANTES de qualquer operação async
    controller.formaPagamento = formaPagamentoSelecionada;
    controller.percentualPago = percentualPagoSelecionado;
    
    final sucesso = await controller.criarReserva();
    
    if (!mounted) return;

    if (sucesso) {
      // Reset do controller antes de fechar
      controller.reset();
      
      // Fechar apenas o modal de confirmação com resultado true
      Navigator.of(context).pop(true);
    } else {
      // Mostrar mensagem de erro se falhou
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.error ?? 'Erro ao criar reserva',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}


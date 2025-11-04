import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../controllers/nova_reserva_controller.dart';
import '../models/cliente.dart';
import 'confirmar_pagamento_modal.dart';

class NovaReservaModal extends StatefulWidget {
  final bool modoEdicao;
  
  const NovaReservaModal({
    super.key,
    this.modoEdicao = false,
  });

  @override
  State<NovaReservaModal> createState() => _NovaReservaModalState();
}

class _NovaReservaModalState extends State<NovaReservaModal> {
  @override
  void initState() {
    super.initState();
    // Se não estiver em modo de edição, carregar dados
    // (no modo de edição, inicializarModoEdicao já carrega)
    if (!widget.modoEdicao) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NovaReservaController>().carregarDadosIniciais();
      });
    }
  }

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
            if (controller.isLoading) {
              return const SizedBox(
                height: 400,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      controller.modoEdicao ? 'Reagendar Reserva' : 'Nova Reserva',
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

                // Cliente
                _buildLabel('Cliente'),
                const SizedBox(height: 8),
                _buildClienteDropdown(controller),

                const SizedBox(height: 16),

                // Campo (Quadra)
                _buildLabel('Campo'),
                const SizedBox(height: 8),
                _buildQuadraDropdown(controller),

                const SizedBox(height: 16),

                // Data
                _buildLabel('Data'),
                const SizedBox(height: 8),
                _buildDataPicker(controller),

                const SizedBox(height: 16),

                // Horário
                _buildLabel('Horário'),
                const SizedBox(height: 8),
                _buildHorarioDropdown(controller),

                const SizedBox(height: 16),

                // Duração
                _buildLabel('Duração'),
                const SizedBox(height: 8),
                _buildDuracaoDropdown(controller),

                const SizedBox(height: 16),

                // Cliente fixo checkbox
                Row(
                  children: [
                    Checkbox(
                      value: controller.isClienteFixo,
                      onChanged: controller.modoEdicao 
                          ? null 
                          : (value) => controller.toggleClienteFixo(value ?? false),
                      fillColor: WidgetStateProperty.resolveWith<Color>(
                        (states) {
                          if (states.contains(WidgetState.disabled)) {
                            return Colors.white12;
                          }
                          return states.contains(WidgetState.selected)
                              ? Colors.green
                              : Colors.white24;
                        },
                      ),
                    ),
                    Text(
                      'Cliente fixo',
                      style: GoogleFonts.poppins(
                        color: controller.modoEdicao ? Colors.white38 : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                if (controller.isClienteFixo) ...[
                  const SizedBox(height: 8),
                  _buildLabel('Fim da recorrência'),
                  const SizedBox(height: 8),
                  _buildFimRecorrenciaPicker(controller),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Limite máximo: 12 meses (1 ano)',
                          style: GoogleFonts.poppins(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
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
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: controller.podeAvancar()
                          ? () => controller.modoEdicao
                              ? _confirmarReagendamento(context, controller)
                              : _abrirConfirmacaoPagamento(context, controller)
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
                      child: Text(
                        controller.modoEdicao ? 'Confirmar' : 'Avançar',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildClienteDropdown(NovaReservaController controller) {
    // Se não houver clientes, mostrar mensagem
    if (controller.clientes.isEmpty && !controller.isLoading && !controller.modoEdicao) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nenhum cliente cadastrado. Cadastre um cliente primeiro.',
                style: GoogleFonts.poppins(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Se estiver em modo de edição, mostrar campo bloqueado
    if (controller.modoEdicao) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock, color: Colors.white24, size: 18),
            const SizedBox(width: 12),
            Text(
              controller.clienteSelecionado?.nomeCompleto ?? 'Cliente não informado',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButton<Cliente>(
        value: controller.clienteSelecionado,
        hint: Text(
          controller.clientes.isEmpty
              ? 'Nenhum cliente disponível'
              : 'Selecione o cliente',
          style: GoogleFonts.poppins(
            color: Colors.white38,
            fontSize: 14,
          ),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF2A2A2A),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
        items: controller.clientes.map((cliente) {
          return DropdownMenuItem<Cliente>(
            value: cliente,
            child: Text(
              cliente.nomeCompleto,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
        onChanged: controller.clientes.isEmpty
            ? null
            : (cliente) {
                if (cliente != null) {
                  controller.selecionarCliente(cliente);
                }
              },
      ),
    );
  }

  Widget _buildQuadraDropdown(NovaReservaController controller) {
    // Se estiver em modo de edição, mostrar campo bloqueado
    if (controller.modoEdicao) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock, color: Colors.white24, size: 18),
            const SizedBox(width: 12),
            Text(
              controller.quadraSelecionada?['nome'] as String? ?? 'Quadra não informada',
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButton<Map<String, dynamic>>(
        value: controller.quadraSelecionada,
        hint: Text(
          'Selecione o campo',
          style: GoogleFonts.poppins(
            color: Colors.white38,
            fontSize: 14,
          ),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF2A2A2A),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
        items: controller.quadras.map((quadra) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: quadra,
            child: Text(
              quadra['nome'] as String,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
        onChanged: (quadra) {
          if (quadra != null) {
            controller.selecionarQuadra(quadra);
          }
        },
      ),
    );
  }

  Widget _buildDataPicker(NovaReservaController controller) {
    return InkWell(
      onTap: () async {
        final data = await showDatePicker(
          context: context,
          initialDate: controller.dataSelecionada ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.green,
                  onPrimary: Colors.white,
                  surface: Color(0xFF2A2A2A),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (data != null) {
          controller.selecionarData(data);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            Text(
              controller.dataSelecionada != null
                  ? '${controller.dataSelecionada!.day.toString().padLeft(2, '0')}/'
                      '${controller.dataSelecionada!.month.toString().padLeft(2, '0')}/'
                      '${controller.dataSelecionada!.year}'
                  : 'Selecione a data',
              style: GoogleFonts.poppins(
                color: controller.dataSelecionada != null
                    ? Colors.white
                    : Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorarioDropdown(NovaReservaController controller) {
    // Usa horários filtrados por disponibilidade e hora atual
    final horariosDisponiveis = controller.horariosDisponiveisFiltrados;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: controller.isLoadingDisponibilidade
          ? const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            )
          : DropdownButton<int>(
              value: controller.horarioSelecionado?.hora,
              hint: Text(
                horariosDisponiveis.isEmpty
                    ? 'Nenhum horário disponível'
                    : 'Selecione o horário',
                style: GoogleFonts.poppins(
                  color: Colors.white38,
                  fontSize: 14,
                ),
              ),
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: const Color(0xFF2A2A2A),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              items: horariosDisponiveis.map((horario) {
                return DropdownMenuItem<int>(
                  value: horario.hora,
                  child: Text(
                    horario.horaFormatada,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
              onChanged: horariosDisponiveis.isEmpty
                  ? null
                  : (hora) {
                      if (hora != null) {
                        final horario = horariosDisponiveis.firstWhere(
                          (h) => h.hora == hora,
                        );
                        controller.selecionarHorario(horario);
                      }
                    },
            ),
    );
  }

  Widget _buildDuracaoDropdown(NovaReservaController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButton<int>(
        value: controller.duracaoMinutos,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF2A2A2A),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
        items: [60, 90, 120].map((minutos) {
          return DropdownMenuItem<int>(
            value: minutos,
            child: Text(
              '$minutos minutos',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
        onChanged: (minutos) {
          if (minutos != null) {
            controller.selecionarDuracao(minutos);
          }
        },
      ),
    );
  }

  Widget _buildFimRecorrenciaPicker(NovaReservaController controller) {
    final data = controller.dataFimRecorrencia;
    final dataInicial = controller.dataSelecionada ?? DateTime.now();
    final limiteMaximo = dataInicial.add(const Duration(days: 365)); // 12 meses = 365 dias
    
    return InkWell(
      onTap: () async {
        final initial = data ??
            dataInicial.add(const Duration(days: 30));
        
        // Garantir que o initialDate não ultrapasse o limite máximo
        final initialDateSafe = initial.isAfter(limiteMaximo) ? limiteMaximo : initial;
        
        final picked = await showDatePicker(
          context: context,
          initialDate: initialDateSafe,
          firstDate: dataInicial,
          lastDate: limiteMaximo, // Limite de 12 meses (1 ano)
          helpText: 'Selecionar data final (máx. 12 meses)',
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.green,
                  onPrimary: Colors.white,
                  surface: Color(0xFF2A2A2A),
                  onSurface: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          controller.selecionarFimRecorrencia(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_repeat, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data != null
                    ? '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}'
                    : 'Selecione a data final da recorrência',
                style: GoogleFonts.poppins(
                  color: data != null ? Colors.white : Colors.white38,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirConfirmacaoPagamento(
    BuildContext context,
    NovaReservaController controller,
  ) async {
    // Abrir modal de confirmação SEM fechar o modal atual
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: controller,
        child: const ConfirmarPagamentoModal(),
      ),
    );

    // Se a reserva foi criada com sucesso, fechar o modal principal
    if (resultado == true && mounted) {
      Navigator.of(context)
          .pop(true); // Fecha modal de nova reserva com sucesso
    }
  }

  Future<void> _confirmarReagendamento(
    BuildContext context,
    NovaReservaController controller,
  ) async {
    final sucesso = await controller.reagendarReserva();
    
    if (!mounted) return;

    if (sucesso) {
      controller.reset();
      Navigator.of(context).pop(true); // Fecha o modal e retorna true
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.error ?? 'Erro ao reagendar reserva'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}

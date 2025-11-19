import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/quadras_controller.dart';
import '../models/quadra.dart';

class QuadrasSection extends StatelessWidget {
  final QuadrasController controller;

  const QuadrasSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuadrasController>(
      builder: (context, quadrasController, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatsRow(quadrasController),
              const SizedBox(height: 24),
              _buildSearchAndAction(context, quadrasController),
              const SizedBox(height: 16),
              Expanded(child: _buildQuadrasList(context, quadrasController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quadras',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Gerencie as quadras da arena',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(QuadrasController controller) {
    final isLoading = controller.isCarregandoResumo;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total de Quadras',
            value: controller.totalQuadras.toString(),
            icon: Icons.grid_view_rounded,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Quadras Ativas',
            value: controller.totalAtivas.toString(),
            icon: Icons.flash_on,
            iconColor: const Color(0xFF4CAF50),
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Quadras Inativas',
            value: controller.totalInativas.toString(),
            icon: Icons.power_settings_new,
            iconColor: const Color(0xFFFF7043),
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndAction(
    BuildContext context,
    QuadrasController controller,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.buscaController,
            onChanged: controller.atualizarBusca,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou tipo de quadra...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1B1E21),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _abrirModalQuadra(context),
          icon: const Icon(Icons.add, color: Colors.black),
          label: Text(
            'Nova Quadra',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF67F373),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuadrasList(
    BuildContext context,
    QuadrasController controller,
  ) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final quadras = controller.quadras;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${controller.totalRegistros} ${controller.totalRegistros == 1 ? 'Quadra' : 'Quadras'}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: controller.error != null
                ? Center(
                    child: Text(
                      controller.error!,
                      style: GoogleFonts.poppins(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  )
                : quadras.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhuma quadra encontrada',
                          style: GoogleFonts.poppins(color: Colors.white54),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: quadras.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) => _QuadraCard(
                          quadra: quadras[index],
                          controller: controller,
                          onEditar: () => _abrirModalQuadra(
                            context,
                            quadra: quadras[index],
                          ),
                          onExcluir: () => _confirmarExclusao(
                            context,
                            controller,
                            quadras[index],
                          ),
                          onAlternarStatus: () => _alternarStatus(
                            context,
                            controller,
                            quadras[index],
                          ),
                        ),
                      ),
          ),
          if (quadras.isNotEmpty || controller.error == null) ...[
            const Divider(color: Colors.white12, height: 1),
            _buildPaginationFooter(controller),
          ],
        ],
      ),
    );
  }

  Widget _buildPaginationFooter(QuadrasController controller) {
    final total = controller.totalRegistros;
    final semResultados = total == 0 || controller.quadras.isEmpty;
    int start = 0;
    int end = 0;

    if (!semResultados) {
      start = ((controller.paginaAtual - 1) * controller.pageSize) + 1;
      if (start > total) start = total;
      end = start + controller.quadras.length - 1;
      if (end > total) end = total;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            semResultados
                ? 'Nenhum registro encontrado'
                : 'Mostrando $start - $end de $total quadras',
            style: GoogleFonts.poppins(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                splashRadius: 20,
                onPressed: controller.paginaAtual > 1
                    ? controller.paginaAnterior
                    : null,
              ),
              Text(
                'Página ${controller.paginaAtual} de ${controller.totalPaginas}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                splashRadius: 20,
                onPressed: controller.paginaAtual < controller.totalPaginas
                    ? controller.proximaPagina
                    : null,
              ),
            ],
          ),
          Row(
            children: [
              Text(
                'Por página:',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1E21),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: controller.pageSize,
                    dropdownColor: const Color(0xFF1B1E21),
                    style: GoogleFonts.poppins(color: Colors.white),
                    items: controller.pageSizeOptions
                        .map(
                          (size) => DropdownMenuItem<int>(
                            value: size,
                            child: Text('$size'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.atualizarPageSize(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _abrirModalQuadra(
    BuildContext context, {
    Quadra? quadra,
  }) async {
    controller.prepararFormulario(quadra);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: controller,
          child: Dialog(
            backgroundColor: const Color(0xFF1B1E21),
            insetPadding: const EdgeInsets.all(32),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: 460,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _QuadraForm(
                  onSuccess: () {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          quadra == null
                              ? 'Quadra criada com sucesso!'
                              : 'Quadra atualizada com sucesso!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    controller.prepararFormulario(null);
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    QuadrasController controller,
    Quadra quadra,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1E21),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Excluir quadra',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Deseja excluir ${quadra.nome}? Esta ação não pode ser desfeita.',
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5F5F),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Excluir',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final sucesso = await controller.excluirQuadra(quadra);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Quadra excluída com sucesso!'
              : controller.error ?? 'Não foi possível excluir a quadra.',
        ),
        backgroundColor: sucesso ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _alternarStatus(
    BuildContext context,
    QuadrasController controller,
    Quadra quadra,
  ) async {
    final sucesso = await controller.alternarStatus(quadra);
    if (!context.mounted) return;
    if (!sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(controller.error ?? 'Não foi possível alterar o status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _QuadraCard extends StatelessWidget {
  final Quadra quadra;
  final QuadrasController controller;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final VoidCallback onAlternarStatus;

  const _QuadraCard({
    required this.quadra,
    required this.controller,
    required this.onEditar,
    required this.onExcluir,
    required this.onAlternarStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isAlternando =
        controller.quadrasAtualizandoStatus.contains(quadra.id);
    final isExcluindo = controller.quadrasExcluindo.contains(quadra.id);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1F12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quadra.nome,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (quadra.tipo != null && quadra.tipo!.isNotEmpty)
                      _ChipLabel(
                        label: quadra.tipo!,
                        background: const Color(0xFF1A2F23),
                        color: const Color(0xFF67F373),
                      ),
                    _ChipLabel(
                      label: quadra.ativa ? 'Ativa' : 'Inativa',
                      background: quadra.ativa
                          ? const Color(0xFF1E3825)
                          : const Color(0xFF3B2617),
                      color: quadra.ativa
                          ? const Color(0xFF5EE687)
                          : const Color(0xFFFFB86C),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                onPressed: onEditar,
              ),
              isExcluindo
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.redAccent),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white54),
                      onPressed: onExcluir,
                    ),
              const SizedBox(width: 4),
              isAlternando
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.power_settings_new,
                        color: quadra.ativa
                            ? const Color(0xFF67F373)
                            : Colors.white54,
                      ),
                      onPressed: onAlternarStatus,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool isLoading;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = Colors.white,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121D17),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      value,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String label;
  final Color background;
  final Color color;

  const _ChipLabel({
    required this.label,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _QuadraForm extends StatelessWidget {
  final VoidCallback onSuccess;

  const _QuadraForm({required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return Consumer<QuadrasController>(
      builder: (context, controller, child) {
        final isEdicao = controller.quadraEmEdicao != null;
        return Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isEdicao ? 'Editar quadra' : 'Nova quadra',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEdicao
                    ? 'Atualize as informações da quadra selecionada'
                    : 'Informe os dados para cadastrar a nova quadra',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nome da quadra',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Quadra Society A',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da quadra';
                  }
                  if (value.trim().length < 2) {
                    return 'O nome deve ter pelo menos 2 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  controller.statusSelecionado
                      ? 'Quadra ativa'
                      : 'Quadra inativa',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  controller.statusSelecionado
                      ? 'A quadra ficará disponível para reservas'
                      : 'A quadra ficará indisponível para uso',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                value: controller.statusSelecionado,
                onChanged: controller.setStatusSelecionado,
                activeColor: const Color(0xFF67F373),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: controller.isSaving
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      child: Text(
                        'Cancelar',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.isSaving
                          ? null
                          : () async {
                              final sucesso = await controller.salvarQuadra();
                              if (sucesso && context.mounted) {
                                onSuccess();
                              } else if (!sucesso && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      controller.error ??
                                          'Não foi possível salvar a quadra',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF67F373),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            )
                          : Text(
                              'Salvar',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

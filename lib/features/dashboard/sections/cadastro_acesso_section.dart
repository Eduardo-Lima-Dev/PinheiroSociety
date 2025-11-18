import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/cadastro_acesso_controller.dart';
import '../models/user_access.dart';

class CadastroAcessoSection extends StatelessWidget {
  final CadastroAcessoController controller;

  const CadastroAcessoSection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CadastroAcessoController>(
      builder: (context, cadastroController, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStatsRow(cadastroController),
              const SizedBox(height: 24),
              _buildSearchAndAction(context, cadastroController),
              const SizedBox(height: 16),
              Expanded(
                  child: _buildFuncionariosTable(context, cadastroController)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationFooter(CadastroAcessoController controller) {
    final total = controller.totalRegistros;
    final semResultados = total == 0 || controller.funcionarios.isEmpty;
    int start = 0;
    int end = 0;

    if (!semResultados) {
      start = ((controller.paginaAtual - 1) * controller.pageSize) + 1;
      if (start > total) start = total;
      end = start + controller.funcionarios.length - 1;
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
                : 'Mostrando $start - $end de $total funcionários',
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gerenciamento de acesso',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cadastre e gerencie os funcionários',
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(CadastroAcessoController controller) {
    final isLoading = controller.isCarregandoResumo;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total de Funcionários',
            value: controller.totalFuncionarios.toString(),
            titleColor: Colors.white70,
            valueColor: Colors.white,
            background: const Color(0xFF153119),
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Ativos',
            value: controller.totalAtivos.toString(),
            titleColor: const Color(0xFF5EE687),
            valueColor: Colors.white,
            background: const Color(0xFF0E2615),
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Inativos',
            value: controller.totalInativos.toString(),
            titleColor: const Color(0xFFFFC87A),
            valueColor: Colors.white,
            background: const Color(0xFF2F1A10),
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndAction(
    BuildContext context,
    CadastroAcessoController controller,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.buscaController,
            onChanged: controller.atualizarBusca,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar por nome ou CPF...',
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
        _StatusFilterDropdown(controller: controller),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _abrirModalFuncionario(context),
          icon: const Icon(Icons.add, color: Colors.black),
          label: Text(
            'Novo Funcionário',
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

  Widget _buildFuncionariosTable(
    BuildContext context,
    CadastroAcessoController controller,
  ) {
    if (controller.isCarregandoFuncionarios) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final funcionarios = controller.funcionarios;

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
          _buildTableHeader(),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: funcionarios.isEmpty
                ? Center(
                    child: Text(
                      controller.funcionariosError ??
                          'Nenhum funcionário encontrado',
                      style: GoogleFonts.poppins(color: Colors.white54),
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    itemCount: funcionarios.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: Colors.white10,
                      height: 1,
                    ),
                    itemBuilder: (_, index) => _buildFuncionarioRow(
                        context, controller, funcionarios[index]),
                  ),
          ),
          const Divider(color: Colors.white12, height: 1),
          _buildPaginationFooter(controller),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: const [
          _TableHeaderCell(text: 'Nome', flex: 3),
          _TableHeaderCell(text: 'CPF', flex: 2),
          _TableHeaderCell(text: 'Status', flex: 1),
          _TableHeaderCell(text: 'Tipo', flex: 1),
          _TableHeaderCell(text: 'Cadastrado em', flex: 2),
          _TableHeaderCell(text: 'Ações', flex: 1, alignEnd: true),
        ],
      ),
    );
  }

  Widget _buildFuncionarioRow(
    BuildContext context,
    CadastroAcessoController controller,
    UserAccess funcionario,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          _TableCellText(
            text: funcionario.name,
            flex: 3,
            primary: true,
          ),
          _TableCellText(
            text: _formatarCpf(funcionario.cpf),
            flex: 2,
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusChip(funcionario.ativo),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildRoleChip(funcionario.role),
            ),
          ),
          _TableCellText(
            text: _formatarData(funcionario.createdAt),
            flex: 2,
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                  onPressed: () => _abrirModalFuncionario(
                    context,
                    funcionario: funcionario,
                  ),
                ),
                controller.usuarioIdEmExclusao == funcionario.id
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.white54),
                        onPressed: () => _confirmarExclusao(
                            context, controller, funcionario),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool ativo) {
    final color = ativo ? const Color(0xFF5EE687) : const Color(0xFFFFB86C);
    final bgColor = ativo ? const Color(0xFF1E3825) : const Color(0xFF3B2617);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        ativo ? 'Ativo' : 'Inativo',
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    final normalized = role.toUpperCase();
    final isAdmin = normalized == 'ADMIN';
    final label = isAdmin ? 'Administrador' : 'Funcionário';
    final color = isAdmin ? const Color(0xFF4DA8FF) : const Color(0xFF67F373);
    final bgColor = isAdmin ? const Color(0xFF11283A) : const Color(0xFF18331F);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.5)),
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

  String _formatarCpf(String? cpf) {
    if (cpf == null || cpf.isEmpty) return '--';
    final digits = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11) return cpf;
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }

  String _formatarData(DateTime? data) {
    if (data == null) return '--';
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();
    return '$dia/$mes/$ano';
  }

  Future<void> _abrirModalFuncionario(
    BuildContext context, {
    UserAccess? funcionario,
  }) async {
    controller.prepararFormularioParaEdicao(funcionario);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ChangeNotifierProvider<CadastroAcessoController>.value(
          value: controller,
          child: Dialog(
            backgroundColor: const Color(0xFF1B1E21),
            insetPadding: const EdgeInsets.all(32),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SizedBox(
              width: 520,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _NovoFuncionarioForm(
                  onSuccess: () async {
                    await controller.carregarFuncionarios();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    controller.prepararFormularioParaEdicao(null);
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    CadastroAcessoController controller,
    UserAccess funcionario,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1E21),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Confirmar exclusão',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Deseja realmente excluir ${funcionario.name}? Esta ação não pode ser desfeita.',
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

    final messenger = ScaffoldMessenger.of(context);
    final sucesso = await controller.excluirUsuario(funcionario);

    if (!context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Funcionário excluído com sucesso!'
              : controller.error ?? 'Não foi possível excluir o funcionário.',
        ),
        backgroundColor: sucesso ? Colors.green : Colors.red,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color titleColor;
  final Color valueColor;
  final Color background;
  final bool isLoading;

  const _StatCard({
    required this.title,
    required this.value,
    required this.titleColor,
    required this.valueColor,
    required this.background,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          isLoading
              ? const SizedBox(
                  height: 32,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: valueColor,
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool alignEnd;

  const _TableHeaderCell({
    required this.text,
    required this.flex,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TableCellText extends StatelessWidget {
  final String text;
  final int flex;
  final bool primary;

  const _TableCellText({
    required this.text,
    required this.flex,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          color: primary ? Colors.white : Colors.white70,
          fontSize: 14,
          fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _StatusFilterDropdown extends StatelessWidget {
  final CadastroAcessoController controller;

  const _StatusFilterDropdown({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<String>(
        value: controller.statusFiltroSelecionado,
        dropdownColor: const Color(0xFF1B1E21),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
        decoration: InputDecoration(
          labelText: 'Status',
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF1B1E21),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        items: controller.statusFiltroOptions.map((option) {
          return DropdownMenuItem<String>(
            value: option['value'],
            child: Text(option['label'] ?? ''),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.atualizarStatusFiltro(value);
          }
        },
      ),
    );
  }
}

class _NovoFuncionarioForm extends StatelessWidget {
  final Future<void> Function() onSuccess;

  const _NovoFuncionarioForm({
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CadastroAcessoController>(
      builder: (context, controller, child) {
        final isEditando = controller.usuarioEmEdicao != null;
        return Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEditando ? 'Editar funcionário' : 'Novo funcionário',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditando
                      ? 'Atualize os dados do funcionário selecionado'
                      : 'Preencha os dados para criar um novo acesso',
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                _ModalFieldLabel(text: 'Nome Completo'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.nomeController,
                  keyboardType: TextInputType.name,
                  style: const TextStyle(color: Colors.white),
                  decoration: _modalInputDecoration('João da Silva'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome completo';
                    }
                    if (value.length < 2) {
                      return 'O nome deve ter pelo menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _ModalFieldLabel(text: 'Email'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _modalInputDecoration('exemplo@exemplo.com'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o email';
                    }
                    final emailRegex =
                        RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _ModalFieldLabel(text: 'CPF'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.cpfController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [controller.cpfMaskFormatter],
                  style: const TextStyle(color: Colors.white),
                  decoration: _modalInputDecoration('000.000.000-00'),
                  validator: (value) {
                    final digits =
                        controller.cpfMaskFormatter.getUnmaskedText();
                    if (digits.isEmpty) {
                      return 'Por favor, informe o CPF';
                    }
                    if (digits.length != 11) {
                      return 'CPF deve ter 11 dígitos';
                    }
                    return null;
                  },
                ),
                if (!isEditando) ...[
                  const SizedBox(height: 16),
                  _ModalFieldLabel(text: 'Senha'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.senhaController,
                    obscureText: !controller.senhaVisivel,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        _modalInputDecoration('Mínimo 6 caracteres').copyWith(
                      suffixIcon: IconButton(
                        onPressed: controller.toggleSenhaVisibilidade,
                        icon: Icon(
                          controller.senhaVisivel
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira a senha';
                      }
                      if (value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _ModalFieldLabel(text: 'Confirmar Senha'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.confirmarSenhaController,
                    obscureText: !controller.confirmarSenhaVisivel,
                    style: const TextStyle(color: Colors.white),
                    decoration:
                        _modalInputDecoration('Digite a senha novamente')
                            .copyWith(
                      suffixIcon: IconButton(
                        onPressed: controller.toggleConfirmarSenhaVisibilidade,
                        icon: Icon(
                          controller.confirmarSenhaVisivel
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme a senha';
                      }
                      if (value != controller.senhaController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                _ModalFieldLabel(text: 'Tipo de Usuário'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.roleSelecionada,
                      dropdownColor: const Color(0xFF1B1E21),
                      style: const TextStyle(color: Colors.white),
                      items: controller.rolesDisponiveis.map((role) {
                        return DropdownMenuItem<String>(
                          value: role['value'],
                          child: Text(
                            role['label']!,
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.setRole(value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ModalFieldLabel(text: 'Status'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: controller.statusSelecionado,
                      dropdownColor: const Color(0xFF1B1E21),
                      style: const TextStyle(color: Colors.white),
                      items: controller.statusDisponiveis.map((status) {
                        return DropdownMenuItem<String>(
                          value: status['value'],
                          child: Text(
                            status['label']!,
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.setStatus(value);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          controller.prepararFormularioParaEdicao(null);
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
                        onPressed: controller.isSubmitting
                            ? null
                            : () async {
                                final estavaEditando =
                                    controller.usuarioEmEdicao != null;
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);
                                final sucesso =
                                    await controller.salvarCadastroAcesso();

                                if (context.mounted) {
                                  if (sucesso) {
                                    await onSuccess();
                                    navigator.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          estavaEditando
                                              ? 'Funcionário atualizado com sucesso!'
                                              : 'Funcionário criado com sucesso!',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else if (controller.error != null) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(controller.error!),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
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
                        child: controller.isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black),
                                ),
                              )
                            : Text(
                                isEditando ? 'Salvar alterações' : 'Salvar',
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
          ),
        );
      },
    );
  }

  InputDecoration _modalInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}

class _ModalFieldLabel extends StatelessWidget {
  final String text;

  const _ModalFieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

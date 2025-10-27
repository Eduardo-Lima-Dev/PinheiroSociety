import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import '../controllers/clientes_controller.dart';
import '../widgets/cliente_card.dart';
import '../widgets/cliente_modal.dart';

class ClientesSection extends StatelessWidget {
  final ClientesController controller;

  const ClientesSection({
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
                'Gerenciar Clientes',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _abrirModalCliente(context),
                icon: const Icon(Icons.add),
                label: const Text('Novo Cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Barra de busca
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: controller.searchController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar clientes...',
              hintStyle: GoogleFonts.poppins(color: Colors.white70),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.black.withOpacity(0.25),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Lista de clientes
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Consumer<ClientesController>(
              builder: (context, controller, child) {
                if (controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                  );
                }
                
                if (controller.clientesFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum cliente encontrado',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: controller.clientesFiltrados.length,
                  itemBuilder: (context, index) {
                    final cliente = controller.clientesFiltrados[index];
                    return ClienteCard(
                      cliente: cliente,
                      onEdit: () => _abrirModalCliente(context, cliente: cliente),
                      onDelete: () => _confirmarDeletarCliente(context, cliente),
                      formatCPF: _formatCPF,
                      formatTelefone: _formatTelefone,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _abrirModalCliente(BuildContext context, {cliente}) {
    controller.abrirModalCliente(cliente: cliente);
    
    showDialog(
      context: context,
      builder: (context) => ClienteModal(
        formKey: controller.formKey,
        nomeController: controller.nomeController,
        emailController: controller.emailController,
        telefoneController: controller.telefoneController,
        cpfController: controller.cpfController,
        cpfMaskFormatter: controller.cpfMaskFormatter,
        telefoneMaskFormatter: controller.telefoneMaskFormatter,
        isEditing: controller.isEditing,
        isSubmitting: controller.isSubmitting,
        onSave: () async {
          await controller.salvarCliente();
          if (context.mounted) {
            Navigator.of(context).pop();
            if (controller.error == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(controller.isEditing 
                      ? 'Cliente atualizado com sucesso!' 
                      : 'Cliente criado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(controller.error!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onCancel: () => Navigator.of(context).pop(),
        isValidCPF: _isValidCPF,
        isValidPhone: _isValidPhone,
      ),
    );
  }

  void _confirmarDeletarCliente(BuildContext context, cliente) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E21),
        title: Text(
          'Confirmar Exclusão',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Text(
          'Tem certeza que deseja excluir o cliente ${cliente.nomeCompleto}?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancelar',
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
              'Excluir',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        await controller.deletarCliente(cliente);
        if (context.mounted) {
          if (controller.error == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cliente excluído com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(controller.error!),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  String _formatCPF(String cpf) {
    if (cpf.length == 11) {
      return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.${cpf.substring(6, 9)}-${cpf.substring(9)}';
    }
    return cpf;
  }

  String _formatTelefone(String telefone) {
    if (telefone.length == 11) {
      return '(${telefone.substring(0, 2)}) ${telefone.substring(2, 7)}-${telefone.substring(7)}';
    }
    return telefone;
  }

  bool _isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return false;
    
    // Validação básica de CPF
    if (cpf == '00000000000' || cpf == '11111111111' || 
        cpf == '22222222222' || cpf == '33333333333' ||
        cpf == '44444444444' || cpf == '55555555555' ||
        cpf == '66666666666' || cpf == '77777777777' ||
        cpf == '88888888888' || cpf == '99999999999') {
      return false;
    }
    
    return true;
  }

  bool _isValidPhone(String phone) {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return phone.length == 11;
  }
}

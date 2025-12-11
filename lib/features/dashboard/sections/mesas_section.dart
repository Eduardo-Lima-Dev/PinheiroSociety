import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/mesas_controller.dart';
import '../models/mesa_aberta.dart';
import '../models/cliente.dart';
import '../widgets/comanda_mesa_modal.dart';
import '../../../services/repositories/cliente_repository.dart';

class MesasSection extends StatelessWidget {
  final MesasController controller;

  const MesasSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Consumer<MesasController>(
      builder: (context, mesasController, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              Expanded(
                child: mesasController.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : mesasController.error != null
                        ? _buildError(mesasController.error!)
                        : _buildMesasGrid(context, mesasController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gerenciamento de Mesas',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Controle das comandas/pedidos',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Image.asset(
          'assets/images/Logo.png',
          height: 50,
          width: 50,
        ),
      ],
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar mesas',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => controller.refresh(),
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMesasGrid(BuildContext context, MesasController controller) {
    final mesas = controller.mesas;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1400
        ? 4
        : screenWidth > 1000
            ? 3
            : screenWidth > 600
                ? 2
                : 1;

    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      color: Colors.green,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: mesas.length + 1, // +1 para o botão adicionar
        itemBuilder: (context, index) {
          if (index == mesas.length) {
            return _buildAddMesaCard(context);
          }
          return _buildMesaCard(context, mesas[index]);
        },
      ),
    );
  }

  Widget _buildMesaCard(BuildContext context, MesaAberta mesa) {
    final isOcupada = mesa.ativa;
    // Cores seguindo a imagem: verde para ocupadas, cinza escuro para livres
    final backgroundColor = isOcupada 
        ? const Color(0xFF4CAF50) // Verde similar ao da imagem
        : const Color(0xFF1B1E21); // Cinza escuro padrão do sistema
    final statusText = isOcupada ? 'Ocupada' : 'Livre';
    final statusColor = isOcupada ? Colors.white : Colors.grey[400];

    return GestureDetector(
      onTap: () {
        if (isOcupada) {
          _abrirComandaMesa(context, mesa);
        } else {
          _abrirMesa(context, mesa);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com número da mesa e status (canto superior direito)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mesa.nome,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Informações da mesa ocupada (seguindo layout da imagem)
              if (isOcupada) ...[
                if (mesa.cliente != null) ...[
                  Text(
                    mesa.cliente!,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'R\$ ${mesa.valor.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              // Para mesas livres, não precisa mostrar nada no centro
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddMesaCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _adicionarMesa(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B1E21), // Mantendo cor padrão do sistema
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Quadrado preto com "+" branco (seguindo a imagem)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Adicionar Mesa',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirComandaMesa(BuildContext context, MesaAberta mesa) async {
    // Verificar se a mesa tem cliente associado
    if (mesa.cliente == null || mesa.cliente!.isEmpty) {
      // Se não tem cliente, mostrar lista para associar
      await _associarClienteMesa(context, mesa);
      return;
    }

    // Se tem cliente, abrir modal da comanda
    showDialog(
      context: context,
      builder: (context) => ComandaMesaModal(
        mesa: mesa,
        onMesaFechada: () {
          // Recarregar mesas após fechar a mesa
          controller.refresh();
        },
        onModalFechado: () {
          // Recarregar mesas sempre que o modal for fechado (para atualizar valores)
          controller.refresh();
        },
      ),
    );
  }

  Future<void> _associarClienteMesa(BuildContext context, MesaAberta mesa) async {
    // Buscar lista de clientes
    final clientesResponse = await ClienteRepository.getClientes();
    List<Cliente> clientes = [];

    if (clientesResponse['success'] == true) {
      final data = clientesResponse['data'];
      List<dynamic> clientesData;
      
      if (data is List) {
        clientesData = data;
      } else if (data is Map && data['clientes'] is List) {
        clientesData = data['clientes'];
      } else if (data is Map && data['data'] is List) {
        clientesData = data['data'];
      } else {
        clientesData = [];
      }

      clientes = clientesData
          .map((json) => Cliente.fromJson(json))
          .toList();
    }

    if (clientes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhum cliente cadastrado. Cadastre um cliente primeiro.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Mostrar diálogo para selecionar cliente
    final clienteSelecionado = await showDialog<Cliente>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Associar Cliente à ${mesa.nome}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'A mesa precisa de um cliente para ser ocupada',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Lista de clientes
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: clientes.length,
                  itemBuilder: (context, index) {
                    final cliente = clientes[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            cliente.nomeCompleto.isNotEmpty
                                ? cliente.nomeCompleto[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          cliente.nomeCompleto,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          cliente.telefone,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
                        onTap: () => Navigator.pop(context, cliente),
                      ),
                    );
                  },
                ),
              ),
              // Botão cancelar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (clienteSelecionado != null && context.mounted) {
      final clienteId = int.tryParse(clienteSelecionado.id);
      
      if (clienteId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ID do cliente inválido'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final sucesso = await controller.ocuparMesa(
        id: mesa.id,
        clienteId: clienteId,
      );

      if (context.mounted) {
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cliente associado à ${mesa.nome} com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          // Recarregar mesas
          await controller.refresh();
          // Buscar mesa atualizada e abrir modal da comanda
          if (context.mounted) {
            final mesaAtualizada = controller.mesas.firstWhere(
              (m) => m.id == mesa.id,
              orElse: () => mesa,
            );
            // Aguardar um pouco para garantir que a API processou
            await Future.delayed(const Duration(milliseconds: 300));
            if (context.mounted) {
              _abrirComandaMesa(context, mesaAtualizada);
            }
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.error ?? 'Erro ao associar cliente'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _abrirMesa(BuildContext context, MesaAberta mesa) async {
    // Buscar lista de clientes
    final clientesResponse = await ClienteRepository.getClientes();
    List<Cliente> clientes = [];

    if (clientesResponse['success'] == true) {
      final data = clientesResponse['data'];
      List<dynamic> clientesData;
      
      if (data is List) {
        clientesData = data;
      } else if (data is Map && data['clientes'] is List) {
        clientesData = data['clientes'];
      } else if (data is Map && data['data'] is List) {
        clientesData = data['data'];
      } else {
        clientesData = [];
      }

      clientes = clientesData
          .map((json) => Cliente.fromJson(json))
          .toList();
    }

    if (clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum cliente cadastrado. Cadastre um cliente primeiro.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar diálogo para selecionar cliente
    final clienteSelecionado = await showDialog<Cliente>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Abrir ${mesa.nome}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Selecione um cliente para associar à mesa',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Lista de clientes
              Flexible(
                child: clientes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 64,
                              color: Colors.white30,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum cliente cadastrado',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: clientes.length,
                        itemBuilder: (context, index) {
                          final cliente = clientes[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Text(
                                  cliente.nomeCompleto.isNotEmpty
                                      ? cliente.nomeCompleto[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(
                                cliente.nomeCompleto,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                cliente.telefone,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                                size: 16,
                              ),
                              onTap: () => Navigator.pop(context, cliente),
                            ),
                          );
                        },
                      ),
              ),
              // Botão cancelar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.white12, width: 1),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[800],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (clienteSelecionado != null) {
      final clienteId = int.tryParse(clienteSelecionado.id);
      
      if (clienteId == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ID do cliente inválido'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final sucesso = await controller.ocuparMesa(
        id: mesa.id,
        clienteId: clienteId,
      );

      if (context.mounted) {
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${mesa.nome} aberta com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.error ?? 'Erro ao abrir mesa'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _fecharMesa(BuildContext context, MesaAberta mesa) async {
    // Confirmar fechamento
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Fechar Mesa',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Deseja realmente fechar ${mesa.nome}?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final sucesso = await controller.liberarMesa(mesa.id);

      if (context.mounted) {
        if (sucesso) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${mesa.nome} fechada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.error ?? 'Erro ao fechar mesa'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _adicionarMesa(BuildContext context) async {
    final numeroController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool mesaAtiva = false;
    Cliente? clienteSelecionado;
    
    // Buscar lista de clientes para o dropdown
    final clientesResponse = await ClienteRepository.getClientes();
    List<Cliente> clientes = [];

    if (clientesResponse['success'] == true) {
      final data = clientesResponse['data'];
      List<dynamic> clientesData;
      
      if (data is List) {
        clientesData = data;
      } else if (data is Map && data['clientes'] is List) {
        clientesData = data['clientes'];
      } else if (data is Map && data['data'] is List) {
        clientesData = data['data'];
      } else {
        clientesData = [];
      }

      clientes = clientesData
          .map((json) => Cliente.fromJson(json))
          .toList();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text(
            'Adicionar Nova Mesa',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campo número da mesa
                  TextFormField(
                    controller: numeroController,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Número da Mesa *',
                      labelStyle: GoogleFonts.poppins(color: Colors.white70),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.green),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite o número da mesa';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Digite um número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Checkbox mesa ativa
                  Row(
                    children: [
                      Checkbox(
                        value: mesaAtiva,
                        onChanged: (value) {
                          setState(() {
                            mesaAtiva = value ?? false;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      Text(
                        'Mesa ativa (ocupada)',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Dropdown cliente (opcional)
                  Text(
                    'Cliente (opcional)',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Cliente?>(
                        value: clienteSelecionado,
                        isExpanded: true,
                        hint: Text(
                          'Selecione um cliente (opcional)',
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                        dropdownColor: Colors.grey[800],
                        style: GoogleFonts.poppins(color: Colors.white),
                        items: [
                          const DropdownMenuItem<Cliente?>(
                            value: null,
                            child: Text('Nenhum cliente'),
                          ),
                          ...clientes.map((cliente) {
                            return DropdownMenuItem<Cliente?>(
                              value: cliente,
                              child: Text(cliente.nomeCompleto),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            clienteSelecionado = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final numero = int.tryParse(numeroController.text);
                  if (numero != null) {
                    Navigator.pop(context);
                    
                    final clienteId = clienteSelecionado != null
                        ? int.tryParse(clienteSelecionado!.id)
                        : null;
                    
                    final sucesso = await controller.criarMesa(
                      numero: numero,
                      ativa: mesaAtiva,
                      clienteId: clienteId,
                    );

                    if (context.mounted) {
                      if (sucesso) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Mesa $numero adicionada com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(controller.error ?? 'Erro ao adicionar mesa'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}


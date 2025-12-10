import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/mesas_controller.dart';
import '../models/mesa_aberta.dart';

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
          _showMesaDetails(context, mesa);
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

  void _showMesaDetails(BuildContext context, MesaAberta mesa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          mesa.nome,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Status', mesa.ativa ? 'Ocupada' : 'Livre'),
            if (mesa.cliente != null)
              _buildDetailRow('Cliente', mesa.cliente!),
            _buildDetailRow('Valor', 'R\$ ${mesa.valor.toStringAsFixed(2)}'),
            if (mesa.dataAbertura != null)
              _buildDetailRow(
                'Aberta em',
                '${mesa.dataAbertura!.day}/${mesa.dataAbertura!.month}/${mesa.dataAbertura!.year}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fechar',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _fecharMesa(context, mesa);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fechar Mesa'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _abrirMesa(BuildContext context, MesaAberta mesa) {
    // TODO: Implementar abertura de mesa
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Abrir mesa ${mesa.nome}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _fecharMesa(BuildContext context, MesaAberta mesa) {
    // TODO: Implementar fechamento de mesa
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fechar mesa ${mesa.nome}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _adicionarMesa(BuildContext context) {
    // TODO: Implementar adição de nova mesa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Adicionar nova mesa'),
        backgroundColor: Colors.green,
      ),
    );
  }
}


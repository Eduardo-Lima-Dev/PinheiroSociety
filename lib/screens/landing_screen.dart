import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background da quadra de beach tennis
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Fundo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Overlay escuro para melhorar legibilidade do texto
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          
          // Conteúdo principal
          SafeArea(
            child: Column(
              children: [
                // Header com logo e ícone de usuário
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo ARENA PINHEIRO SOCIETY
                      Image.asset(
                        'assets/images/Logo.png',
                        height: 60,
                        fit: BoxFit.contain,
                      ),
                      
                      // Menu do usuário
                      _buildUserMenu(context),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Conteúdo principal - overlay com texto e botão na lateral direita
                Row(
                  children: [
                    const Spacer(),
                    Container(
                      width: 500,
                      margin: const EdgeInsets.only(right: 20.0, bottom: 20.0),
                      padding: const EdgeInsets.all(30.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]!.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Título principal
                          Text(
                            'Bem-vindo ao Sistema de Reservas da Arena Pinheiro Society',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 15),
                      
                          // Descrição
                          Text(
                            'Chega de complicação! Agende seu jogo em segundos. Com nossa reserva online, você vê os horários livres em tempo real e garante sua quadra sem sair de casa. Simples e rápido!',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                      
                          // Botão de reserva
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'Reserve aqui sua quadra',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Footer
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Arena Pinheiro Society All Rights Reserved Privacy Policy | Terms of Service',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.grey,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 24,
        ),
      ),
      onSelected: (String value) {
        switch (value) {
          case 'login':
            Navigator.of(context).pushNamed('/login');
            break;
          case 'register':
            // TODO: Implementar tela de cadastro
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tela de cadastro será implementada em breve'),
                backgroundColor: Colors.orange,
              ),
            );
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'login',
          child: Row(
            children: [
              Icon(Icons.login, color: Colors.blue),
              SizedBox(width: 8),
              Text('Login'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'register',
          child: Row(
            children: [
              Icon(Icons.person_add, color: Colors.green),
              SizedBox(width: 8),
              Text('Cadastrar'),
            ],
          ),
        ),
      ],
    );
  }
}

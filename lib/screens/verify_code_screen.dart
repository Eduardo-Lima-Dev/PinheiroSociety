import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/repositories/repositories.dart';
import 'reset_password_screen.dart';

class VerifyCodeScreen extends StatefulWidget {
  final String email;

  const VerifyCodeScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerifyCode() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final code = _codeController.text.trim();
      print('🔵 [VERIFY CODE] Validando código para email: ${widget.email}');
      print('🔵 [VERIFY CODE] Código: $code');

      try {
        final result = await AuthRepository.verifyCode(
          email: widget.email,
          code: code,
        );

        print('🟢 [VERIFY CODE] Resultado recebido:');
        print('   - success: ${result['success']}');
        print('   - error: ${result['error']}');
        print('   - data: ${result['data']}');
        print('   - Resultado completo: $result');

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Extrair o resetToken da resposta
          // A resposta vem no formato: {'message': '...', 'resetToken': '...'}
          // E o ApiClient retorna: {'success': true, 'data': {'message': '...', 'resetToken': '...'}}
          final data = result['data'];
          String? resetToken;
          
          if (data != null && data is Map) {
            // Buscar resetToken no objeto data
            resetToken = data['resetToken']?.toString();
            
            if (resetToken == null || resetToken.isEmpty) {
              // Tentar outras possibilidades
              resetToken = data['token']?.toString();
            }
          } else if (data != null && data is String) {
            // Se data for uma string, assumir que é o token
            resetToken = data;
          }
          
          if (resetToken != null && resetToken.isNotEmpty) {
            print('✅ [VERIFY CODE] Código verificado! ResetToken recebido.');
            print('✅ [VERIFY CODE] Token (primeiros 30 chars): ${resetToken.substring(0, resetToken.length > 30 ? 30 : resetToken.length)}...');
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => ResetPasswordScreen(
                    resetToken: resetToken!,
                  ),
                ),
              );
            }
          } else {
            print('❌ [VERIFY CODE] Código verificado mas resetToken não encontrado na resposta');
            print('❌ [VERIFY CODE] Data recebida: $data');
            print('❌ [VERIFY CODE] Tipo de data: ${data?.runtimeType}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Erro: Token de redefinição não recebido. Tente novamente.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          print('❌ [VERIFY CODE] Código inválido: ${result['error']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Código inválido'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        print('🔴 [VERIFY CODE] Exceção capturada:');
        print('   - Erro: $e');
        print('   - Tipo: ${e.runtimeType}');
        print('   - StackTrace: $stackTrace');

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro inesperado: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final containerWidth = isMobile ? screenWidth - 40 : 400.0;

    return Scaffold(
      body: Stack(
        children: [
          // Background do campo de futebol
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Fundo_Login.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Conteúdo principal
          SafeArea(
            child: Column(
              children: [
                // Header com logo e botão voltar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/Logo.png',
                            height: isMobile ? 50 : 60,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balancear o botão voltar
                    ],
                  ),
                ),

                const Spacer(),

                // Formulário de verificação de código centralizado
                Center(
                  child: SingleChildScrollView(
                    child: Container(
                      width: containerWidth,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: EdgeInsets.all(isMobile ? 20 : 30),
                      decoration: BoxDecoration(
                        color: Colors.grey[900]!.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Título
                            Text(
                              'Verificar código',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              'Digite o código de 6 dígitos enviado para:',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 13 : 14,
                                color: Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.email,
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 13 : 14,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),

                            // Campo de Código
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Código',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _codeController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 20 : 24,
                                    letterSpacing: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    hintText: '123456',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: isMobile ? 20 : 24,
                                      letterSpacing: 8,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isMobile ? 14 : 16,
                                    ),
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, insira o código';
                                    }
                                    if (value.length != 6) {
                                      return 'O código deve ter 6 dígitos';
                                    }
                                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                                      return 'O código deve conter apenas números';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),

                            // Botão Verificar
                            SizedBox(
                              width: double.infinity,
                              height: isMobile ? 48 : 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleVerifyCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        'Verificar código',
                                        style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 14 : 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Footer
                Padding(
                  padding: EdgeInsets.all(isMobile ? 15 : 20.0),
                  child: Text(
                    'Arena Pinheiro Society All Rights Reserved. Privacy Policy | Terms of Service.',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 10 : 12,
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
}


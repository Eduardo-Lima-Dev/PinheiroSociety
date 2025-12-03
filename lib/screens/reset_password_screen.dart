import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/repositories/repositories.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? resetToken;
  final String? email;
  final String? code;

  const ResetPasswordScreen({
    super.key,
    this.resetToken,
    this.email,
    this.code,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _codeController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
    _codeController = TextEditingController(text: widget.code ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      // Se temos resetToken, usar ele. Caso contrário, validar email e código (modo legado)
      final resetToken = widget.resetToken;
      
      if (resetToken == null || resetToken.isEmpty) {
        // Modo legado - ainda não implementado no novo fluxo, mas mantido para compatibilidade
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token de redefinição não encontrado. Por favor, verifique o código novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      print('🔵 [RESET PASSWORD] Iniciando redefinição de senha');
      print('🔵 [RESET PASSWORD] ResetToken: $resetToken');

      try {
        final result = await AuthRepository.resetPassword(
          resetToken: resetToken,
          newPassword: _newPasswordController.text,
        );

        print('🟢 [RESET PASSWORD] Resultado recebido:');
        print('   - success: ${result['success']}');
        print('   - error: ${result['error']}');
        print('   - Resultado completo: $result');

        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          print('✅ [RESET PASSWORD] Senha redefinida com sucesso!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Senha redefinida com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
            // Navegar para login após 2 segundos
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              }
            });
          }
        } else {
          print('❌ [RESET PASSWORD] Erro na resposta: ${result['error']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Erro ao redefinir senha'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        print('🔴 [RESET PASSWORD] Exceção capturada:');
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
    final hasResetToken = widget.resetToken != null && widget.resetToken!.isNotEmpty;
    final hasPreFilledData = widget.email != null && widget.code != null;

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

                // Formulário de redefinir senha centralizado
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
                              'Redefinir senha',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 24 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              hasResetToken || hasPreFilledData
                                  ? 'Digite sua nova senha'
                                  : 'Digite o código recebido por email e sua nova senha',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 13 : 14,
                                color: Colors.grey[400],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (hasPreFilledData && widget.email != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.email!,
                                style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 13 : 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 30),

                            // Campo de Email (apenas se não tiver resetToken nem dados preenchidos)
                            if (!hasResetToken && !hasPreFilledData) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 14 : 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: 'exemplo@exemplo.com',
                                      hintStyle:
                                          TextStyle(color: Colors.grey[400]),
                                      filled: true,
                                      fillColor: Colors.grey[800],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira seu email';
                                      }
                                      if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                          .hasMatch(value)) {
                                        return 'Por favor, insira um email válido';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Campo de Código (apenas se não vier preenchido)
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
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
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
                                      if (!RegExp(r'^[0-9]+$')
                                          .hasMatch(value)) {
                                        return 'O código deve conter apenas números';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Campo de Nova Senha
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nova Senha',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: !_isPasswordVisible,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Digite sua nova senha',
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[400],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, insira a nova senha';
                                    }
                                    if (value.length < 6) {
                                      return 'A senha deve ter pelo menos 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Campo de Confirmar Senha
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Confirmar Nova Senha',
                                  style: GoogleFonts.poppins(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: !_isConfirmPasswordVisible,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Confirme sua nova senha',
                                    hintStyle:
                                        TextStyle(color: Colors.grey[400]),
                                    filled: true,
                                    fillColor: Colors.grey[800],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isConfirmPasswordVisible
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey[400],
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isConfirmPasswordVisible =
                                              !_isConfirmPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, confirme a senha';
                                    }
                                    if (value != _newPasswordController.text) {
                                      return 'As senhas não coincidem';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 25),

                            // Botão Redefinir
                            SizedBox(
                              width: double.infinity,
                              height: isMobile ? 48 : 50,
                              child: ElevatedButton(
                                onPressed:
                                    _isLoading ? null : _handleResetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
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
                                        'Redefinir Senha',
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


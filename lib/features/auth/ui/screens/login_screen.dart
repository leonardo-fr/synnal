import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController =
      TextEditingController();

  final _usuarioController =
      TextEditingController();

  final _senhaController =
      TextEditingController();

  final _confirmarSenhaController =
      TextEditingController();

  final _nomeFocusNode =
      FocusNode();

  final _usuarioFocusNode =
      FocusNode();

  final _senhaFocusNode =
      FocusNode();

  final _confirmarSenhaFocusNode =
      FocusNode();

  bool _ocultarSenha = true;
  bool _modoCadastro = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _usuarioController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();

    _nomeFocusNode.dispose();
    _usuarioFocusNode.dispose();
    _senhaFocusNode.dispose();
    _confirmarSenhaFocusNode.dispose();

    super.dispose();
  }

  void _enviar() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_modoCadastro) {
      context.read<AuthBloc>().add(
        AuthCriouUsuario(
          _usuarioController.text.trim(),
          _senhaController.text,
          _nomeController.text.trim(),
        ),
      );

      return;
    }

    context.read<AuthBloc>().add(
      AuthEntrou(
        _usuarioController.text.trim(),
        _senhaController.text,
      ),
    );
  }

  void _alternarModo() {
    setState(() {
      _modoCadastro =
          !_modoCadastro;

      _nomeController.clear();
      _confirmarSenhaController.clear();
    });

    _formKey.currentState?.reset();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_modoCadastro) {
        _nomeFocusNode.requestFocus();
      } else {
        _usuarioFocusNode.requestFocus();
      }
    });
  }

  String? _validarNome(
    String? value,
  ) {
    if (!_modoCadastro) {
      return null;
    }

    if (value == null ||
        value.trim().isEmpty) {
      return 'Informe seu nome';
    }

    if (value.trim().length < 3) {
      return 'Informe um nome válido';
    }

    return null;
  }

  String? _validarUsuario(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Informe o usuário';
    }

    return null;
  }

  String? _validarSenha(
    String? value,
  ) {
    if (value == null ||
        value.isEmpty) {
      return 'Informe a senha';
    }

    if (_modoCadastro &&
        value.length < 6) {
      return 'A senha deve possuir pelo menos 6 caracteres';
    }

    return null;
  }

  String? _validarConfirmacaoSenha(
    String? value,
  ) {
    if (!_modoCadastro) {
      return null;
    }

    if (value == null ||
        value.isEmpty) {
      return 'Confirme a senha';
    }

    if (value !=
        _senhaController.text) {
      return 'As senhas não são iguais';
    }

    return null;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (
        previous,
        current,
      ) {
        return current is AuthEntrarFalha ||
            current
                is AuthCriarUsuarioFalha;
      },
      listener: (
        context,
        state,
      ) {
        final mensagem =
            state is AuthCriarUsuarioFalha
                ? 'Não foi possível criar o usuário.'
                : 'Não foi possível realizar o login.';

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                mensagem,
              ),
            ),
          );
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                32,
              ),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(
                  maxWidth: 420,
                ),
                child: BlocBuilder<
                    AuthBloc,
                    AuthState>(
                  buildWhen: (
                    previous,
                    current,
                  ) {
                    return current
                            is AuthEntrarEmProgresso ||
                        current
                            is AuthCriarUsuarioEmProgresso ||
                        current
                            is AuthEntrarFalha ||
                        current
                            is AuthCriarUsuarioFalha ||
                        previous
                            is AuthEntrarEmProgresso ||
                        previous
                            is AuthCriarUsuarioEmProgresso;
                  },
                  builder: (
                    context,
                    state,
                  ) {
                    final carregando =
                        state
                                is AuthEntrarEmProgresso ||
                            state
                                is AuthCriarUsuarioEmProgresso;

                    return Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .stretch,
                          children: [
                            _cabecalho(),
                            const SizedBox(
                              height: 40,
                            ),

                            if (_modoCadastro) ...[
                              _campoNome(
                                carregando,
                              ),
                              const SizedBox(
                                height: 16,
                              ),
                            ],

                            _campoUsuario(
                              carregando,
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            _campoSenha(
                              carregando,
                            ),

                            if (_modoCadastro) ...[
                              const SizedBox(
                                height: 16,
                              ),
                              _campoConfirmarSenha(
                                carregando,
                              ),
                            ],

                            const SizedBox(
                              height: 24,
                            ),

                            _botaoPrincipal(
                              carregando,
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            _botaoAlternarModo(
                              carregando,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Column(
      children: [
        const Icon(
          Icons.forum_outlined,
          size: 64,
        ),
        const SizedBox(
          height: 16,
        ),
        const Text(
          'Synnal',
          textAlign:
              TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Text(
          _modoCadastro
              ? 'Crie sua conta'
              : 'Entre com sua conta',
          textAlign:
              TextAlign.center,
        ),
      ],
    );
  }

  Widget _campoNome(
    bool carregando,
  ) {
    return TextFormField(
      controller:
          _nomeController,
      focusNode:
          _nomeFocusNode,
      enabled: !carregando,
      autofocus:
          _modoCadastro,
      autofillHints: const [
        AutofillHints.name,
      ],
      textCapitalization:
          TextCapitalization.words,
      textInputAction:
          TextInputAction.next,
      validator:
          _validarNome,
      onFieldSubmitted: (_) {
        _usuarioFocusNode
            .requestFocus();
      },
      decoration:
          const InputDecoration(
        labelText: 'Nome e sobrenome',
        hintText: 'Ex: João de Farias',
        prefixIcon: Icon(
          Icons.badge_outlined,
        ),
        border:
            OutlineInputBorder(),
      ),
    );
  }

  Widget _campoUsuario(
    bool carregando,
  ) {
    return TextFormField(
      controller:
          _usuarioController,
      focusNode:
          _usuarioFocusNode,
      enabled: !carregando,
      autofocus:
          !_modoCadastro,
      autofillHints: const [
        AutofillHints.username,
      ],
      textInputAction:
          TextInputAction.next,
      validator:
          _validarUsuario,
      onFieldSubmitted: (_) {
        _senhaFocusNode
            .requestFocus();
      },
      decoration:
          InputDecoration(
        labelText: 'Usuário',
        hintText:
            _modoCadastro
                ? 'joao'
                : '@usuario:servidor.com',
        prefixIcon:
            const Icon(
          Icons.person_outline,
        ),
        border:
            const OutlineInputBorder(),
      ),
    );
  }

  Widget _campoSenha(
    bool carregando,
  ) {
    return TextFormField(
      controller:
          _senhaController,
      focusNode:
          _senhaFocusNode,
      enabled: !carregando,
      obscureText:
          _ocultarSenha,
      autofillHints: [
        _modoCadastro
            ? AutofillHints
                .newPassword
            : AutofillHints
                .password,
      ],
      textInputAction:
          _modoCadastro
              ? TextInputAction
                  .next
              : TextInputAction
                  .done,
      validator:
          _validarSenha,
      onFieldSubmitted: (_) {
        if (carregando) {
          return;
        }

        if (_modoCadastro) {
          _confirmarSenhaFocusNode
              .requestFocus();

          return;
        }

        _enviar();
      },
      decoration:
          InputDecoration(
        labelText: 'Senha',
        prefixIcon:
            const Icon(
          Icons.lock_outline,
        ),
        suffixIcon:
            IconButton(
          tooltip:
              _ocultarSenha
                  ? 'Mostrar senha'
                  : 'Ocultar senha',
          onPressed:
              carregando
                  ? null
                  : () {
                      setState(
                        () {
                          _ocultarSenha =
                              !_ocultarSenha;
                        },
                      );
                    },
          icon: Icon(
            _ocultarSenha
                ? Icons
                    .visibility_outlined
                : Icons
                    .visibility_off_outlined,
          ),
        ),
        border:
            const OutlineInputBorder(),
      ),
    );
  }

  Widget _campoConfirmarSenha(
    bool carregando,
  ) {
    return TextFormField(
      controller:
          _confirmarSenhaController,
      focusNode:
          _confirmarSenhaFocusNode,
      enabled: !carregando,
      obscureText:
          _ocultarSenha,
      autofillHints: const [
        AutofillHints.newPassword,
      ],
      textInputAction:
          TextInputAction.done,
      validator:
          _validarConfirmacaoSenha,
      onFieldSubmitted: (_) {
        if (!carregando) {
          _enviar();
        }
      },
      decoration:
          const InputDecoration(
        labelText:
            'Confirmar senha',
        prefixIcon:
            Icon(
          Icons.lock_outline,
        ),
        border:
            OutlineInputBorder(),
      ),
    );
  }

  Widget _botaoPrincipal(
    bool carregando,
  ) {
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed:
            carregando
                ? null
                : _enviar,
        child: carregando
            ? const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : Text(
                _modoCadastro
                    ? 'Criar conta'
                    : 'Entrar',
              ),
      ),
    );
  }

  Widget _botaoAlternarModo(
    bool carregando,
  ) {
    return TextButton(
      onPressed:
          carregando
              ? null
              : _alternarModo,
      child: Text(
        _modoCadastro
            ? 'Já tenho uma conta'
            : 'Criar uma conta',
      ),
    );
  }
}
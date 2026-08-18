import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sentinela/helpers/text_uppercase_formater.dart';

/// Campo de placa dividido em 7 caixas individuais (padrão de placa brasileira,
/// Mercosul `ABC1D23` ou antiga `ABC1234`), com avanço automático de foco e
/// voltar ao digitar backspace. Integra com [Form] via `FormField<String>`.
///
/// O valor completo é sincronizado com o [controller] externo: ler por câmera
/// (definir `controller.text`) distribui os caracteres nas caixas.
class PlateInputField extends FormField<String> {
  PlateInputField({
    super.key,
    required TextEditingController controller,
    super.validator,
    this.showCameraButton = false,
    this.onCameraTap,
    ValueChanged<String>? onChanged,
  }) : super(
          initialValue: _assemble(controller.text),
          builder: (state) {
            return _PlateBoxesField(
              controller: controller,
              onChanged: onChanged,
              showCameraButton: showCameraButton,
              onCameraTap: onCameraTap,
              fieldState: state,
            );
          },
        );

  final bool showCameraButton;
  final VoidCallback? onCameraTap;

  static String _assemble(String text) =>
      text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

class _PlateBoxesField extends StatefulWidget {
  const _PlateBoxesField({
    required this.controller,
    required this.onChanged,
    required this.showCameraButton,
    required this.onCameraTap,
    required this.fieldState,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final bool showCameraButton;
  final VoidCallback? onCameraTap;
  final FormFieldState<String> fieldState;

  @override
  State<_PlateBoxesField> createState() => _PlateBoxesFieldState();
}

class _PlateBoxesFieldState extends State<_PlateBoxesField> {
  late final List<TextEditingController> _boxes;
  late final List<FocusNode> _focuses;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _boxes = List.generate(7, (_) => TextEditingController());
    _focuses = List.generate(7, (_) => FocusNode());
    final plate = _assemble(widget.controller.text);
    for (var i = 0; i < 7; i++) {
      _boxes[i].text = i < plate.length ? plate[i] : '';
    }
    widget.controller.addListener(_syncFromExternal);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromExternal);
    for (final c in _boxes) {
      c.dispose();
    }
    for (final f in _focuses) {
      f.dispose();
    }
    super.dispose();
  }

  static String _assemble(String text) =>
      text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Sincroniza as caixas quando o valor externo muda (ex.: leitura por câmera).
  void _syncFromExternal() {
    if (_syncing) return;
    final external = _assemble(widget.controller.text);
    final current = _boxes.map((c) => c.text).join();
    if (external == current) return;
    setState(() {
      for (var i = 0; i < 7; i++) {
        _boxes[i].text = i < external.length ? external[i] : '';
      }
    });
    _emit(fromExternal: true);
  }

  void _onBoxChanged(int index, String value) {
    if (_syncing) return;
    final normalized = value.toUpperCase().isEmpty ? '' : value.toUpperCase()[0];
    setState(() {
      _boxes[index].text = normalized;
    });
    _emit();
    if (normalized.isNotEmpty && index < 6) {
      _focuses[index + 1].requestFocus();
    }
  }

  /// Trata backspace: em caixa vazia, volta o foco para a caixa anterior.
  KeyEventResult _onBoxKey(int index, FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _boxes[index].text.isEmpty &&
        index > 0) {
      _focuses[index - 1].requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _emit({bool fromExternal = false}) {
    final plate = _boxes.map((c) => c.text).join();
    _syncing = true;
    if (widget.controller.text != plate) {
      widget.controller.text = plate;
    }
    _syncing = false;
    widget.fieldState.didChange(plate);
    if (!fromExternal) widget.onChanged?.call(plate);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _Box(
                    controller: _boxes[i],
                    focusNode: _focuses[i],
                    hasError: widget.fieldState.hasError,
                    onChanged: (v) => _onBoxChanged(i, v),
                    onKey: (node, event) => _onBoxKey(i, node, event),
                  ),
                ),
              ),
            if (widget.showCameraButton)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  onPressed: widget.onCameraTap,
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Ler placa pela câmera',
                ),
              ),
          ],
        ),
        if (widget.fieldState.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.fieldState.errorText ?? '',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ),
      ],
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onKey,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final FocusOnKeyEventCallback onKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = hasError ? colorScheme.error : colorScheme.outline;
    return Focus(
      onKeyEvent: onKey,
      child: SizedBox(
        height: 60,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          textCapitalization: TextCapitalization.characters,
          keyboardType: TextInputType.text,
          inputFormatters: [
            UpperCaseTextFormatter(),
            LengthLimitingTextInputFormatter(1),
          ],
          decoration: InputDecoration(
            counterText: '',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

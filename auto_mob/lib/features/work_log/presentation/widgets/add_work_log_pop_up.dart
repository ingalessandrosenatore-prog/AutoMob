import 'package:auto_mob_v1/core/di/injection_container.dart';
import 'package:auto_mob_v1/core/types/enum_pop_up.dart';
import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:auto_mob_v1/core/widgets/buttons/back_button.dart';
import 'package:auto_mob_v1/core/widgets/input/drop_down_react.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_bloc.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_event.dart';
import 'package:auto_mob_v1/features/work_log/presentation/bloc/work_log_state.dart';
import 'package:auto_mob_v1/features/work_log/presentation/pages/midify_item.dart';
import 'package:auto_mob_v1/features/work_log/presentation/widgets/am_expand_cont.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/widgets/blur/am_edge_blur.dart';
import '../../../../core/widgets/card/pup_up_head_card.dart';
import '../../../../core/widgets/input/date_picker_field.dart';
import 'parts_picker_body.dart';

class AddWorkLogPopUp extends StatefulWidget {
  final EnumPopUp initialWorkType;
  final String id;
  final int currentKm;

  const AddWorkLogPopUp({
    super.key,
    required this.initialWorkType,
    required this.id,
    required this.currentKm,
  });

  @override
  State<AddWorkLogPopUp> createState() => _AddWorkLogPopUpState();
}

class _AddWorkLogPopUpState extends State<AddWorkLogPopUp> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousPage() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = sl<WorkLogBloc>(param1: widget.id);
        bloc.add(OnWorkTypeChange(type: widget.initialWorkType));
        // Seed dei km attuali del veicolo: pavimento per la validazione (il km
        // del lavoro non puo' regredire) e base per il "prossimo richiamo".
        bloc.add(InitKm(vehicleKm: widget.currentKm));
        return bloc;
      },
      child: BlocConsumer<WorkLogBloc, WorkLogState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        buildWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == WorkLogStatus.success) {
            final messenger = ScaffoldMessenger.of(context);
            context.pop(true);
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Intervento salvato'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state.status == WorkLogStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? 'Errore durante il salvataggio',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final sheetHeight = MediaQuery.of(context).size.height * 0.85;
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: sheetHeight,
              minHeight: sheetHeight,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  top: 0,
                  right: 0,
                  left: 0,
                  child: AmEdgeBlur(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      children: [
                        FirstPageAddWork(
                          initialWorkType: widget.initialWorkType,
                          currentKm: widget.currentKm,
                        ),
                        const Midifyitem(),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.transparent,
                    child: WizardHeader(
                      stepIcon: HugeIcons.strokeRoundedAddCircle,
                      stepNumber: _currentPage + 1,
                      totalSteps: 2,
                      title: "Aggiungi intervento",
                      onClose: () => context.pop('/home'),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 30.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Bottone INDIETRO con animazione di comparsa/scomparsa laterale e opacità

                        // Solo la larghezza è animata: altezza fissa + ClipRect,
                        // così il bottone non viene forzato in un box 0×0
                        // (overflow ad ogni frame, vedi ROADMAP #7).
                        ClipRect(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: _currentPage > 0 ? 120 : 0,
                            height: 60,
                            child: OverflowBox(
                              alignment: Alignment.centerRight,
                              maxWidth: 120,
                              minWidth: 120,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.ease,
                                opacity: _currentPage > 0 ? 1.0 : 0.0,
                                child: AmOutlinedButton(
                                  label: 'INDIETRO',
                                  color: const Color(0xFFE85A1A),
                                  onPressed: _goToPreviousPage,
                                ),
                              ),
                            ),
                          ),
                        ),

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.linear,
                          width: _currentPage > 0 ? 16 : 0,
                        ),
                        Expanded(
                          child: AnimatedScale(
                            curve: Curves.linear,
                            scale: _currentPage == 0 ? 1.0 : 0.97,
                            duration: const Duration(milliseconds: 300),
                            child: AmMainFab(
                              label: _currentPage == 0 ? 'CONTINUA' : 'SALVA',
                              color: _currentPage == 0
                                  ? const Color(0x7E90E2FF)
                                  : const Color(0x4A90E2FF),
                              onPressed: _currentPage == 0
                                  ? _goToNextPage
                                  : () {
                                      context.read<WorkLogBloc>().add(
                                        OnSubmitEvent(),
                                      );
                                    },
                              icon: _currentPage == 0
                                  ? HugeIcons.strokeRoundedArrowRight01
                                  : HugeIcons.strokeRoundedAddToList,
                              width: double.infinity,
                              height: 60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.status == WorkLogStatus.loading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0xCC000000),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE85A1A),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class FirstPageAddWork extends StatefulWidget {
  final EnumPopUp initialWorkType;
  final int currentKm;

  const FirstPageAddWork({
    super.key,
    required this.initialWorkType,
    required this.currentKm,
  });

  @override
  State<FirstPageAddWork> createState() => _FirstPageAddWorkState();
}

class _FirstPageAddWorkState extends State<FirstPageAddWork> {
  late EnumPopUp _selectedWorkType;
  int _valore = 0;
  final _kmController = TextEditingController();
  final _dateController = TextEditingController();
  final _noteController = TextEditingController();
  final _customNameController = TextEditingController();

  /// Messaggio di errore sotto il campo km (null = ok).
  String? _erroreKm;

  @override
  void initState() {
    super.initState();
    _selectedWorkType = widget.initialWorkType;
    // Prefill: parto dai km attuali del veicolo (l'utente li vede e li alza).
    _kmController.text = '${widget.currentKm}';
  }

  /// Il km del lavoro non puo' essere inferiore agli attuali (no regressione).
  void _onKmChanged(dynamic _) {
    final testo = _kmController.text.trim();
    final n = int.tryParse(testo);
    setState(() {
      if (testo.isEmpty || n == null) {
        _erroreKm = 'Inserisci un numero valido';
      } else if (n < widget.currentKm) {
        _erroreKm =
            'Non possono essere meno degli attuali (${widget.currentKm} km)';
      } else {
        _erroreKm = null;
      }
    });
    context.read<WorkLogBloc>().add(
      CurrentKmChange(currentKm: int.tryParse(_kmController.text) ?? 0),
    );
  }

  @override
  void dispose() {
    _kmController.dispose();
    _dateController.dispose();
    _noteController.dispose();
    _customNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 300),
      children: [
        const SizedBox(height: 150),
        Row(
          children: [
            BlocBuilder<WorkLogBloc, WorkLogState>(
              builder: (context, state) {
                return AmDropdown<EnumPopUp>(
                  label: "Tipo Intervento",
                  placeholder: "Seleziona...",
                  value: _selectedWorkType,
                  items: EnumPopUp.values,
                  itemLabelBuilder: (val) => val.name,
                  onChanged: (val) {
                    if (val == null) return;
                    setState(() => _selectedWorkType = val);
                    context.read<WorkLogBloc>().add(
                      OnWorkTypeChange(type: val),
                    );
                  },
                );
              },
            ),
          ],
        ),
        BlocBuilder<WorkLogBloc, WorkLogState>(
          buildWhen: (prev, curr) => prev.type != curr.type,
          builder: (context, state) {
            if (state.type != EnumPopUp.altro) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 24),
              // AmTextField ha un Expanded come root: serve un Flex come genitore
              // diretto (vedi ROADMAP #7), altrimenti crash BoxParentData/FlexParentData.
              child: Row(
                children: [
                  AmTextField(
                    label: "Nome intervento",
                    placeholder: "Specifica il tipo di intervento...",
                    controller: _customNameController,
                    isRequired: true,
                    obscureText: false,
                    keyboardType: TextInputType.text,
                    onChanged: (_) => context.read<WorkLogBloc>().add(
                      CustomNameChange(customName: _customNameController.text),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            AmDatePickerField(
              label: "Data",
              placeholder: "gg/mm/aaaa",
              controller: _dateController,
              onDateSelected: (date) => context.read<WorkLogBloc>().add(
                ServiceDateChange(date: date),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            AmTextField(
              label: "Km al lavoro (attuali: ${widget.currentKm})",
              placeholder: "${widget.currentKm}",
              controller: _kmController,
              isRequired: true,
              obscureText: false,
              onChanged: _onKmChanged,
              errorText: _erroreKm,
              keyboardType: TextInputType.number,
              suffixIcon: const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text(
                  "km",
                  style: TextStyle(
                    color: Color(0xFF48484A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  BlocBuilder<WorkLogBloc, WorkLogState>(
                    builder: (context, state) {
                      return AmDropdown<int>(
                        label: "Richiamo tra",
                        placeholder: "Seleziona...",
                        value: _valore,
                        items: const [
                          0,
                          1000,
                          2000,
                          5000,
                          10000,
                          15000,
                          20000,
                          25000,
                          30000,
                          40000,
                          50000,
                          60000,
                          80000,
                          100000,
                          120000,
                          150000,
                        ],
                        itemLabelBuilder: (val) => val.toString(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _valore = v);
                          context.read<WorkLogBloc>().add(
                            RichiamoChange(intervallKM: v),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "PROSSIMO RICHIAMO",
                style: TextStyle(
                  color: Color(0xFF636366),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              BlocBuilder<WorkLogBloc, WorkLogState>(
                builder: (context, state) {
                  return Container(
                    height: 60,
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F11),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE85A1A).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      "${state.prosssimoRichiamo}km",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const AmExpandableContainer(
          title: "SEKEZIONA RICAMBI",
          subtitle: "PARTI SELZIONATE ",
          collapsedHeight: 72, // <- l'altezza chiusa, decidi tu
          expandedHeight: 400, // <- l'altezza aperta, decidi tu
          borderRadius: 16,
          child: PartsPickerBody(),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            AmTextField(
              label: "Note",
              placeholder: "Dettagli aggiuntivi...",
              controller: _noteController,
              isRequired: false,
              obscureText: false,
              keyboardType: TextInputType.multiline,
              onChanged: (_) => context.read<WorkLogBloc>().add(
                NoteChange(note: _noteController.text),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

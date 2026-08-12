import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/voice_search_bloc.dart';
import '../bloc/voice_search_event.dart';
import '../bloc/voice_search_state.dart';
import '../bloc/workshop_bloc.dart';
import '../bloc/workshop_event.dart';
import '../bloc/workshop_state.dart';
import '../widgets/workshop_home_view.dart';

class WorkshopHomePage extends StatefulWidget {
  const WorkshopHomePage({super.key, this.onSettingsPressed});

  final VoidCallback? onSettingsPressed;

  @override
  State<WorkshopHomePage> createState() => _WorkshopHomePageState();
}

class _WorkshopHomePageState extends State<WorkshopHomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleVoiceSearch(BuildContext context, VoiceSearchState state) {
    final bloc = context.read<VoiceSearchBloc>();
    if (state.isListening) {
      bloc.add(const VoiceSearchStopped());
    } else if (state.isVisible) {
      bloc.add(const VoiceSearchDismissed());
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
      bloc.add(const VoiceSearchStarted());
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<WorkshopBloc, WorkshopState>(
        listenWhen: (previous, current) => current is WorkshopLoadFailure,
        listener: (context, state) {
          if (state is WorkshopLoadFailure) _showLoadFailure(context, state);
        },
      ),
      BlocListener<VoiceSearchBloc, VoiceSearchState>(
        // The BLoC transcript is the single source for both the visible
        // SearchBar text and the existing WorkshopBloc text filter.
        listenWhen: (previous, current) =>
            previous.transcript != current.transcript,
        listener: (context, state) {
          // Partial speech results follow the same path as typed text:
          // VoiceSearchBloc -> transcript -> SearchBar -> WorkshopBloc.
          _searchController.value = TextEditingValue(
            text: state.transcript,
            selection: TextSelection.collapsed(offset: state.transcript.length),
          );
          context.read<WorkshopBloc>().add(
            WorkshopSearchChanged(state.transcript),
          );
        },
      ),
    ],
    child: BlocBuilder<WorkshopBloc, WorkshopState>(
      builder: (context, state) => switch (state) {
        WorkshopReady ready => WorkshopHomeView(
          mechanicName: ready.mechanic.displayName,
          totalVehicles: ready.allVehicles.length,
          vehicles: ready.visibleVehicles,
          hasLinkedVehicles: ready.allVehicles.isNotEmpty,
          hasSearchResults: ready.filteredVehicles.isNotEmpty,
          visibleCount: ready.visibleCount,
          hasMore: ready.hasMore,
          query: ready.query,
          filter: ready.filter,
          searchController: _searchController,
          onVoicePressed: (voiceState) =>
              _toggleVoiceSearch(context, voiceState),
          onSettingsPressed: widget.onSettingsPressed,
        ),
        WorkshopLoading() => WorkshopHomeView(
          mechanicName: 'Meccanico',
          isLoading: true,
          searchController: _searchController,
          onVoicePressed: (voiceState) =>
              _toggleVoiceSearch(context, voiceState),
          onSettingsPressed: widget.onSettingsPressed,
        ),
        WorkshopInitial() => WorkshopHomeView(
          mechanicName: 'Meccanico',
          isLoading: true,
          searchController: _searchController,
          onVoicePressed: (voiceState) =>
              _toggleVoiceSearch(context, voiceState),
          onSettingsPressed: widget.onSettingsPressed,
        ),
        WorkshopLoadFailure() => WorkshopHomeView(
          mechanicName: 'Meccanico',
          hasLoadFailure: true,
          searchController: _searchController,
          onVoicePressed: (voiceState) =>
              _toggleVoiceSearch(context, voiceState),
          onSettingsPressed: widget.onSettingsPressed,
        ),
      },
    ),
  );

  void _showLoadFailure(BuildContext context, WorkshopLoadFailure state) {
    final colors = AmThemeColors.of(context);
    showAmStatusDialog<void>(
      context,
      title: 'Impossibile caricare i veicoli',
      message: state.message,
      iconColor: colors.danger,
      actions: [
        AmDialogAction(
          label: 'Chiudi',
          color: colors.textSecondary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AmDialogAction(
          label: 'Riprova',
          color: colors.accent,
          filled: true,
          onPressed: () {
            Navigator.of(context).pop();
            context.read<WorkshopBloc>().add(const WorkshopRetryRequested());
          },
        ),
      ],
    );
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/service_request.dart';
import '../../domain/usecases/get_service_requests.dart';

sealed class ServiceRequestsState {
  const ServiceRequestsState();
}

final class ServiceRequestsLoading extends ServiceRequestsState {
  const ServiceRequestsLoading();
}

final class ServiceRequestsReady extends ServiceRequestsState {
  const ServiceRequestsReady(this.requests, {this.query = ''});
  final List<ServiceRequest> requests;
  final String query;
}

final class ServiceRequestsFailure extends ServiceRequestsState {
  const ServiceRequestsFailure();
}

class ServiceRequestsCubit extends Cubit<ServiceRequestsState> {
  ServiceRequestsCubit(this.getServiceRequests)
    : super(const ServiceRequestsLoading());
  final GetServiceRequests getServiceRequests;
  List<ServiceRequest> _requests = const [];
  String _query = '';
  Future<void>? _pending;
  Future<void> load() =>
      _pending ??= _load().whenComplete(() => _pending = null);
  Future<void> refresh() => load();
  Future<void> _load() async {
    emit(const ServiceRequestsLoading());
    try {
      final requests = await getServiceRequests();
      _requests = List.unmodifiable(requests);
      if (!isClosed) emit(_readyState());
    } on Object {
      if (!isClosed) emit(const ServiceRequestsFailure());
    }
  }

  void search(String query) {
    if (state is! ServiceRequestsReady) return;
    _query = query.trim();
    emit(_readyState());
  }

  ServiceRequestsReady _readyState() {
    final tokens = _normalize(
      _query,
    ).split(' ').where((token) => token.isNotEmpty).toList(growable: false);
    final filtered = tokens.isEmpty
        ? _requests
        : _requests
              .where((request) {
                final searchable = _normalize(
                  '${request.vehicleModel} ${request.plate} ${request.issues.join(' ')}',
                );
                final compact = searchable.replaceAll(' ', '');
                return tokens.every(
                  (token) =>
                      searchable.contains(token) || compact.contains(token),
                );
              })
              .toList(growable: false);
    return ServiceRequestsReady(filtered, query: _query);
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
}

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
  const ServiceRequestsReady(this.requests);
  final List<ServiceRequest> requests;
}

final class ServiceRequestsFailure extends ServiceRequestsState {
  const ServiceRequestsFailure();
}

class ServiceRequestsCubit extends Cubit<ServiceRequestsState> {
  ServiceRequestsCubit(this.getServiceRequests)
    : super(const ServiceRequestsLoading());
  final GetServiceRequests getServiceRequests;
  Future<void>? _pending;
  Future<void> load() =>
      _pending ??= _load().whenComplete(() => _pending = null);
  Future<void> refresh() => load();
  Future<void> _load() async {
    emit(const ServiceRequestsLoading());
    try {
      final requests = await getServiceRequests();
      if (!isClosed) emit(ServiceRequestsReady(List.unmodifiable(requests)));
    } on Object {
      if (!isClosed) emit(const ServiceRequestsFailure());
    }
  }
}

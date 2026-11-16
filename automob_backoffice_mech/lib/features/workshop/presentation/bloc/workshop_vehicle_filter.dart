enum WorkshopVehicleFilter { all, connected, maintenanceDue }

extension WorkshopVehicleFilterLabel on WorkshopVehicleFilter {
  String get label => switch (this) {
    WorkshopVehicleFilter.all => 'Tutti',
    WorkshopVehicleFilter.connected => 'OK',
    WorkshopVehicleFilter.maintenanceDue => 'Segnalazioni',
  };
}

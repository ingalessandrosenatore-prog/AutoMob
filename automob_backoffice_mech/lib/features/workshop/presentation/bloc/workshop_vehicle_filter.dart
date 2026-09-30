enum WorkshopVehicleFilter { all, connected, maintenanceDue }

extension WorkshopVehicleFilterLabel on WorkshopVehicleFilter {
  String get label => switch (this) {
    WorkshopVehicleFilter.all => 'Tutti i veicoli',
    WorkshopVehicleFilter.connected => 'In regola',
    WorkshopVehicleFilter.maintenanceDue => 'Da controllare',
  };
}

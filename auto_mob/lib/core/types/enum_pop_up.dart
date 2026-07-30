enum EnumPopUp {
  aggiornaTagliando,
  aggiornaDistribuzione,
  aggiornaCambioGomme,
  revisione,
  pneumaticiInversione,
  altro;

  String get dbValue => switch (this) {
        aggiornaTagliando => 'tagliando',
        aggiornaDistribuzione => 'distribuzione',
        aggiornaCambioGomme => 'pneumatici_cambio',
        revisione => 'revisione',
        pneumaticiInversione => 'pneumatici_inversione',
        altro => 'altro',
      };
}

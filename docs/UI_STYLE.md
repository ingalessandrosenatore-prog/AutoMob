# AutoMob UI style

## Menu pull-down

| Proprietà | Token adottato |
| --- | ---: |
| Larghezza | 250 pt |
| Radius esterno | 29 pt |
| Padding top/bottom | 10 pt |
| Padding orizzontale | 18 pt |
| Altezza riga | 52 pt |
| Spazio icona-testo | 13 pt |
| Icona | 21 pt |
| Touch target minimo | 44 pt |

Il trigger è alto 40 pt e ha radius 20 pt. Il fill è bianco al 78% in Light e
`rgb(28, 28, 30)` al 78% in Dark; il popup usa gli stessi colori all'80%.
L'ombra è `0 4 12` al 6% in Light e `0 6 18` al 30% in Dark.

Border e highlight restano responsabilità di `OCLiquidGlass`: base 10-14% e
highlight superiore 35-45% in Light; base 8-12% e highlight 16-24% in Dark.
Non vanno ricreati con overlay, painter o blur aggiuntivi.

## Pulsanti

| Variante | Altezza | Padding orizzontale | Testo | Radius |
| --- | ---: | ---: | --- | ---: |
| Medio con testo | 38 pt | 17 pt | 15-16 pt, 500-600 | 19 pt |
| Standard | 44 pt | 19 pt | 16-17 pt | 22 pt |
| Circolare AppBar | visuale 40 pt, touch 44 pt | - | icona 20 pt | cerchio |

Le misure runtime sono centralizzate in `AmControlMetrics` nel package
`common_ui_widget`.

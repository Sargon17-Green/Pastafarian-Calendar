# Pensaernïaeth Cam 1

Mae'r haen gynhyrchu ar hyn o bryd yn fwriadol niwtral. Mae `BaseMonsterContext` yn perthyn i un galwad yn unig. Mae `BaseMonsterDispatcher` yn trosglwyddo cam at handler cofrestredig. Mae `BaseValidationManager` yn gwirio cyflwr y bootstrap. Mae `BaseErrorWrapper` yn trosi methiant annisgwyl yn god peiriant penderfynedig. Mae `BaseMetricsManager` yn cadw cyfrifon arsylwadol nad ydynt yn fewnbynnau semantig.

Nid oes cache semantig, retry semantig, compatibility mode, legacy adapter na patch hanesyddol yn y cam hwn. Byddai ychwanegu un ohonynt yn gynnar yn halogi'r dilyniant 55 cam.

Mae'r cyfeirnod normadol yn byw dan `src/test` ac felly nid yw'r haen gynhyrchu yn gallu ei ddefnyddio fel fallback. Mae'r math `ExactInt` yn y prif god oherwydd bydd y gweithrediad cynhyrchu yn ei angen yn y camau dilynol; nid yw'n dibynnu ar lyfrgell arbitrary-precision allanol.

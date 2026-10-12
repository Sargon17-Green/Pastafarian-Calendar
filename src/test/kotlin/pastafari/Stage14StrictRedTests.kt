package pastafari

/** Methu'n fwriadol pan geisir gwneud y helper zero-based yn GREEN. */
object Stage14StrictRedTests {
    @JvmStatic fun main(args: Array<String>) {
        require(args.isEmpty()) { "E_DISCOVERY07_STRICT_ARGS" }
        val old = LegacyGrindTableAdapter().legacyGrindRow(1)
        val normativeFirst = VisibleGrindRow(3,5,7,11,0)
        check(old.row == VisibleGrindRow(5,7,11,13,1) && !old.undefined) {
            "E_DISCOVERY07_STRICT_SCAR_ABSENT"
        }
        println("STAGE14_STRICT_EXPECTED_FAILURE")
        check(old.row == normativeFirst) { "E_DISCOVERY07_STRICT_GRIND1_RED" }
    }
}

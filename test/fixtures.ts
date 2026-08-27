import { FOUNDATION_DAY, M } from "./normativeOracle.ts";

export const STAGE_01_FIXTURES = Object.freeze({
  save: Object.freeze([
    Object.freeze({ input: 1n, expected: 1n }),
    Object.freeze({ input: M - 1n, expected: M - 1n }),
    Object.freeze({ input: M, expected: M }),
    Object.freeze({ input: M + 1n, expected: 1n }),
    Object.freeze({ input: 2n * M, expected: M })
  ]),
  dayCount: Object.freeze([
    Object.freeze({ input: FOUNDATION_DAY - 1n, expected: 2n }),
    Object.freeze({ input: FOUNDATION_DAY, expected: 1n }),
    Object.freeze({ input: FOUNDATION_DAY + 1n, expected: 3n })
  ]),
  foundationSauce: Object.freeze({
    bowls: Object.freeze([
      65286679584284972964194865805379907599n,
      127720283375330263615328810127751035299n,
      54364069496183805843611594721403108554n,
      93072329024469476118876155742008280619n,
      54867842942953573450868747713087920246n,
      111207247632761530752404582123499651367n
    ]),
    orderAtDrop46: Object.freeze([4, 5, 2, 3, 6, 1])
  }),
  secondStone: Object.freeze([378n, 1073n, 2375n, 6195n, 10493n])
});

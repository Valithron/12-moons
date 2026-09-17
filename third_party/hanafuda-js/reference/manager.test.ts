import { describe, it, expect } from "vitest"
import { createCollection } from "../../src/core/collection.ts"
import { createScoringManager, KOIKOI_RULES, HACHI_RULES } from "../../src/scoring/manager.ts"
import type { Collection } from "../../src/core/types.ts"
import type { ScoringManager, YakuResult, ScoringContext } from "../../src/scoring/types.ts"

// Test card indices for bright cards
const CRANE = 0 // Pine Bright
const CURTAIN = 8 // Cherry Bright
const MOON = 28 // Susuki Bright
const RAIN_MAN = 40 // Willow Rain-man
const PHOENIX = 44 // Paulownia Bright

// Test card indices for animal cards
const BOAR = 24 // Bush Clover Animal
const DEER = 36 // Maple Animal
const BUTTERFLY = 20 // Peony Animal
const SAKE_CUP = 32 // Chrysanthemum Animal/Chaff

// Test card indices for month cards
const PINE_CARDS = [0, 1, 2, 3] // All Pine cards (Month 1)
const PLUM_CARDS = [4, 5, 6, 7] // All Plum cards (Month 2)

describe("ScoringManager", () => {
  it("applies Koi-Koi rules correctly", () => {
    const collection: Collection = createCollection()
    const scoring: ScoringManager = createScoringManager(KOIKOI_RULES)

    // Test bright yaku with no multiple scoring
    collection.addMany([CRANE, CURTAIN, MOON])
    let result: YakuResult[] = scoring(collection)
    expect(result).toHaveLength(1)
    expect(result[0].name).toBe("sankou")

    collection.add(RAIN_MAN)
    result = scoring(collection)
    expect(result).toHaveLength(1)
    expect(result[0].name).toBe("ame-shikou")

    // Test animal yaku with sake cup as animal
    collection.clear()
    collection.addMany([BOAR, DEER, BUTTERFLY, SAKE_CUP])
    result = scoring(collection)
    expect(result).toHaveLength(1)
    expect(result[0].points).toBe(6) // Should count sake cup as animal
  })

  it.skip("applies Hachi-Hachi rules correctly", () => {
    const collection: Collection = createCollection()
    const scoring: ScoringManager = createScoringManager(HACHI_RULES)

    // Test bright yaku with rain-man requirement
    collection.addMany([CRANE, CURTAIN, MOON, PHOENIX])
    let result: YakuResult[] = scoring(collection)
    expect(result).toHaveLength(0) // Should not score without rain-man

    collection.remove(PHOENIX)
    collection.add(RAIN_MAN)
    result = scoring(collection)
    expect(result).toHaveLength(1)
    expect(result[0].name).toBe("ame-shikou")

    // Test animal yaku with sake cup as chaff
    collection.clear()
    collection.addMany([BOAR, DEER, BUTTERFLY, SAKE_CUP])
    result = scoring(collection)
    expect(result[0].points).toBe(5) // Should not count sake cup as animal
  })

  it("prioritizes hand yaku correctly", () => {
    const collection: Collection = createCollection()
    const scoring: ScoringManager = createScoringManager(KOIKOI_RULES)

    // Create a hand that could score both teshi and month yaku
    collection.addMany([...PINE_CARDS, ...PLUM_CARDS])

    // Should only score teshi when checking hand yaku
    const result: YakuResult[] = scoring(collection, {
      checkTeyaku: true,
      currentMonth: 1,
    } as ScoringContext)
    expect(result).toHaveLength(1)
    expect(result[0].name).toBe("teshi")

    // Should score normal yaku when not checking hand yaku
    const normalResult: YakuResult[] = scoring(collection, {
      currentMonth: 1,
    } as ScoringContext)
    expect(normalResult).toHaveLength(1)
    expect(normalResult[0].name).toBe("tsuki-fuda")
  })
})

import { describe, it, expect } from "vitest"
import { isMatch, compareCards, hasMatch } from "../../src/core/matching.ts"

describe("Matching", () => {
  it("matches cards correctly", () => {
    // Test matching cards from the same month
    expect(isMatch(0, 1)).toBe(true) // Pine cards (month 1)
    expect(isMatch(4, 7)).toBe(true) // Plum cards (month 2)

    // Test non-matching cards from different months
    expect(isMatch(0, 4)).toBe(false) // Pine (month 1) vs Plum (month 2)
    expect(isMatch(0, 8)).toBe(false) // Pine (month 1) vs Cherry (month 3)

    // Test invalid indices
    expect(isMatch(-1, 0)).toBe(false)
    expect(isMatch(0, 48)).toBe(false)
    expect(isMatch(48, 48)).toBe(false)
  })

  it("compares cards correctly", () => {
    // Test same month comparison (should sort by type)
    // Pine cards (month 1): Bright Crane (0), Animal Poetry Ribbon (1), Chaff (2,3)
    expect(compareCards(0, 1)).toBe(1) // Bright comes before Animal
    expect(compareCards(1, 2)).toBe(1) // Animal comes before Chaff
    expect(compareCards(2, 3)).toBe(0) // Same type (Chaff) should be equal
    expect(compareCards(3, 0)).toBe(-1) // Chaff comes after Bright

    // Test different month comparison
    expect(compareCards(0, 4)).toBe(-1) // Month 1 comes before Month 2
    expect(compareCards(4, 0)).toBe(1) // Month 2 comes after Month 1

    // Test invalid indices
    expect(compareCards(-1, 0)).toBe(0)
    expect(compareCards(0, 48)).toBe(0)
    expect(compareCards(48, 48)).toBe(0)
  })
})

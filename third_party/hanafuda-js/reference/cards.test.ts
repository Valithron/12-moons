import { describe, it, expect } from "vitest"
import {
  getCard,
  findCardIndicesByType,
  findCardIndicesByMonth,
  CardType,
  type Card,
} from "../../src/core/cards.ts"

describe("Cards", () => {
  it("retrieves cards correctly", () => {
    // Test valid card
    const card: Card | null = getCard(0)
    expect(card?.type).toBe(CardType.BRIGHT)

    // Test invalid indices
    expect(getCard(-1)).toBeNull()
    expect(getCard(48)).toBeNull()
  })

  it("finds cards by type", () => {
    const brights: number[] = findCardIndicesByType(CardType.BRIGHT)
    expect(brights.length).toBe(5)

    const animals: number[] = findCardIndicesByType(CardType.ANIMAL)
    expect(animals.length).toBe(9)

    const ribbons: number[] = findCardIndicesByType(CardType.RIBBON)
    expect(ribbons.length).toBe(10)

    const chaff: number[] = findCardIndicesByType(CardType.CHAFF)
    expect(chaff.length).toBe(24)
  })

  it("finds cards by month", () => {
    // Test each month has exactly 4 cards
    for (let month = 1; month <= 12; month++) {
      const cards: number[] = findCardIndicesByMonth(month)
      expect(cards.length).toBe(4)
    }

    // Test invalid month
    expect(findCardIndicesByMonth(13).length).toBe(0)
    expect(findCardIndicesByMonth(0).length).toBe(0)
  })
})

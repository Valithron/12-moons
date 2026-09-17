import { describe, it, expect } from "vitest"
import { createDeck, createStandardDeck } from "../../src/core/deck.ts"
import type { Deck } from "../../src/core/types.ts"

describe("Deck", () => {
  it("creates empty deck", () => {
    const deck: Deck = createDeck({ cards: [] })
    expect(deck.size).toBe(0)
    expect(deck.isEmpty).toBe(true)
    expect(deck.draw()).toBeNull()
  })

  it("creates standard deck", () => {
    const deck: Deck = createStandardDeck()
    expect(deck.size).toBe(48)
    expect(deck.isEmpty).toBe(false)

    // Test that all cards are present
    const allCards = new Set(deck.cards)
    expect(allCards.size).toBe(48)
    for (let i = 0; i < 48; i++) {
      expect(allCards.has(i)).toBe(true)
    }
  })

  it("shuffles deck properly", () => {
    // Test both initial shuffle and reshuffle
    const orderedDeck: Deck = createDeck({ shuffled: false })
    const originalOrder: number[] = [...orderedDeck.cards]

    let differentOrderCount = 0
    const iterations = 100

    for (let i = 0; i < iterations; i++) {
      orderedDeck.reshuffle()

      // Verify all cards are still present
      expect(orderedDeck.size).toBe(48)
      expect(new Set(orderedDeck.cards)).toEqual(new Set(Array.from({ length: 48 }, (_, i) => i)))

      // Count if order is different from original
      if (orderedDeck.cards.some((card, index) => card !== originalOrder[index])) {
        differentOrderCount++
      }
    }

    expect(differentOrderCount).toBeGreaterThan(98)

    // Test that unshuffled decks are in order
    const newOrderedDeck: Deck = createDeck({ shuffled: false })
    expect(newOrderedDeck.cards).toEqual(Array.from({ length: 48 }, (_, i) => i))
  })

  it("draws single card", () => {
    const deck: Deck = createStandardDeck()
    const initialSize = deck.size

    const card = deck.draw()
    expect(typeof card).toBe("number")
    expect(card).toBeGreaterThanOrEqual(0)
    expect(card).toBeLessThan(48)
    expect(deck.size).toBe(initialSize - 1)

    // Drawing all cards
    const cards: number[] = []
    while (!deck.isEmpty) {
      const drawnCard = deck.draw()
      if (drawnCard !== null) {
        cards.push(drawnCard)
      }
    }
    expect(cards.length).toBe(initialSize - 1)
    expect(deck.draw()).toBeNull()
  })

  it("draws multiple cards", () => {
    const deck: Deck = createStandardDeck()

    // Default draw count (8)
    const hand: number[] = deck.drawMany()
    expect(hand.length).toBe(8)
    expect(deck.size).toBe(40)

    // Custom draw count
    const threeCards: number[] = deck.drawMany(3)
    expect(threeCards.length).toBe(3)
    expect(deck.size).toBe(37)

    // Drawing more cards than available
    const remaining: number[] = deck.drawMany(50)
    expect(remaining.length).toBe(37)
    expect(deck.isEmpty).toBe(true)
  })

  it("places card on top of deck", () => {
    const deck: Deck = createDeck({ cards: [7, 8, 9, 10] })
    const initialSize = deck.size
    const cardToPlace = 47

    deck.placeOnTop(cardToPlace)
    expect(deck.size).toBe(initialSize + 1)
    expect(deck.cards[deck.size - 1]).toBe(cardToPlace) // Check if card is on top

    // Attempt to place the same card again
    expect(() => deck.placeOnTop(cardToPlace)).toThrow(`Card ${cardToPlace} already exists`)
    // Size should remain the same after attempting to add duplicate
    expect(deck.size).toBe(initialSize + 1)
    // Card should still be on top
    expect(deck.cards[deck.size - 1]).toBe(cardToPlace)
  })

  it("places card on bottom of deck", () => {
    const deck: Deck = createDeck({ cards: [7, 8, 9, 10] })
    const initialSize = deck.size
    const cardToPlace = 47

    deck.placeOnBottom(cardToPlace)
    expect(deck.size).toBe(initialSize + 1)
    expect(deck.cards[0]).toBe(cardToPlace) // Check if card is at the bottom

    // Attempt to place the same card again
    expect(() => deck.placeOnBottom(cardToPlace)).toThrow(`Card ${cardToPlace} already exists`)
    // Size should remain the same after attempting to add duplicate
    expect(deck.size).toBe(initialSize + 1)
    // Card should still be at the bottom
    expect(deck.cards[0]).toBe(cardToPlace)
  })

  it("maintains deck immutability", () => {
    const deck: Deck = createStandardDeck()
    const initialSize = deck.size

    // Modifying returned cards array shouldn't affect deck
    const cards: number[] = deck.cards
    cards.pop()
    expect(deck.size).toBe(initialSize)
    expect(deck.cards.length).toBe(initialSize)

    // Drawing shouldn't affect previously returned cards array
    deck.draw()
    expect(cards.length + 1).toBe(initialSize)
  })

  it("provides string representation", () => {
    const deck: Deck = createDeck({
      cards: [0, 1, 2],
      shuffled: false,
    })

    // Test toString method
    expect(deck.toString()).toBe("Deck(0, 1, 2)")

    // Test empty deck
    const emptyDeck: Deck = createDeck({ cards: [] })
    expect(emptyDeck.toString()).toBe("Deck()")
  })

  it("handles JSON serialization", () => {
    const original: Deck = createDeck({
      cards: [0, 1, 2],
      shuffled: false,
    })

    // Test toJSON method - returns array directly
    expect(original.toJSON()).toEqual([0, 1, 2])

    // Test JSON.stringify integration - returns string
    const json: string = JSON.stringify(original)
    expect(json).toBe("[0,1,2]")

    // Test empty deck
    const empty: Deck = createDeck({ cards: [] })
    expect(JSON.stringify(empty)).toBe("[]")
  })

  it("handles JSON deserialization", () => {
    const original: Deck = createDeck({
      cards: [0, 1, 2],
      shuffled: false,
    })
    const json: string = JSON.stringify(original)

    // Test creating from JSON string
    const restored: Deck = createDeck({ fromJSON: json, shuffled: false })
    expect(restored.size).toBe(3)
    expect(restored.cards).toEqual([0, 1, 2])

    // Test with empty deck
    const emptyJson = "[]"
    const emptyRestored: Deck = createDeck({ fromJSON: emptyJson })
    expect(emptyRestored.size).toBe(0)

    // Test invalid JSON
    expect(() => createDeck({ fromJSON: "invalid json" })).toThrow("Unexpected token")

    // Test invalid card indices in JSON
    expect(() => createDeck({ fromJSON: "[-1]" })).toThrow("Invalid card index")
  })
})

import { DuplicateCardError, InvalidCardError, InvalidStateError } from "../errors.ts"
import { isValidCardIndex } from "./cards.ts"

/**
 * Fisher-Yates shuffle algorithm
 */
const shuffle = <T>(array: Array<T>): Array<T> => {
  const result = [...array]
  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[result[i], result[j]] = [result[j], result[i]]
  }
  return result
}

export interface Deck extends Iterable<number> {
  [Symbol.iterator]: () => IterableIterator<number>
  cards: number[]
  draw: () => number | null
  drawMany: (count?: number) => number[]
  placeOnTop: (cardIndex: number) => void
  placeOnBottom: (cardIndex: number) => void
  reshuffle: () => void
  isEmpty: boolean
  size: number
  reset: () => void
  toJSON: () => number[]
  toString: () => string
}

/**
 * Create a new deck of cards
 * @param {Object} [options]
 * @param {boolean} [options.shuffled=true] Whether to shuffle the deck
 * @param {Array<number>} [options.cards] Initial cards (indices) to use
 * @param {string} [options.fromJSON] JSON string to initialize from
 * @returns {Readonly<Deck>}
 * @throws {InvalidCardError} If any card index is invalid
 * @throws {SyntaxError} If JSON string is invalid
 */
export const createDeck = (
  options: {
    shuffled?: boolean
    cards?: number[]
    fromJSON?: string
  } = {}
): Deck => {
  const { shuffled = true, cards = Array.from({ length: 48 }, (_, i) => i), fromJSON } = options

  // If JSON string provided, parse it and use those cards
  const initialCards = fromJSON ? JSON.parse(fromJSON) : cards

  // If cards are not an array, throw an error
  if (!Array.isArray(initialCards)) {
    throw new InvalidStateError(`Invalid cards array from JSON: ${initialCards}`)
  }

  // Validate initial cards
  initialCards.forEach((index, i) => {
    if (!isValidCardIndex(index)) {
      throw new InvalidCardError(index)
    }
  })

  /**
   * Initialize internal card array
   * @private
   */
  let cardArray: number[] = shuffled ? shuffle(initialCards) : [...initialCards]

  /**
   * Check if a card can be placed in the deck
   * @private
   * @throws {InvalidCardError} If card index is invalid
   * @throws {DuplicateCardError} If card is already in deck
   */
  const isValidPlacement = (cardIndex: number): boolean => {
    if (!isValidCardIndex(cardIndex)) {
      throw new InvalidCardError(cardIndex)
    }
    if (cardArray.includes(cardIndex)) {
      throw new DuplicateCardError(cardIndex)
    }
    return true
  }

  return Object.freeze<Deck>({
    /**
     * Make deck iterable
     */
    [Symbol.iterator](): IterableIterator<number> {
      return cardArray[Symbol.iterator]()
    },

    /**
     * Current cards in deck
     */
    get cards(): number[] {
      return [...cardArray]
    },

    /**
     * Draw a single card from the deck
     * @returns Card index or null if deck is empty
     */
    draw(): number | null {
      return cardArray.length > 0 ? cardArray.pop()! : null
    },

    /**
     * Draw multiple cards from the deck
     * @param count Number of cards to draw
     * @returns Array of card indices
     */
    drawMany(count = 8): number[] {
      const drawn = []
      for (let i = 0; i < count && cardArray.length > 0; i++) {
        drawn.push(cardArray.pop()!)
      }
      return drawn
    },

    /**
     * Add a card to the deck
     */
    placeOnTop(cardIndex: number): void {
      if (isValidPlacement(cardIndex)) {
        cardArray.push(cardIndex)
      }
    },

    /**
     * Add a card to the deck
     */
    placeOnBottom(cardIndex: number): void {
      if (isValidPlacement(cardIndex)) {
        cardArray.unshift(cardIndex)
      }
    },

    /**
     * Reshuffle current deck
     */
    reshuffle(): void {
      cardArray = shuffle(cardArray)
    },

    /**
     * Check if deck is empty
     */
    get isEmpty(): boolean {
      return cardArray.length === 0
    },

    /**
     * Get number of remaining cards
     */
    get size(): number {
      return cardArray.length
    },

    /**
     * Reset deck to initial state
     */
    reset(): void {
      cardArray = shuffled ? shuffle(cards) : [...cards]
    },

    /**
     * Get string representation of deck
     */
    toString(): string {
      return `Deck(${cardArray.join(", ")})`
    },

    /**
     * Custom inspection for console.log
     */
    [Symbol.for("nodejs.util.inspect.custom")]() {
      return this.toString()
    },

    /**
     * Get JSON representation of deck
     * @returns Array of card indices
     */
    toJSON(): number[] {
      return this.cards
    },
  })
}

/**
 * Create a standard shuffled Hanafuda deck
 * @returns Readonly<Deck>
 */
export const createStandardDeck = (): Deck => createDeck({ shuffled: true })

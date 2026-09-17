import { InvalidCardError } from "../errors.ts"
import { CardType, getCard, isValidCardIndex } from "./cards.ts"

export interface Collection extends Iterable<number> {
  [Symbol.iterator]: () => IterableIterator<number>
  has: (cardIndex: number) => boolean
  findByType: (type: CardType) => number[]
  findByMonth: (month: number) => number[]
  add: (cardIndex: number) => boolean
  addMany: (cardIndices: number[]) => number
  remove: (cardIndex: number) => boolean
  removeMany: (cardIndices: number[]) => number
  size: number
  isEmpty: boolean
  clear: () => void
  toJSON: () => number[]
  toString: () => string
}

/**
 * Create a new card collection with automatic deduplication and O(1) operations.
 * @param options Configuration options
 * @param options.cards Initial cards to add to the collection
 * @param options.fromJSON JSON string to initialize collection from
 * @throws {SyntaxError} If JSON string is invalid
 * @throws {InvalidCardError} If any card index is invalid
 * @example
 * const collection = createCollection({ cards: [0, 1, 2] })
 * collection.add(3)
 * collection.has(1) // true
 */
export const createCollection = (
  options: { cards?: number[]; fromJSON?: string } = {}
): Collection => {
  const { cards = [], fromJSON } = options

  // If JSON string provided, parse it and use those cards
  const initialCards: number[] = fromJSON ? JSON.parse(fromJSON) : cards

  // Validate initial cards
  initialCards.forEach((index, i) => {
    if (!isValidCardIndex(index)) {
      throw new InvalidCardError(index)
    }
  })

  /**
   * Initialize internal card set
   * @private
   */
  const cardSet: Set<number> = new Set(initialCards)

  const collection: Collection = Object.freeze({
    /**
     * Make collection iterable
     */
    [Symbol.iterator](): IterableIterator<number> {
      return cardSet.values()
    },

    /**
     * Check if collection has card
     */
    has(cardIndex: number): boolean {
      return cardSet.has(cardIndex)
    },

    /**
     * Add card to collection
     * @returns Whether card was added
     * @throws {InvalidCardError} If card index is invalid
     */
    add(cardIndex: number): boolean {
      if (!isValidCardIndex(cardIndex)) {
        throw new InvalidCardError(cardIndex)
      }
      const size = cardSet.size
      cardSet.add(cardIndex)
      return cardSet.size > size
    },

    /**
     * Add multiple cards to collection
     * @returns Number of cards actually added
     * @throws {InvalidCardError} If any card index is invalid
     */
    addMany(cardIndices: number[]): number {
      cardIndices.forEach((index, i) => {
        if (!isValidCardIndex(index)) {
          throw new InvalidCardError(index)
        }
      })
      const initialSize = cardSet.size
      cardIndices.forEach((index) => cardSet.add(index))
      return cardSet.size - initialSize
    },

    /**
     * Remove card from collection
     * @returns Whether card was removed
     */
    remove(cardIndex: number): boolean {
      return cardSet.delete(cardIndex)
    },

    /**
     * Remove multiple cards from collection
     * @returns Number of cards actually removed
     */
    removeMany(cardIndices: number[]): number {
      const initialSize = cardSet.size
      cardIndices.forEach((index) => cardSet.delete(index))
      return initialSize - cardSet.size
    },

    /**
     * Find cards of a specific type in the collection
     */
    findByType(type: CardType): Array<number> {
      return Array.from(this).filter((index) => {
        const card = getCard(index)
        return card && card.type === type
      })
    },

    /**
     * Find cards from a specific month in the collection
     */
    findByMonth(month: number): Array<number> {
      return Array.from(this).filter((index) => {
        const card = getCard(index)
        return card && card.month === month
      })
    },

    /**
     * Get collection size
     */
    get size(): number {
      return cardSet.size
    },

    /**
     * Check if collection is empty
     */
    get isEmpty(): boolean {
      return cardSet.size === 0
    },

    /**
     * Clear all cards
     */
    clear() {
      cardSet.clear()
    },

    /**
     * Get JSON representation of collection
     */
    toJSON(): number[] {
      return Array.from(this)
    },

    /**
     * Get string representation of collection
     */
    toString(): string {
      return `Collection(${Array.from(this).join(", ")})`
    },

    /**
     * Custom inspection for console.log
     */
    [Symbol.for("nodejs.util.inspect.custom")](): string {
      return this.toString()
    },
  })

  // Wrap collection with Proxy to enable array-like index access
  return new Proxy(collection, {
    get(target, prop: string | symbol) {
      if (typeof prop === "symbol") return target[prop as keyof typeof target]
      // Handle numeric indices
      const index = Number(prop)
      if (Number.isInteger(index) && index >= 0) {
        const arr = Array.from(target)
        return arr[index]
      }
      return target[prop as keyof typeof target]
    },
  })
}

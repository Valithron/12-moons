export const CardType = {
  CHAFF: "chaff",
  ANIMAL: "animal",
  RIBBON: "ribbon",
  BRIGHT: "bright",
} as const
export type CardType = (typeof CardType)[keyof typeof CardType]

export const FlowerType = {
  PINE: "pine",
  PLUM: "plum",
  CHERRY: "cherry",
  WISTERIA: "wisteria",
  IRIS: "iris",
  PEONY: "peony",
  BUSH_CLOVER: "bush-clover",
  SUSUKI: "susuki",
  CHRYSANTHEMUM: "chrysanthemum",
  MAPLE: "maple",
  WILLOW: "willow",
  PAULOWNIA: "paulownia",
} as const
export type FlowerType = (typeof FlowerType)[keyof typeof FlowerType]

const CARDS_LENGTH = 48

const CARD_DATA: ReadonlyArray<[string, CardType, FlowerType, number]> = Object.freeze([
  // January - Pine (Matsu)
  ["crane", CardType.BRIGHT, FlowerType.PINE, 1], // 0
  ["poetry-ribbon", CardType.RIBBON, FlowerType.PINE, 1], // 1
  ["chaff-1", CardType.CHAFF, FlowerType.PINE, 1], // 2
  ["chaff-2", CardType.CHAFF, FlowerType.PINE, 1], // 3

  // February - Plum (Ume)
  ["bush-warbler", CardType.ANIMAL, FlowerType.PLUM, 2], // 4
  ["poetry-ribbon", CardType.RIBBON, FlowerType.PLUM, 2], // 5
  ["chaff-1", CardType.CHAFF, FlowerType.PLUM, 2], // 6
  ["chaff-2", CardType.CHAFF, FlowerType.PLUM, 2], // 7

  // March - Cherry (Sakura)
  ["curtain", CardType.BRIGHT, FlowerType.CHERRY, 3], // 8
  ["poetry-ribbon", CardType.RIBBON, FlowerType.CHERRY, 3], // 9
  ["chaff-1", CardType.CHAFF, FlowerType.CHERRY, 3], // 10
  ["chaff-2", CardType.CHAFF, FlowerType.CHERRY, 3], // 11

  // April - Wisteria (Fuji)
  ["cuckoo", CardType.ANIMAL, FlowerType.WISTERIA, 4], // 12
  ["red-ribbon", CardType.RIBBON, FlowerType.WISTERIA, 4], // 13
  ["chaff-1", CardType.CHAFF, FlowerType.WISTERIA, 4], // 14
  ["chaff-2", CardType.CHAFF, FlowerType.WISTERIA, 4], // 15

  // May - Iris (Ayame)
  ["bridge", CardType.ANIMAL, FlowerType.IRIS, 5], // 16
  ["red-ribbon", CardType.RIBBON, FlowerType.IRIS, 5], // 17
  ["chaff-1", CardType.CHAFF, FlowerType.IRIS, 5], // 18
  ["chaff-2", CardType.CHAFF, FlowerType.IRIS, 5], // 19

  // June - Peony (Botan)
  ["butterfly", CardType.ANIMAL, FlowerType.PEONY, 6], // 20
  ["blue-ribbon", CardType.RIBBON, FlowerType.PEONY, 6], // 21
  ["chaff-1", CardType.CHAFF, FlowerType.PEONY, 6], // 22
  ["chaff-2", CardType.CHAFF, FlowerType.PEONY, 6], // 23

  // July - Bush Clover (Hagi)
  ["boar", CardType.ANIMAL, FlowerType.BUSH_CLOVER, 7], // 24
  ["red-ribbon", CardType.RIBBON, FlowerType.BUSH_CLOVER, 7], // 25
  ["chaff-1", CardType.CHAFF, FlowerType.BUSH_CLOVER, 7], // 26
  ["chaff-2", CardType.CHAFF, FlowerType.BUSH_CLOVER, 7], // 27

  // August - Susuki Grass
  ["moon", CardType.BRIGHT, FlowerType.SUSUKI, 8], // 28
  ["geese", CardType.ANIMAL, FlowerType.SUSUKI, 8], // 29
  ["chaff-1", CardType.CHAFF, FlowerType.SUSUKI, 8], // 30
  ["chaff-2", CardType.CHAFF, FlowerType.SUSUKI, 8], // 31

  // September - Chrysanthemum (Kiku)
  ["sake-cup", CardType.ANIMAL, FlowerType.CHRYSANTHEMUM, 9], // 32
  ["blue-ribbon", CardType.RIBBON, FlowerType.CHRYSANTHEMUM, 9], // 33
  ["chaff-1", CardType.CHAFF, FlowerType.CHRYSANTHEMUM, 9], // 34
  ["chaff-2", CardType.CHAFF, FlowerType.CHRYSANTHEMUM, 9], // 35

  // October - Maple (Momiji)
  ["deer", CardType.ANIMAL, FlowerType.MAPLE, 10], // 36
  ["blue-ribbon", CardType.RIBBON, FlowerType.MAPLE, 10], // 37
  ["chaff-1", CardType.CHAFF, FlowerType.MAPLE, 10], // 38
  ["chaff-2", CardType.CHAFF, FlowerType.MAPLE, 10], // 39

  // November - Willow (Yanagi)
  ["rain-man", CardType.BRIGHT, FlowerType.WILLOW, 11], // 40
  ["swallow", CardType.ANIMAL, FlowerType.WILLOW, 11], // 41
  ["red-ribbon", CardType.RIBBON, FlowerType.WILLOW, 11], // 42
  ["chaff", CardType.CHAFF, FlowerType.WILLOW, 11], // 43

  // December - Paulownia (Kiri)
  ["phoenix", CardType.BRIGHT, FlowerType.PAULOWNIA, 12], // 44
  ["chaff-1", CardType.CHAFF, FlowerType.PAULOWNIA, 12], // 45
  ["chaff-2", CardType.CHAFF, FlowerType.PAULOWNIA, 12], // 46
  ["chaff-3", CardType.CHAFF, FlowerType.PAULOWNIA, 12], // 47
])

export type Card = {
  id: string
  name: string
  type: CardType
  flower: FlowerType
  month: number
}

export const CARDS: ReadonlyArray<Card> = Object.freeze(
  Array.from({ length: CARDS_LENGTH }, (_, index) => {
    const [name, type, flower, month] = CARD_DATA[index]
    return Object.freeze({
      id: `${flower}-${name}`,
      name,
      type,
      flower,
      month,
    })
  })
)

// Commonly referenced card indices
export const BRIGHT_INDICES: ReadonlyArray<number> = Object.freeze([0, 8, 28, 40, 44])
export const POETRY_RIBBON_INDICES: ReadonlyArray<number> = Object.freeze([1, 5, 9])
export const BLUE_RIBBON_INDICES: ReadonlyArray<number> = Object.freeze([21, 33, 37])
export const RED_RIBBON_INDICES: ReadonlyArray<number> = Object.freeze([13, 17, 25, 42])
export const ANIMAL_INDICES: ReadonlyArray<number> = Object.freeze([
  4, 12, 16, 20, 24, 29, 32, 36, 41,
])

/**
 * Get card data by index
 */
export const getCard = (index: number): Card | null => {
  if (index < 0 || index >= CARDS_LENGTH) return null
  return CARDS[index]
}

/**
 * Get multiple cards by indices
 */
export const getCards = (indices: number[]): Card[] => {
  return indices.map(getCard).filter((card) => card !== null)
}

/**
 * Find all cards of a specific type
 */
export const findCardIndicesByType = (type: CardType): number[] =>
  CARDS.reduce((indices, card, index) => {
    if (card.type === type) indices.push(index)
    return indices
  }, [] as number[])

/**
 * Find all cards from a specific month
 */
export const findCardIndicesByMonth = (month: number): number[] =>
  CARDS.reduce((indices, card, index) => {
    if (card.month === month) indices.push(index)
    return indices
  }, [] as number[])

/**
 * Check if a value is a valid card index
 */
export const isValidCardIndex = (index: unknown): index is number => {
  return typeof index === "number" && Number.isInteger(index) && index >= 0 && index < CARDS_LENGTH
}

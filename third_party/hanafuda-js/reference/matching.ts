import { InvalidCardError } from "../errors.ts"
import { getCard, isValidCardIndex } from "./cards.ts"

/**
 * Check if two card indices match (are from the same month)
 */
export const isMatch = (index1: number, index2: number): boolean => {
  if (!isValidCardIndex(index1) || !isValidCardIndex(index2)) return false
  const card1 = getCard(index1)
  const card2 = getCard(index2)
  return Boolean(card1 && card2 && card1.month === card2.month)
}

/**
 * Compare two card indices for sorting (by month, then by type)
 * @returns -1 if card1 comes first, 1 if card2 comes first, 0 if equal
 */
export const compareCards = (index1: number, index2: number): number => {
  const card1 = getCard(index1)
  const card2 = getCard(index2)

  if (!card1 || !card2) return 0

  // First compare by month
  if (card1.month !== card2.month) {
    return card1.month - card2.month
  }

  // Then by type (BRIGHT > ANIMAL > RIBBON > CHAFF)
  const typeOrder = { bright: 3, animal: 2, ribbon: 1, chaff: 0 }
  return typeOrder[card1.type] - typeOrder[card2.type] > 0
    ? 1
    : typeOrder[card1.type] - typeOrder[card2.type] < 0
    ? -1
    : 0
}

/**
 * Check if any cards in the iterable match the given card
 * @throws {InvalidCardError} If the card index is invalid
 */
export const hasMatch = (cards: Iterable<number>, cardIndex: number): boolean => {
  if (!isValidCardIndex(cardIndex)) {
    throw new InvalidCardError(cardIndex)
  }
  for (const index of cards) {
    if (isMatch(cardIndex, index)) return true
  }
  return false
}

import { INO_SHIKA_CHOU, TANE } from "../yaku/standard/animal.ts"
import { CardType } from "../../core/cards.ts"
import { createCollection } from "../../core/collection.ts"
import type { Collection } from "../../core/types.ts"
import type { AnimalRules } from "./types.ts"
import type { ScoringManager, YakuResult } from "../types.ts"

const SAKE_CUP = 32 // Chrysanthemum Sake Cup

/**
 * Create a custom animal yaku checker with specific rules
 */
export const createAnimalChecker = (rules: AnimalRules = {}): ScoringManager => {
  const { allowMultiple = true, extraPoints = 1, countSakeCup = true } = rules

  /**
   * Check animal yaku for a collection of cards
   */
  return (collection: Collection): YakuResult[] => {
    const completed: YakuResult[] = []

    // Create effective collection based on sake cup handling
    let effectiveCollection = collection
    if (!countSakeCup && collection.has(SAKE_CUP)) {
      // Create a copy of the collection without the sake cup
      effectiveCollection = createCollection({ cards: Array.from(collection) })
      effectiveCollection.remove(SAKE_CUP)
    }
    // Count animals in the effective collection
    const animalCount = effectiveCollection.findByType(CardType.ANIMAL).length

    // Check Ino-Shika-Chou first (higher points)
    const inoShikaChouPoints = INO_SHIKA_CHOU.check(effectiveCollection)
    if (inoShikaChouPoints > 0) {
      // Calculate extra points for additional animals
      const extraAnimalPoints = Math.max(0, animalCount - 3) * extraPoints

      completed.push({
        name: INO_SHIKA_CHOU.name,
        points: inoShikaChouPoints + extraAnimalPoints,
      })
      if (!allowMultiple) return completed
    }

    // Check Tane (Animals)
    if (!countSakeCup && animalCount < 5) {
      // Skip if sake cup is not counted and there are less than 5 animals
      return completed
    }
    const basePoints = TANE.check(effectiveCollection)
    if (basePoints > 0) {
      // Calculate extra points for additional animals
      const extraAnimalPoints = Math.max(0, animalCount - 5) * extraPoints

      completed.push({
        name: TANE.name,
        points: basePoints + extraAnimalPoints,
      })
    }

    return completed
  }
}

/**
 * Default animal yaku checker (allows multiple scoring, 1 extra point per additional animal)
 */
export const checkAnimalYaku: ScoringManager = createAnimalChecker()

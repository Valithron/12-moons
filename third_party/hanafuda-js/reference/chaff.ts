import { KASU } from "../yaku/standard/chaff.ts"
import { CardType } from "../../core/cards.ts"
import type { ChaffRules } from "./types.ts"
import type { Collection } from "../../core/types.ts"
import type { ScoringManager, YakuResult } from "../types.ts"

const SAKE_CUP = 32 // Chrysanthemum Sake Cup

/**
 * Create a custom chaff yaku checker with specific rules
 */
export const createChaffChecker = (rules: ChaffRules = {}): ScoringManager => {
  const { extraPoints = 1, countSakeCup = false } = rules

  return (collection: Collection): YakuResult[] => {
    const completed: YakuResult[] = []

    // Count regular chaff cards
    const chaffCards = collection.findByType(CardType.CHAFF)
    let totalChaffCount = chaffCards.length

    // Handle sake cup counting
    if (countSakeCup && collection.has(SAKE_CUP)) {
      totalChaffCount++
    }

    // Check if we have enough chaff for base yaku
    if (totalChaffCount >= 10) {
      // Get base points from KASU yaku check
      const basePoints = KASU.points
      const extraChaffPoints = Math.max(0, totalChaffCount - 10) * extraPoints

      completed.push({
        name: KASU.name,
        points: basePoints + extraChaffPoints,
      })
    }

    return completed
  }
}

/**
 * Default chaff yaku checker (1 extra point per chaff beyond 10)
 */
export const checkChaffYaku: ScoringManager = createChaffChecker()

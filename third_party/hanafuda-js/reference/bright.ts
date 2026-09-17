import { createCollection } from "../../core/collection.ts"
import type { Collection } from "../../core/types.ts"
import type { ScoringManager, YakuResult } from "../types.ts"
import { GOKOU, SHIKOU, AME_SHIKOU, SANKOU } from "../yaku/standard/bright.ts"
import type { BrightRules } from "./types.ts"

/**
 * Order of precedence for bright yaku (highest to lowest)
 */
const BRIGHT_PRECEDENCE = [GOKOU, SHIKOU, AME_SHIKOU, SANKOU]

/**
 * Rain-man card index
 */
const RAIN_MAN = 40

/**
 * Create a custom bright yaku checker with specific rules
 */
export const createBrightChecker = (rules: BrightRules = {}): ScoringManager => {
  const { allowMultiple = false } = rules

  /**
   * Check bright yaku for a collection of cards
   */
  return (collection: Collection): YakuResult[] => {
    const completed: YakuResult[] = []

    for (const yaku of BRIGHT_PRECEDENCE) {
      let effectiveCollection = collection
      if (yaku === SHIKOU) {
        effectiveCollection = createCollection({ cards: Array.from(collection) })
        effectiveCollection.remove(RAIN_MAN) // Remove Rain-man
      }
      const points = yaku.check(effectiveCollection)
      if (points > 0) {
        completed.push({ name: yaku.name, points })
        // Break after first match unless multiple scoring is allowed
        if (!allowMultiple) break
      }
    }

    return completed
  }
}

/**
 * Default bright yaku checker (no special rules)
 */
export const checkBrightYaku: ScoringManager = createBrightChecker()

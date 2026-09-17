import { TSUKI_FUDA } from "../yaku/standard/month.ts"
import { getCard } from "../../core/cards.ts"
import type { Collection } from "../../core/types.ts"
import type { ScoringContext, ScoringManager, YakuResult } from "../types.ts"
import type { MonthRules } from "./types.ts"

/**
 * Create a custom month cards yaku checker with specific rules
 */
export const createMonthChecker = (rules: MonthRules = {}): ScoringManager => {
  const { allowMultipleMonths = false } = rules

  return (collection: Collection, context: ScoringContext = {}): YakuResult[] => {
    const completed: YakuResult[] = []

    if (!context?.currentMonth) return completed

    // Check current month
    const monthYaku = {
      ...TSUKI_FUDA,
      pattern: {
        cards: [{ month: context.currentMonth, count: 4 }],
      },
    }

    const monthPoints = monthYaku.check(collection)
    if (monthPoints > 0) {
      completed.push({ name: TSUKI_FUDA.name, points: monthPoints })
    }

    // If allowed, check other months too
    if (allowMultipleMonths) {
      // Get counts for all months
      const monthCounts = new Array(12).fill(0)
      for (const cardIndex of collection) {
        const card = getCard(cardIndex)
        if (card && card.month !== context.currentMonth) {
          monthCounts[card.month - 1]++
        }
      }

      // Add yaku for any other months with 4 cards
      monthCounts.forEach((count) => {
        if (count === 4) {
          completed.push({ name: TSUKI_FUDA.name, points: TSUKI_FUDA.points })
        }
      })
    }

    return completed
  }
}

/**
 * Default month cards yaku checker (only current month)
 */
export const checkMonthYaku: ScoringManager = createMonthChecker()

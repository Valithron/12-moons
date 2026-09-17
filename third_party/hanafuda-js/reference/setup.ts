import { getCard } from "../core/cards.ts"
import { checkHandYaku } from "../scoring/rules/hand.ts"
import { YakuResults } from "../scoring/types.ts"
import { createGameState } from "./state.ts"
import type { GameState } from "./types.ts"
/**
 * Determine first player using traditional rules
 * @throws {Error} If no card is drawn from the deck
 */
export function determineFirstPlayer(state: GameState): string {
  // In traditional rules, each player draws a card
  // Player with earliest month goes first
  const draws: Record<string, number> = {}

  for (const playerId of Object.keys(state.players)) {
    const cardIndex = state.deck.draw()
    if (cardIndex === null) {
      throw new Error("No card drawn from deck")
    }
    const card = getCard(cardIndex)
    if (card === null) {
      throw new Error("No card drawn from deck")
    }
    draws[playerId] = card.month

    // Return card to deck
    state.deck.placeOnBottom(cardIndex)
  }

  // Find player with earliest month
  return Object.entries(draws).sort(([, monthA], [, monthB]) => monthA - monthB)[0][0]
}

/**
 * Deal initial cards to players and field
 */
export function dealInitialCards(state: GameState): GameState {
  // Deal 8 cards to each player
  for (const playerId of Object.keys(state.players)) {
    const hand = state.deck.drawMany(8)
    state.players[playerId].hand.addMany(hand)
  }

  // Deal 8 cards to field
  const fieldCards = state.deck.drawMany(8)
  state.field.addMany(fieldCards)

  return state
}

/**
 * Check for teyaku (hand yaku) for all players
 */
export function checkInitialTeyaku(
  state: GameState
): Record<keyof GameState["players"], YakuResults> {
  const results: Record<keyof GameState["players"], YakuResults> = {}

  for (const [playerId, playerState] of Object.entries(state.players)) {
    const teyaku = checkHandYaku(playerState.hand, { checkTeyaku: true })
    if (teyaku.length > 0) {
      results[playerId] = teyaku
    }
  }

  return results
}

/**
 * Initialize a new round
 */
export function initializeRound(
  playerIds: string[],
  options: Record<string, any> = {}
): {
  state: GameState
  teyaku: Record<keyof GameState["players"], YakuResults>
  firstPlayer: string
} {
  // Create initial state
  const state = createGameState(playerIds, options)

  // Deal cards
  dealInitialCards(state)

  // Check for teyaku
  const teyaku = checkInitialTeyaku(state)

  // Return state and first player separately
  return {
    state,
    teyaku,
    firstPlayer: determineFirstPlayer(state),
  }
}

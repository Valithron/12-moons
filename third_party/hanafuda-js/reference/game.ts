import { initializeRound } from "./setup.ts"
import { isMatch } from "../core/matching.ts"
import { createScoringManager, KOIKOI_RULES } from "../scoring/manager.ts"
import { validateGameState } from "./state.ts"
import { isNullish } from "../utils/is-nullish.ts"
import type { GameState } from "./types.ts"
import { RuleConfig, YakuResults } from "../scoring/types.ts"
import { Collection } from "../core/types.ts"
import { InvalidStateError } from "../errors.ts"

export const GamePhase = {
  WAITING_FOR_HAND_CARD: "WAITING_FOR_HAND_CARD",
  WAITING_FOR_FIELD_CARDS: "WAITING_FOR_FIELD_CARDS",
  WAITING_FOR_DECK_MATCH: "WAITING_FOR_DECK_MATCH",
  WAITING_FOR_KOI_DECISION: "WAITING_FOR_KOI_DECISION",
  NO_MATCHES_DISCARD: "NO_MATCHES_DISCARD",
  ROUND_END: "ROUND_END",
} as const
export type GamePhase = (typeof GamePhase)[keyof typeof GamePhase]

export const GameResultType = {
  SELECTION_UPDATED: "SELECTION_UPDATED",
  MATCH_INVALID: "MATCH_INVALID",
  MATCH_VALID: "MATCH_VALID",
  SCORE_UPDATE: "SCORE_UPDATE",
  DECK_DRAW: "DECK_DRAW",
  ROUND_END: "ROUND_END",
  NO_MATCHES: "NO_MATCHES",
  CARD_PLACED: "CARD_PLACED",
  CAPTURE_COMPLETE: "CAPTURE_COMPLETE",
  TURN_END: "TURN_END",
  ERROR: "ERROR",
  STATE_LOADED: "STATE_LOADED",
} as const
export type GameResultType = (typeof GameResultType)[keyof typeof GameResultType]

// Base type for all results
type BaseResult<T extends GameResultType, D = undefined> = {
  type: T
  message?: string
  data: D
}

// Data types for each result type
type HandSelectionData = {
  selectedHandCard: number
  matchingCards: number[]
  canAutoCapture: boolean // true for 1 or 3 matches, false for 2
  phase: GamePhase
}

type FieldSelectionData = {
  selectedHandCard: number
  selectedFieldCards: number[]
  autoSelected?: boolean
  phase: GamePhase
}

type NoMatchesData = {
  selectedHandCard: number
}

type DeckDrawData = {
  drawnCard: number
  matchingCards: number[]
  placedOnField?: boolean
  phase: GamePhase
}

type ScoreUpdateData = {
  completedYaku: YakuResults
  phase: GamePhase
  drawnCard?: number
  placedOnField?: boolean
}

type CardPlacedData = {
  placedCard: number
  nextAction: GameResult
}

type RoundEndData = {
  winner?: keyof GameState["players"]
  yaku?: YakuResults
  message?: string
  phase: GamePhase
}

type CaptureCompleteData = {
  phase: GamePhase
}

type TurnEndData = {
  phase: GamePhase
}

type StateLoadedData = {
  state: GameState
}

// Specific result types used by the API
type HandSelectionResult =
  | BaseResult<"NO_MATCHES", NoMatchesData>
  | BaseResult<"SELECTION_UPDATED", HandSelectionData>
  | BaseResult<"ERROR", { message: string }>

type FieldSelectionResult =
  | BaseResult<"SELECTION_UPDATED", FieldSelectionData>
  | BaseResult<"ERROR", { message: string }>

type CardPlacementResult =
  | { type: "CARD_PLACED"; data: CardPlacedData }
  | { type: "ERROR"; data: { message: string } }

type CaptureResult =
  | { type: "CAPTURE_COMPLETE"; data: CaptureCompleteData }
  | { type: "SCORE_UPDATE"; data: ScoreUpdateData }
  | { type: "ERROR"; data: { message: string } }

type KoiKoiDecisionResult =
  | { type: "TURN_END"; data: TurnEndData }
  | { type: "ROUND_END"; data: RoundEndData }
  | { type: "ERROR"; data: { message: string } }

type StateLoadResult =
  | { type: "STATE_LOADED"; data: StateLoadedData }
  | { type: "ERROR"; data: { message: string } }

// General GameResult type that includes all possible results
export type GameResult =
  | BaseResult<"SELECTION_UPDATED", HandSelectionData | FieldSelectionData>
  | BaseResult<"NO_MATCHES", NoMatchesData>
  | BaseResult<"DECK_DRAW", DeckDrawData>
  | BaseResult<"SCORE_UPDATE", ScoreUpdateData>
  | BaseResult<"CARD_PLACED", CardPlacedData>
  | BaseResult<"ROUND_END", RoundEndData>
  | BaseResult<"CAPTURE_COMPLETE", CaptureCompleteData>
  | BaseResult<"TURN_END", TurnEndData>
  | BaseResult<"STATE_LOADED", StateLoadedData>
  | BaseResult<"ERROR", { message: string }>

/**
 * Core game interface for Koi-Koi implementation.
 * Provides methods for game actions and state management.
 */
export type KoiKoiGame = {
  /** Start a new round with optional player IDs */
  startRound: (players?: string[]) => {
    state: GameState
    teyaku: Record<keyof GameState["players"], YakuResults>
  }
  /** Get current game state */
  getState: () => GameState | null

  // Split selectCard into two specific methods
  /** Select a card from the current player's hand */
  selectHandCard: (cardIndex: number) => HandSelectionResult
  /** Select a card from the field (after hand selection) */
  selectFieldCard: (cardIndex: number) => FieldSelectionResult

  /** Place selected card on field */
  placeSelectedCard: () => CardPlacementResult
  /** Capture matching cards */
  captureCards: () => CaptureResult
  /** Make koi-koi decision to continue or end round */
  makeKoiKoiDecision: (continuePlay: boolean) => KoiKoiDecisionResult
  /** Load a saved game state */
  loadState: (state: GameState) => StateLoadResult
  /** Get current player ID */
  getCurrentPlayer: () => string | null
  /** Get current player's hand */
  getCurrentHand: () => Collection | null
  setCurrentPlayer?: (player: keyof GameState["players"]) => void
  setPhase?: (phase: GamePhase) => void
}

/**
 * Creates a new KoiKoi game instance
 * @param options - Game options
 * @param options.rules - Custom scoring rules
 * @param options.initialState - Initial game state
 * @param options.debug - Whether to enable debug mode
 * @returns {KoiKoiGame}
 */
export const createKoiKoiGame = (
  options: { rules?: RuleConfig; initialState?: GameState; debug?: boolean } = {}
): KoiKoiGame => {
  let state: GameState | null = null
  let phase: GamePhase = "WAITING_FOR_HAND_CARD"
  let selectedHandCard: number | null = null
  const selectedFieldCards = new Set<number>()
  let drawnCard: number | null = null
  const scoring = createScoringManager(options.rules || KOIKOI_RULES)
  const debug = options.debug || false

  const log = (message: string) => {
    if (debug) {
      console.log(message)
    }
  }

  /**
   * Sets the game phase (only available in debug mode)
   * @throws {Error} If not in debug mode
   */
  const setPhase = (newPhase: GamePhase) => {
    if (!debug) {
      throw new Error("Phase can only be set in debug mode")
    }
    phase = newPhase
    // log(`Phase set to ${newPhase}`)
  }

  /**
   * Switches to the next player and resets selection state
   */
  const switchPlayers = () => {
    if (!state) return

    // Update current player
    state.currentPlayer = state.currentPlayer === "player1" ? "player2" : "player1"

    // Reset selection state
    selectedHandCard = null
    selectedFieldCards.clear()
    drawnCard = null
    phase = "WAITING_FOR_HAND_CARD"
  }

  /**
   * Get the current player's hand
   * @throws {InvalidStateError}
   */
  const getCurrentHand = (): Collection => {
    if (!state) {
      throw new InvalidStateError("Game not initialized")
    }

    return state.players[state.currentPlayer].hand
  }

  /**
   * Draws a card and handles matching logic
   * @throws {InvalidStateError}
   */
  const drawCard = (): GameResult => {
    if (!state) {
      throw new InvalidStateError("Game not initialized")
    }

    if (state.deck.isEmpty) {
      phase = "ROUND_END"
      return {
        type: "ROUND_END",
        data: { message: "Deck is empty", phase },
      }
    }

    drawnCard = state.deck.draw()

    if (isNullish(drawnCard)) {
      throw new InvalidStateError("Failed to draw card")
    }

    const cardToMatch = drawnCard
    selectedFieldCards.clear()
    selectedHandCard = null

    const matchingCards = Array.from(state.field).filter((fieldCard) =>
      isMatch(cardToMatch, fieldCard)
    )
    const hasMatches = matchingCards.length > 0

    if (hasMatches) {
      phase = "WAITING_FOR_DECK_MATCH"
      return {
        type: "DECK_DRAW",
        data: { drawnCard, matchingCards, phase },
      }
    }

    // Auto-place card and check scoring
    state.field.add(drawnCard)
    const placedCard = drawnCard
    drawnCard = null

    if (!state.currentPlayer) {
      throw new InvalidStateError("Current player not set")
    }

    const capturedPile = state.players[state.currentPlayer].captured
    const completedYaku = scoring(capturedPile)

    if (completedYaku.length > 0) {
      state.completedYaku = completedYaku
      phase = "WAITING_FOR_KOI_DECISION"
      return {
        type: "SCORE_UPDATE",
        data: { drawnCard: placedCard, placedOnField: true, completedYaku, phase },
      }
    }

    if (getCurrentHand().isEmpty) {
      phase = "ROUND_END"
      return {
        type: "ROUND_END",
        data: { message: `Exhaustive draw: ${state.currentPlayer} has no cards`, phase },
      }
    }
    switchPlayers()
    return {
      type: "DECK_DRAW",
      data: { drawnCard: placedCard, matchingCards: [], placedOnField: true, phase },
    }
  }

  /**
   * Handles selection of a card from the player's hand
   * @throws {InvalidStateError}
   */
  const handleHandCardSelection = (cardIndex: number): GameResult => {
    if (!state) {
      throw new InvalidStateError("Game not initialized")
    }

    const currentHand = getCurrentHand()

    if (!currentHand.has(cardIndex)) {
      return {
        type: "ERROR",
        data: { message: `Card ${cardIndex} not in current player's hand` },
      }
    }

    selectedHandCard = cardIndex
    selectedFieldCards.clear()

    const matchingCards = Array.from(state.field).filter((fieldCard) =>
      isMatch(cardIndex, fieldCard)
    )

    if (matchingCards.length === 0) {
      phase = "NO_MATCHES_DISCARD"
      return {
        type: "NO_MATCHES",
        data: {
          selectedHandCard: cardIndex,
        },
      }
    }

    phase = "WAITING_FOR_FIELD_CARDS"
    return {
      type: "SELECTION_UPDATED",
      data: {
        selectedHandCard: cardIndex,
        matchingCards,
        canAutoCapture: matchingCards.length === 3 || matchingCards.length === 1,
        phase,
      },
    }
  }

  /**
   * Handles selection of cards from the field
   * @throws {InvalidStateError}
   */
  const handleFieldCardSelection = (cardIndex: number): GameResult => {
    if (!state) {
      throw new InvalidStateError("Game not initialized")
    }

    if (isNullish(selectedHandCard) && isNullish(drawnCard)) {
      return {
        type: "ERROR",
        data: { message: "Must select hand card first" },
      }
    }

    const sourceCard = selectedHandCard ?? drawnCard
    if (isNullish(sourceCard)) {
      throw new InvalidStateError("Source card is null despite previous check")
    }

    const fieldCard = cardIndex

    if (!state.field.has(fieldCard)) {
      return {
        type: "ERROR",
        data: { message: `Invalid field card index: ${fieldCard}` },
      }
    }

    if (!isMatch(sourceCard, fieldCard)) {
      return {
        type: "ERROR",
        data: { message: `Selected cards do not match: ${sourceCard} and ${fieldCard}` },
      }
    }

    // Get all matching cards in the field
    const allMatches = Array.from(state.field).filter((card) => isMatch(sourceCard, card))

    if (allMatches.length === 3) {
      // With three matches, automatically select all cards
      selectedFieldCards.clear()
      allMatches.forEach((card) => selectedFieldCards.add(card))

      return {
        type: "SELECTION_UPDATED",
        data: {
          selectedHandCard: sourceCard,
          selectedFieldCards: Array.from(selectedFieldCards),
          autoSelected: true,
          phase,
        },
      }
    } else if (allMatches.length === 2) {
      // With two matches, allow selecting exactly one card
      if (selectedFieldCards.has(fieldCard)) {
        selectedFieldCards.delete(fieldCard)
      } else {
        selectedFieldCards.clear()
        selectedFieldCards.add(fieldCard)
      }

      return {
        type: "SELECTION_UPDATED",
        data: {
          selectedHandCard: sourceCard,
          selectedFieldCards: Array.from(selectedFieldCards),
          phase,
        },
      }
    } else {
      // With single match, automatically select it
      selectedFieldCards.clear()
      selectedFieldCards.add(fieldCard)

      return {
        type: "SELECTION_UPDATED",
        data: {
          selectedHandCard: sourceCard,
          selectedFieldCards: Array.from(selectedFieldCards),
          phase,
        },
      }
    }
  }

  /**
   * Places selected card on the field when no matches are available
   * @throws {InvalidStateError}
   */
  const handlePlaceSelectedCard = (): GameResult => {
    if (!state || !state.currentPlayer) {
      throw new InvalidStateError("Game not initialized")
    }

    if (isNullish(selectedHandCard)) {
      return {
        type: "ERROR",
        data: { message: "No card selected" },
      }
    }

    // Remove from hand and add to field
    getCurrentHand().remove(selectedHandCard)
    state.field.add(selectedHandCard)

    const placedCard = selectedHandCard
    selectedHandCard = null

    return {
      type: "CARD_PLACED",
      data: {
        placedCard,
        nextAction: drawCard(),
      },
    }
  }

  /**
   * Captures selected matching cards
   * @throws {InvalidStateError}
   */
  const handleCaptureCards = (): GameResult => {
    if (!state || !state.currentPlayer) {
      throw new InvalidStateError("Game not initialized")
    }

    if ((isNullish(selectedHandCard) && isNullish(drawnCard)) || selectedFieldCards.size === 0) {
      return {
        type: "ERROR",
        data: { message: "Invalid card selection" },
      }
    }

    const sourceCard = selectedHandCard ?? drawnCard
    if (isNullish(sourceCard)) {
      throw new InvalidStateError("Source card is null despite previous check")
    }

    const fieldCards = Array.from(selectedFieldCards)
    const allMatches = Array.from(state.field).filter((card) => isMatch(sourceCard, card))

    // Validate capture rules
    if (allMatches.length === 3 && fieldCards.length !== 3) {
      return {
        type: "ERROR",
        data: { message: "Must capture all three matching cards" },
      }
    }

    if (allMatches.length === 2 && fieldCards.length !== 1) {
      return {
        type: "ERROR",
        data: { message: "Must capture exactly one card when two matches exist" },
      }
    }

    if (allMatches.length === 1 && fieldCards.length !== 1) {
      return {
        type: "ERROR",
        data: { message: "Must capture the matching card" },
      }
    }

    // Validate all matches
    if (!fieldCards.every((card) => isMatch(sourceCard, card))) {
      return {
        type: "ERROR",
        data: { message: "Invalid matches selected" },
      }
    }

    // Remove cards from their sources
    if (!isNullish(selectedHandCard)) {
      getCurrentHand().remove(selectedHandCard)
    }
    fieldCards.forEach((card) => state!.field.remove(card))

    // Add to captured pile
    const capturedPile = state!.players[state.currentPlayer].captured
    capturedPile?.addMany([sourceCard, ...fieldCards])

    // Check for completed yaku
    const completedYaku = scoring(capturedPile)

    selectedHandCard = null
    selectedFieldCards.clear()
    drawnCard = null

    if (completedYaku.length > 0) {
      state.completedYaku = completedYaku
      phase = "WAITING_FOR_KOI_DECISION"
      return {
        type: "SCORE_UPDATE",
        data: { completedYaku, phase },
      }
    }

    if (isNullish(selectedHandCard)) {
      switchPlayers()
    }

    return {
      type: "CAPTURE_COMPLETE",
      data: { phase: phase! },
    }
  }

  /**
   * Loads a game state
   * @throws {InvalidStateError}
   */
  const loadState = (newState: GameState): StateLoadResult => {
    const result = handleLoadState(newState)

    // Type guard to ensure we only return StateLoadResult types
    if (result.type === "STATE_LOADED" || result.type === "ERROR") {
      return result as StateLoadResult
    }

    return {
      type: "ERROR",
      data: { message: `Unexpected result type: ${result.type}` },
    }
  }

  // Rename the original loadState function to avoid naming conflict
  const handleLoadState = (newState: GameState): GameResult => {
    if (!debug && !validateGameState(newState)) {
      return {
        type: "ERROR",
        data: { message: "Invalid game state" },
      }
    }

    // Reset current selections and phase
    selectedHandCard = null
    selectedFieldCards.clear()
    drawnCard = null

    // Apply new state
    state = newState
    phase = "WAITING_FOR_HAND_CARD"
    return {
      type: "STATE_LOADED",
      data: { state: api.getState()! },
    }
  }

  /**
   * @type {KoiKoiGame}
   */
  const api: KoiKoiGame = {
    startRound: (players: string[] = ["player1", "player2"]) => {
      if (!Array.isArray(players) || players.length !== 2) {
        throw new Error("Players must be an array of length 2")
      }

      const result = initializeRound(players)

      if (!result.state) {
        throw new Error("Failed to initialize round")
      }
      // If initial state was provided, use it instead
      if (options.initialState) {
        const loadResult = loadState(options.initialState)
        if (loadResult.type === "ERROR") {
          throw new Error(loadResult.data.message)
        }
        return { state: api.getState()!, teyaku: result.teyaku }
      }

      state = result.state
      phase = "WAITING_FOR_HAND_CARD"
      drawnCard = null
      return { state: api.getState()!, teyaku: result.teyaku }
    },

    getState: () =>
      state
        ? Object.freeze({
            ...state,
            currentPlayer: state.currentPlayer,
            phase,
            selectedHandCard,
            selectedFieldCards: Array.from(selectedFieldCards),
            drawnCard,
          })
        : null,

    selectHandCard: (cardIndex: number): HandSelectionResult => {
      const result = handleHandCardSelection(cardIndex)

      // Type guard to ensure we only return HandSelectionResult types
      if (
        result.type === "NO_MATCHES" ||
        result.type === "SELECTION_UPDATED" ||
        result.type === "ERROR"
      ) {
        return result as HandSelectionResult
      }

      // If we get an unexpected result type, convert it to an error
      return {
        type: "ERROR",
        data: { message: `Unexpected result type: ${result.type}` },
      }
    },

    selectFieldCard: (cardIndex: number): FieldSelectionResult => {
      const result = handleFieldCardSelection(cardIndex)

      // Type guard to ensure we only return FieldSelectionResult types
      if (result.type === "SELECTION_UPDATED" || result.type === "ERROR") {
        return result as FieldSelectionResult
      }

      // If we get an unexpected result type, convert it to an error
      return {
        type: "ERROR",
        data: { message: `Unexpected result type: ${result.type}` },
      }
    },

    placeSelectedCard: (): CardPlacementResult => {
      if (!state) {
        return { type: "ERROR", data: { message: "Game not initialized" } }
      }

      if (phase !== "NO_MATCHES_DISCARD") {
        return { type: "ERROR", data: { message: "Invalid game phase for placing card" } }
      }

      const result = handlePlaceSelectedCard()

      // Type guard to ensure we only return CardPlacementResult types
      if (result.type === "CARD_PLACED" || result.type === "ERROR") {
        return result as CardPlacementResult
      }

      return {
        type: "ERROR",
        data: { message: `Unexpected result type: ${result.type}` },
      }
    },

    captureCards: (): CaptureResult => {
      if (!state) {
        return { type: "ERROR", data: { message: "Game not initialized" } }
      }

      if (phase !== "WAITING_FOR_FIELD_CARDS" && phase !== "WAITING_FOR_DECK_MATCH") {
        return { type: "ERROR", data: { message: "Invalid game phase for capturing cards" } }
      }

      const result = handleCaptureCards()

      // Type guard to ensure we only return CaptureResult types
      if (
        result.type === "CAPTURE_COMPLETE" ||
        result.type === "SCORE_UPDATE" ||
        result.type === "ERROR"
      ) {
        return result as CaptureResult
      }

      return {
        type: "ERROR",
        data: { message: `Unexpected result type: ${result.type}` },
      }
    },

    makeKoiKoiDecision: (continuePlay: boolean): KoiKoiDecisionResult => {
      if (!state) {
        return { type: "ERROR", data: { message: "Game not initialized" } }
      }

      if (phase !== "WAITING_FOR_KOI_DECISION") {
        return {
          type: "ERROR",
          data: { message: "Invalid game phase for koi-koi decision" },
        }
      }

      if (continuePlay) {
        switchPlayers()
        return {
          type: "TURN_END",
          data: { phase },
        }
      }

      phase = "ROUND_END"
      return {
        type: "ROUND_END",
        data: {
          winner: state.currentPlayer,
          yaku: state.completedYaku,
          phase,
        },
      }
    },

    loadState,

    setPhase: debug ? setPhase : undefined,

    getCurrentPlayer: () => state?.currentPlayer ?? null,

    getCurrentHand: () => (state ? state.players[state.currentPlayer].hand : null),

    ...(debug && {
      setCurrentPlayer: (player: keyof GameState["players"]) => {
        if (state?.players[player]) {
          state.currentPlayer = player
        } else {
          throw new Error(`Invalid player: ${player}`)
        }
      },
    }),
  }

  return api
}

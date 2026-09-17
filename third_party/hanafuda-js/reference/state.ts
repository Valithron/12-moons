import { createDeck } from "../core/deck.ts"
import { createCollection } from "../core/collection.ts"
import type { Collection, Deck } from "../core/types.ts"
import { InvalidStateError } from "../errors.ts"
import { YakuName } from "../scoring/types.ts"

export type PlayerState = {
  hand: Collection
  captured: Collection
  isActive: boolean
  score: number
}

export type GameState = {
  deck: Deck
  field: Collection
  players: Record<string, PlayerState>
  currentPlayer: string
  currentMonth: number
  weather: string | null
  completedYaku: Array<{ name: YakuName; points: number }>
  debug?: boolean
  toJSON(): any
  toString(): string
}

/**
 * Create initial game state for a new round
 * @throws {InvalidStateError} If the JSON is invalid
 */
export function createGameState(
  playerIds: string[],
  options: { month?: number; weather?: string; fromJSON?: string; debug?: boolean } = {}
): Readonly<GameState> {
  const { month = 1, weather = null, fromJSON, debug = false } = options

  if (fromJSON) {
    return deserializeState(fromJSON)
  }

  // Initialize player states with new fields
  const players: Record<string, PlayerState> = {}
  for (const [index, id] of playerIds.entries()) {
    players[id] = {
      hand: createCollection(),
      captured: createCollection(),
      isActive: index === 0, // First player starts active
      score: 0,
    }
  }

  // Create a mutable container for state that needs to change
  const mutableState = {
    currentMonth: month,
    completedYaku: [],
    currentPlayerId: playerIds[0], // Add this to track current player
  }

  const state = {
    deck: createDeck(),
    field: createCollection(),
    players,
    get currentPlayer() {
      return mutableState.currentPlayerId
    },
    get currentMonth() {
      return mutableState.currentMonth
    },
    set currentMonth(newMonth: number) {
      if (newMonth >= 1 && newMonth <= 12) {
        mutableState.currentMonth = newMonth
      } else {
        throw new Error(`Invalid month: ${newMonth}`)
      }
    },
    weather,
    get completedYaku() {
      return [...mutableState.completedYaku]
    },
    set completedYaku(yaku) {
      mutableState.completedYaku = [...yaku]
    },
    toJSON() {
      return {
        deck: this.deck.toJSON(),
        field: this.field.toJSON(),
        players: Object.fromEntries(
          Object.entries(this.players).map(([id, state]) => [
            id,
            {
              hand: state.hand.toJSON(),
              captured: state.captured.toJSON(),
              isActive: state.isActive,
              score: state.score,
            },
          ])
        ),
        currentPlayer: mutableState.currentPlayerId,
        currentMonth: mutableState.currentMonth,
        weather: this.weather,
        completedYaku: mutableState.completedYaku,
      }
    },
    toString() {
      return `GameState(month: ${mutableState.currentMonth})`
    },
    [Symbol.for("nodejs.util.inspect.custom")]() {
      return this.toString()
    },
    set currentPlayer(playerId: string) {
      if (!players[playerId]) {
        throw new Error(`Invalid player ID: ${playerId}`)
      }

      // Update active status for all players
      Object.keys(players).forEach((id) => {
        players[id].isActive = id === playerId
      })
      mutableState.currentPlayerId = playerId
    },
  } as const satisfies GameState

  return Object.freeze(state)
}

/**
 * Deserialize a game state from JSON
 * @param {string} json - JSON string to parse
 * @returns {Readonly<GameState>}
 * @throws {InvalidStateError} If JSON is invalid
 */
function deserializeState(json: string): Readonly<GameState> {
  const data: GameState = JSON.parse(json)

  // Basic property validation
  if (!data.deck || !data.field || !data.players || !data.currentMonth || !data.currentPlayer) {
    throw new InvalidStateError("Invalid state data: missing required properties")
  }

  // Create state with collections
  const state: GameState = {
    deck: createDeck({ fromJSON: JSON.stringify(data.deck) }),
    field: createCollection({ fromJSON: JSON.stringify(data.field) }),
    players: {},
    currentPlayer: data.currentPlayer,
    currentMonth: data.currentMonth,
    weather: data.weather,
    completedYaku: data.completedYaku || [],
    toJSON() {
      return {
        deck: this.deck.toJSON(),
        field: this.field.toJSON(),
        players: Object.fromEntries(
          Object.entries(this.players).map(([id, state]) => [
            id,
            {
              hand: state.hand.toJSON(),
              captured: state.captured.toJSON(),
              isActive: state.isActive,
              score: state.score,
            },
          ])
        ),
        currentPlayer: this.currentPlayer,
        currentMonth: this.currentMonth,
        weather: this.weather,
        completedYaku: this.completedYaku,
      }
    },
    toString() {
      return `GameState(month: ${this.currentMonth})`
    },
    [Symbol.for("nodejs.util.inspect.custom")]() {
      return this.toString()
    },
  }

  // Restore player states
  for (const [playerId, playerData] of Object.entries(data.players)) {
    state.players[playerId] = {
      hand: createCollection({ fromJSON: JSON.stringify(playerData.hand) }),
      captured: createCollection({ fromJSON: JSON.stringify(playerData.captured) }),
      isActive: playerData.isActive ?? false,
      score: playerData.score ?? 0,
    }
    if (playerData.isActive) {
      state.currentPlayer = playerId
    }
  }

  // Validate the complete state
  validateGameState(state)

  return Object.freeze(state)
}

/**
 * Validates a game state object
 * @throws {InvalidStateError} If state is invalid
 */
export function validateGameState(state: GameState): boolean {
  // Check required properties
  if (!state.deck || !state.field || !state.players || !state.currentPlayer) {
    throw new InvalidStateError("Invalid state data: missing required properties")
  }

  // Validate players
  for (const [_, playerState] of Object.entries(state.players)) {
    if (!playerState.hand || !playerState.captured) {
      throw new InvalidStateError("Invalid state data: missing player hand or captured")
    }
  }

  // Validate card uniqueness
  const allCards = new Set([
    ...state.deck.toJSON(),
    ...state.field.toJSON(),
    ...Object.values(state.players).flatMap((p) => [...p.hand.toJSON(), ...p.captured.toJSON()]),
  ])

  // Total cards should be 48
  if (allCards.size !== 48) {
    throw new InvalidStateError("Invalid state data: total cards should be 48")
  }

  // Validate active player
  const activeCount = Object.values(state.players).filter((p) => p.isActive).length
  if (activeCount !== 1) {
    throw new InvalidStateError("Invalid state data: found no or multiple active players")
  }

  if (!state.players[state.currentPlayer]) {
    throw new InvalidStateError("Invalid state data: current player not found")
  }

  return true
}

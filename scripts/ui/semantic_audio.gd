class_name MoonSemanticAudio
extends RefCounted

## Semantic audio hooks. Audio assets and mixing may be authored later; callers
## emit intent names rather than coupling gameplay to a particular sample.
const UI_CONFIRM := "ui.confirm"
const UI_REJECT := "ui.reject"
const CARD_PLAY := "card.play"
const CARD_CAPTURE := "card.capture"
const SCORE_REVEAL := "score.reveal"
const REWARD_COMMIT := "reward.commit"
const SHOP_PURCHASE := "shop.purchase"
const SHOP_REROLL := "shop.reroll"
const MONTH_TRANSITION := "month.transition"

--!strict
-- Tipos compartilhados entre Enemies e BossAI (evita dependência circular).

local EnemySpec = require(game:GetService("ReplicatedStorage").Shared.EnemySpec)

export type Target = { player: Player, root: BasePart, humanoid: Humanoid }
export type Wave = { x: number, y: number, dir: number, speed: number, untilT: number }
export type Rock = { x: number, y: number, hitAt: number, fallSent: boolean }

export type BossData = {
	phase: number,
	lastAttack: string,
	damageSince: number,
	pendingStagger: boolean,
	arenaMin: number,
	arenaMax: number,
	waves: { Wave },
	rocks: { Rock },
	fromX: number,
	toX: number,
	airT: number,
	airDur: number,
	noTargetSince: number,
}

export type Enemy = {
	def: EnemySpec.EnemyDef,
	model: Model,
	root: BasePart,
	x: number,
	y: number,
	facing: number,
	knockVx: number,
	health: number,
	maxHealth: number,
	state: string,
	stateEnd: number,
	nextAction: number,
	stunnedUntil: number,
	homeX: number,
	homeY: number,
	range: number,
	groundY: number,
	aimX: number,
	aimY: number,
	phaseOffset: number,
	boss: BossData?,
	shownTo: { [Player]: boolean },
	markerId: string,
}

export type Env = {
	now: number,
	targets: { Target },
	floorY: (x: number, y: number) -> number?,
	damage: (Player, number, number) -> (),
	fx: (kind: string, a: any?, b: any?, c: any?, d: any?) -> (),
	setState: (Enemy, string, number, string?) -> (),
}

return {}

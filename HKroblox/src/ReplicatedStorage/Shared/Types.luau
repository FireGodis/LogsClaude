--!strict
-- Tipos compartilhados entre cliente e servidor.

export type AttackDir = "F" | "U" | "D"

export type AnimInfo = {
	state: string, -- locomoção: Idle | Run | Jump | Fall
	facing: number, -- 1 direita, -1 esquerda
	vx: number,
	vy: number,
	grounded: boolean,
	attackDir: string,
	attackP: number, -- progresso do golpe 0..1, ou -1 se não está atacando
	hurt: boolean,
	dashing: boolean,
	focusing: boolean,
	dead: boolean,
	flapP: number, -- progresso do bater de asas 0..1, ou -1
	wallSide: number, -- -1/1 = agarrado à parede daquele lado, 0 = não
}

export type Profile = {
	version: number,
	cacos: number,
	fragments: number,
	maxMasks: number,
	checkpoint: string,
	flags: { [string]: boolean },
	collected: { [string]: boolean },
	abilities: { [string]: boolean },
	lock: { jobId: string, at: number }?,
}

return {}

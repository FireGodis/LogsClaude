--!strict
-- Todos os números de ajuste do jogo ficam aqui. Nada de números mágicos espalhados.

local Config = {
	GameTitle = "ROLLOW KNIFE",

	Respawn = { Delay = 2.4 },

	Masks = { Default = 5, Max = 9, IFrames = 1.3, ContactDamage = 1 },
	Soul = { Max = 99, GainPerHit = 11, FocusCost = 33, FocusTime = 0.95 },

	Move = {
		RunSpeed = 21,
		JumpVelocity = 60,
		DoubleJumpVelocity = 68,
		DoubleJumpDrift = 8,
		DoubleJumpFloatTime = 0.22,
		FlapDuration = 0.52,
		WallProbeDistance = 1.35,
		WallJumpVelocityX = 36,
		WallJumpVelocityY = 78,
		WallSlideSpeed = 9,
		WallJumpLock = 0.18,
		WallJumpRegrabCooldown = 0.16,
		UnskilledWallFallSpeed = 26,
		JumpCut = 0.42,
		CoyoteTime = 0.09,
		JumpBuffer = 0.12,
		FallGravityMult = 1.7,
		MaxFallSpeed = 88,
		DashSpeed = 70,
		DashTime = 0.17,
		DashCooldown = 0.6,
		PogoVelocity = 56,
		KnockbackX = 30,
		KnockbackY = 24,
		HurtStagger = 0.3,
	},

	Combat = {
		NailDamage = 2,
		AttackCooldown = 0.36,
		AttackTime = 0.24,
		ReachForward = 6.4,
		ReachVertical = 6.2,
		HalfHeight = 2.7,
		HitStop = 0.06,
		PulseCooldown = 5,
		PulseRadius = 18,
		EchoDuration = 5,
		StunDuration = 1.5,
	},

	World = { BenchSafeRadius = 15, BenchSafeHeight = 8 },

	Enemy = {
		SentinelSpeed = 3.5,
		SentinelContactRange = 3.5,
		SentinelReward = 4,
		BossReward = 60,
		BossDamage = 2,
		BossAttackCooldown = 3.4,
		BossPhase2Cooldown = 2.5,
		BossTelegraph = 0.85,
		BossPhase2Telegraph = 0.62,
		BossSweepRange = 8,
	},

	Camera = { Distance = 38, FOV = 50, LookAhead = 4, VerticalOffset = 3, MinX = -26 },

	DefaultAbilities = { dash = true, pulse = true },
}

return Config

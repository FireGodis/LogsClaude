--!strict
-- Regras puras (sem Instances): dano em máscaras, alma, caixa de golpe.
-- Por ser pura, é testável sem rodar o jogo.

local MaskMath = {}

function MaskMath.applyDamage(masks: number, amount: number): (number, boolean)
	local remaining = math.max(0, masks - math.max(0, amount))
	return remaining, remaining <= 0
end

function MaskMath.heal(masks: number, maxMasks: number, amount: number): number
	return math.min(maxMasks, masks + amount)
end

function MaskMath.addSoul(soul: number, gain: number, cap: number): number
	return math.clamp(soul + gain, 0, cap)
end

function MaskMath.canFocus(soul: number, masks: number, maxMasks: number, cost: number): boolean
	return soul >= cost and masks > 0 and masks < maxMasks
end

-- Caixa do golpe do Prego. origin = posição do jogador. Retorna (centro, meia-medida).
function MaskMath.hitBox(origin: Vector2, dir: string, facing: number, reachF: number, reachV: number, halfH: number): (Vector2, Vector2)
	if dir == "U" then
		return Vector2.new(origin.X, origin.Y + 1.2 + reachV * 0.5), Vector2.new(halfH * 0.9, reachV * 0.5 + 0.6)
	elseif dir == "D" then
		return Vector2.new(origin.X, origin.Y - 1.2 - reachV * 0.5), Vector2.new(halfH * 0.9, reachV * 0.5 + 0.6)
	end
	return Vector2.new(origin.X + facing * (reachF * 0.5 + 0.4), origin.Y + 0.4), Vector2.new(reachF * 0.5 + 0.4, halfH)
end

function MaskMath.overlaps(center: Vector2, half: Vector2, target: Vector2, radius: Vector2): boolean
	return math.abs(target.X - center.X) <= half.X + radius.X and math.abs(target.Y - center.Y) <= half.Y + radius.Y
end

return MaskMath

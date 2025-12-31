package event

PlayerEvent :: union {
	Playing,
	Paused,
}

Playing :: struct {
	track_id: string,
	position_ms: int,
}

Paused :: struct {
	track_id: string,
	position_ms: int,
}
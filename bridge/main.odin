package bridge

import "core:os"
import win "core:sys/windows"
import "core:encoding/cbor"

import "event"

main :: proc() {
	handle := win.CreateNamedPipeW(
		"\\\\.\\pipe\\jamjambridge",
		win.PIPE_ACCESS_OUTBOUND,
        win.PIPE_TYPE_BYTE | win.PIPE_WAIT,
        1, 4096, 4096, 0, nil,
	)
    defer win.CloseHandle(handle)

    ok := win.ConnectNamedPipe(handle, nil)
	assert(bool(ok))

	player_event: event.PlayerEvent
	switch os.get_env("PLAYER_EVENT") {
	case "playing":
		player_event = event.Playing {
			track_id = os.get_env("TRACK_ID"),
			// position_ms = os.get_env("POSITION_MS"),
		}
	case "paused":
		player_event = event.Paused {
			track_id = os.get_env("TRACK_ID"),
			// position_ms = os.get_env("POSITION_MS"),
		}
	case:
		player_event = nil
	}

	player_event_data, err := cbor.marshal(player_event)
	assert(err == nil)

	bytes_written: u32
	ok = win.WriteFile(handle, raw_data(player_event_data), u32(len(player_event_data)), &bytes_written, nil)
	assert(bool(ok))
}
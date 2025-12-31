package client

import "core:fmt"
import "core:os/os2"
import win "core:sys/windows"
import "core:encoding/cbor"

import "../bridge/event"

main :: proc() {
	librespot, err := os2.process_start({
		command = {
			"librespot.exe",
			"-o bridge.exe",
		}
	})
	assert(err == nil)
	defer {
		err := os2.process_kill(librespot)
		assert(err == nil)
		err = os2.process_close(librespot)
		assert(err == nil)
	}

	// ui_init()
	// defer ui_deinit()
	
	// ui_loop()

	for {
		h := win.CreateFileW("\\\\.\\pipe\\jamjambridge", win.GENERIC_READ, 0, nil, win.OPEN_EXISTING, 0, nil)
		if h == win.INVALID_HANDLE do continue
		buf: [4096]u8
		bytes_read: u32
		ok := win.ReadFile(h, raw_data(buf[:]), 4096, &bytes_read, nil)
		if !ok do continue
		fmt.println(ok, bytes_read, string(buf[:bytes_read]))

		player_event: event.PlayerEvent
		err := cbor.unmarshal(buf[:bytes_read], &player_event)
		assert(err == nil)

		fmt.println(player_event)
	}
}

package cliend

import "core:fmt"
import "core:os/os2"
import win "core:sys/windows"
import "core:encoding/cbor"

import "../bridge/event"
import http "../odin-http"
import "../odin-http/client"
import "core:net"
import "core:bytes"
import "core:encoding/base64"
import "core:encoding/json"
import "core:os"
import "core:time"

callback :: proc(req: ^http.Request, res: ^http.Response) {
	http.respond_plain(res, "you can close me :)")
	code := http.query_get(req.url, "code")

	req: client.Request
	client.request_init(&req, .Post)
	defer client.request_destroy(&req)
	
	// dumbass fucking http api......
	bytes.buffer_write_string(&req.body, fmt.tprintf("code=%s&redirect_uri=%s&grant_type=authorization_code", code, "http://127.0.0.1:5500/callback"))

	b64auth := base64.encode(transmute([]u8)string("593d8afbe20c4048a1d5377a4d45bb74:6af4de1840b94bc7a5e719423906542e"))
	http.headers_set_content_type_mime(&req.headers, .Url_Encoded)
	http.headers_set(&req.headers, "Authorization", fmt.tprintf("Basic %s", b64auth))

	res, err := client.request(&req, "https://accounts.spotify.com/api/token")
	assert(err == nil)
	defer client.response_destroy(&res)

	body, alloc, berr := client.response_body(&res)
	assert(berr == nil)
	defer client.body_destroy(body, alloc)

	fmt.println(body)

	token_body: TokenBody
	jerr := json.unmarshal(transmute([]u8)body.(client.Body_Plain), &token_body)
	assert(jerr == nil)

	expires := time.time_add(time.now(), time.Second * time.Duration(token_body.expires_in))
	ok := os.write_entire_file(".token", transmute([]u8)fmt.tprintf("%d\n%s\n%s", time.time_to_unix(expires), token_body.access_token, token_body.refresh_token))
	assert(ok)
}

TokenBody :: struct {
	access_token: string,
	refresh_token: string,
	expires_in: int,
}

main :: proc() {
	server: http.Server
	http.server_shutdown_on_interrupt(&server)  // do this for librespot process aswell

	router: http.Router
	http.router_init(&router)
	defer http.router_destroy(&router)

	http.route_get(&router, "/callback", http.handler(callback))

	routed := http.router_handler(&router)
	err := http.listen_and_serve(&server, routed, {
		address = net.IP4_Loopback,
		port = 5500,
	})
	assert(err == nil)

	// librespot, err := os2.process_start({
	// 	command = {
	// 		"librespot.exe",
	// 		"-o bridge.exe",
	// 	}
	// })
	// assert(err == nil)
	// defer {
	// 	err := os2.process_kill(librespot)
	// 	assert(err == nil)
	// 	err = os2.process_close(librespot)
	// 	assert(err == nil)
	// }

	// ui_init()
	// defer ui_deinit()
	
	// ui_loop()

	// for {
	// 	h := win.CreateFileW("\\\\.\\pipe\\jamjambridge", win.GENERIC_READ, 0, nil, win.OPEN_EXISTING, 0, nil)
	// 	if h == win.INVALID_HANDLE do continue
	// 	buf: [4096]u8
	// 	bytes_read: u32
	// 	ok := win.ReadFile(h, raw_data(buf[:]), 4096, &bytes_read, nil)
	// 	if !ok do continue
	// 	fmt.println(ok, bytes_read, string(buf[:bytes_read]))

	// 	player_event: event.PlayerEvent
	// 	err := cbor.unmarshal(buf[:bytes_read], &player_event)
	// 	assert(err == nil)

	// 	fmt.println(player_event)
	// }
}

// https://accounts.spotify.com/authorize?response_type=code&client_id=593d8afbe20c4048a1d5377a4d45bb74&scope=user-modify-playback-state&redirect_uri=http://127.0.0.1:5500/callback
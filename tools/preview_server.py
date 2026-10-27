"""Serve the compiled Flutter app on this computer only. Standard library only."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Timer
import sys
import webbrowser


def main():
    root = Path(sys.argv[1]).resolve()
    if not (root / "index.html").is_file():
        raise SystemExit("The Flutter preview folder does not contain index.html.")
    handler = partial(SimpleHTTPRequestHandler, directory=str(root))
    server = None
    for port in range(5183, 5194):
        try:
            server = ThreadingHTTPServer(("127.0.0.1", port), handler)
            break
        except OSError:
            continue
    if server is None:
        raise SystemExit("No free preview port (5183-5193). Close an earlier preview and retry.")
    url = f"http://127.0.0.1:{server.server_port}/"
    print(f"\nOtbasy Capital: {url}\nKeep this window open. Ctrl+C stops the preview.\n", flush=True)
    if "--no-browser" not in sys.argv[2:]:
        Timer(0.8, lambda: webbrowser.open(url)).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nPreview stopped.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()

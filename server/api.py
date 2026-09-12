"""WSGI API factory; deployment must supply authenticated identity and store verifier."""
import json


def create_app(ledger, authenticate):
    def app(environ, start_response):
        status = "200 OK"
        try:
            account = authenticate(environ.get("HTTP_AUTHORIZATION", ""))
            if not account:
                raise PermissionError("authentication required")
            if environ.get("REQUEST_METHOD") != "POST":
                raise ValueError("POST required")
            size = int(environ.get("CONTENT_LENGTH") or 0)
            if not 0 <= size <= 65536:
                raise ValueError("invalid request size")
            body = json.loads(environ["wsgi.input"].read(size) or b"{}")
            if not isinstance(body, dict):
                raise ValueError("invalid body")
            route = environ.get("PATH_INFO")
            if route == "/wallet":
                response = ledger.wallet(account)
            elif route == "/unlock":
                response = ledger.unlock(account, body.get("kind"), body.get("id"))
            elif route == "/receipt":
                response = ledger.credit(account, body.get("proof"))
            else:
                status, response = "404 Not Found", {"error": "not found"}
        except PermissionError:
            status, response = "401 Unauthorized", {"error": "authentication required"}
        except (ValueError, TypeError):
            status, response = "409 Conflict", {"error": "request rejected"}
        except Exception:
            status, response = "503 Service Unavailable", {"error": "temporarily unavailable"}
        data = json.dumps(response).encode()
        start_response(status, [("Content-Type", "application/json"), ("Content-Length", str(len(data))), ("Cache-Control", "no-store")])
        return [data]
    return app

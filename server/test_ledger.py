import io
import json
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from dataclasses import replace
from pathlib import Path
from server.ledger import Ledger, VerifiedPurchase
from server.api import create_app


class LedgerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.purchase = VerifiedPurchase("google", "transaction-1", "alice", "nightcat.tokens.300", "purchased", "sandbox")
        self.ledger = Ledger(str(Path(self.temp.name) / "ledger.db"), lambda proof: self.purchase if proof == "verified-fixture" else None, "sandbox")

    def test_credit_dedup_and_shared_unlocks(self):
        with ThreadPoolExecutor(4) as pool:
            list(pool.map(lambda _: self.ledger.credit("alice", "verified-fixture"), range(8)))
        self.assertEqual(self.ledger.wallet("alice")["tokens"], 300)
        self.ledger.unlock("alice", "cat", 1)
        with ThreadPoolExecutor(4) as pool:
            list(pool.map(lambda _: self.ledger.unlock("alice", "theme", 1), range(8)))
        self.assertEqual(self.ledger.wallet("alice"), {"tokens": 120, "cats": [0, 1], "themes": [0, 1]})
        with self.assertRaises(ValueError):
            self.ledger.unlock("alice", "cat", 3)
        self.assertEqual(self.ledger.wallet("alice")["tokens"], 120)

    def test_concurrent_spends_cannot_overdraw_and_survive_restart(self):
        self.ledger.credit("alice", "verified-fixture")
        def spend(kind):
            try:
                self.ledger.unlock("alice", kind, 3)
                return True
            except ValueError:
                return False
        with ThreadPoolExecutor(2) as pool:
            self.assertEqual(sorted(pool.map(spend, ["cat", "theme"])), [False, True])
        reopened = Ledger(self.ledger.path, lambda _: None, "sandbox")
        self.assertEqual(reopened.wallet("alice")["tokens"], 120)
        self.assertEqual(sum(len(reopened.wallet("alice")[key]) for key in ("cats", "themes")), 3)

    def test_rejected_receipts_do_not_credit(self):
        for change in ({"state": "pending"}, {"state": "cancelled"}, {"state": "refunded"}, {"account": "bob"}, {"environment": "production"}, {"quantity": -1}, {"product": "forged"}):
            original = self.purchase
            self.purchase = replace(original, **change)
            with self.assertRaises(ValueError):
                self.ledger.credit("alice", "verified-fixture")
            self.purchase = original
        with self.assertRaises(ValueError):
            self.ledger.credit("alice", {"tokens": 9999})
        self.assertEqual(self.ledger.wallet("alice")["tokens"], 0)

    def test_receipt_cannot_move_accounts(self):
        self.ledger.credit("alice", "verified-fixture")
        self.purchase = replace(self.purchase, account="bob")
        with self.assertRaises(ValueError):
            self.ledger.credit("bob", "verified-fixture")
        self.assertEqual(self.ledger.wallet("bob")["tokens"], 0)

    def test_api_uses_authenticated_account_and_server_price(self):
        app = create_app(self.ledger, lambda token: "alice" if token == "Bearer fixture" else None)
        def request(route, body, token="Bearer fixture"):
            data = json.dumps(body).encode()
            statuses = []
            result = app({"HTTP_AUTHORIZATION": token, "REQUEST_METHOD": "POST", "PATH_INFO": route, "CONTENT_LENGTH": str(len(data)), "wsgi.input": io.BytesIO(data)}, lambda status, headers: statuses.append(status))
            return statuses[0], json.loads(b"".join(result))
        self.assertEqual(request("/receipt", {"proof": "verified-fixture"})[1]["tokens"], 300)
        self.assertEqual(request("/unlock", {"kind": "cat", "id": 1, "price": 0, "account": "bob"})[1]["tokens"], 220)
        self.assertEqual(request("/wallet", {}, "")[0], "401 Unauthorized")
        self.assertEqual(self.ledger.wallet("bob")["tokens"], 0)


if __name__ == "__main__":
    unittest.main()

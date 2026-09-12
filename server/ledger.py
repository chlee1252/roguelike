"""Server-owned token ledger. Native store verification is an injected boundary."""
from dataclasses import dataclass
from contextlib import contextmanager
import sqlite3

CAT_PRICES = (0, 80, 140, 180)
THEME_PRICES = (0, 100, 140, 180)
PRODUCTS = {f"nightcat.tokens.{n}": n for n in (100, 300, 700)}


@dataclass(frozen=True)
class VerifiedPurchase:
    store: str
    transaction: str
    account: str
    product: str
    state: str
    environment: str
    quantity: int = 1


class Ledger:
    def __init__(self, path, verifier, environment="production"):
        self.path = path
        self.verifier = verifier
        self.environment = environment
        with self.connect() as db:
            db.executescript("""
                CREATE TABLE IF NOT EXISTS wallets(account TEXT PRIMARY KEY, tokens INTEGER NOT NULL CHECK(tokens>=0));
                CREATE TABLE IF NOT EXISTS receipts(store TEXT, transaction_id TEXT, account TEXT NOT NULL,
                    product TEXT NOT NULL, quantity INTEGER NOT NULL, PRIMARY KEY(store, transaction_id));
                CREATE TABLE IF NOT EXISTS unlocks(account TEXT, kind TEXT, item INTEGER,
                    PRIMARY KEY(account, kind, item));
            """)

    @contextmanager
    def connect(self):
        db = sqlite3.connect(self.path, timeout=15)
        try:
            with db:
                yield db
        finally:
            db.close()

    @staticmethod
    def _snapshot(db, account):
        row = db.execute("SELECT tokens FROM wallets WHERE account=?", (account,)).fetchone()
        result = {"tokens": row[0] if row else 0, "cats": [0], "themes": [0]}
        for kind, item in db.execute("SELECT kind,item FROM unlocks WHERE account=? ORDER BY item", (account,)):
            result["cats" if kind == "cat" else "themes"].append(item)
        return result

    def wallet(self, account):
        with self.connect() as db:
            return self._snapshot(db, account)

    def credit(self, account, proof):
        # Verifier must contact the store / validate its signed transaction, including app ID,
        # account binding, revocation and environment. Never construct this from client fields.
        purchase = self.verifier(proof)
        if not isinstance(purchase, VerifiedPurchase) or purchase.account != account:
            raise ValueError("unverified purchase or account mismatch")
        if (purchase.store not in ("apple", "google") or not purchase.transaction
                or purchase.product not in PRODUCTS or purchase.state != "purchased"
                or purchase.environment != self.environment or type(purchase.quantity) is not int
                or not 1 <= purchase.quantity <= 100):
            raise ValueError("purchase not eligible")
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            prior = db.execute("SELECT account,product,quantity FROM receipts WHERE store=? AND transaction_id=?",
                               (purchase.store, purchase.transaction)).fetchone()
            if prior:
                if prior != (account, purchase.product, purchase.quantity):
                    raise ValueError("receipt already bound")
                return self._snapshot(db, account)
            db.execute("INSERT OR IGNORE INTO wallets VALUES (?,0)", (account,))
            db.execute("INSERT INTO receipts VALUES (?,?,?,?,?)",
                       (purchase.store, purchase.transaction, account, purchase.product, purchase.quantity))
            db.execute("UPDATE wallets SET tokens=tokens+? WHERE account=?",
                       (PRODUCTS[purchase.product] * purchase.quantity, account))
            return self._snapshot(db, account)

    def unlock(self, account, kind, item):
        if kind not in ("cat", "theme") or type(item) is not int or not 0 <= item < 4:
            raise ValueError("invalid item")
        cost = (CAT_PRICES if kind == "cat" else THEME_PRICES)[item]
        with self.connect() as db:
            db.execute("BEGIN IMMEDIATE")
            if item == 0 or db.execute("SELECT 1 FROM unlocks WHERE account=? AND kind=? AND item=?", (account, kind, item)).fetchone():
                return self._snapshot(db, account)
            changed = db.execute("UPDATE wallets SET tokens=tokens-? WHERE account=? AND tokens>=?", (cost, account, cost)).rowcount
            if changed != 1:
                raise ValueError("insufficient tokens")
            db.execute("INSERT INTO unlocks VALUES (?,?,?)", (account, kind, item))
            return self._snapshot(db, account)

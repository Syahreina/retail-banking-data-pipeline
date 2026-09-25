"""Generate reproducible, entirely fictional retail banking CSV data."""

from datetime import date, timedelta
from pathlib import Path
import random

import pandas as pd


SEED = 20260923
OUTPUT_DIR = Path(__file__).resolve().parents[1] / "data" / "raw"
RNG = random.Random(SEED)

FIRST_NAMES = ["Alya", "Bima", "Citra", "Dimas", "Eka", "Farah", "Gilang", "Hana", "Indra", "Jihan"]
LAST_NAMES = ["Pratama", "Putri", "Saputra", "Permata", "Nugraha", "Lestari", "Wijaya", "Salsabila"]
CITIES = ["Jakarta", "Bandung", "Surabaya", "Medan", "Semarang", "Yogyakarta"]


def random_date(start: date, end: date) -> str:
    """Return one random date within the inclusive range as ISO text."""
    days = (end - start).days
    return (start + timedelta(days=RNG.randint(0, days))).isoformat()


def make_customers(count: int = 1000) -> pd.DataFrame:
    rows = []
    for number in range(1, count + 1):
        rows.append({
            "customer_id": f"C{number:06d}",
            "customer_name": f"{RNG.choice(FIRST_NAMES)} {RNG.choice(LAST_NAMES)}",
            "city": RNG.choice(CITIES),
            "registration_date": random_date(date(2019, 1, 1), date(2025, 12, 31)),
        })
    # Each slice targets different rows so the issue counts are easy to verify.
    for index in range(10):
        rows[index]["city"] = RNG.choice(["JAKARTA", "jakarta", " Jakarta "])
    for index in range(10, 15):
        rows[index]["customer_name"] = f" {rows[index]['customer_name']} "
    rows.append(rows[20].copy())  # One exact duplicate customer record.
    return pd.DataFrame(rows)


def make_accounts(customer_ids: list[str], count: int = 1800) -> pd.DataFrame:
    rows = []
    for number in range(1, count + 1):
        rows.append({
            "account_id": f"A{number:07d}",
            "customer_id": RNG.choice(customer_ids),
            "account_type": RNG.choice(["SAVINGS", "CURRENT", "DEPOSIT"]),
            "opening_date": random_date(date(2020, 1, 1), date(2026, 6, 30)),
            "status": RNG.choices(["ACTIVE", "CLOSED"], weights=[85, 15])[0],
        })
    for index in range(4):
        rows[index]["customer_id"] = ""  # Missing master reference.
    return pd.DataFrame(rows)


def make_transactions(account_ids: list[str], count: int = 20000) -> pd.DataFrame:
    rows = []
    for number in range(1, count + 1):
        rows.append({
            "transaction_id": f"T{number:08d}",
            "account_id": RNG.choice(account_ids),
            "transaction_date": random_date(date(2025, 1, 1), date(2026, 8, 31)),
            "transaction_type": RNG.choice(["DEPOSIT", "WITHDRAWAL", "TRANSFER"]),
            "amount": RNG.randint(1, 5000) * 1000,
        })
    for index in range(0, 8):
        rows[index]["account_id"] = ""
    for index in range(8, 18):
        rows[index]["account_id"] = f"A999{index:04d}"  # Not in accounts master.
    for index in range(18, 30):
        rows[index]["transaction_date"] = date.fromisoformat(rows[index]["transaction_date"]).strftime("%d/%m/%Y")
    for index in range(30, 38):
        rows[index]["amount"] = None
    for index in range(38, 48):
        rows[index]["amount"] = -rows[index]["amount"]
    for index in range(48, 58):
        rows[index]["transaction_type"] = "UNKNOWN"
    for index in range(58, 63):
        rows[index]["transaction_type"] = f" {rows[index]['transaction_type']} "
    for index in range(5):
        rows.append(rows[100 + index].copy())  # Duplicate transaction IDs.
    return pd.DataFrame(rows)


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    customers = make_customers()
    accounts = make_accounts(customers["customer_id"].drop_duplicates().tolist())
    transactions = make_transactions(accounts["account_id"].tolist())

    for filename, frame in [
        ("customers.csv", customers),
        ("accounts.csv", accounts),
        ("transactions.csv", transactions),
    ]:
        frame.to_csv(OUTPUT_DIR / filename, index=False)
        print(f"{filename}: {len(frame):,} rows")

    print("Injected issues (before cleansing):")
    print("  customers: 1 duplicate row, 10 inconsistent city values, 5 padded names")
    print("  accounts: 4 missing customer_id values")
    print("  transactions: 5 duplicate IDs, 8 missing account_id, 10 orphan account_id,")
    print("                12 non-ISO dates, 8 missing amounts, 10 negative amounts,")
    print("                10 invalid types, 5 padded types")


if __name__ == "__main__":
    main()

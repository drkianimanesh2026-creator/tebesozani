# Public website visitor counter setup

The public counter is implemented with a Cloudflare Pages Function and D1. It counts at most one visit per browser per Tehran calendar day. The browser receives a first-party, HTTP-only day cookie. The database stores only aggregate daily totals; it does not store IP addresses or personal identifiers.

## One-time Cloudflare setup

1. In Cloudflare, open **Workers & Pages → D1 SQL Database** and create a database named `tebesozani-visits`.
2. Open the new database's **Console** and run the complete SQL from `database/visits.sql` in this repository.
3. Open **Workers & Pages → tebesozani → Settings → Bindings**.
4. Add a **D1 database binding**:
   - Variable name: `VISITS_DB`
   - Database: `tebesozani-visits`
5. Save the binding and trigger a new production deployment (or push a new commit).

## Verification

After deployment, open `https://marketing4u.ir/api/visits`. It should return JSON containing `total`, `today`, and `date`. Open the home page and the footer counter will display the totals. Visiting from the same browser more than once on the same Tehran calendar day will not increment the count again.

The counter is an approximate daily browser count, not a count of distinct human beings. It intentionally avoids retaining IP addresses. Cloudflare Web Analytics remains the source for detailed private analytics.

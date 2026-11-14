const json = (data, status = 200, extraHeaders = {}) => new Response(JSON.stringify(data), {
  status,
  headers: {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store, max-age=0",
    "x-content-type-options": "nosniff",
    ...extraHeaders
  }
});

const todayInTehran = () => new Intl.DateTimeFormat("en-CA", {
  timeZone: "Asia/Tehran",
  year: "numeric",
  month: "2-digit",
  day: "2-digit"
}).format(new Date());

async function readCounts(db, day) {
  const [totalRow, todayRow] = await Promise.all([
    db.prepare("SELECT total_count FROM site_stats WHERE id = 'all'").first(),
    db.prepare("SELECT visit_count FROM daily_visits WHERE visit_day = ?1").bind(day).first()
  ]);
  return {
    total: Number(totalRow?.total_count || 0),
    today: Number(todayRow?.visit_count || 0)
  };
}

export async function onRequest({ request, env }) {
  if (!env.VISITS_DB) {
    return json({ error: "Visitor counter is not configured yet." }, 503);
  }

  if (request.method !== "GET" && request.method !== "POST") {
    return json({ error: "Method not allowed." }, 405, { allow: "GET, POST" });
  }

  if (request.method === "POST") {
    const origin = request.headers.get("Origin");
    if (origin) {
      try {
        if (new URL(origin).host !== new URL(request.url).host) {
          return json({ error: "Origin not allowed." }, 403);
        }
      } catch {
        return json({ error: "Invalid origin." }, 400);
      }
    }
  }

  const day = todayInTehran();

  try {
    if (request.method === "POST") {
      const cookie = request.headers.get("Cookie") || "";
      const seenToday = cookie.split(";").some(part => {
        const [key, ...value] = part.trim().split("=");
        return key === "site_visit_day" && value.join("=") === day;
      });

      if (!seenToday) {
        await env.VISITS_DB.batch([
          env.VISITS_DB.prepare(
            "INSERT INTO daily_visits (visit_day, visit_count) VALUES (?1, 1) ON CONFLICT(visit_day) DO UPDATE SET visit_count = visit_count + 1"
          ).bind(day),
          env.VISITS_DB.prepare(
            "INSERT INTO site_stats (id, total_count) VALUES ('all', 1) ON CONFLICT(id) DO UPDATE SET total_count = total_count + 1"
          )
        ]);
      }

      const counts = await readCounts(env.VISITS_DB, day);
      const headers = seenToday ? {} : {
        "set-cookie": `site_visit_day=${day}; Path=/; Max-Age=31536000; Secure; HttpOnly; SameSite=Lax`
      };
      return json({ ...counts, counted: !seenToday, date: day }, 200, headers);
    }

    return json({ ...(await readCounts(env.VISITS_DB, day)), date: day });
  } catch {
    return json({ error: "Unable to read visitor statistics." }, 500);
  }
}

export async function onRequest({ request, next }) {
  const response = await next();
  const url = new URL(request.url);

  if (url.pathname.startsWith("/api/") ||
      !((response.headers.get("content-type") || "").includes("text/html")) ||
      response.status !== 200) {
    return response;
  }

  const html = await response.text();
  if (!/<\/body>/i.test(html)) return new Response(html, response);

  const script = `<script>
(function () {
  var total = document.getElementById("siteVisitCount");
  var today = document.getElementById("siteVisitToday");
  fetch("/api/visits", { method: "POST", headers: { "Accept": "application/json" }, credentials: "same-origin" })
    .then(function (response) {
      if (!response.ok) throw new Error("counter unavailable");
      return response.json();
    })
    .then(function (data) {
      if (total) total.textContent = Number(data.total || 0).toLocaleString("fa-IR");
      if (today) today.textContent = Number(data.today || 0).toLocaleString("fa-IR");
    })
    .catch(function () {
      if (total) total.textContent = "به‌زودی";
      if (today) today.textContent = "—";
    });
})();
</script>`;

  const headers = new Headers(response.headers);
  headers.delete("content-length");
  headers.delete("content-encoding");
  headers.delete("etag");
  const updated = html.replace(/<\/body>/i, script + "</body>");
  return new Response(updated, {
    status: response.status,
    statusText: response.statusText,
    headers
  });
}

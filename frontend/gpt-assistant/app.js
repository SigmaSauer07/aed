async function ask() {
  const q = document.getElementById("question").value;
  const res = await fetch("/ask", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ message: q })
  });
  const data = await res.json();
  document.getElementById("response").textContent = data.response || data.error;
}
